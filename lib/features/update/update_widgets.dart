import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import 'app_update.dart';
import 'sde_controller.dart';
import 'sde_installer.dart';

String sdeErrorText(BuildContext context, Object error) => switch (error) {
      DioException(response: Response(statusCode: 404)) => context.l10n.sdeNotPublished,
      SdeChecksumMismatch() => context.l10n.sdeChecksumFailed,
      SdeSchemaUnsupported() => context.l10n.sdeSchemaTooNew,
      _ => errorMessage(context, error),
    };

class SdeProgress extends StatelessWidget {
  const SdeProgress({required this.state, super.key});

  final SdeState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final installing = state.phase == SdePhase.installing;
    final progress = state.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          installing ? l.sdeInstalling : l.sdeDownloading(((progress ?? 0) * 100).round()),
          style: context.text.bodySmall!.copyWith(fontFeatures: tabular),
        ),
        const SizedBox(height: Space.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: installing ? null : progress, minHeight: 4),
        ),
      ],
    );
  }
}

/// First launch: nothing works without the static data, so ask for the one-time download.
class SdeOnboarding extends ConsumerWidget {
  const SdeOnboarding({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(sdeControllerProvider);
    final controller = ref.read(sdeControllerProvider.notifier);
    final size = state.manifest == null ? '3 MB' : formatSize(state.manifest!.size);
    final busy = state.phase == SdePhase.downloading || state.phase == SdePhase.installing;
    final error = state.error;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.sdeOnboardingTitle, style: context.text.titleLarge),
                  const SizedBox(height: Space.s),
                  Text(l.sdeOnboardingBody(size), style: context.text.bodyMedium!.copyWith(color: context.tokens.textMuted)),
                  const SizedBox(height: Space.xl),
                  if (busy)
                    SdeProgress(state: state)
                  else
                    FilledButton(onPressed: controller.installLatest, child: Text(l.sdeDownload(size))),
                  if (error != null && !busy) ...[
                    const SizedBox(height: Space.l),
                    Text(sdeErrorText(context, error), style: context.text.bodySmall!.copyWith(color: context.tokens.danger)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single line above the tabs when new game data or a new app version exists.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final sde = ref.watch(sdeControllerProvider);
    final app = ref.watch(appUpdateProvider).value;
    final busy = sde.phase == SdePhase.downloading || sde.phase == SdePhase.installing;

    Widget bar(String text, String action, VoidCallback? onTap, {Widget? below}) => Material(
          color: t.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.s),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(text, style: context.text.bodySmall!.copyWith(color: t.text))),
                      TextButton(onPressed: onTap, child: Text(action)),
                    ],
                  ),
                  ?below,
                ],
              ),
            ),
          ),
        );

    if (busy) {
      return bar(l.sdeUpdateAvailable(sde.manifest?.buildNumber ?? '', formatSize(sde.manifest?.size ?? 0)), l.sdeUpdate, null,
          below: Padding(padding: const EdgeInsets.only(right: Space.s), child: SdeProgress(state: sde)));
    }
    if (sde.updateAvailable) {
      return bar(
        l.sdeUpdateAvailable(sde.manifest!.buildNumber, formatSize(sde.manifest!.size)),
        l.sdeUpdate,
        () => ref.read(sdeControllerProvider.notifier).installLatest(),
      );
    }
    if (app != null) {
      return bar(
        l.appUpdateAvailable(app.version),
        app.appStore ? l.appUpdateOpenStore : l.appUpdateDownload,
        () => launchUrl(app.downloadUrl ?? app.page, mode: LaunchMode.externalApplication),
      );
    }
    return const SizedBox.shrink();
  }
}
