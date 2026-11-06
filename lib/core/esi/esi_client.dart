import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpDate, HttpException;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../../app/config.dart';
import '../log.dart';
import 'esi_errors.dart';
import 'rate_limiter.dart';

/// One cached ESI response.
class CachedResponse {
  const CachedResponse({
    required this.body,
    required this.storedAt,
    this.etag,
    this.expires,
    this.lastModified,
    this.pages,
  });

  final String body;
  final DateTime storedAt;
  final String? etag;
  final DateTime? expires;
  final String? lastModified;
  final int? pages;
}

abstract interface class EsiCacheStore {
  Future<CachedResponse?> read(String key);
  Future<void> write(String key, CachedResponse value);
  Future<void> deleteForCharacter(int characterId);
}

class MemoryEsiCacheStore implements EsiCacheStore {
  final entries = <String, CachedResponse>{};

  @override
  Future<CachedResponse?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, CachedResponse value) async => entries[key] = value;

  @override
  Future<void> deleteForCharacter(int characterId) async =>
      entries.removeWhere((k, _) => k.startsWith('$characterId|'));
}

typedef AccessTokenProvider = Future<String> Function(int characterId, {bool forceRefresh});

class EsiResponse<T> {
  const EsiResponse({
    required this.data,
    required this.fetchedAt,
    this.expires,
    this.lastModified,
    this.pages = 1,
    this.fromCache = false,
    this.staleBecause,
  });

  final T data;

  /// When ESI produced this data (stored time for cached responses).
  final DateTime fetchedAt;
  final DateTime? expires;
  final String? lastModified;
  final int pages;
  final bool fromCache;

  /// Set when ESI could not be reached and older cached data is returned instead.
  final EsiException? staleBecause;

  bool get isStale => staleBecause != null;
}

/// ESI over dio, with the rules from developers.eveonline.com/docs/services/esi/:
/// * X-Compatibility-Date and a User-Agent identifying the app on every request;
/// * responses cached until their Expires time and revalidated with If-None-Match (304);
/// * X-Pages pagination with a Last-Modified consistency check;
/// * error-limit and bucket rate-limit headers respected through [EsiRateLimiter].
class EsiClient {
  EsiClient({
    required this.dio,
    required this.cache,
    required this.limiter,
    this.accessToken,
    DateTime Function()? clock,
    this.maxConcurrentPages = 3,
  }) : _clock = clock ?? DateTime.now;

  final Dio dio;
  final EsiCacheStore cache;
  final EsiRateLimiter limiter;
  final AccessTokenProvider? accessToken;
  final int maxConcurrentPages;
  final DateTime Function() _clock;

  static const _maxSoftWait = Duration(seconds: 10);

