import 'bus_arrival.dart';
import 'bus_route_summary.dart';

abstract interface class BusArrivalRepository {
  Future<List<BusArrival>> fetchArrivals({required String stopId});

  Future<List<BusRouteSummary>> fetchRoutesThroughStop({
    required String stopId,
  });

  void dispose();
}
