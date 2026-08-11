import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_api_client.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_exception.dart';

void main() {
  group('TagoBusApiClient', () {
    test('returns parsed items for a successful response', () async {
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
      final apiClient = TagoBusApiClient(client: httpClient);
      addTearDown(apiClient.dispose);

      final items = await apiClient.fetchArrivals(
        serviceKey: 'test key',
        cityCode: '33020',
        stopId: 'CHB272060002',
      );

      expect(items.single['routeno'], '100');
    });

    test('returns an empty list for a successful empty response', () async {
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
      );
      addTearDown(apiClient.dispose);

      final items = await apiClient.fetchArrivals(
        serviceKey: 'key',
        cityCode: '33020',
        stopId: 'stop',
      );

      expect(items, isEmpty);
    });

    test('throws the status code for an HTTP error', () async {
      final apiClient = TagoBusApiClient(
        client: MockClient((_) async => http.Response('unavailable', 503)),
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
    });

    test(
      'throws TimeoutException when the request exceeds its limit',
      () async {
        final pendingResponse = Completer<http.Response>();
        final apiClient = TagoBusApiClient(
          client: MockClient((_) => pendingResponse.future),
          requestTimeout: const Duration(milliseconds: 10),
        );
        addTearDown(apiClient.dispose);

        final request = apiClient.fetchArrivals(
          serviceKey: 'key',
          cityCode: '33020',
          stopId: 'stop',
        );

        await expectLater(request, throwsA(isA<TimeoutException>()));
      },
    );
  });
}
