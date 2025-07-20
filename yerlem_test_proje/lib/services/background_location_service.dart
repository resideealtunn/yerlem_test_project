import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Ana uygulama için background service wrapper
class BackgroundLocationService {
  static const MethodChannel _channel = MethodChannel('background_location_service');
  
  static Future<void> startBackgroundLocation() async {
    try {
      await _channel.invokeMethod('startBackgroundLocation');
      print('Background location service başlatıldı');
    } catch (e) {
      print('Background service başlatılamadı: $e');
    }
  }

  static Future<void> stopBackgroundLocation() async {
    try {
      await _channel.invokeMethod('stopBackgroundLocation');
      print('Background location service durduruldu');
    } catch (e) {
      print('Background service durdurulamadı: $e');
    }
  }
} 