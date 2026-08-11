class BusArrival {
  const BusArrival({
    required this.routeId,
    required this.routeName,
    required this.minutes,
    required this.stopsAway,
    required this.direction,
  });

  final String routeId;
  final String routeName;
  final int minutes;
  final int stopsAway;
  final String direction;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BusArrival &&
            routeId == other.routeId &&
            routeName == other.routeName &&
            minutes == other.minutes &&
            stopsAway == other.stopsAway &&
            direction == other.direction;
  }

  @override
  int get hashCode {
    return Object.hash(routeId, routeName, minutes, stopsAway, direction);
  }
}
