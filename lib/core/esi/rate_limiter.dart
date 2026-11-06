import 'esi_errors.dart';

/// Tracks both ESI limits (developers.eveonline.com/docs/services/esi/rate-limiting/):
///
/// * error limit: X-ESI-Error-Limit-Remain / -Reset, 420 once exhausted, applies to every route
///   that does not use the newer bucket limit;
/// * bucket limit: X-Ratelimit-Group / -Limit / -Remaining per route group, 429 + Retry-After.
///
/// When a limit is hit we stop sending (throw [EsiThrottled]) instead of retrying, and we slow
/// down before getting there.
class EsiRateLimiter {
  EsiRateLimiter({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  DateTime? _globalBlockedUntil;
  final _groupBlockedUntil = <String, DateTime>{};
  final _routeGroup = <String, String>{};
  final _groupRemaining = <String, int>{};
  final _groupLimit = <String, int>{};
  int? _errorRemain;
  DateTime? _errorResetAt;

  /// Errors left in the current error-limit window, if a response told us.
  int? get errorRemain => _errorRemain;

  /// Replaces numeric path segments so /characters/123/assets and /characters/456/assets share
  /// one key.
  static String routeKey(String path) =>
      path.split('?').first.split('/').map((s) => RegExp(r'^\d+$').hasMatch(s) ? '{id}' : s).join('/');

  /// Throws [EsiThrottled] if this route must not be called yet; otherwise returns how long the
  /// caller should wait first (zero most of the time).
  Duration beforeRequest(String path) {
    final now = _clock();
    final route = routeKey(path);
    final group = _routeGroup[route];
    DateTime? until = _globalBlockedUntil;
    final groupUntil = group == null ? null : _groupBlockedUntil[group];
    if (groupUntil != null && (until == null || groupUntil.isAfter(until))) until = groupUntil;
    if (until != null && until.isAfter(now)) {
      throw EsiThrottled(until.difference(now), group: group);
    }
    // Slow down when close to a limit rather than running into it.
    final remain = _errorRemain;
    final reset = _errorResetAt;
    if (remain != null && reset != null && reset.isAfter(now) && remain <= 10) {
      return reset.difference(now);
    }
    if (group != null) {
      final left = _groupRemaining[group];
      final limit = _groupLimit[group];
      if (left != null && limit != null && left < limit * 0.05) {
        return const Duration(seconds: 2);
      }
    }
    return Duration.zero;
  }

  void afterResponse(String path, int status, Map<String, String> headers) {
    final now = _clock();
    final route = routeKey(path);

    final group = headers['x-ratelimit-group'];
    if (group != null) {
      _routeGroup[route] = group;
      final remaining = int.tryParse(headers['x-ratelimit-remaining'] ?? '');
      if (remaining != null) _groupRemaining[group] = remaining;
      final limit = headers['x-ratelimit-limit'];
      if (limit != null) {
        final tokens = int.tryParse(limit.split('/').first);
        if (tokens != null) _groupLimit[group] = tokens;
      }
    }

    final remain = int.tryParse(headers['x-esi-error-limit-remain'] ?? '');
    final reset = int.tryParse(headers['x-esi-error-limit-reset'] ?? '');
    if (remain != null) _errorRemain = remain;
    if (reset != null) _errorResetAt = now.add(Duration(seconds: reset));

    if (status == 420) {
      // Error limit exhausted: everything is blocked until the window resets.
      _globalBlockedUntil = now.add(Duration(seconds: reset ?? 60));
    } else if (status == 429) {
      final retry = Duration(seconds: int.tryParse(headers['retry-after'] ?? '') ?? 60);
      if (group != null) {
        _groupBlockedUntil[group] = now.add(retry);
      } else {
        _globalBlockedUntil = now.add(retry);
      }
    }
  }

  Duration? blockedFor(String path) {
    try {
      beforeRequest(path);
      return null;
    } on EsiThrottled catch (e) {
      return e.retryAfter;
    }
  }
}
