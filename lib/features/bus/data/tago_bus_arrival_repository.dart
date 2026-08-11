import '../domain/bus_arrival.dart';
import '../domain/bus_arrival_repository.dart';
import '../domain/bus_route_summary.dart';
import 'tago_bus_api_client.dart';

class TagoBusArrivalRepository implements BusArrivalRepository {
  TagoBusArrivalRepository({
    required TagoBusApiClient apiClient,
    required this.serviceKey,
    required this.cityCode,
    this.minuteBias = 2,
    this.stopsBias = 1,
  }) : _apiClient = apiClient;

  factory TagoBusArrivalRepository.live({
    required String serviceKey,
    required String cityCode,
  }) {
    return TagoBusArrivalRepository(
      apiClient: TagoBusApiClient.live(),
      serviceKey: serviceKey,
      cityCode: cityCode,
    );
  }

  final TagoBusApiClient _apiClient;
  final String serviceKey;
  final String cityCode;
  final int minuteBias;
  final int stopsBias;

  @override
  Future<List<BusArrival>> fetchArrivals({required String stopId}) async {
    final items = await _apiClient.fetchArrivals(
      serviceKey: serviceKey,
      cityCode: cityCode,
      stopId: stopId,
    );

    final arrivals = items.map(_mapArrival).toList(growable: false)
      ..sort((first, second) {
        final byMinutes = first.minutes.compareTo(second.minutes);
        if (byMinutes != 0) {
          return byMinutes;
        }

        final byStops = first.stopsAway.compareTo(second.stopsAway);
        if (byStops != 0) {
          return byStops;
        }

        return first.routeName.compareTo(second.routeName);
      });

    return List.unmodifiable(arrivals);
  }

  @override
  Future<List<BusRouteSummary>> fetchRoutesThroughStop({
    required String stopId,
  }) async {
    final items = await _apiClient.fetchRoutesThroughStop(
      serviceKey: serviceKey,
      cityCode: cityCode,
      stopId: stopId,
    );

    return List.unmodifiable(
      items.map(
        (item) => BusRouteSummary(
          routeId: _asString(item['routeid']),
          routeName: _asString(item['routeno']),
        ),
      ),
    );
  }

  BusArrival _mapArrival(Map<String, dynamic> item) {
    final seconds = _asInt(item['arrtime']);
    final minutes = (seconds / 60).ceil();
    final stopsAway = _asInt(item['arrprevstationcnt']);
    final direction = _asString(item['updown']) == '0' ? '상행' : '하행';

    return BusArrival(
      routeId: _asString(item['routeid']),
      routeName: _asString(item['routeno']),
      minutes: (minutes - minuteBias).clamp(0, 9999).toInt(),
      stopsAway: (stopsAway - stopsBias).clamp(0, 9999).toInt(),
      direction: direction,
    );
  }

  int _asInt(Object? value) => int.tryParse(_asString(value)) ?? 0;

  String _asString(Object? value) => value?.toString() ?? '';

  @override
  void dispose() => _apiClient.dispose();
}
