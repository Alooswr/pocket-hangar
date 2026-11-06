import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../app/config.dart';
import '../esi/esi_errors.dart';
import '../log.dart';
import 'jwt_verifier.dart';
import 'token_store.dart';

class OAuthTokens {
  const OAuthTokens({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;
}

/// Opens the EVE login page and returns tokens; null when the user cancels.
abstract interface class OAuthLauncher {
  Future<OAuthTokens?> authorize();
}

/// Authorization code + PKCE through AppAuth (flutter_appauth). AppAuth generates the code
/// verifier and the S256 challenge and exchanges the code; no client secret exists in the app.
class AppAuthLauncher implements OAuthLauncher {
  const AppAuthLauncher();

  static const _appAuth = FlutterAppAuth();

  @override
  Future<OAuthTokens?> authorize() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.ssoClientId,
          AppConfig.ssoRedirectUrl,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: AppConfig.ssoAuthorizeUrl,
            tokenEndpoint: AppConfig.ssoTokenUrl,
          ),
          scopes: AppConfig.ssoScopes,
          externalUserAgent: ExternalUserAgent.ephemeralAsWebAuthenticationSession,
        ),
      );
      final access = result.accessToken;
      if (access == null) return null;
      return OAuthTokens(accessToken: access, refreshToken: result.refreshToken);
    } on FlutterAppAuthUserCancelledException {
      return null;
    }
  }
}

/// Holds access tokens in memory, refreshes them with the stored refresh token (one request per
/// character at a time) and stores rotated refresh tokens.
class AuthService {
  AuthService({
    required this.ssoDio,
    required this.tokens,
    required this.verifier,
    required this.launcher,
    required this.clientId,
    this.onReloginRequired,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Dio ssoDio;
  final TokenStore tokens;
  final EveJwtVerifier verifier;
  final OAuthLauncher launcher;
  final String clientId;
  final void Function(int characterId)? onReloginRequired;
  final DateTime Function() _clock;

  final _access = <int, (String, DateTime)>{};
  final _inflight = <int, Future<String>>{};

  static const _refreshMargin = Duration(seconds: 60);

  bool get isConfigured => clientId.isNotEmpty;

  static Dio createSsoDio() => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'User-Agent': AppConfig.userAgent},
        ),
      );

  /// Interactive sign-in. Returns null when cancelled.
  Future<EveTokenClaims?> signIn() async {
    final result = await launcher.authorize();
    if (result == null) return null;
    final claims = await verifier.verify(result.accessToken);
    final refresh = result.refreshToken;
    if (refresh == null) throw const JwtValidationException('SSO returned no refresh token');
    await tokens.saveRefreshToken(claims.characterId, refresh);
    _access[claims.characterId] = (result.accessToken, claims.expiry);
    appLog('signed in character ${claims.characterId}');
    return claims;
  }

  /// A valid access token for [characterId], refreshing it when it expires within a minute.
  Future<String> accessToken(int characterId, {bool forceRefresh = false}) {
    final cached = _access[characterId];
    if (!forceRefresh && cached != null && cached.$2.isAfter(_clock().toUtc().add(_refreshMargin))) {
      return Future.value(cached.$1);
    }
    return _inflight[characterId] ??= _refresh(characterId).whenComplete(() => _inflight.remove(characterId));
  }

  Future<String> _refresh(int characterId) async {
    final refresh = await tokens.refreshToken(characterId);
    if (refresh == null) {
      onReloginRequired?.call(characterId);
      throw EsiReloginRequired(characterId);
    }
    final Response<Map<String, dynamic>> resp;
    try {
      resp = await ssoDio.post<Map<String, dynamic>>(
        AppConfig.ssoTokenUrl,
        data: {'grant_type': 'refresh_token', 'refresh_token': refresh, 'client_id': clientId},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw EsiNetworkError(e.type);
    }
    final status = resp.statusCode ?? 0;
    if (status == 400 || status == 401 || status == 403) {
      // invalid_grant: revoked in the account settings, or expired. Only a new login helps.
      appLog('refresh rejected for $characterId: $status');
      onReloginRequired?.call(characterId);
      throw EsiReloginRequired(characterId);
    }
    if (status != 200 || resp.data == null) throw EsiServerError(status);
    final body = resp.data!;
    final access = body['access_token'] as String?;
    if (access == null) throw EsiServerError(status);
    final claims = await verifier.verify(access);
    if (claims.characterId != characterId) {
      throw const JwtValidationException('refreshed token belongs to another character');
    }
    final rotated = body['refresh_token'] as String?;
    if (rotated != null && rotated != refresh) await tokens.saveRefreshToken(characterId, rotated);
    _access[characterId] = (access, claims.expiry);
    return access;
  }

  /// Forgets the character on this device and asks SSO to revoke the refresh token.
  Future<void> signOut(int characterId) async {
    final refresh = await tokens.refreshToken(characterId);
    _access.remove(characterId);
    await tokens.delete(characterId);
    if (refresh == null) return;
    try {
      await ssoDio.post<Object?>(
        AppConfig.ssoRevokeUrl,
        data: {'token_type_hint': 'refresh_token', 'token': refresh, 'client_id': clientId},
        options: Options(contentType: Headers.formUrlEncodedContentType, validateStatus: (_) => true),
      );
    } on DioException {
      // Revocation is best effort; the token is already gone from this device.
    }
  }
}
