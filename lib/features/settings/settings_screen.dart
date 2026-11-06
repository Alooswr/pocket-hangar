import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../app/locale.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../update/app_update.dart';
import '../update/sde_controller.dart';
import '../update/update_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final locale = ref.watch(localeProvider).value;
    final sde = ref.watch(sdeControllerProvider);
    final version = ref.watch(appVersionProvider).value ?? AppConfig.version;
    final busy = sde.phase != SdePhase.idle;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          SectionTitle(l.language),
          RadioGroup<String>(
            groupValue: locale?.languageCode ?? 'system',
            onChanged: (v) => ref.read(localeProvider.notifier).set(v == null || v == 'system' ? null : Locale(v)),
            child: Column(
              children: [
                for (final (value, label) in [
                  ('system', l.languageSystem),
                  ('zh', l.languageChinese),
                  ('en', l.languageEnglish),
                ])
                  RadioListTile<String>(value: value, title: Text(label), activeColor: t.accent),
              ],
            ),
          ),
          SectionTitle(l.dataSection),
          ListTile(
            title: Text(
              sde.installedBuild == null
                  ? l.dataNone
                  : l.dataBuild(sde.installedBuild!, _date(ref.watch(sdeMetaProvider).value?.releaseDate)),
            ),
            subtitle: sde.updateAvailable
                ? Text(l.sdeUpdateAvailable(sde.manifest!.buildNumber, formatSize(sde.manifest!.size)))
                : null,
            trailing: sde.updateAvailable
                ? FilledButton(
                    onPressed: busy ? null : () => ref.read(sdeControllerProvider.notifier).installLatest(),
                    child: Text(l.sdeUpdate),
                  )
                : null,
          ),
          if (sde.phase == SdePhase.downloading || sde.phase == SdePhase.installing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: SdeProgress(state: sde),
            ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l.checkForUpdates),
            onTap: busy
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(sdeControllerProvider.notifier).checkForUpdate();
                    ref.invalidate(appUpdateProvider);
                    final app = await ref.read(appUpdateProvider.future);
                    final s = ref.read(sdeControllerProvider);
                    if (!context.mounted) return;
                    final messages = [
                      if (s.error != null) errorMessage(context, s.error!),
                      if (s.error == null && !s.updateAvailable) l.sdeUpToDate,
                      app == null ? l.appUpToDate : l.appUpdateAvailable(app.version),
                    ];
                    messenger.showSnackBar(SnackBar(content: Text(messages.join('\n'))));
                  },
          ),
          SectionTitle(l.aboutSection),
          ListTile(title: Text(l.appVersion(version)), subtitle: Text(Platform.operatingSystem)),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l.sourceCode),
            subtitle: const Text(AppConfig.sourceUrl),
            onTap: () => launchUrl(Uri.parse(AppConfig.sourceUrl), mode: LaunchMode.externalApplication),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
            child: Text(l.ccpNotice, style: context.text.bodySmall),
          ),
        ],
      ),
    );
  }

  static String _date(String? iso) => iso == null || iso.length < 10 ? '' : iso.substring(0, 10);
}
