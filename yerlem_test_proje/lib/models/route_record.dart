/// Bir rota kaydını temsil eder. Kullanıcının bir rota üzerindeki başlangıç ve bitiş zamanları,
/// rota üzerindeki noktalar (RoutePoint) ve ziyaret edilen konumlar (LocationVisit) bilgilerini içerir.
class RouteRecord {
  final int? id; // Veritabanında her rotaya atanacak benzersiz ID (otomatik olabilir)
  final String? userId; // Rota kaydını oluşturan kullanıcıya ait ID
  final DateTime startTime; // Rota kaydının başlama zamanı
  final DateTime? endTime; // Rota kaydının bitiş zamanı (henüz bitmemişse null olabilir)
  final List<RoutePoint> points; // Rota üzerindeki konum noktaları (ayrı tabloda tutulacak)
  final List<LocationVisit> visits; // Rota sırasında ziyaret edilen yerler (ayrı tabloda tutulacak)

  RouteRecord({
    this.id,
    this.userId,
    required this.startTime,
    this.endTime,
    required this.points,
    required this.visits,
  });

  /// RouteRecord nesnesini Map yapısına dönüştürür.
  /// Bu yöntem veritabanına kayıt için kullanılır.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
    };
  }

  /// Map verisinden bir RouteRecord nesnesi oluşturur.
  /// points ve visits listeleri veritabanında ayrı tutulduğu için burada boş verilir.
  factory RouteRecord.fromMap(Map<String, dynamic> map) {
    return RouteRecord(
      id: map['id'],
      userId: map['userId'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      points: [], // Ayrı tablodan yüklenecek
      visits: [], // Ayrı tablodan yüklenecek
    );
  }
}

/// Rota üzerindeki bir coğrafi noktayı temsil eder.
/// Konum bilgisi ve zamana göre sıralı veri içerir.
class RoutePoint {
  final int? id; // Her nokta için veritabanı ID'si (otomatik olabilir)
  final int routeId; // Bu noktanın ait olduğu rota ID’si
  final double latitude; // Enlem bilgisi
  final double longitude; // Boylam bilgisi
  final DateTime timestamp; // Bu konuma varılan zaman

  RoutePoint({
    this.id,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// RoutePoint nesnesini Map yapısına dönüştürür (veritabanına kaydetmek için).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Map verisinden bir RoutePoint nesnesi oluşturur.
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

/// Rota sırasında ziyaret edilen belirli bir konumu temsil eder.
/// Konum ID'si, adı ve ziyaret zamanı içerir.
class LocationVisit {
  final int? id; // Veritabanı için benzersiz ID
  final int routeId; // Bu ziyaretin ait olduğu rota ID’si
  final int locationId; // Ziyaret edilen yerin ID’si
  final DateTime visitTime; // Ziyaret zamanı
  final String locationName; // Ziyaret edilen yerin adı

  LocationVisit({
    this.id,
    required this.routeId,
    required this.locationId,
    required this.visitTime,
    required this.locationName,
  });

  /// LocationVisit nesnesini Map yapısına dönüştürür.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'locationId': locationId,
      'visitTime': visitTime.millisecondsSinceEpoch,
      'locationName': locationName,
    };
  }

  /// Map verisinden bir LocationVisit nesnesi oluşturur.
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
