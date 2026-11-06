import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

final _isk = NumberFormat('#,##0.00', 'en_US');
final _int = NumberFormat('#,##0', 'en_US');

String formatIsk(double value) => _isk.format(value);

String formatInt(num value) => _int.format(value);

String formatFixed(double value, int decimals) => NumberFormat(
      decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}',
      'en_US',
    ).format(value);

String formatPercent(double fraction, {int decimals = 1}) => (fraction * 100).toStringAsFixed(decimals);

/// Days/hours/minutes for long spans, minutes/seconds for short ones.
String formatDuration(Duration d, AppLocalizations l) {
  if (d.isNegative) d = Duration.zero;
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  if (days > 0) return l.durationDHM(days, hours, minutes);
  if (d.inHours > 0) return l.durationHM(hours, minutes);
  return l.durationMS(d.inMinutes, d.inSeconds % 60);
}

/// Short local date-time, with the year only when it is not the current one.
String formatDateTime(DateTime t) {
  final local = t.toLocal();
  final now = DateTime.now();
  return DateFormat(local.year == now.year ? 'MM-dd HH:mm' : 'yyyy-MM-dd HH:mm').format(local);
}

String formatTime(DateTime t) => DateFormat('HH:mm').format(t.toLocal());

/// Security status as the game shows it: one decimal, and anything above 0.0 but below 0.05
/// shows as 0.1 (it is low-sec, not null-sec).
String formatSecurity(double security) {
  if (security > 0 && security < 0.05) return '0.1';
  return ((security * 10).round() / 10).toStringAsFixed(1);
}

String formatSize(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}
