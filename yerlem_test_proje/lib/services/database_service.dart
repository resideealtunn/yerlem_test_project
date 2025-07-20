import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location.dart';
import '../models/route_record.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'location_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Konumlar tablosu
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius REAL NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Rota kayıtları tablosu
    await db.execute('''
      CREATE TABLE route_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        startTime INTEGER NOT NULL,
        endTime INTEGER
      )
    ''');

    // Rota noktaları tablosu
    await db.execute('''
      CREATE TABLE route_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routeId INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (routeId) REFERENCES route_records (id)
      )
    ''');

    // Konum ziyaretleri tablosu
    await db.execute('''
      CREATE TABLE location_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routeId INTEGER NOT NULL,
        locationId INTEGER NOT NULL,
        visitTime INTEGER NOT NULL,
        locationName TEXT NOT NULL,
        FOREIGN KEY (routeId) REFERENCES route_records (id),
        FOREIGN KEY (locationId) REFERENCES locations (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // userId sütunlarını ekle
      await db.execute('ALTER TABLE locations ADD COLUMN userId TEXT');
      await db.execute('ALTER TABLE route_records ADD COLUMN userId TEXT');
      
      // Mevcut kayıtlar için varsayılan userId (eski kullanıcılar için)
      await db.execute('UPDATE locations SET userId = "legacy_user" WHERE userId IS NULL');
      await db.execute('UPDATE route_records SET userId = "legacy_user" WHERE userId IS NULL');
    }
  }

  // Konum işlemleri
  Future<int> insertLocation(Location location, String userId) async {
    final db = await database;
    final locationMap = location.toMap();
    locationMap['userId'] = userId;
    return await db.insert('locations', locationMap);
  }

  Future<List<Location>> getLocations(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Location.fromMap(maps[i]));
  }

  Future<void> deleteLocation(int id, String userId) async {
    final db = await database;
    await db.delete(
      'locations', 
      where: 'id = ? AND userId = ?', 
      whereArgs: [id, userId]
    );
  }

  Future<void> updateLocation(Location location, String userId) async {
    final db = await database;
    final locationMap = location.toMap();
    print('Güncellenecek konum verisi: $locationMap');
    
    final result = await db.update(
      'locations',
      locationMap,
      where: 'id = ? AND userId = ?',
      whereArgs: [location.id, userId],
    );
    
    print('Güncelleme sonucu: $result satır etkilendi');
    
    // Güncellenmiş veriyi kontrol et
    final updatedMaps = await db.query(
      'locations',
      where: 'id = ? AND userId = ?',
      whereArgs: [location.id, userId],
    );
    
    if (updatedMaps.isNotEmpty) {
      print('Güncellenmiş veri: ${updatedMaps.first}');
    } else {
      print('Güncellenmiş veri bulunamadı!');
    }
  }

  // Rota kayıt işlemleri
  Future<int> insertRouteRecord(RouteRecord route, String userId) async {
    final db = await database;
    final routeMap = route.toMap();
    routeMap['userId'] = userId;
    return await db.insert('route_records', routeMap);
  }

  Future<void> updateRouteRecord(RouteRecord route, String userId) async {
    final db = await database;
    await db.update(
      'route_records',
      route.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [route.id, userId],
    );
  }

  Future<List<RouteRecord>> getRouteRecords(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'route_records',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => RouteRecord.fromMap(maps[i]));
  }

  // Rota noktaları işlemleri
  Future<void> insertRoutePoint(RoutePoint point) async {
    final db = await database;
    await db.insert('route_points', point.toMap());
  }

  Future<List<RoutePoint>> getRoutePoints(int routeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'route_points',
      where: 'routeId = ?',
      whereArgs: [routeId],
    );
    return List.generate(maps.length, (i) => RoutePoint.fromMap(maps[i]));
  }

  // Konum ziyaretleri işlemleri
  Future<void> insertLocationVisit(LocationVisit visit) async {
    final db = await database;
    await db.insert('location_visits', visit.toMap());
  }

  Future<List<LocationVisit>> getLocationVisits(int routeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'location_visits',
      where: 'routeId = ?',
      whereArgs: [routeId],
    );
    return List.generate(maps.length, (i) => LocationVisit.fromMap(maps[i]));
  }
} 