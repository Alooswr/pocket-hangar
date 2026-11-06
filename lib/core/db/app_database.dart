import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Signed-in characters. Refresh tokens are NOT here; they live in the platform keystore
/// (see core/auth/token_store.dart).
class Characters extends Table {
  IntColumn get characterId => integer()();
  TextColumn get name => text()();
  TextColumn get scopes => text().withDefault(const Constant(''))();
  BoolColumn get needsRelogin => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {characterId};
}

/// ESI response cache, keyed by character + path + query. Holds what the Expires / ETag /
/// Last-Modified headers said so requests are never repeated before ESI has new data.
class HttpCacheEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get body => text()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get expires => dateTime().nullable()();
  TextColumn get lastModified => text().nullable()();
  IntColumn get pages => integer().nullable()();
  DateTimeColumn get storedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

class FavoriteTypes extends Table {
  IntColumn get typeId => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {typeId};
}

/// Fits are stored as EFT text: portable, readable, and the same format the user imports.
class SavedFits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get shipTypeId => integer()();
  TextColumn get fitJson => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Player structures we looked up (or were refused). Lets "unknown structure" still show a
/// solar system when we learned it earlier, and avoids re-asking ESI for structures that 403.
class StructureInfos extends Table {
  IntColumn get structureId => integer()();
  TextColumn get name => text().nullable()();
  IntColumn get solarSystemId => integer().nullable()();
  IntColumn get typeId => integer().nullable()();
  BoolColumn get accessDenied => boolean().withDefault(const Constant(false))();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {structureId};
}

class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Characters, HttpCacheEntries, FavoriteTypes, SavedFits, StructureInfos, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.open() : super(driftDatabase(name: 'pocket_hangar'));

  @override
  int get schemaVersion => 1;

  // ---- key/value settings ----
  Future<String?> getValue(String key) async =>
      (await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setValue(String key, String? value) async {
    if (value == null) {
      await (delete(keyValues)..where((t) => t.key.equals(key))).go();
    } else {
      await into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));
    }
  }
}
