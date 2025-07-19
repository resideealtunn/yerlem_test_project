import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  
  // Konya koordinatları
  static const LatLng _konyaCenter = LatLng(37.872669888420376, 32.49263157763532);

  @override
  void initState() {
    super.initState();
    // Provider'dan konumları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().refreshLocations();
    });
  }

  void _updateMapData() {
    final provider = context.read<LocationProvider>();
    
    print('=== HARITA GÜNCELLENİYOR ===');
    print('Konumlar güncelleniyor. Toplam: ${provider.locations.length}');
    
    // Yeni set'ler oluştur
    final Set<Marker> newMarkers = {};
    final Set<Circle> newCircles = {};
    final Set<Polyline> newPolylines = {};
    
    // Konumları ekle
    for (final location in provider.locations) {
      print('Konum ekleniyor: ${location.name} - ${location.latitude}, ${location.longitude}');
      
      final marker = Marker(
        markerId: MarkerId('location_${location.id}'),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: 'Yarıçap: ${location.radius.toInt()}m',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
      newMarkers.add(marker);

      // Daire ekle - Daha büyük ve görünür yap
      print('Circle ekleniyor: ${location.name} - Merkez: ${location.latitude}, ${location.longitude} - Yarıçap: ${location.radius}m');
      final circle = Circle(
        circleId: CircleId('circle_${location.id}'),
        center: LatLng(location.latitude, location.longitude),
        radius: location.radius,
        fillColor: const Color(0xFF2196F3).withOpacity(0.4),
        strokeColor: const Color(0xFF1976D2),
        strokeWidth: 4,
      );
      newCircles.add(circle);
      print('Circle eklendi. Toplam circle sayısı: ${newCircles.length}');
    }

    print('Toplam marker: ${newMarkers.length}');
    print('Toplam circle: ${newCircles.length}');

    // Mevcut konumu ekle
    if (provider.currentPosition != null) {
      print('Mevcut konum ekleniyor: ${provider.currentPosition!.latitude}, ${provider.currentPosition!.longitude}');
      
      final currentMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(
          provider.currentPosition!.latitude,
          provider.currentPosition!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Mevcut Konum',
          snippet: 'Şu anki konumunuz',
        ),
      );
      newMarkers.add(currentMarker);
    }

    // Rota çizgisini ekle
    if (provider.isTracking && provider.currentRoutePoints.isNotEmpty) {
      print('Rota çizgisi ekleniyor. Nokta sayısı: ${provider.currentRoutePoints.length}');
      
      final points = provider.currentRoutePoints.map((point) {
        return LatLng(point.latitude, point.longitude);
      }).toList();

      final polyline = Polyline(
        polylineId: const PolylineId('current_route'),
        points: points,
        color: Colors.red,
        width: 4,
      );
      newPolylines.add(polyline);
    }
    
    // setState ile güncelle
    setState(() {
      _markers = newMarkers;
      _circles = newCircles;
      _polylines = newPolylines;
    });
    
    print('=== HARITA GÜNCELLEME TAMAMLANDI ===');
    print('Final marker sayısı: ${_markers.length}');
    print('Final circle sayısı: ${_circles.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Haritayı yenile
              context.read<LocationProvider>().refreshLocations();
              _updateMapData();
            },
            tooltip: 'Haritayı Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Mevcut konuma odaklan
              final provider = context.read<LocationProvider>();
              if (provider.currentPosition != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      provider.currentPosition!.latitude,
                      provider.currentPosition!.longitude,
                    ),
                  ),
                );
              } else {
                // Konum yoksa kullanıcıya bilgi ver
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Konum alınamıyor. GPS\'i kontrol edin.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            tooltip: 'Mevcut Konuma Git',
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          // Sadece konumlar değiştiğinde güncelle
          if (_markers.isEmpty || _markers.length != provider.locations.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('Consumer tetiklendi. Konum sayısı: ${provider.locations.length}');
              _updateMapData();
            });
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _konyaCenter,
                  zoom: 12,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Harita oluşturulduktan sonra verileri güncelle
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateMapData();
                  });
                },
                markers: _markers,
                circles: _circles,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onCameraMove: (position) {
                  // Harita hareket ettiğinde mevcut konumu takip et
                  if (provider.isTracking && provider.currentPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(
                          provider.currentPosition!.latitude,
                          provider.currentPosition!.longitude,
                        ),
                      ),
                    );
                  }
                },
              ),
              // Üst bilgi kartı
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: provider.isTracking 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                provider.isTracking ? Icons.gps_fixed : Icons.gps_off,
                                color: provider.isTracking ? Colors.green : Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.isTracking ? 'Rota Kaydediliyor' : 'Rota Bekliyor',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${provider.locations.length} konum takip ediliyor',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: provider.isTracking ? null : () => _handleStartTracking(context),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Başlat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: provider.isTracking ? provider.stopTracking : null,
                                icon: const Icon(Icons.stop),
                                label: const Text('Bitir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (provider.currentPosition != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Konum: ${provider.currentPosition!.latitude.toStringAsFixed(6)}, '
                                    '${provider.currentPosition!.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_off, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Konum alınamıyor. GPS\'i kontrol edin.',
                                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Basit bilgi kartı
              if (provider.locations.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${provider.locations.length} konum haritada gösteriliyor',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleStartTracking(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.isGuest) {
      // Misafir kullanıcı için uyarı göster
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kayıt Gerekli'),
          content: const Text(
            'Rota kaydetmek için öncelikle kayıt olmanız gerekmektedir. '
            'Misafir kullanıcılar rota kaydedemez.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Ana giriş ekranına yönlendir
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      );
    } else {
      // Kayıtlı kullanıcı için tracking başlat
      context.read<LocationProvider>().startTracking();
    }
  }
} 