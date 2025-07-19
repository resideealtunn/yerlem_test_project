import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isTracking = false;

  Stream<Position> get locationStream => _locationController.stream;

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      print('Konum alınıyor...');
      
      // Önce konum servisinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Konum servisi kapalı!');
        return null;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
        forceAndroidLocationManager: true,
      );
      print('Konum alındı: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Konum alınamadı: $e');
      return null;
    }
  }

  void startLocationTracking() {
    if (_isTracking) return;
    
    _isTracking = true;
    print('Konum takibi başlatılıyor...');
    
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1, // 1 metre
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      print('Yeni konum alındı: ${position.latitude}, ${position.longitude}');
      _locationController.add(position);
      
      // Background'da çalışırken bildirim göster
      _showBackgroundNotification(position);
    });
    
    // Başlangıç bildirimi
    _showBackgroundNotification(null);
  }

  void stopLocationTracking() {
    if (!_isTracking) return;
    
    _isTracking = false;
    _positionStream?.cancel();
    print('Konum takibi durduruldu');
    
    // Bildirimi kaldır
    _notifications.cancel(100);
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void dispose() {
    _positionStream?.cancel();
    _locationController.close();
  }

  // Background notification göster
  void _showBackgroundNotification(Position? position) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'location_tracking',
      'Konum Takibi',
      channelDescription: 'Arkaplan konum takibi',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    String message = 'Konum takibi aktif';
    if (position != null) {
      message = 'Konum: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }

    await _notifications.show(
      100,
      'Rota Kaydediliyor',
      message,
      platformChannelSpecifics,
    );
  }
} 