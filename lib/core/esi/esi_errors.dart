/// Errors the ESI layer raises. UI code maps them to messages; nothing here holds tokens.
sealed class EsiException implements Exception {
  const EsiException();
}

/// Error limit (420) or bucket rate limit (429), or our own gate before a request.
class EsiThrottled extends EsiException {
  const EsiThrottled(this.retryAfter, {this.group});

  final Duration retryAfter;
  final String? group;

  @override
  String toString() => 'EsiThrottled(${retryAfter.inSeconds}s${group == null ? '' : ', $group'})';
}

/// The refresh token was rejected: the character has to sign in again.
class EsiReloginRequired extends EsiException {
  const EsiReloginRequired(this.characterId);

  final int characterId;

  @override
  String toString() => 'EsiReloginRequired($characterId)';
}

class EsiForbidden extends EsiException {
  const EsiForbidden(this.path);

  final String path;

  @override
  String toString() => 'EsiForbidden($path)';
}

class EsiNotFound extends EsiException {
  const EsiNotFound(this.path);

  final String path;

  @override
  String toString() => 'EsiNotFound($path)';
}

class EsiServerError extends EsiException {
  const EsiServerError(this.status);

  final int status;

  @override
  String toString() => 'EsiServerError($status)';
}

class EsiHttpError extends EsiException {
  const EsiHttpError(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => 'EsiHttpError($status, $message)';
}

class EsiNetworkError extends EsiException {
  const EsiNetworkError(this.cause);

  final Object cause;

  @override
  String toString() => 'EsiNetworkError(${cause.runtimeType})';
}
