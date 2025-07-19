class RouteRecord {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<RoutePoint> points;
  final List<LocationVisit> visits;

  RouteRecord({
    this.id,
    required this.startTime,
    this.endTime,
    required this.points,
    required this.visits,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
    };
  }

  factory RouteRecord.fromMap(Map<String, dynamic> map) {
    return RouteRecord(
      id: map['id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      points: [], // Bu veriler ayrı tabloda saklanacak
      visits: [], // Bu veriler ayrı tabloda saklanacak
    );
  }
}

class RoutePoint {
  final int? id;
  final int routeId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  RoutePoint({
    this.id,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    return RoutePoint(
      id: map['id'],
      routeId: map['routeId'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

class LocationVisit {
  final int? id;
  final int routeId;
  final int locationId;
  final DateTime visitTime;
  final String locationName;

  LocationVisit({
    this.id,
    required this.routeId,
    required this.locationId,
    required this.visitTime,
    required this.locationName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'locationId': locationId,
      'visitTime': visitTime.millisecondsSinceEpoch,
      'locationName': locationName,
    };
  }

  factory LocationVisit.fromMap(Map<String, dynamic> map) {
    return LocationVisit(
      id: map['id'],
      routeId: map['routeId'],
      locationId: map['locationId'],
      visitTime: DateTime.fromMillisecondsSinceEpoch(map['visitTime']),
      locationName: map['locationName'],
    );
  }
} 