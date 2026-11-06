import 'dart:convert';
import 'dart:io' show HttpDate;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/app/config.dart';
import 'package:pocket_hangar/core/esi/esi_client.dart';
import 'package:pocket_hangar/core/esi/esi_errors.dart';
import 'package:pocket_hangar/core/esi/rate_limiter.dart';

typedef Handler = ResponseBody Function(RequestOptions options);

/// Answers dio requests from a list of handlers; records every request.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  Handler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object? body, {int status = 200, Map<String, String> headers = const {}}) => ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        for (final e in headers.entries) e.key: [e.value],
      },
    );

void main() {
  var now = DateTime.utc(2026, 11, 6, 12);
  late FakeAdapter adapter;
  late MemoryEsiCacheStore cache;
  late EsiRateLimiter limiter;
  late EsiClient client;
  var tokenCalls = <bool>[];

  String http(Duration fromNow) => HttpDate.format(now.add(fromNow));

  setUp(() {
    now = DateTime.utc(2026, 11, 6, 12);
    adapter = FakeAdapter((_) => json(null, status: 500));
    cache = MemoryEsiCacheStore();
    limiter = EsiRateLimiter(clock: () => now);
    tokenCalls = [];
    final dio = EsiClient.createDio()..httpClientAdapter = adapter;
    client = EsiClient(
      dio: dio,
      cache: cache,
      limiter: limiter,
      clock: () => now,
      accessToken: (id, {forceRefresh = false}) async {
        tokenCalls.add(forceRefresh);
        return forceRefresh ? 'fresh-token' : 'old-token';
      },
    );
  });

  group('request headers', () {
    test('compatibility date, user agent and language on every call', () async {
      adapter.handler = (_) => json({'ok': true});
      await client.get('/status');
      final h = adapter.requests.single.headers;
      expect(h['X-Compatibility-Date'], AppConfig.esiCompatibilityDate);
      expect(h['User-Agent'], AppConfig.userAgent);
      expect(h['User-Agent'], startsWith('PocketHangar/'));
      expect(h.containsKey('Authorization'), isFalse);
    });

    test('authenticated calls carry the bearer token; a 401 refreshes once and retries', () async {
      adapter.handler = (o) => o.headers['Authorization'] == 'Bearer fresh-token' ? json([1, 2]) : json({}, status: 401);
      final r = await client.get('/characters/1/skillqueue', characterId: 1);
      expect(r.data, [1, 2]);
      expect(tokenCalls, [false, true]);
      expect(adapter.requests.length, 2);
    });
  });

  group('cache', () {
    test('fresh cache answers without a request', () async {
      adapter.handler = (_) => json({'v': 1}, headers: {'expires': http(const Duration(minutes: 5)), 'etag': '"a"'});
      final first = await client.get('/markets/prices');
      final second = await client.get('/markets/prices');
      expect(adapter.requests.length, 1);
      expect(first.fromCache, isFalse);
      expect(second.fromCache, isTrue);
      expect(second.data, {'v': 1});
    });

    test('expired cache is revalidated with If-None-Match; 304 keeps the body', () async {
      adapter.handler = (_) => json({'v': 1}, headers: {'expires': http(const Duration(minutes: 5)), 'etag': '"a"'});
      await client.get('/markets/prices');
      now = now.add(const Duration(minutes: 6));
      adapter.handler = (o) {
        expect(o.headers['If-None-Match'], '"a"');
        return json(null, status: 304, headers: {'expires': http(const Duration(minutes: 5)), 'etag': '"a"'});
      };
      final r = await client.get('/markets/prices');
      expect(r.data, {'v': 1});
      expect(r.isStale, isFalse);
      expect(r.fetchedAt, now);
      // The new Expires is stored: the next call is served from cache.
      await client.get('/markets/prices');
      expect(adapter.requests.length, 2);
    });

    test('network failure returns the old data marked stale', () async {
      adapter.handler = (_) => json({'v': 1}, headers: {'expires': http(const Duration(minutes: 5))});
      await client.get('/markets/prices');
      now = now.add(const Duration(hours: 1));
      adapter.handler = (o) => throw DioException.connectionError(requestOptions: o, reason: 'offline');
      final r = await client.get('/markets/prices');
      expect(r.data, {'v': 1});
      expect(r.staleBecause, isA<EsiNetworkError>());
    });

    test('5xx with cache returns stale data, without cache throws', () async {
      adapter.handler = (_) => json({'error': 'down'}, status: 503);
      await expectLater(client.get('/markets/prices'), throwsA(isA<EsiServerError>()));
      adapter.handler = (_) => json({'v': 2}, headers: {'expires': http(const Duration(minutes: 5))});
      await client.get('/markets/prices');
      now = now.add(const Duration(hours: 1));
      adapter.handler = (_) => json({'error': 'down'}, status: 503);
      final r = await client.get('/markets/prices');
      expect(r.staleBecause, isA<EsiServerError>());
    });

    test('403 and 404 map to their own errors', () async {
      adapter.handler = (_) => json({'error': 'forbidden'}, status: 403);
      await expectLater(client.get('/characters/1/assets', characterId: 1), throwsA(isA<EsiForbidden>()));
      adapter.handler = (_) => json({'error': 'not found'}, status: 404);
      await expectLater(client.get('/universe/structures/1'), throwsA(isA<EsiNotFound>()));
    });
  });

  group('pagination', () {
    test('reads every page reported by X-Pages', () async {
      adapter.handler = (o) {
        final page = o.queryParameters['page'] as int;
        return json([page * 10, page * 10 + 1], headers: {
          'x-pages': '3',
          'expires': http(const Duration(minutes: 5)),
          'last-modified': 'Fri, 06 Nov 2026 11:59:00 GMT',
        });
      };
      final r = await client.getAllPages('/markets/10000002/orders', query: {'order_type': 'all'});
      expect(r.data, [10, 11, 20, 21, 30, 31]);
      expect(r.pages, 3);
      expect(adapter.requests.length, 3);
    });

    test('pages from different cache generations are fetched again', () async {
      var round = 0;
      adapter.handler = (o) {
        final page = o.queryParameters['page'] as int;
        if (page == 1) round++;
        // First round: page 2 comes from a newer generation than page 1.
        final lastModified = round == 1 && page == 2 ? 'Fri, 06 Nov 2026 12:00:00 GMT' : 'Fri, 06 Nov 2026 11:59:00 GMT';
        return json([page], headers: {
          'x-pages': '2',
          'expires': http(const Duration(minutes: 5)),
          'last-modified': lastModified,
        });
      };
      final r = await client.getAllPages('/characters/1/assets', characterId: 1);
      expect(round, 2);
      expect(r.data, [1, 2]);
      expect(adapter.requests.length, 4);
    });
  });

  group('rate limits', () {
    test('420 blocks every route until the error window resets', () async {
      adapter.handler = (_) => json({'error': 'limited'}, status: 420, headers: {
            'x-esi-error-limit-remain': '0',
            'x-esi-error-limit-reset': '30',
          });
      await expectLater(client.get('/markets/prices'), throwsA(isA<EsiThrottled>()));
      final before = adapter.requests.length;
      await expectLater(
        client.get('/universe/types/587'),
        throwsA(isA<EsiThrottled>().having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 30))),
      );
      expect(adapter.requests.length, before, reason: 'no request is sent while blocked');
      now = now.add(const Duration(seconds: 31));
      adapter.handler = (_) => json({'ok': true});
      await client.get('/universe/types/587');
    });

    test('429 blocks only its rate-limit group', () async {
      adapter.handler = (_) => json({'error': 'slow down'}, status: 429, headers: {
            'retry-after': '20',
            'x-ratelimit-group': 'char-location',
            'x-ratelimit-limit': '1200/15m',
            'x-ratelimit-remaining': '0',
          });
      await expectLater(client.get('/characters/1/location', characterId: 1), throwsA(isA<EsiThrottled>()));
      expect(limiter.blockedFor('/characters/2/location'), const Duration(seconds: 20));
      expect(limiter.blockedFor('/markets/prices'), isNull);
    });

    test('slows down when few errors are left', () {
      limiter.afterResponse('/x', 200, {'x-esi-error-limit-remain': '5', 'x-esi-error-limit-reset': '40'});
      expect(limiter.beforeRequest('/y'), const Duration(seconds: 40));
      limiter.afterResponse('/x', 200, {'x-esi-error-limit-remain': '90', 'x-esi-error-limit-reset': '40'});
      expect(limiter.beforeRequest('/y'), Duration.zero);
    });

    test('route keys ignore ids', () {
      expect(EsiRateLimiter.routeKey('/characters/123/assets?page=2'), '/characters/{id}/assets');
    });
  });
}
