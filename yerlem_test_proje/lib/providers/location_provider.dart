import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location.dart';
import '../models/route_record.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class LocationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  
  List<Location> _locations = [];
  Position? _currentPosition;
  bool _isTracking = false;
  RouteRecord? _currentRoute;
  List<RoutePoint> _currentRoutePoints = [];
  List<LocationVisit> _currentVisits = [];
  Set<int> _visitedLocations = {};

  List<Location> get locations => _locations;
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  RouteRecord? get currentRoute => _currentRoute;
  List<RoutePoint> get currentRoutePoints => _currentRoutePoints;

  LocationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadLocations();
    await _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    print('Konum izni kontrol ediliyor...');
    bool hasPermission = await _locationService.checkLocationPermission();
    print('Konum izni durumu: $hasPermission');
    
    if (hasPermission) {
      print('Konum alınıyor...');
      _currentPosition = await _locationService.getCurrentLocation();
      print('Mevcut konum alındı: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      notifyListeners();
      
      // Konum takibini başlat
      print('Konum takibi başlatılıyor...');
      _locationService.startLocationTracking();
      _locationService.locationStream.listen(_onLocationUpdate);
      
      // 5 saniye sonra tekrar konum al
      Future.delayed(const Duration(seconds: 5), () async {
        print('5 saniye sonra konum yeniden alınıyor...');
        _currentPosition = await _locationService.getCurrentLocation();
        print('Yeni konum alındı: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
        notifyListeners();
      });
    } else {
      print('Konum izni verilmedi! Lütfen uygulama ayarlarından konum iznini verin.');
    }
  }

  Future<void> _loadLocations() async {
    try {
      _locations = await _databaseService.getLocations();
      print('Konumlar yüklendi. Toplam: ${_locations.length}');
      for (final location in _locations) {
        print('Konum: ${location.name} - ${location.latitude}, ${location.longitude}');
      }
      notifyListeners();
    } catch (e) {
      print('Konumlar yüklenirken hata: $e');
    }
  }

  Future<void> addLocation(String name, double latitude, double longitude, double radius) async {
    print('Konum ekleniyor: $name, $latitude, $longitude, $radius');
    
    final location = Location(
      name: name,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      createdAt: DateTime.now(),
    );

    try {
      final id = await _databaseService.insertLocation(location);
      print('Konum başarıyla eklendi. ID: $id');
      await _loadLocations();
      print('Konumlar yeniden yüklendi. Toplam: ${_locations.length}');
    } catch (e) {
      print('Konum eklenirken hata: $e');
    }
  }

  Future<void> deleteLocation(int id) async {
    await _databaseService.deleteLocation(id);
    await _loadLocations();
  }

  // Konumları manuel olarak yeniden yükleme metodu
  Future<void> refreshLocations() async {
    await _loadLocations();
  }

  // Konumu yeniden al
  Future<void> refreshCurrentLocation() async {
    print('Konum yeniden alınıyor...');
    
    // Önce konum servisini kontrol et
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Konum servisi kapalı! Lütfen GPS\'i açın.');
      return;
    }
    
    _currentPosition = await _locationService.getCurrentLocation();
    print('Yeni konum alındı: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    notifyListeners();
    
    // 3 saniye sonra tekrar dene
    Future.delayed(const Duration(seconds: 3), () async {
      print('3 saniye sonra konum tekrar alınıyor...');
      final newPosition = await _locationService.getCurrentLocation();
      if (newPosition != null) {
        _currentPosition = newPosition;
        print('Güncellenmiş konum: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
        notifyListeners();
      }
    });
  }

  void startTracking() async {
    if (_isTracking) return;

    print('Rota takibi başlatılıyor...');
    _isTracking = true;
    _currentRoute = RouteRecord(
      startTime: DateTime.now(),
      points: [],
      visits: [],
    );

    final routeId = await _databaseService.insertRouteRecord(_currentRoute!);
    _currentRoute = RouteRecord(
      id: routeId,
      startTime: _currentRoute!.startTime,
      points: [],
      visits: [],
    );

    _currentRoutePoints = [];
    _currentVisits = [];
    _visitedLocations = {};

    _locationService.startLocationTracking();
    _locationService.locationStream.listen(_onLocationUpdate);

    await NotificationService.showRouteStartedNotification();
    notifyListeners();
    
    print('Rota takibi başlatıldı. Route ID: $routeId');
  }

  void stopTracking() async {
    if (!_isTracking) return;

    print('Rota takibi durduruluyor...');
    _isTracking = false;
    _locationService.stopLocationTracking();

    if (_currentRoute != null) {
      final updatedRoute = RouteRecord(
        id: _currentRoute!.id,
        startTime: _currentRoute!.startTime,
        endTime: DateTime.now(),
        points: _currentRoutePoints,
        visits: _currentVisits,
      );

      await _databaseService.updateRouteRecord(updatedRoute);
      print('Rota kaydedildi. Route ID: ${_currentRoute!.id}');
    }

    await NotificationService.showRouteEndedNotification();
    notifyListeners();
  }

  void _onLocationUpdate(Position position) {
    print('Konum güncelleniyor: ${position.latitude}, ${position.longitude}');
    _currentPosition = position;
    
    if (_isTracking && _currentRoute != null) {
      final routePoint = RoutePoint(
        routeId: _currentRoute!.id!,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      _currentRoutePoints.add(routePoint);
      _databaseService.insertRoutePoint(routePoint);

      // Konum ziyaretlerini kontrol et
      _checkLocationVisits(position);
    }

    notifyListeners();
  }

  void _checkLocationVisits(Position position) {
    for (final location in _locations) {
      if (_visitedLocations.contains(location.id)) continue;

      final distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        location.latitude,
        location.longitude,
      );

      if (distance <= location.radius) {
        _visitedLocations.add(location.id!);
        
        final visit = LocationVisit(
          routeId: _currentRoute!.id!,
          locationId: location.id!,
          visitTime: DateTime.now(),
          locationName: location.name,
        );

        _currentVisits.add(visit);
        _databaseService.insertLocationVisit(visit);
        NotificationService.showLocationNotification(location.name);
      }
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
} 