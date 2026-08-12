import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_api_client.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_exception.dart';

import '../../../support/fake_app_performance_monitor.dart';

void main() {
  group('TagoBusApiClient', () {
    test('returns parsed items for a successful response', () async {
      final performanceMonitor = FakeAppPerformanceMonitor();
      final httpClient = MockClient((request) async {
        expect(request.url.queryParameters['serviceKey'], 'test key');
        expect(request.url.queryParameters['cityCode'], '33020');
        expect(request.url.queryParameters['nodeId'], 'CHB272060002');

        return http.Response('''
          {
            "response": {
              "body": {
                "totalCount": 1,
                "items": {
                  "item": {"routeid": "CHB1", "routeno": "100"}
                }
              }
            }
          }
        ''', 200);
      });
      final apiClient = TagoBusApiClient(
        client: httpClient,
        performanceMonitor: performanceMonitor,
      );
      addTearDown(apiClient.dispose);

      final items = await apiClient.fetchArrivals(
        serviceKey: 'test key',
        cityCode: '33020',
        stopId: 'CHB272060002',
      );

      expect(items.single['routeno'], '100');
      final trace = performanceMonitor.traces.single;
      expect(trace.name, TagoBusApiClient.performanceTraceName);
      expect(trace.attributes, {
        'operation': 'arrivals',
        'http_status': '200',
        'outcome': 'success',
      });
      expect(trace.metrics['item_count'], 1);
      expect(trace.metrics['response_bytes'], greaterThan(0));
      expect(trace.stopped, isTrue);
    });

    test('returns an empty list for a successful empty response', () async {
      final performanceMonitor = FakeAppPerformanceMonitor();
      final apiClient = TagoBusApiClient(
        client: MockClient(
          (_) async => http.Response('''
            {
              "response": {
                "body": {"totalCount": 0, "items": null}
              }
            }
          ''', 200),
        ),
        performanceMonitor: performanceMonitor,
      );
      addTearDown(apiClient.dispose);

      final items = await apiClient.fetchArrivals(
        serviceKey: 'key',
        cityCode: '33020',
        stopId: 'stop',
      );

      expect(items, isEmpty);
      final trace = performanceMonitor.traces.single;
      expect(trace.attributes['outcome'], 'empty');
      expect(trace.metrics['item_count'], 0);
      expect(trace.stopped, isTrue);
    });

    test('throws the status code for an HTTP error', () async {
      final performanceMonitor = FakeAppPerformanceMonitor();
      final apiClient = TagoBusApiClient(
        client: MockClient((_) async => http.Response('unavailable', 503)),
        performanceMonitor: performanceMonitor,
      );
      addTearDown(apiClient.dispose);

      final request = apiClient.fetchArrivals(
        serviceKey: 'key',
        cityCode: '33020',
        stopId: 'stop',
      );

      await expectLater(
        request,
        throwsA(
          isA<TagoBusHttpException>().having(
            (error) => error.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
      final trace = performanceMonitor.traces.single;
      expect(trace.attributes['http_status'], '503');
      expect(trace.attributes['outcome'], 'http_error');
      expect(trace.stopped, isTrue);
    });

    test(
      'throws TimeoutException when the request exceeds its limit',
      () async {
        final performanceMonitor = FakeAppPerformanceMonitor();
        final pendingResponse = Completer<http.Response>();
        final apiClient = TagoBusApiClient(
          client: MockClient((_) => pendingResponse.future),
          performanceMonitor: performanceMonitor,
          requestTimeout: const Duration(milliseconds: 10),
        );
        addTearDown(apiClient.dispose);

        final request = apiClient.fetchArrivals(
          serviceKey: 'key',
          cityCode: '33020',
          stopId: 'stop',
        );

        await expectLater(request, throwsA(isA<TimeoutException>()));
        final trace = performanceMonitor.traces.single;
        expect(trace.attributes['outcome'], 'timeout');
        expect(trace.stopped, isTrue);
      },
    );

    test(
      'records an invalid response without exposing request values',
      () async {
        final performanceMonitor = FakeAppPerformanceMonitor();
        final apiClient = TagoBusApiClient(
          client: MockClient((_) async => http.Response('not-json', 200)),
          performanceMonitor: performanceMonitor,
        );
        addTearDown(apiClient.dispose);

        final request = apiClient.fetchRoutesThroughStop(
          serviceKey: 'private-service-key',
          cityCode: '33020',
          stopId: 'private-stop-id',
        );

        await expectLater(request, throwsA(isA<FormatException>()));
        final trace = performanceMonitor.traces.single;
        expect(trace.attributes, {
          'operation': 'routes',
          'http_status': '200',
          'outcome': 'invalid_response',
        });
        expect(
          trace.attributes.toString(),
          isNot(contains('private-service-key')),
        );
        expect(trace.attributes.toString(), isNot(contains('private-stop-id')));
        expect(trace.stopped, isTrue);
      },
    );
  });
}
