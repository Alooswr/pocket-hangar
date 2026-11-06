import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/db/app_database.dart';
import 'core/esi/esi_cache_drift.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  final support = await getApplicationSupportDirectory();
  final dataDir = Directory(p.join(support.path, 'sde'));
  await dataDir.create(recursive: true);
  unawaited(DriftEsiCacheStore(db).prune(const Duration(days: 30)));

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        dataDirectoryProvider.overrideWithValue(dataDir),
      ],
      // Riverpod 3 retries failing providers by default. ESI counts every error against the
      // error limit (100 per minute for everyone behind this IP + app), so failures are shown
      // and the user retries; nothing retries in a loop.
      retry: (retryCount, error) => null,
      child: const PocketHangarApp(),
    ),
  );
}
