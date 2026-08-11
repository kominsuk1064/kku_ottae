import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_api_client.dart';
import 'package:kku_ottae/features/bus/data/tago_bus_arrival_repository.dart';
import 'package:kku_ottae/features/bus/domain/bus_arrival.dart';
import 'package:kku_ottae/features/bus/domain/bus_route_summary.dart';

void main() {
  group('TagoBusArrivalRepository', () {
    test('maps, adjusts, and sorts arrival items', () async {
      final repository = _repositoryWithResponse('''
        {
          "response": {
            "body": {
              "totalCount": 3,
              "items": {
                "item": [
                  {
                    "routeid": "B",
                    "routeno": "200",
                    "arrtime": "180",
                    "arrprevstationcnt": "4",
                    "updown": "1"
                  },
                  {
                    "routeid": "A",
                    "routeno": "100",
                    "arrtime": "61",
                    "arrprevstationcnt": "2",
                    "updown": "0"
                  },
                  {
                    "routeid": "C",
                    "routeno": "300",
                    "arrtime": null,
                    "arrprevstationcnt": null,
                    "updown": null
                  }
                ]
              }
            }
          }
        }
      ''');
      addTearDown(repository.dispose);

      final arrivals = await repository.fetchArrivals(stopId: 'stop');

      expect(arrivals, [
        const BusArrival(
          routeId: 'C',
          routeName: '300',
          minutes: 0,
          stopsAway: 0,
          direction: '하행',
        ),
        const BusArrival(
          routeId: 'A',
          routeName: '100',
          minutes: 0,
          stopsAway: 1,
          direction: '상행',
        ),
        const BusArrival(
          routeId: 'B',
          routeName: '200',
          minutes: 1,
          stopsAway: 3,
          direction: '하행',
        ),
      ]);
    });

    test('maps routes that pass through the stop', () async {
      final repository = _repositoryWithResponse('''
        {
          "response": {
            "body": {
              "totalCount": 1,
              "items": {
                "item": {"routeid": "A", "routeno": "100"}
              }
            }
          }
        }
      ''');
      addTearDown(repository.dispose);

      final routes = await repository.fetchRoutesThroughStop(stopId: 'stop');

      expect(routes, [const BusRouteSummary(routeId: 'A', routeName: '100')]);
    });
  });
}

TagoBusArrivalRepository _repositoryWithResponse(String responseBody) {
  final apiClient = TagoBusApiClient(
    client: MockClient((_) async => http.Response(responseBody, 200)),
  );
  return TagoBusArrivalRepository(
    apiClient: apiClient,
    serviceKey: 'key',
    cityCode: '33020',
  );
}
