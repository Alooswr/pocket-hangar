import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/log.dart';
import '../../core/providers.dart';
import '../../core/sde/sde_database.dart';
import '../../core/sde/sde_models.dart';
import '../../core/sde/sde_repository.dart';
import 'sde_installer.dart';

enum SdePhase { idle, checking, downloading, installing }

class SdeState {
  const SdeState({
    this.repository,
    this.installedBuild,
    this.manifest,
    this.phase = SdePhase.idle,
    this.progress,
    this.error,
    this.lastInstalled,
  });

  /// Null until a database is installed.
  final SdeRepository? repository;
  final int? installedBuild;

  /// Latest manifest read from the release, if the check succeeded.
  final SdeManifest? manifest;
  final SdePhase phase;
  final double? progress;
  final Object? error;
  final int? lastInstalled;

  bool get installed => repository != null;

  bool get updateAvailable =>
      manifest != null && installedBuild != null && manifest!.buildNumber != installedBuild;

  SdeState copyWith({
    SdeRepository? repository,
    int? installedBuild,
    SdeManifest? manifest,
    SdePhase? phase,
    double? progress,
    Object? error,
    int? lastInstalled,
    bool clearError = false,
    bool clearProgress = false,
  }) =>
      SdeState(
        repository: repository ?? this.repository,
        installedBuild: installedBuild ?? this.installedBuild,
        manifest: manifest ?? this.manifest,
        phase: phase ?? this.phase,
        progress: clearProgress ? null : (progress ?? this.progress),
        error: clearError ? null : (error ?? this.error),
        lastInstalled: lastInstalled ?? this.lastInstalled,
      );
}

/// Owns the open SDE connection. Startup: open the installed file (if any) and read
/// manifest.json once; a different build number shows the update banner. Installing closes the
/// connection, swaps the file atomically and reopens it.
class SdeController extends Notifier<SdeState> {
  SdeDatabase? _db;
  SdeInstaller? _installer;
  CancelToken? _cancel;

  SdeInstaller get installer => _installer!;

  @override
  SdeState build() {
    _installer = SdeInstaller(dio: SdeInstaller.createDio(), directory: ref.watch(dataDirectoryProvider));
    ref.onDispose(() {
      _cancel?.cancel();
      unawaited(_db?.close());
    });
    final build = installer.installedBuild();
    SdeRepository? repository;
    if (build != null) {
      _db = SdeDatabase.openFile(installer.databaseFile);
      repository = SdeRepository(_db!);
    }
    Future.microtask(checkForUpdate);
    return SdeState(repository: repository, installedBuild: build);
  }

  Future<void> checkForUpdate() async {
    if (state.phase != SdePhase.idle) return;
    state = state.copyWith(phase: SdePhase.checking, clearError: true);
    try {
      final manifest = await installer.fetchManifest();
      state = state.copyWith(manifest: manifest, phase: SdePhase.idle);
    } on Object catch (e) {
      appLog('manifest check failed: $e');
      state = state.copyWith(phase: SdePhase.idle, error: e);
    }
  }

  Future<void> installLatest() async {
    var manifest = state.manifest;
    if (state.phase == SdePhase.downloading || state.phase == SdePhase.installing) return;
    state = state.copyWith(phase: SdePhase.downloading, progress: 0, clearError: true);
    try {
      manifest ??= await installer.fetchManifest();
      _cancel = CancelToken();
      await installer.install(
        manifest,
        cancelToken: _cancel,
        onProgress: (received, total) {
          state = state.copyWith(progress: total > 0 ? received / total : null);
        },
        beforeSwap: () async {
          state = state.copyWith(phase: SdePhase.installing, clearProgress: true);
          final old = _db;
          _db = null;
          await old?.close();
        },
      );
      _db = SdeDatabase.openFile(installer.databaseFile);
      state = SdeState(
        repository: SdeRepository(_db!),
        installedBuild: manifest.buildNumber,
        manifest: manifest,
        lastInstalled: manifest.buildNumber,
      );
    } on Object catch (e) {
      appLog('SDE install failed: $e');
      // The live file was not replaced; reopen it if we had closed it.
      if (_db == null && installer.databaseFile.existsSync()) {
        _db = SdeDatabase.openFile(installer.databaseFile);
      }
      state = SdeState(
        repository: _db == null ? null : SdeRepository(_db!),
        installedBuild: installer.installedBuild(),
        manifest: manifest,
        error: e,
      );
    } finally {
      _cancel = null;
    }
  }
}

final sdeControllerProvider = NotifierProvider<SdeController, SdeState>(SdeController.new);

/// The open SDE, or null before the first download.
final sdeRepositoryProvider = Provider<SdeRepository?>((ref) => ref.watch(sdeControllerProvider).repository);

/// Build number and release date of the installed database.
final sdeMetaProvider = FutureProvider<SdeMeta?>((ref) async => ref.watch(sdeRepositoryProvider)?.meta());

class SdeMissing implements Exception {
  const SdeMissing();
}

/// For providers that cannot do anything without static data.
SdeRepository requireSde(Ref ref) => ref.watch(sdeRepositoryProvider) ?? (throw const SdeMissing());
