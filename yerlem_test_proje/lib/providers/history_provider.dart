import 'package:flutter/foundation.dart';
import '../models/route_record.dart';
import '../services/database_service.dart';

class HistoryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<RouteRecord> _routeRecords = [];
  final Map<int, List<RoutePoint>> _routePoints = {};
  final Map<int, List<LocationVisit>> _routeVisits = {};
  String? _currentUserId;

  List<RouteRecord> get routeRecords => _routeRecords;
  Map<int, List<RoutePoint>> get routePoints => _routePoints;
  Map<int, List<LocationVisit>> get routeVisits => _routeVisits;

  // Kullanıcı ID'sini ayarla
  void setUserId(String userId) {
    _currentUserId = userId;
    _loadRouteRecords();
  }

  Future<void> _loadRouteRecords() async {
    if (_currentUserId == null) {
      print('Kullanıcı ID\'si ayarlanmamış, rota kayıtları yüklenmiyor');
      return;
    }
    
    _routeRecords = await _databaseService.getRouteRecords(_currentUserId!);
    
    // Her rota için noktaları ve ziyaretleri yükle
    for (final route in _routeRecords) {
      if (route.id != null) {
        _routePoints[route.id!] = await _databaseService.getRoutePoints(route.id!);
        _routeVisits[route.id!] = await _databaseService.getLocationVisits(route.id!);
      }
    }
    
    notifyListeners();
  }

  Future<List<RoutePoint>> getRoutePoints(int routeId) async {
    if (_routePoints.containsKey(routeId)) {
      return _routePoints[routeId]!;
    }
    
    final points = await _databaseService.getRoutePoints(routeId);
    _routePoints[routeId] = points;
    return points;
  }

  Future<List<LocationVisit>> getRouteVisits(int routeId) async {
    if (_routeVisits.containsKey(routeId)) {
      return _routeVisits[routeId]!;
    }
    
    final visits = await _databaseService.getLocationVisits(routeId);
    _routeVisits[routeId] = visits;
    return visits;
  }

  void refreshData() {
    _loadRouteRecords();
  }

  // Bitmemiş rotayı sonlandır
  Future<void> finishRoute(int routeId) async {
    if (_currentUserId == null) {
      print('Kullanıcı ID\'si ayarlanmamış, rota sonlandırılamıyor');
      return;
    }
    
    try {
      // Rotayı sonlandır
      final route = _routeRecords.firstWhere((r) => r.id == routeId);
      final updatedRoute = RouteRecord(
        id: route.id,
        userId: _currentUserId,
        startTime: route.startTime,
        endTime: DateTime.now(),
        points: route.points,
        visits: route.visits,
      );
      
      await _databaseService.updateRouteRecord(updatedRoute, _currentUserId!);
      
      // Verileri yenile
      await _loadRouteRecords();
      
      print('Rota $routeId sonlandırıldı');
    } catch (e) {
      print('Rota sonlandırılırken hata: $e');
    }
  }
} 