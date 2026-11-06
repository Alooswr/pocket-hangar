import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;

import '../app/theme.dart';
import '../core/esi/esi_errors.dart';
import '../features/update/sde_controller.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';

extension LocaleX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Show Chinese names from the database when the UI is in Chinese.
  bool get zh => Localizations.localeOf(this).languageCode == 'zh';
}

String errorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  final e = error is ProviderException ? error.exception : error;
  return switch (e) {
    EsiThrottled(:final retryAfter) => l.errorEsiThrottled(retryAfter.inSeconds),
    EsiNetworkError() => l.errorNetwork,
    EsiServerError(:final status) => l.errorEsiServer(status),
    EsiForbidden() => l.errorForbidden,
    EsiReloginRequired() => l.errorReloginNeeded(''),
    EsiHttpError(:final status, :final message) => l.errorWithMessage('$status $message'),
    SdeMissing() => l.dataNone,
    DioException(response: final response?) => l.errorHttpStatus(response.statusCode ?? 0),
    DioException() => l.errorNetwork,
    _ => l.errorWithMessage(_short('$e')),
  };
}

/// Unexpected errors are shown with their first line only; the full text goes to the debug log.
String _short(String text) {
  final line = text.split('\n').first.trim();
  return line.length > 160 ? '${line.substring(0, 160)}…' : line;
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(Space.xxl),
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

class MessageView extends StatelessWidget {
  const MessageView({required this.message, this.icon, this.action, super.key});

  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 32, color: t.textMuted), const SizedBox(height: Space.m)],
            Text(message, textAlign: TextAlign.center, style: context.text.bodyMedium!.copyWith(color: t.textMuted)),
            if (action != null) ...[const SizedBox(height: Space.l), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => MessageView(
        message: errorMessage(context, error),
        icon: Icons.error_outline,
        action: onRetry == null ? null : OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      );
}

/// AsyncValue -> loading / error / data, keeping old data on screen while refreshing.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({required this.value, required this.builder, this.onRetry, super.key});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: builder,
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: onRetry),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.s),
        child: Row(
          children: [
            Expanded(child: Text(text, style: context.text.titleSmall)),
            ?trailing,
          ],
        ),
      );
}

/// "Updated 12:03", plus a warning when ESI could not be reached and the data is older.
class FreshnessLine extends StatelessWidget {
  const FreshnessLine({required this.fetchedAt, required this.stale, super.key});

  final DateTime fetchedAt;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.xs),
      child: Row(
        children: [
          if (stale) ...[
            Icon(Icons.cloud_off_outlined, size: 16, color: t.warning),
            const SizedBox(width: Space.s),
          ],
          Text(context.l10n.updatedAt(formatDateTime(fetchedAt)), style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow({required this.label, required this.value, this.valueColor, super.key});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(label, style: context.text.bodyMedium!.copyWith(color: context.tokens.textMuted))),
            Text(
              value,
              style: context.text.bodyMedium!.copyWith(fontFeatures: tabular, color: valueColor),
            ),
          ],
        ),
      );
}

/// Used / total with a thin bar; turns red when over.
class UsageMeter extends StatelessWidget {
  const UsageMeter({required this.label, required this.used, required this.total, required this.unit, super.key});

  final String label;
  final double used;
  final double total;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final over = used > total + 1e-9;
    final decimals = total < 100 ? 1 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(label, style: context.text.bodySmall),
            const Spacer(),
            Text(
              '${formatFixed(used, decimals)} / ${formatFixed(total, decimals)}${unit.isEmpty ? '' : ' $unit'}',
              style: context.text.bodySmall!.copyWith(
                fontFeatures: tabular,
                color: over ? t.danger : t.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: total <= 0 ? (used > 0 ? 1 : 0) : (used / total).clamp(0.0, 1.0),
            minHeight: 4,
            color: over ? t.danger : t.accent,
            backgroundColor: t.surface3,
          ),
        ),
      ],
    );
  }
}

/// Shown instead of a tab's content when static data is not installed yet.
class NeedsSde extends ConsumerWidget {
  const NeedsSde({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(sdeRepositoryProvider) == null ? const LoadingView() : child;
}
