import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../app/config.dart';
import '../../core/log.dart';

/// manifest.json published next to every SDE release (see pipeline/sde_pipeline/manifest.py).
class SdeManifest {
  const SdeManifest({
    required this.buildNumber,
    required this.releaseDate,
    required this.url,
    required this.sha256,
    required this.size,
    required this.schemaVersion,
    required this.compression,
  });

  factory SdeManifest.fromJson(Map<String, dynamic> json) => SdeManifest(
        buildNumber: (json['buildNumber'] as num).toInt(),
        releaseDate: json['releaseDate'] as String? ?? '',
        url: json['url'] as String,
        sha256: (json['sha256'] as String).toLowerCase(),
        size: (json['size'] as num).toInt(),
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        compression: json['compression'] as String? ?? 'gzip',
      );

  final int buildNumber;
  final String releaseDate;
  final String url;
  final String sha256;
  final int size;
  final int schemaVersion;
  final String compression;
}

sealed class SdeInstallException implements Exception {
  const SdeInstallException();
}

class SdeChecksumMismatch extends SdeInstallException {
  const SdeChecksumMismatch(this.expected, this.actual);

  final String expected;
  final String actual;
}

class SdeSchemaUnsupported extends SdeInstallException {
  const SdeSchemaUnsupported(this.schemaVersion);

  final int schemaVersion;
}

class SdeInvalidDatabase extends SdeInstallException {
  const SdeInvalidDatabase(this.reason);

  final String reason;

  @override
  String toString() => 'SdeInvalidDatabase($reason)';
}

/// Downloads, verifies and installs the SDE database:
///   download to `sde.download`  ->  SHA-256 must equal the manifest
///   gunzip to `sde.new`          ->  user_version, meta.buildNumber, quick_check
///   rename sde.new over sde.sqlite  (same directory, so the swap is atomic)
/// The live database is only touched by the final rename; any failure leaves it as it was.
class SdeInstaller {
  SdeInstaller({required this.dio, required this.directory});

  final Dio dio;
  final Directory directory;

  File get databaseFile => File(p.join(directory.path, 'sde.sqlite'));
  File get _download => File(p.join(directory.path, 'sde.download'));
  File get _staged => File(p.join(directory.path, 'sde.new'));

  static Dio createDio() => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(minutes: 5),
          headers: {'User-Agent': AppConfig.userAgent},
        ),
      );

  Future<SdeManifest> fetchManifest({String url = AppConfig.sdeManifestUrl}) async {
    final resp = await dio.get<String>(url, options: Options(responseType: ResponseType.plain));
    return SdeManifest.fromJson(jsonDecode(resp.data ?? '{}') as Map<String, dynamic>);
  }

  /// Build number of the installed database, or null when there is none (or it is unreadable).
  int? installedBuild() {
    if (!databaseFile.existsSync()) return null;
    try {
      return readBuildNumber(databaseFile);
    } on Object catch (e) {
      appLog('installed SDE unreadable: $e');
      return null;
    }
  }

  static int readBuildNumber(File file) {
    final db = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
    try {
      final row = db.select("SELECT value FROM meta WHERE key = 'buildNumber'");
      if (row.isEmpty) throw const SdeInvalidDatabase('meta.buildNumber missing');
      return int.parse(row.first['value'] as String);
    } finally {
      db.close();
    }
  }

  /// Downloads and installs [manifest]. [beforeSwap] runs right before the live file is
  /// replaced; the caller closes its open connection there.
  Future<void> install(
    SdeManifest manifest, {
    void Function(int received, int total)? onProgress,
    Future<void> Function()? beforeSwap,
    CancelToken? cancelToken,
  }) async {
    if (manifest.schemaVersion > AppConfig.supportedSdeSchema) throw SdeSchemaUnsupported(manifest.schemaVersion);
    await directory.create(recursive: true);
    for (final f in [_download, _staged]) {
      if (f.existsSync()) f.deleteSync();
    }
    try {
      await dio.download(
        manifest.url,
        _download.path,
        cancelToken: cancelToken,
        onReceiveProgress: (r, t) => onProgress?.call(r, t > 0 ? t : manifest.size),
      );
      await installFromFile(_download, manifest, beforeSwap: beforeSwap);
    } finally {
      for (final f in [_download, _staged]) {
        if (f.existsSync()) f.deleteSync();
      }
    }
  }

  /// Verifies and installs an already downloaded file (also used by tests).
  Future<void> installFromFile(File downloaded, SdeManifest manifest, {Future<void> Function()? beforeSwap}) async {
    final actual = (await sha256.bind(downloaded.openRead()).first).toString();
    if (actual != manifest.sha256) throw SdeChecksumMismatch(manifest.sha256, actual);

    if (manifest.compression == 'gzip') {
      await downloaded.openRead().transform(gzip.decoder).pipe(_staged.openWrite());
    } else {
      await downloaded.copy(_staged.path);
    }
    _validate(_staged, manifest);
    await beforeSwap?.call();
    await _staged.rename(databaseFile.path);
    appLog('SDE ${manifest.buildNumber} installed');
  }

  static void _validate(File file, SdeManifest manifest) {
    final db = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
    try {
      final version = db.select('PRAGMA user_version').first.values.first as int;
      if (version > AppConfig.supportedSdeSchema) throw SdeSchemaUnsupported(version);
      final check = db.select('PRAGMA quick_check').first.values.first;
      if (check != 'ok') throw SdeInvalidDatabase('quick_check: $check');
      final build = db.select("SELECT value FROM meta WHERE key = 'buildNumber'");
      if (build.isEmpty || int.parse(build.first['value'] as String) != manifest.buildNumber) {
        throw const SdeInvalidDatabase('build number differs from manifest');
      }
      final types = db.select('SELECT COUNT(*) AS n FROM inv_types').first['n'] as int;
      if (types == 0) throw const SdeInvalidDatabase('no types');
    } on sqlite.SqliteException catch (e) {
      throw SdeInvalidDatabase(e.message);
    } finally {
      db.close();
    }
  }
}
