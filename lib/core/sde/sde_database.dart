import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../search/name_search.dart';

/// The static data file built by pipeline/ and downloaded from the GitHub release.
/// Its schema belongs to the pipeline, so there are no generated tables here: queries are
/// plain SQL through [customSelect]. Migrations are disabled so drift never writes to it.
/// Every connection gets the name search function `ph_name_score` (see [registerNameSearch]).
class SdeDatabase extends GeneratedDatabase {
  SdeDatabase(super.executor);

  /// Opens on a background isolate; the search function is installed there.
  factory SdeDatabase.openFile(File file) =>
      SdeDatabase(NativeDatabase.createInBackground(file, enableMigrations: false, setup: registerNameSearch));

  /// Synchronous, same-isolate open. Used by tests and by the installer's validation step.
  factory SdeDatabase.openFileSync(File file) =>
      SdeDatabase(NativeDatabase(file, enableMigrations: false, setup: registerNameSearch));

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}
