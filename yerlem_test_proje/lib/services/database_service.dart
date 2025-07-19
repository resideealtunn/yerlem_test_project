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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Konumlar tablosu
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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

  // Konum işlemleri
  Future<int> insertLocation(Location location) async {
    final db = await database;
    return await db.insert('locations', location.toMap());
  }

  Future<List<Location>> getLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('locations');
    return List.generate(maps.length, (i) => Location.fromMap(maps[i]));
  }

  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  // Rota kayıt işlemleri
  Future<int> insertRouteRecord(RouteRecord route) async {
    final db = await database;
    return await db.insert('route_records', route.toMap());
  }

  Future<void> updateRouteRecord(RouteRecord route) async {
    final db = await database;
    await db.update(
      'route_records',
      route.toMap(),
      where: 'id = ?',
      whereArgs: [route.id],
    );
  }

  Future<List<RouteRecord>> getRouteRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('route_records');
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