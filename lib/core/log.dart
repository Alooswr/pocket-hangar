import 'package:flutter/foundation.dart';

// Anything that could carry a credential is rewritten before it reaches a log line.
final _bearer = RegExp(r'Bearer\s+[A-Za-z0-9\-_.~+/=]+');
final _jwt = RegExp(r'eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+');
final _secretField = RegExp(
  r'\b(access_token|refresh_token|code_verifier|code|token|client_secret)("?\s*[:=]\s*"?)[^"&,\s}]+',
);

/// Removes bearer tokens, JWTs and token-like form/JSON fields from [input].
String redact(String input) => input
    .replaceAll(_bearer, 'Bearer <redacted>')
    .replaceAll(_jwt, '<jwt>')
    .replaceAllMapped(_secretField, (m) => '${m[1]}${m[2]}<redacted>');

/// Debug-only log. Never pass request headers or token responses here unredacted; [redact] is
/// applied anyway as a second line of defence.
void appLog(String message) {
  if (kDebugMode) {
    debugPrint(redact(message));
  }
}
