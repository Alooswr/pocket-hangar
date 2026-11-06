import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'esi_client.dart';

/// ESI cache persisted in the app database, so cached data survives restarts and the app
/// still shows the last known state offline.
class DriftEsiCacheStore implements EsiCacheStore {
  DriftEsiCacheStore(this.db);

  final AppDatabase db;

  @override
  Future<CachedResponse?> read(String key) async {
    final row = await (db.select(db.httpCacheEntries)..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
    if (row == null) return null;
    return CachedResponse(
      body: row.body,
      storedAt: row.storedAt,
      etag: row.etag,
      expires: row.expires,
      lastModified: row.lastModified,
      pages: row.pages,
    );
  }

  @override
  Future<void> write(String key, CachedResponse value) => db.into(db.httpCacheEntries).insertOnConflictUpdate(
        HttpCacheEntriesCompanion.insert(
          cacheKey: key,
          body: value.body,
          storedAt: value.storedAt,
          etag: Value(value.etag),
          expires: Value(value.expires),
          lastModified: Value(value.lastModified),
          pages: Value(value.pages),
        ),
      );

  @override
  Future<void> deleteForCharacter(int characterId) =>
      (db.delete(db.httpCacheEntries)..where((t) => t.cacheKey.like('$characterId|%'))).go();

  /// Drops entries nobody has refreshed for [age]; called at startup.
  Future<int> prune(Duration age) =>
      (db.delete(db.httpCacheEntries)..where((t) => t.storedAt.isSmallerThanValue(DateTime.now().subtract(age)))).go();
}
