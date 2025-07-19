class Location {
  final int? id;
  final String? userId;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final DateTime createdAt;

  Location({
    this.id,
    this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      radius: map['radius'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 