  static Dio createDio() => Dio(
        BaseOptions(
          baseUrl: AppConfig.esiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 45),
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
          headers: {'User-Agent': AppConfig.userAgent},
        ),
      );

  static String cacheKey(String path, Map<String, Object?> query, int? characterId) {
    final keys = query.keys.toList()..sort();
    final q = keys.map((k) => '$k=${query[k]}').join('&');
    return '${characterId ?? 0}|$path${q.isEmpty ? '' : '?$q'}';
  }

  /// GET with caching. [characterId] makes it an authenticated request for that character.
  Future<EsiResponse<Object?>> get(
    String path, {
    Map<String, Object?> query = const {},
    int? characterId,
    bool ignoreFreshCache = false,
  }) async {
    final key = cacheKey(path, query, characterId);
    final cached = await cache.read(key);
    final now = _clock();
    if (!ignoreFreshCache && cached != null && cached.expires != null && cached.expires!.isAfter(now)) {
      return _fromCached(cached);
    }

    final Response<String> resp;
    try {
      resp = await _send('GET', path, query: query, characterId: characterId, etag: cached?.etag);
    } on EsiException catch (e) {
      if (cached != null && (e is EsiNetworkError || e is EsiThrottled)) return _fromCached(cached, stale: e);
      rethrow;
    }

    final status = resp.statusCode ?? 0;
    final headers = _headerMap(resp);
    if (status == 304 && cached != null) {
      final refreshed = CachedResponse(
        body: cached.body,
        storedAt: now,
        etag: headers['etag'] ?? cached.etag,
        expires: _parseDate(headers['expires']) ?? cached.expires,
        lastModified: headers['last-modified'] ?? cached.lastModified,
        pages: int.tryParse(headers['x-pages'] ?? '') ?? cached.pages,
      );
      await cache.write(key, refreshed);
      return _fromCached(refreshed, fromCache: false);
    }
    if (status >= 200 && status < 300) {
      final body = resp.data ?? '';
      final entry = CachedResponse(
        body: body,
        storedAt: now,
        etag: headers['etag'],
        expires: _parseDate(headers['expires']),
        lastModified: headers['last-modified'],
        pages: int.tryParse(headers['x-pages'] ?? ''),
      );
      if (entry.etag != null || entry.expires != null) await cache.write(key, entry);
      return EsiResponse(
        data: await _decode(body),
        fetchedAt: now,
        expires: entry.expires,
        lastModified: entry.lastModified,
        pages: entry.pages ?? 1,
      );
    }
    final error = _errorFor(status, path, headers, resp.data);
    if (cached != null && (error is EsiServerError || error is EsiThrottled)) return _fromCached(cached, stale: error);
    throw error;
  }

  /// Fetches every page of an X-Pages resource and concatenates the arrays.
  Future<EsiResponse<List<Object?>>> getAllPages(
    String path, {
    Map<String, Object?> query = const {},
    int? characterId,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final refetch = attempt > 0;
      var first = await get(path, query: {...query, 'page': 1}, characterId: characterId, ignoreFreshCache: refetch);
      // Page 1 about to expire: wait for the new cache generation, then fetch every page from it.
      final expires = first.expires;
      final untilExpiry = expires?.difference(_clock());
      if (first.pages > 1 && untilExpiry != null && untilExpiry < const Duration(seconds: 5)) {
        await Future<void>.delayed(untilExpiry.isNegative ? Duration.zero : untilExpiry + const Duration(seconds: 1));
        first = await get(path, query: {...query, 'page': 1}, characterId: characterId, ignoreFreshCache: true);
      }
      final pages = first.pages;
      final results = List<EsiResponse<Object?>?>.filled(pages, null)..[0] = first;
      var next = 2;
      Future<void> worker() async {
        while (true) {
          final page = next++;
          if (page > pages) return;
          results[page - 1] =
              await get(path, query: {...query, 'page': page}, characterId: characterId, ignoreFreshCache: refetch);
        }
      }

      await Future.wait([for (var i = 0; i < math.min(maxConcurrentPages, pages - 1); i++) worker()]);
      final versions = {for (final r in results) r!.lastModified};
      if (versions.length > 1 && attempt == 0) {
        appLog('ESI $path: pages from different cache generations $versions, fetching again');
        final latest = results.map((r) => r!.expires).whereType<DateTime>().fold<DateTime?>(
            null, (a, b) => a == null || b.isAfter(a) ? b : a);
        final wait = latest?.difference(_clock());
        if (wait != null && wait > Duration.zero && wait < const Duration(seconds: 30)) {
          await Future<void>.delayed(wait + const Duration(seconds: 1));
        }
        continue;
      }
      final stale = results.map((r) => r!.staleBecause).whereType<EsiException>().firstOrNull;
      return EsiResponse(
        data: [for (final r in results) ...(r!.data as List<Object?>? ?? const [])],
        fetchedAt: first.fetchedAt,
        expires: first.expires,
        lastModified: first.lastModified,
        pages: pages,
        fromCache: results.every((r) => r!.fromCache),
        staleBecause: stale,
      );
    }
    throw StateError('unreachable');
  }

  /// POST (no caching): /universe/names, /characters/{id}/assets/names, fittings.
  Future<Object?> post(String path, Object body, {int? characterId}) async {
    final resp = await _send('POST', path, characterId: characterId, body: jsonEncode(body));
    final status = resp.statusCode ?? 0;
    if (status >= 200 && status < 300) return _decode(resp.data ?? '');
    throw _errorFor(status, path, _headerMap(resp), resp.data);
  }

  Future<void> delete(String path, {int? characterId}) async {
    final resp = await _send('DELETE', path, characterId: characterId);
    final status = resp.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    throw _errorFor(status, path, _headerMap(resp), resp.data);
  }

  Future<Response<String>> _send(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    int? characterId,
    String? etag,
    String? body,
  }) async {
    final wait = limiter.beforeRequest(path);
    if (wait > Duration.zero) await Future<void>.delayed(wait > _maxSoftWait ? _maxSoftWait : wait);

    Future<Response<String>> once({bool forceRefresh = false}) async {
      final headers = <String, Object>{
        'X-Compatibility-Date': AppConfig.esiCompatibilityDate,
        'Accept-Language': 'en',
        'If-None-Match': ?etag,
        if (body != null) 'Content-Type': 'application/json',
      };
      if (characterId != null) {
        final provider = accessToken;
        if (provider == null) throw StateError('authenticated request without a token provider');
        headers['Authorization'] = 'Bearer ${await provider(characterId, forceRefresh: forceRefresh)}';
      }
      try {
        final resp = await dio.request<String>(
          path,
          queryParameters: query.isEmpty ? null : query,
          data: body,
          options: Options(method: method, headers: headers),
        );
        limiter.afterResponse(path, resp.statusCode ?? 0, _headerMap(resp));
        appLog('ESI $method $path ${resp.statusCode}');
        return resp;
      } on DioException catch (e) {
        appLog('ESI $method $path failed: ${e.type}');
        throw EsiNetworkError(e.type);
      }
    }

    final resp = await once();
    if (resp.statusCode == 401 && characterId != null) {
      // The access token may have been revoked or expired early; refresh once and retry.
      return once(forceRefresh: true);
    }
    return resp;
  }

  EsiException _errorFor(int status, String path, Map<String, String> headers, String? body) {
    switch (status) {
      case 403:
        return EsiForbidden(path);
      case 404:
        return EsiNotFound(path);
      case 420:
        return EsiThrottled(Duration(seconds: int.tryParse(headers['x-esi-error-limit-reset'] ?? '') ?? 60));
      case 429:
        return EsiThrottled(
          Duration(seconds: int.tryParse(headers['retry-after'] ?? '') ?? 60),
          group: headers['x-ratelimit-group'],
        );
    }
    if (status >= 500) return EsiServerError(status);
    var message = '';
    try {
      final decoded = jsonDecode(body ?? '');
      if (decoded is Map && decoded['error'] is String) message = decoded['error'] as String;
    } on FormatException {
      message = '';
    }
    return EsiHttpError(status, message);
  }

  Future<EsiResponse<Object?>> _fromCached(CachedResponse c, {EsiException? stale, bool fromCache = true}) async =>
      EsiResponse(
        data: await _decode(c.body),
        fetchedAt: c.storedAt,
        expires: c.expires,
        lastModified: c.lastModified,
        pages: c.pages ?? 1,
        fromCache: fromCache,
        staleBecause: stale,
      );

  static Future<Object?> _decode(String body) async {
    if (body.isEmpty) return null;
    // Large bodies (asset pages, market orders) are parsed off the UI isolate.
    if (body.length > 64 * 1024) return Isolate.run(() => jsonDecode(body));
    return jsonDecode(body);
  }

  static Map<String, String> _headerMap(Response<Object?> resp) => {
        for (final e in resp.headers.map.entries) e.key.toLowerCase(): ?e.value.firstOrNull,
      };

  static DateTime? _parseDate(String? value) {
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } on HttpException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
