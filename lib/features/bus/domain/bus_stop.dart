class BusStop {
  const BusStop({
    required this.stopId,
    required this.stopName,
    this.latitude,
    this.longitude,
  });

  final String stopId;
  final String stopName;
  final double? latitude;
  final double? longitude;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BusStop &&
            stopId == other.stopId &&
            stopName == other.stopName &&
            latitude == other.latitude &&
            longitude == other.longitude;
  }

  @override
  int get hashCode => Object.hash(stopId, stopName, latitude, longitude);
}
