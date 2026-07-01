import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worldcup2026/data/api_football/api_football_client.dart';

String _envelope(List<dynamic> response, {int page = 1, int total = 1}) =>
    jsonEncode({
      'errors': [],
      'paging': {'current': page, 'total': total},
      'response': response,
    });

void main() {
  test('getAll concatenates every page of a paginated endpoint', () async {
    final requestedPages = <String>[];
    final mock = MockClient((request) async {
      final page = request.url.queryParameters['page'] ?? '1';
      requestedPages.add(page);
      return http.Response(
        _envelope([int.parse(page)], page: int.parse(page), total: 3),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = ApiFootballClient(httpClient: mock);
    final all = await client.getAll('fixtures', {'league': '1'});

    expect(all, unorderedEquals([1, 2, 3]));
    expect(requestedPages, hasLength(3));
  });

  test('getAll serves a cached result within the TTL and refetches after', () async {
    var calls = 0;
    final mock = MockClient((request) async {
      calls++;
      return http.Response(_envelope(['v$calls']), 200);
    });

    final client = ApiFootballClient(httpClient: mock, cacheTtl: const Duration(minutes: 2));
    var fakeNow = DateTime(2026, 7, 1, 12);

    final first = await client.getAll('standings', {'league': '1'}, now: () => fakeNow);
    final cachedHit = await client.getAll('standings', {'league': '1'}, now: () => fakeNow);
    fakeNow = fakeNow.add(const Duration(minutes: 3));
    final afterExpiry = await client.getAll('standings', {'league': '1'}, now: () => fakeNow);

    expect(first, ['v1']);
    expect(cachedHit, ['v1']);
    expect(afterExpiry, ['v2']);
    expect(calls, 2);
  });

  test('getAll returns an unmodifiable list so callers cannot poison the cache', () async {
    final mock = MockClient((request) async => http.Response(_envelope([1]), 200));
    final client = ApiFootballClient(httpClient: mock);

    final result = await client.getAll('fixtures', {});
    expect(() => result.add(2), throwsUnsupportedError);
  });

  test('a hung request fails with a timeout instead of hanging forever', () async {
    final mock = MockClient((request) => Completer<http.Response>().future);
    final client = ApiFootballClient(
      httpClient: mock,
      requestTimeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      client.getAll('fixtures', {}),
      throwsA(isA<ApiFootballException>().having(
        (e) => e.message,
        'message',
        contains('timed out'),
      )),
    );
  });

  test('an API error envelope (errors map) surfaces as ApiFootballException', () async {
    final mock = MockClient((request) async => http.Response(
          jsonEncode({
            'errors': {'token': 'Error/Missing application key.'},
            'response': [],
          }),
          200,
        ));
    final client = ApiFootballClient(httpClient: mock);

    await expectLater(
      client.getAll('fixtures', {}),
      throwsA(isA<ApiFootballException>()),
    );
  });

  test('a non-200 status surfaces as ApiFootballException', () async {
    final mock = MockClient((request) async => http.Response('rate limited', 429));
    final client = ApiFootballClient(httpClient: mock);

    await expectLater(
      client.getAll('fixtures', {}),
      throwsA(isA<ApiFootballException>()),
    );
  });
}
