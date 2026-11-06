// Live check of the published game data, through the same installer the app uses: the manifest at
// AppConfig.sdeManifestUrl, the download, the SHA-256, the swap, and a search on the result.
// It needs the network and downloads about 3 MB, so it only runs with LIVE_SDE=1:
//   LIVE_SDE=1 flutter test test/live_release_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/app/config.dart';
import 'package:pocket_hangar/core/sde/sde_database.dart';
import 'package:pocket_hangar/core/sde/sde_repository.dart';
import 'package:pocket_hangar/features/update/sde_installer.dart';

void main() {
  final live = Platform.environment['LIVE_SDE'] == '1';

  test('the published SDE downloads, verifies, installs and searches', () async {
    final dir = Directory.systemTemp.createTempSync('pocket_hangar_live_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final installer = SdeInstaller(dio: SdeInstaller.createDio(), directory: dir);

    final manifest = await installer.fetchManifest();
    expect(
      manifest.url,
      startsWith('https://github.com/${AppConfig.repo}/releases/download/sde-${manifest.buildNumber}/'),
    );
    expect(manifest.schemaVersion, lessThanOrEqualTo(AppConfig.supportedSdeSchema));

    await installer.install(manifest);
    expect(installer.installedBuild(), manifest.buildNumber);
    expect(dir.listSync().map((e) => e.uri.pathSegments.last), ['sde.sqlite']);

    // Torn down before the directory, so Windows can delete the file.
    final sde = SdeRepository(SdeDatabase.openFileSync(installer.databaseFile));
    addTearDown(sde.db.close);
    expect((await sde.searchTypes('裂谷', marketOnly: true)).first.typeId, 587);
    expect((await sde.searchTypes('rfiter', marketOnly: true)).map((t) => t.typeId), contains(587));
  }, skip: live ? false : 'LIVE_SDE not set', timeout: const Timeout(Duration(minutes: 3)));
}
