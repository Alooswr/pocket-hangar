import 'package:dio/dio.dart';
import 'package:jose/jose.dart';

import '../../app/config.dart';

class EveTokenClaims {
  const EveTokenClaims({
    required this.characterId,
    required this.name,
    required this.scopes,
    required this.expiry,
    this.ownerHash,
  });

  final int characterId;
  final String name;
  final List<String> scopes;
  final DateTime expiry;
  final String? ownerHash;
}

class JwtValidationException implements Exception {
  const JwtValidationException(this.reason);

  final String reason;

  @override
  String toString() => 'JwtValidationException($reason)';
}

typedef JwksLoader = Future<Map<String, dynamic>> Function();

/// Verifies EVE SSO access tokens as described in the SSO docs:
/// signature against the JWKS published by login.eveonline.com (RS256 or ES256), issuer,
/// audience (our client id and "EVE Online"), expiry; then reads the character from "sub".
class EveJwtVerifier {
  EveJwtVerifier({required this.loadJwks, required this.clientId, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final JwksLoader loadJwks;
  final String clientId;
  final DateTime Function() _clock;

  static const acceptedIssuers = {
    'login.eveonline.com',
    'https://login.eveonline.com',
    'https://login.eveonline.com/',
  };
  static const _algorithms = ['RS256', 'ES256'];
  static const _jwksMaxAge = Duration(hours: 12);
  static const _leeway = Duration(seconds: 30);

  JsonWebKeyStore? _store;
  DateTime? _storeLoadedAt;

  /// Production loader: metadata document first, then the jwks_uri it names (the SSO docs ask
  /// not to hard-code the JWKS location).
  static JwksLoader httpLoader(Dio dio) => () async {
        final meta = await dio.get<Map<String, dynamic>>(AppConfig.ssoMetadataUrl);
        final uri = meta.data?['jwks_uri'] as String?;
        if (uri == null) throw const JwtValidationException('metadata has no jwks_uri');
        final jwks = await dio.get<Map<String, dynamic>>(uri);
        return jwks.data ?? const {'keys': <Object>[]};
      };

  Future<JsonWebKeyStore> _keyStore({bool reload = false}) async {
    final loadedAt = _storeLoadedAt;
    final cached = _store;
    if (!reload && cached != null && loadedAt != null && _clock().difference(loadedAt) < _jwksMaxAge) {
      return cached;
    }
    final store = JsonWebKeyStore()..addKeySet(JsonWebKeySet.fromJson(await loadJwks()));
    _store = store;
    _storeLoadedAt = _clock();
    return store;
  }

  Future<EveTokenClaims> verify(String token) async {
    JsonWebToken jwt;
    try {
      jwt = await JsonWebToken.decodeAndVerify(token, await _keyStore(), allowedArguments: _algorithms);
    } on Object {
      // Unknown key id after a key rotation: reload the key set once.
      try {
        jwt = await JsonWebToken.decodeAndVerify(token, await _keyStore(reload: true), allowedArguments: _algorithms);
      } on Object catch (e) {
        throw JwtValidationException('signature: ${e.runtimeType}');
      }
    }
    return checkClaims(jwt.claims.toJson());
  }

  EveTokenClaims checkClaims(Map<String, dynamic> claims) {
    final iss = claims['iss'];
    if (iss is! String || !acceptedIssuers.contains(iss)) {
      throw JwtValidationException('issuer $iss');
    }
    final aud = claims['aud'];
    final audiences = aud is List ? aud.map((e) => '$e').toSet() : {if (aud != null) '$aud'};
    if (!audiences.contains(clientId) || !audiences.contains('EVE Online')) {
      throw const JwtValidationException('audience');
    }
    final exp = claims['exp'];
    if (exp is! num) throw const JwtValidationException('no exp');
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
    if (_clock().toUtc().isAfter(expiry.add(_leeway))) throw const JwtValidationException('expired');

    final sub = claims['sub'];
    final match = sub is String ? RegExp(r'^CHARACTER:EVE:(\d+)$').firstMatch(sub) : null;
    if (match == null) throw JwtValidationException('subject $sub');

    final scp = claims['scp'];
    final scopes = switch (scp) {
      final String s => [s],
      final List<dynamic> l => [for (final s in l) '$s'],
      _ => const <String>[],
    };
    return EveTokenClaims(
      characterId: int.parse(match.group(1)!),
      name: '${claims['name'] ?? ''}',
      scopes: scopes,
      expiry: expiry,
      ownerHash: claims['owner'] as String?,
    );
  }
}
