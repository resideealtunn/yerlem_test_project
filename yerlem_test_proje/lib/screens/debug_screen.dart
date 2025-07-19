import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/history_provider.dart';
import '../services/database_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      // Debug için tüm kullanıcıların verilerini göster
      final authProvider = context.read<AuthProvider>();
      String? userId = authProvider.user?.uid;
      
      if (userId == null) {
        setState(() {
          _debugLogs = [
            '=== DEBUG BİLGİLERİ ===',
            'Kullanıcı giriş yapmamış',
            'Debug bilgileri için giriş yapın',
          ];
        });
        return;
      }
      
      final locations = await _databaseService.getLocations(userId);
      final routes = await _databaseService.getRouteRecords(userId);
      
      setState(() {
        _debugLogs = [
          '=== DEBUG BİLGİLERİ ===',
          'Kullanıcı ID: $userId',
          'Toplam Konum: ${locations.length}',
          'Toplam Rota: ${routes.length}',
          '',
          '=== KONUMLAR ===',
          ...locations.map((loc) => 
            'ID: ${loc.id}, Ad: ${loc.name}, Enlem: ${loc.latitude}, Boylam: ${loc.longitude}, Yarıçap: ${loc.radius}m'
          ),
          '',
          '=== ROTALAR ===',
          ...routes.map((route) => 
            'ID: ${route.id}, Başlangıç: ${route.startTime}, Bitiş: ${route.endTime}'
          ),
        ];
      });
    } catch (e) {
      setState(() {
        _debugLogs = ['Hata: $e'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Bilgileri'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _debugLogs.length,
        itemBuilder: (context, index) {
          final log = _debugLogs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              log,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: log.startsWith('===') ? Colors.blue : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
} 