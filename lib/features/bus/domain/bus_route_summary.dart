class BusRouteSummary {
  const BusRouteSummary({required this.routeId, required this.routeName});

  final String routeId;
  final String routeName;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BusRouteSummary &&
            routeId == other.routeId &&
            routeName == other.routeName;
  }

  @override
  int get hashCode => Object.hash(routeId, routeName);
}
