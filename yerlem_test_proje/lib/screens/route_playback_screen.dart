import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../models/route_record.dart';

class RoutePlaybackScreen extends StatefulWidget {
  final int routeId;
  final List<RoutePoint> routePoints;
  final List<LocationVisit> visits;
  final bool isIncompleteRoute;

  const RoutePlaybackScreen({
    super.key,
    required this.routeId,
    required this.routePoints,
    required this.visits,
    this.isIncompleteRoute = false,
  });

  @override
  State<RoutePlaybackScreen> createState() => _RoutePlaybackScreenState();
}

class _RoutePlaybackScreenState extends State<RoutePlaybackScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  
  bool _isPlaying = false;
  int _currentPointIndex = 0;
  Timer? _playbackTimer;
  double _playbackSpeed = 1.0; // Oynatım hızı (1.0 = normal hız)
  
  // Rota sınırlarını hesaplama
  LatLngBounds? _routeBounds;

  @override
  void initState() {
    super.initState();
    _calculateRouteBounds();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  // Rota sınırlarını hesapla
  void _calculateRouteBounds() {
    if (widget.routePoints.isEmpty) return;
    
    double minLat = widget.routePoints.first.latitude;
    double maxLat = widget.routePoints.first.latitude;
    double minLng = widget.routePoints.first.longitude;
    double maxLng = widget.routePoints.first.longitude;
    
    for (final point in widget.routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    _routeBounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _startPlayback() {
    if (_isPlaying || widget.routePoints.isEmpty) return;

    // Eğer rota bittiyse baştan başlat
    if (_currentPointIndex >= widget.routePoints.length) {
      _currentPointIndex = 0;
    }

    setState(() {
      _isPlaying = true;
    });

    _startTimer();
  }

  // Bitmemiş rotalar için özel oynatma metodu
  void _startPlaybackFromCurrentPosition() {
    if (_isPlaying || widget.routePoints.isEmpty) return;

    // Mevcut pozisyondan devam et, baştan başlatma
    setState(() {
      _isPlaying = true;
    });

    _startTimer();
  }

  void _startTimer() {
    // Hıza göre timer süresini hesapla (500ms normal hız)
    final timerDuration = (500 / _playbackSpeed).round();
    
    _playbackTimer = Timer.periodic(Duration(milliseconds: timerDuration), (timer) {
      if (_currentPointIndex >= widget.routePoints.length) {
        _stopPlayback();
        return;
      }

      setState(() {
        _currentPointIndex++;
        _updateMapData();
      });
    });
  }

  void _restartPlaybackWithNewSpeed() {
    // Mevcut timer'ı durdur
    _playbackTimer?.cancel();
    
    // Yeni hızla timer'ı başlat
    _startTimer();
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _resetPlayback() {
    _stopPlayback();
    setState(() {
      _currentPointIndex = 0;
      _updateMapData();
    });
  }

  void _updateMapData() {
    _markers.clear();
    _polylines.clear();
    _circles.clear();

    if (widget.routePoints.isEmpty) return;

    // Tam rotayı çiz
    final allPoints = widget.routePoints.map((point) {
      return LatLng(point.latitude, point.longitude);
    }).toList();

    final fullPolyline = Polyline(
      polylineId: const PolylineId('full_route'),
      points: allPoints,
      color: Colors.grey.withOpacity(0.5),
      width: 2,
    );
    _polylines.add(fullPolyline);

    // Oynatılan kısmı çiz
    if (_currentPointIndex > 0) {
      final playedPoints = widget.routePoints
          .take(_currentPointIndex)
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      final playedPolyline = Polyline(
        polylineId: const PolylineId('played_route'),
        points: playedPoints,
        color: Colors.red,
        width: 4,
      );
      _polylines.add(playedPolyline);
    }

    // Mevcut konum marker'ı
    if (_currentPointIndex < widget.routePoints.length) {
      final currentPoint = widget.routePoints[_currentPointIndex];
      final currentMarker = Marker(
        markerId: const MarkerId('current_position'),
        position: LatLng(currentPoint.latitude, currentPoint.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Konum ${_currentPointIndex + 1}',
          snippet: 'Zaman: ${_formatDateTime(currentPoint.timestamp)}',
        ),
      );
      _markers.add(currentMarker);

      // Haritayı mevcut konuma odakla (daha yumuşak geçiş)
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentPoint.latitude, currentPoint.longitude),
          16, // Daha yakın zoom seviyesi
        ),
      );
    }

    // Ziyaret edilen konumları işaretle
    for (final visit in widget.visits) {
      final visitTime = visit.visitTime;
      final visitIndex = widget.routePoints.indexWhere((point) => 
        point.timestamp.isAfter(visitTime.subtract(const Duration(minutes: 1))) &&
        point.timestamp.isBefore(visitTime.add(const Duration(minutes: 1)))
      );

      if (visitIndex != -1 && visitIndex <= _currentPointIndex) {
        final visitPoint = widget.routePoints[visitIndex];
        final visitMarker = Marker(
          markerId: MarkerId('visit_${visit.locationId}'),
          position: LatLng(visitPoint.latitude, visitPoint.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: visit.locationName,
            snippet: 'Ziyaret: ${_formatDateTime(visit.visitTime)}',
          ),
        );
        _markers.add(visitMarker);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _getProgressText() {
    if (widget.routePoints.isEmpty) return '0%';
    final progress = (_currentPointIndex / widget.routePoints.length * 100).round();
    return '$progress%';
  }

  // Başlangıç kamera pozisyonunu hesapla
  CameraPosition _getInitialCameraPosition() {
    if (widget.routePoints.isEmpty) {
      // Varsayılan Konya koordinatları
      return const CameraPosition(
        target: LatLng(37.872669888420376, 32.49263157763532),
        zoom: 12,
      );
    }
    
    // Rota noktalarının ortalamasını al
    double avgLat = 0;
    double avgLng = 0;
    
    for (final point in widget.routePoints) {
      avgLat += point.latitude;
      avgLng += point.longitude;
    }
    
    avgLat /= widget.routePoints.length;
    avgLng /= widget.routePoints.length;
    
    return CameraPosition(
      target: LatLng(avgLat, avgLng),
      zoom: 14, // Daha yakın zoom
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rota #${widget.routeId} ${widget.isIncompleteRoute ? '(Devam Ediyor)' : 'Oynatımı'}'),
        backgroundColor: widget.isIncompleteRoute ? Colors.orange : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _getInitialCameraPosition(),
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMapData();
                // Haritayı rota sınırlarına göre ayarla
                if (_routeBounds != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(_routeBounds!, 50),
                  );
                }
              },
              markers: _markers,
              polylines: _polylines,
              circles: _circles,
              zoomControlsEnabled: false,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (widget.isIncompleteRoute) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu rota henüz tamamlanmamış. Kaldığınız yerden devam edebilirsiniz.',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İlerleme: ${_currentPointIndex + 1}/${widget.routePoints.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getProgressText(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.routePoints.isEmpty ? 0 : _currentPointIndex / widget.routePoints.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                // Hız ayarlama
                Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Hız:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _playbackSpeed,
                        min: 0.25,
                        max: 4.0,
                        divisions: 15,
                        label: '${_playbackSpeed.toStringAsFixed(1)}x',
                        onChanged: (value) {
                          setState(() {
                            _playbackSpeed = value;
                          });
                          // Eğer oynatım devam ediyorsa timer'ı yeniden başlat
                          if (_isPlaying) {
                            _restartPlaybackWithNewSpeed();
                          }
                        },
                      ),
                    ),
                    Text(
                      '${_playbackSpeed.toStringAsFixed(1)}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? null : (widget.isIncompleteRoute ? _startPlaybackFromCurrentPosition : _startPlayback),
                      icon: Icon(widget.isIncompleteRoute ? Icons.play_circle_outline : Icons.play_arrow),
                      label: Text(widget.isIncompleteRoute ? 'Devam Et' : 'Oynat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isIncompleteRoute ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? _stopPlayback : null,
                      icon: const Icon(Icons.pause),
                      label: const Text('Duraklat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                    if (!widget.isIncompleteRoute) ...[
                      ElevatedButton.icon(
                        onPressed: _resetPlayback,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Sıfırla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 