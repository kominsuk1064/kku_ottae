import '../domain/bus_arrival.dart';
import '../domain/bus_route_summary.dart';

enum BusArrivalsStatus { loading, empty, success, error }

final class BusArrivalsState {
  BusArrivalsState._({
    required this.status,
    required List<BusArrival> arrivals,
    required List<BusRouteSummary> routes,
    required this.errorMessage,
    required this.lastUpdated,
    required this.isRefreshing,
  }) : arrivals = List.unmodifiable(arrivals),
       routes = List.unmodifiable(routes);

  factory BusArrivalsState.loading({DateTime? lastUpdated}) {
    return BusArrivalsState._(
      status: BusArrivalsStatus.loading,
      arrivals: const [],
      routes: const [],
      errorMessage: null,
      lastUpdated: lastUpdated,
      isRefreshing: false,
    );
  }

  factory BusArrivalsState.empty({
    required List<BusRouteSummary> routes,
    required DateTime lastUpdated,
  }) {
    return BusArrivalsState._(
      status: BusArrivalsStatus.empty,
      arrivals: const [],
      routes: routes,
      errorMessage: null,
      lastUpdated: lastUpdated,
      isRefreshing: false,
    );
  }

  factory BusArrivalsState.success({
    required List<BusArrival> arrivals,
    required DateTime lastUpdated,
  }) {
    return BusArrivalsState._(
      status: BusArrivalsStatus.success,
      arrivals: arrivals,
      routes: const [],
      errorMessage: null,
      lastUpdated: lastUpdated,
      isRefreshing: false,
    );
  }

  factory BusArrivalsState.error({
    required String message,
    DateTime? lastUpdated,
  }) {
    return BusArrivalsState._(
      status: BusArrivalsStatus.error,
      arrivals: const [],
      routes: const [],
      errorMessage: message,
      lastUpdated: lastUpdated,
      isRefreshing: false,
    );
  }

  final BusArrivalsStatus status;
  final List<BusArrival> arrivals;
  final List<BusRouteSummary> routes;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final bool isRefreshing;

  BusArrivalsState startRefreshing() {
    return BusArrivalsState._(
      status: status,
      arrivals: arrivals,
      routes: routes,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated,
      isRefreshing: true,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BusArrivalsState &&
            status == other.status &&
            _listEquals(arrivals, other.arrivals) &&
            _listEquals(routes, other.routes) &&
            errorMessage == other.errorMessage &&
            lastUpdated == other.lastUpdated &&
            isRefreshing == other.isRefreshing;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      Object.hashAll(arrivals),
      Object.hashAll(routes),
      errorMessage,
      lastUpdated,
      isRefreshing,
    );
  }
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
