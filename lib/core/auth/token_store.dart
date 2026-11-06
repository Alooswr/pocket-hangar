import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Android Keystore / iOS Keychain via flutter_secure_storage.
class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemorySecretStore implements SecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Refresh tokens only. Access tokens live in memory (20 minute lifetime) and are never written
/// to disk or logs.
class TokenStore {
  TokenStore(this._store);

  final SecretStore _store;

  static String _key(int characterId) => 'eve.refresh.$characterId';

  Future<String?> refreshToken(int characterId) => _store.read(_key(characterId));

  Future<void> saveRefreshToken(int characterId, String token) => _store.write(_key(characterId), token);

  Future<void> delete(int characterId) => _store.delete(_key(characterId));
}
