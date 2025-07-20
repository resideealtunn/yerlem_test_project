import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../providers/location_provider.dart';
import '../models/location.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  Location? _startLocation;
  Location? _endLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = false;
  String? _errorMessage;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Location> _selectedStops = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocations();
    });
  }

  void _loadLocations() {
    final locationProvider = context.read<LocationProvider>();
    locationProvider.refreshLocations();
  }

  Future<void> _findRoute() async {
    if (_startLocation == null || _endLocation == null) {
      setState(() {
        _errorMessage = 'Lütfen başlangıç ve bitiş noktalarını seçin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Seçilen durakları al ve tekrarları kaldır
      Set<Location> uniqueStops = _selectedStops.toSet();
      
      // Başlangıç ve bitiş aynı ise özel işlem
      bool isSameLocation = _startLocation == _endLocation;
      
      // Başlangıç ve bitiş noktalarını duraklar listesinden çıkar
      uniqueStops.remove(_startLocation);
      uniqueStops.remove(_endLocation);
      
      List<Location> waypoints = uniqueStops.toList();
      
      // Eğer hiç durak yoksa ve başlangıç/bitiş aynıysa, rota bulmaya gerek yok
      if (waypoints.isEmpty && isSameLocation) {
        setState(() {
          _routePoints = [];
          _updateMap();
          _isLoading = false;
        });
        return;
      }

      // En kısa yol sıralamasını hesapla
      List<Location> optimizedWaypoints = await _calculateOptimalRoute(waypoints);
      
      // Google Maps Routes API kullanarak rota bul
      final response = await http.post(
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': 'AIzaSyDbTv86Dw8N1GZg7zioE0XSMCdsEhgHfvE',
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
        },
        body: json.encode({
          'origin': {
            'location': {
              'latLng': {
                'latitude': _startLocation!.latitude,
                'longitude': _startLocation!.longitude,
              }
            }
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': _endLocation!.latitude,
                'longitude': _endLocation!.longitude,
              }
            }
          },
          'intermediates': optimizedWaypoints.map((waypoint) => {
            'location': {
              'latLng': {
                'latitude': waypoint.latitude,
                'longitude': waypoint.longitude,
              }
            }
          }).toList(),
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'computeAlternativeRoutes': false,
          'routeModifiers': {
            'avoidTolls': false,
            'avoidHighways': false,
            'avoidFerries': false,
          },
          'languageCode': 'tr-TR',
          'units': 'METRIC',
        }),
      );

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          if (route['polyline'] != null && route['polyline']['encodedPolyline'] != null) {
            final points = route['polyline']['encodedPolyline'];
            _routePoints = _decodePolyline(points);
            
            setState(() {
              _updateMap();
            });
          } else {
            setState(() {
              _errorMessage = 'Rota çizgisi bulunamadı';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Rota bulunamadı';
          });
        }
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = 'API hatası: ${errorData['error']?['message'] ?? 'Bilinmeyen hata'}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // En kısa yol hesaplama (Nearest Neighbor algoritması)
  Future<List<Location>> _calculateOptimalRoute(List<Location> waypoints) async {
    if (waypoints.isEmpty) return waypoints;
    
    List<Location> optimizedRoute = [];
    List<Location> unvisited = List.from(waypoints);
    
    // Başlangıç noktasından başla
    Location currentLocation = _startLocation!;
    
    while (unvisited.isNotEmpty) {
      // En yakın noktayı bul
      Location nearestLocation = unvisited[0];
      double shortestDistance = _calculateDistance(currentLocation, nearestLocation);
      
      for (Location location in unvisited) {
        double distance = _calculateDistance(currentLocation, location);
        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestLocation = location;
        }
      }
      
      // En yakın noktayı rotaya ekle
      optimizedRoute.add(nearestLocation);
      unvisited.remove(nearestLocation);
      currentLocation = nearestLocation;
    }
    
    return optimizedRoute;
  }

  // İki nokta arası mesafe hesaplama (Haversine formülü)
  double _calculateDistance(Location loc1, Location loc2) {
    const double earthRadius = 6371; // km
    
    double lat1Rad = loc1.latitude * (pi / 180);
    double lat2Rad = loc2.latitude * (pi / 180);
    double deltaLat = (loc2.latitude - loc1.latitude) * (pi / 180);
    double deltaLon = (loc2.longitude - loc1.longitude) * (pi / 180);
    
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  // Optimize edilmiş durak listesini döndür
  List<Location> _getOptimizedStops() {
    Set<Location> uniqueStops = _selectedStops.toSet();
    uniqueStops.remove(_startLocation);
    uniqueStops.remove(_endLocation);
    
    if (uniqueStops.isEmpty) return [];
    
    // En kısa yol sıralamasını hesapla
    List<Location> optimizedRoute = [];
    List<Location> unvisited = List.from(uniqueStops);
    
    // Başlangıç noktasından başla
    Location currentLocation = _startLocation!;
    
    while (unvisited.isNotEmpty) {
      // En yakın noktayı bul
      Location nearestLocation = unvisited[0];
      double shortestDistance = _calculateDistance(currentLocation, nearestLocation);
      
      for (Location location in unvisited) {
        double distance = _calculateDistance(currentLocation, location);
        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestLocation = location;
        }
      }
      
      // En yakın noktayı rotaya ekle
      optimizedRoute.add(nearestLocation);
      unvisited.remove(nearestLocation);
      currentLocation = nearestLocation;
    }
    
    return optimizedRoute;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  void _updateMap() {
    _markers.clear();
    _polylines.clear();

    // Başlangıç ve bitiş noktaları marker'ları
    if (_startLocation != null && _endLocation != null) {
      if (_startLocation == _endLocation) {
        // Başlangıç ve bitiş aynı ise tek marker
        _markers.add(Marker(
          markerId: const MarkerId('start_end'),
          position: LatLng(_startLocation!.latitude, _startLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: 'Başlangıç/Bitiş',
            snippet: _startLocation!.name,
          ),
        ));
      } else {
        // Başlangıç ve bitiş farklı ise iki ayrı marker
        _markers.add(Marker(
          markerId: const MarkerId('start'),
          position: LatLng(_startLocation!.latitude, _startLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Başlangıç',
            snippet: _startLocation!.name,
          ),
        ));
        
        _markers.add(Marker(
          markerId: const MarkerId('end'),
          position: LatLng(_endLocation!.latitude, _endLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Bitiş',
            snippet: _endLocation!.name,
          ),
        ));
      }
    }

    // Seçilen duraklar için marker'lar
    int stopIndex = 1;
    for (final stop in _selectedStops) {
      _markers.add(Marker(
        markerId: MarkerId('stop_$stopIndex'),
        position: LatLng(stop.latitude, stop.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Durak $stopIndex',
          snippet: stop.name,
        ),
      ));
      stopIndex++;
    }

    // Rota çizgisi
    if (_routePoints.isNotEmpty) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.blue,
        width: 5,
      ));
    }

    // Haritayı güncelle
    if (_mapController != null && _routePoints.isNotEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _getBounds(),
          50.0,
        ),
      );
    }
  }

  LatLngBounds _getBounds() {
    double? minLat, maxLat, minLng, maxLng;

    // Başlangıç ve bitiş noktalarını dahil et
    if (_startLocation != null) {
      if (minLat == null || _startLocation!.latitude < minLat) minLat = _startLocation!.latitude;
      if (maxLat == null || _startLocation!.latitude > maxLat) maxLat = _startLocation!.latitude;
      if (minLng == null || _startLocation!.longitude < minLng) minLng = _startLocation!.longitude;
      if (maxLng == null || _startLocation!.longitude > maxLng) maxLng = _startLocation!.longitude;
    }

    if (_endLocation != null) {
      if (minLat == null || _endLocation!.latitude < minLat) minLat = _endLocation!.latitude;
      if (maxLat == null || _endLocation!.latitude > maxLat) maxLat = _endLocation!.latitude;
      if (minLng == null || _endLocation!.longitude < minLng) minLng = _endLocation!.longitude;
      if (maxLng == null || _endLocation!.longitude > maxLng) maxLng = _endLocation!.longitude;
    }

    // Seçilen durakları dahil et
    for (final stop in _selectedStops) {
      if (minLat == null || stop.latitude < minLat) minLat = stop.latitude;
      if (maxLat == null || stop.latitude > maxLat) maxLat = stop.latitude;
      if (minLng == null || stop.longitude < minLng) minLng = stop.longitude;
      if (maxLng == null || stop.longitude > maxLng) maxLng = stop.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güzergah'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Başlangıç noktası seçimi
            Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return DropdownButtonFormField<Location>(
                  decoration: const InputDecoration(
                    labelText: 'Başlangıç Noktası',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
                  ),
                  value: _startLocation,
                  items: locationProvider.locations.map((location) {
                    return DropdownMenuItem<Location>(
                      value: location,
                      child: Text(location.name),
                    );
                  }).toList(),
                  onChanged: (Location? value) {
                    setState(() {
                      _startLocation = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Bitiş noktası seçimi
            Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return DropdownButtonFormField<Location>(
                  decoration: const InputDecoration(
                    labelText: 'Bitiş Noktası',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                  ),
                  value: _endLocation,
                  items: locationProvider.locations.map((location) {
                    return DropdownMenuItem<Location>(
                      value: location,
                      child: Text(location.name),
                    );
                  }).toList(),
                  onChanged: (Location? value) {
                    setState(() {
                      _endLocation = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Durak seçimi
            Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text(
                              'Uğranacak Duraklar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Başlangıç ve bitiş aynı ise bilgilendirme mesajı
                        if (_startLocation != null && _endLocation != null && _startLocation == _endLocation)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Başlangıç ve bitiş aynı seçildi. Bu nokta başlangıç ve bitiş olarak kullanılacak.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...locationProvider.locations.map((location) {
                          // Başlangıç ve bitiş noktalarını duraklar listesinden hariç tut
                          if (location == _startLocation || location == _endLocation) {
                            return const SizedBox.shrink();
                          }
                          
                          return CheckboxListTile(
                            title: Text(location.name),
                            subtitle: Text('${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                            value: _selectedStops.contains(location),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedStops.add(location);
                                } else {
                                  _selectedStops.remove(location);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Rota bul butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _findRoute,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.directions),
                label: Text(_isLoading ? 'Rota Bulunuyor...' : 'Rota Bul'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            // Hata mesajı
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Rota oluştuktan sonra durak listesi
            if (_routePoints.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.route, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Güzergah Durakları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Başlangıç noktası
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(_startLocation?.name ?? ''),
                        subtitle: Text('Başlangıç'),
                        tileColor: Colors.green.shade50,
                      ),
                      // Seçilen duraklar (optimize edilmiş sıralama)
                      ..._getOptimizedStops().asMap().entries.map((entry) {
                        final index = entry.key;
                        final stop = entry.value;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text('${index + 2}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(stop.name),
                          subtitle: Text('Durak ${index + 2} (Optimize edilmiş sıralama)'),
                          tileColor: Colors.orange.shade50,
                        );
                      }).toList(),
                      // Bitiş noktası
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Text('${_getOptimizedStops().length + 2}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(_endLocation?.name ?? ''),
                        subtitle: Text(_endLocation == _startLocation ? 'Bitiş (Başlangıç ile aynı)' : 'Bitiş'),
                        tileColor: Colors.red.shade50,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Harita
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(39.9334, 32.8597), // Ankara
                    zoom: 10,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 