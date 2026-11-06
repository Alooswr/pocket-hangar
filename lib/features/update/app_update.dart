import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/config.dart';
import '../../core/log.dart';

class AppRelease {
  const AppRelease({required this.version, required this.page, this.downloadUrl, required this.appStore});

  final String version;

  /// Release page (Android) or App Store page (iOS).
  final Uri page;

  /// Direct APK link from the release assets, when there is one.
  final Uri? downloadUrl;
  final bool appStore;
}

/// Compares dotted numeric versions ("1.2.10" > "1.2.9"). A leading "v" is ignored.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .trim()
      .replaceFirst(RegExp('^[vV]'), '')
      .split(RegExp(r'[.+\-]'))
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

final _appTag = RegExp(r'^[vV]?\d+\.\d+\.\d+$');

/// The newest app release in a GitHub releases list that is newer than [currentVersion].
/// Only tags like v1.2.3 count: the data pipeline publishes its releases in the same repository
/// (`sde-<build>`, `sde-latest`), and those must never look like an app version.
AppRelease? newestAppRelease(List<dynamic> releases, {required String currentVersion}) {
  Map<String, dynamic>? best;
  for (final r in releases) {
    if (r is! Map<String, dynamic>) continue;
    final tag = r['tag_name'] as String? ?? '';
    if (r['draft'] == true || r['prerelease'] == true || !_appTag.hasMatch(tag)) continue;
    if (best == null || compareVersions(tag, best['tag_name'] as String) > 0) best = r;
  }
  if (best == null) return null;
  final tag = best['tag_name'] as String;
  if (compareVersions(tag, currentVersion) <= 0) return null;
  Uri? apk;
  for (final a in (best['assets'] as List<dynamic>? ?? const [])) {
    final asset = a as Map<String, dynamic>;
    final name = asset['name'] as String? ?? '';
    if (name.endsWith('.apk')) apk = Uri.parse(asset['browser_download_url'] as String);
  }
  return AppRelease(
    version: tag.replaceFirst(RegExp('^[vV]'), ''),
    page: Uri.parse(best['html_url'] as String? ?? AppConfig.githubReleasesPage),
    downloadUrl: apk,
    appStore: false,
  );
}

/// Android: newest app release on GitHub. iOS: App Store lookup; only a notice and a link, the
/// app never updates itself.
Future<AppRelease?> checkAppUpdate(Dio dio, {required String currentVersion, required bool ios}) async {
  if (ios) {
    final resp = await dio.get<Map<String, dynamic>>(AppConfig.appStoreLookup);
    final results = resp.data?['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) return null;
    final app = results.first as Map<String, dynamic>;
    final version = app['version'] as String?;
    final url = app['trackViewUrl'] as String?;
    if (version == null || url == null || compareVersions(version, currentVersion) <= 0) return null;
    return AppRelease(version: version, page: Uri.parse(url), appStore: true);
  }
  // GitHub answers 404 (no repository or no releases yet) with a JSON object, so the body is
  // read untyped and only a list is used.
  final resp = await dio.get<Object?>(
    AppConfig.githubReleasesApi,
    queryParameters: {'per_page': 30},
    options: Options(headers: {'Accept': 'application/vnd.github+json'}, validateStatus: (s) => s == 200 || s == 404),
  );
  final data = resp.data;
  if (resp.statusCode != 200 || data is! List<dynamic>) return null;
  return newestAppRelease(data, currentVersion: currentVersion);
}

final appVersionProvider = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);

/// Checked once per launch; failures (offline, rate limit) are silent.
final appUpdateProvider = FutureProvider<AppRelease?>((ref) async {
  try {
    final version = await ref.watch(appVersionProvider.future);
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'User-Agent': AppConfig.userAgent},
    ));
    return await checkAppUpdate(dio, currentVersion: version, ios: Platform.isIOS);
  } on Object catch (e) {
    appLog('app update check failed: $e');
    return null;
  }
});
