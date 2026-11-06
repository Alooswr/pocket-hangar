import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/config.dart';
import 'auth/auth_service.dart';
import 'auth/jwt_verifier.dart';
import 'auth/token_store.dart';
import 'db/app_database.dart';
import 'esi/esi_cache_drift.dart';
import 'esi/esi_client.dart';
import 'esi/eve_api.dart';
import 'esi/rate_limiter.dart';

/// Overridden in main() with the opened database.
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('appDatabaseProvider'));

/// Directory that holds sde.sqlite. Overridden in main().
final dataDirectoryProvider = Provider<Directory>((ref) => throw UnimplementedError('dataDirectoryProvider'));

final secretStoreProvider = Provider<SecretStore>((ref) => const SecureSecretStore());

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore(ref.watch(secretStoreProvider)));

final ssoDioProvider = Provider<Dio>((ref) => AuthService.createSsoDio());

final oauthLauncherProvider = Provider<OAuthLauncher>((ref) => const AppAuthLauncher());

/// Called by the auth layer when a refresh token is rejected; the accounts notifier listens.
final reloginSignalProvider = Provider<ValueNotifier<int?>>((ref) {
  final notifier = ValueNotifier<int?>(null);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(ssoDioProvider);
  final signal = ref.watch(reloginSignalProvider);
  return AuthService(
    ssoDio: dio,
    tokens: ref.watch(tokenStoreProvider),
    verifier: EveJwtVerifier(loadJwks: EveJwtVerifier.httpLoader(dio), clientId: AppConfig.ssoClientId),
    launcher: ref.watch(oauthLauncherProvider),
    clientId: AppConfig.ssoClientId,
    onReloginRequired: (id) => signal.value = id,
  );
});

final esiRateLimiterProvider = Provider<EsiRateLimiter>((ref) => EsiRateLimiter());

final esiCacheProvider = Provider<EsiCacheStore>((ref) => DriftEsiCacheStore(ref.watch(appDatabaseProvider)));

final esiClientProvider = Provider<EsiClient>((ref) {
  final auth = ref.watch(authServiceProvider);
  return EsiClient(
    dio: EsiClient.createDio(),
    cache: ref.watch(esiCacheProvider),
    limiter: ref.watch(esiRateLimiterProvider),
    accessToken: auth.accessToken,
  );
});

final eveApiProvider = Provider<EveApi>((ref) => EveApi(ref.watch(esiClientProvider)));
