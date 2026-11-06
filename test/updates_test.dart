import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/app/config.dart';
import 'package:pocket_hangar/features/update/app_update.dart';
import 'package:pocket_hangar/features/update/sde_installer.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// A database shaped like the pipeline output, gzipped, plus its manifest.
(File, SdeManifest) makeRelease(Directory dir, {required int build, int schema = 1, int types = 1}) {
  final raw = File('${dir.path}/raw-$build.sqlite');
  if (raw.existsSync()) raw.deleteSync();
  final db = sqlite.sqlite3.open(raw.path);
  db
    ..execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)')
    ..execute('CREATE TABLE inv_types (type_id INTEGER PRIMARY KEY, name_en TEXT)')
    ..execute("INSERT INTO meta VALUES ('buildNumber', '$build')")
    ..execute('PRAGMA user_version = $schema');
  for (var i = 0; i < types; i++) {
    db.execute("INSERT INTO inv_types VALUES (${587 + i}, 'Rifter')");
  }
  db.close();
  final gz = File('${dir.path}/eve-sde-$build.sqlite.gz')..writeAsBytesSync(gzip.encode(raw.readAsBytesSync()));
  return (
    gz,
    SdeManifest(
      buildNumber: build,
      releaseDate: '2026-11-04T12:07:32Z',
      url: 'https://example.invalid/eve-sde-$build.sqlite.gz',
      sha256: sha256.convert(gz.readAsBytesSync()).toString(),
      size: gz.lengthSync(),
      schemaVersion: schema,
      compression: 'gzip',
    ),
  );
}

void main() {
  late Directory dir;
  late SdeInstaller installer;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sde_installer_test');
    installer = SdeInstaller(dio: Dio(), directory: Directory('${dir.path}/data')..createSync());
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('game data install', () {
    test('installs a verified build and replaces an older one', () async {
      final (gz1, m1) = makeRelease(dir, build: 100);
      await installer.installFromFile(gz1, m1);
      expect(installer.installedBuild(), 100);
      final (gz2, m2) = makeRelease(dir, build: 101);
      var swapped = false;
      await installer.installFromFile(gz2, m2, beforeSwap: () async => swapped = true);
      expect(swapped, isTrue);
      expect(installer.installedBuild(), 101);
    });

    test('a checksum mismatch leaves the installed data alone', () async {
      final (gz1, m1) = makeRelease(dir, build: 100);
      await installer.installFromFile(gz1, m1);
      final (gz2, m2) = makeRelease(dir, build: 101);
      final wrong = SdeManifest(
        buildNumber: m2.buildNumber,
        releaseDate: m2.releaseDate,
        url: m2.url,
        sha256: '0' * 64,
        size: m2.size,
        schemaVersion: 1,
        compression: 'gzip',
      );
      await expectLater(installer.installFromFile(gz2, wrong), throwsA(isA<SdeChecksumMismatch>()));
      expect(installer.installedBuild(), 100);
    });

    test('a database from a newer schema is refused', () async {
      final (gz, m) = makeRelease(dir, build: 102, schema: AppConfig.supportedSdeSchema + 1);
      await expectLater(installer.install(m), throwsA(isA<SdeSchemaUnsupported>()));
      // Also when only the file says so.
      final lying = SdeManifest(
        buildNumber: m.buildNumber,
        releaseDate: m.releaseDate,
        url: m.url,
        sha256: m.sha256,
        size: m.size,
        schemaVersion: 1,
        compression: 'gzip',
      );
      await expectLater(installer.installFromFile(gz, lying), throwsA(isA<SdeSchemaUnsupported>()));
      expect(installer.installedBuild(), isNull);
    });

    test('build number must match the manifest, and the file must have types', () async {
      final (gz, m) = makeRelease(dir, build: 103);
      final other = SdeManifest(
        buildNumber: 999,
        releaseDate: m.releaseDate,
        url: m.url,
        sha256: m.sha256,
        size: m.size,
        schemaVersion: 1,
        compression: 'gzip',
      );
      await expectLater(installer.installFromFile(gz, other), throwsA(isA<SdeInvalidDatabase>()));
      final (empty, me) = makeRelease(dir, build: 104, types: 0);
      await expectLater(installer.installFromFile(empty, me), throwsA(isA<SdeInvalidDatabase>()));
      expect(installer.installedBuild(), isNull);
    });

    test('manifest JSON from the pipeline', () {
      final m = SdeManifest.fromJson({
        'buildNumber': 3670638,
        'releaseDate': '2026-11-04T12:07:32Z',
        'url': 'https://github.com/Alooswr/pocket-hangar/releases/download/sde-3670638/eve-sde-3670638.sqlite.gz',
        'sha256': 'D2577F14',
        'size': 3022889,
        'schemaVersion': 1,
        'compression': 'gzip',
        'uncompressedSize': 9338880,
      });
      expect(m.buildNumber, 3670638);
      expect(m.sha256, 'd2577f14');
    });
  });

  group('app release check', () {
    Map<String, dynamic> release(String tag, {bool draft = false, bool pre = false, bool apk = true}) => {
          'tag_name': tag,
          'draft': draft,
          'prerelease': pre,
          'html_url': 'https://github.com/x/y/releases/tag/$tag',
          'assets': [
            if (apk) {'name': 'PocketHangar-$tag.apk', 'browser_download_url': 'https://example.invalid/$tag.apk'},
          ],
        };

    test('data releases in the same repository are never taken for app versions', () {
      final r = newestAppRelease([release('sde-3670638'), release('sde-latest')], currentVersion: '0.1.0');
      expect(r, isNull);
    });

    test('picks the highest v-tag, skipping drafts and pre-releases', () {
      final r = newestAppRelease(
        [release('sde-3670639'), release('v0.3.0', pre: true), release('v0.2.1'), release('v0.2.0'), release('v0.4.0', draft: true)],
        currentVersion: '0.1.0',
      );
      expect(r?.version, '0.2.1');
      expect(r?.downloadUrl.toString(), 'https://example.invalid/v0.2.1.apk');
    });

    test('nothing when the app is current', () {
      expect(newestAppRelease([release('v0.1.0')], currentVersion: '0.1.0'), isNull);
    });
  });

  group('app version compare', () {
    test('numeric, ignores v prefix and build suffix', () {
      expect(compareVersions('0.1.0', '0.1.1'), lessThan(0));
      expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('v1.2.0', '1.2.0+5'), 0);
      expect(compareVersions('2.0', '1.99.99'), greaterThan(0));
    });
  });
}
