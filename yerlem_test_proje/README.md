# Yerlem - Konum Takip Uygulaması

Yerlem, kullanıcıların konumlarını takip etmelerine, rotalarını kaydetmelerine ve geçmiş verilerini görüntülemelerine olanak sağlayan kapsamlı bir Flutter mobil uygulamasıdır.

## Görev Gereksinimleri Karşılanma Durumu

Konumlar Sayfası: Tamamlandı
- Konumlar sayfası mevcut
- Konum ekleme özelliği
- Yarıçap seçimi (50m, 100m, 200m, 500m)
- SQLite veritabanında saklama

Harita Ekranı: Tamamlandı
- Konya koordinatlarına odaklanma (37.872669888420376, 32.49263157763532)
- Konumların daire ile gösterimi
- Gerçek zamanlı konum takibi
- Rota kaydetme (Başlat/Bitir)
- Konum girişinde bildirim
- Geçmişe kaydetme

Geçmiş Rotalar: Tamamlandı
- Rota geçmişi görüntüleme
- Ziyaret edilen konumlar ve bildirim zamanları
- Oynat butonu ile animasyonlu rota çizimi
- Otomatik harita takibi ve yakınlaştırma

Teknik Gereksinimler: Tamamlandı
- Flutter (en güncel sürüm)
- google_maps_flutter entegrasyonu
- geolocator ile gerçek zamanlı konum
- sqflite ile yerel veri saklama
- provider ile durum yönetimi
- flutter_local_notifications ile bildirimler
- Android ve iOS platform desteği

Özellikler
Kimlik Doğrulama
Email/Şifre ile kayıt ve giriş
Google ile giriş
Misafir modu
Misafir hesabı kalıcı hesaba dönüştürme
Konum Yönetimi
Özel konum ekleme (koordinat ve yarıçap ile)
Yarıçap seçenekleri (50m, 100m, 200m, 500m)
Haritada konum görselleştirme
Konum silme

Harita Özellikleri
Google Maps entegrasyonu
Gerçek zamanlı konum takibi
Belirlenen konumlara yaklaşınca bildirim gönderimi
Manuel harita yenileme
Mevcut konuma odaklanma

Rota Yönetimi
Rota başlatma ve bitirme ile kaydetme
Google Maps Directions API ile rota planlama
Rota üzerinde durak noktaları belirleme
Haritada rota çizgisi ile görselleştirme
Geçmiş rotaları animasyonlu izleme

Geçmiş ve Analiz
Tamamlanan rotaların listelenmesi
Başlangıç, bitiş ve süre bilgileri
Rota sırasında ziyaret edilen konumlar
Mesafe, süre ve ortalama hız istatistikleri
Tamamlanan ve devam eden rotaların durumu

Geliştirici Araçları
Kullanıcı verilerini görüntüleme
SQLite veritabanı içeriğini inceleme
Detaylı hata logları

Teknik Gereksinimler
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_maps_flutter: ^2.6.0
  geolocator: ^11.0.0
  sqflite: ^2.3.2
  path: ^1.9.0
  provider: ^6.1.2
  flutter_local_notifications: ^17.2.2
  http: ^1.2.1
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.0
  google_sign_in: ^6.2.1

Platform Desteği
Android: API 21+
iOS: 12.0+
Web: Modern tarayıcılar
Windows: Windows 10+
Linux: Ubuntu 18.04+
macOS: 10.14+

Ekranlar
Kimlik Doğrulama Ekranları
auth_screen.dart: Ana giriş ekranı
login_screen.dart: Email/şifre giriş ekranı
register_screen.dart: Hesap oluşturma ekranı
guest_register_screen.dart: Misafir hesabı dönüştürme ekranı
Ana Uygulama Ekranları
map_screen.dart: Harita ekranı
locations_screen.dart: Konum yönetimi
route_screen.dart: Rota planlama ve kayıt
history_screen.dart: Geçmiş rotalar
debug_screen.dart: Debug ekranı
Özel Ekranlar
route_playback_screen.dart: Rota oynatma
Mimari Yapı
Provider Yapısı
auth_provider.dart: Kimlik doğrulama durumu
location_provider.dart: Konum yönetimi
history_provider.dart: Geçmiş veriler
Servisler
auth_service.dart: Firebase kimlik servisi
database_service.dart: SQLite işlemleri
location_service.dart: Konum servisleri
notification_service.dart: Bildirimler
Modeller
location.dart: Konum modeli
route_record.dart: Rota kayıt modeli

## API Anahtarları

### Google Maps API
- API Key: 'AIzaSyDbTv86Dw8N1GZg7zioE0XSMCdsEhgHfvE'
- Kullanım: Harita görüntüleme ve rota hesaplama
- Konum: `lib/screens/route_screen.dart` ve `ios/Runner/Info.plist`

### Firebase (Opsiyonel)
- GoogleService-Info.plist: iOS için mevcut
- google-services.json: Android için mevcut
- Kullanım: Kimlik doğrulama ve veri senkronizasyonu

## Proje Çalıştırma Talimatları

### Gereksinimler
- Flutter SDK (3.8.0+)
- Dart SDK (3.8.0+)
- Android Studio / VS Code
- Android SDK (API 21+)
- iOS için: macOS ve Xcode (iOS geliştirme için)

### Konum İzinleri
- Android: `android/app/src/main/AndroidManifest.xml` dosyasında izinler tanımlı
- iOS: `ios/Runner/Info.plist` dosyasında izinler tanımlı

## Veritabanı Yapısı (SQLite)

### Konumlar Tablosu
```sql
CREATE TABLE locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId TEXT NOT NULL,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  radius REAL NOT NULL,
  createdAt INTEGER NOT NULL
);
```

### Rota Kayıtları Tablosu
```sql
CREATE TABLE route_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId TEXT NOT NULL,
  startTime INTEGER NOT NULL,
  endTime INTEGER
);
```

### Rota Noktaları Tablosu
```sql
CREATE TABLE route_points (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  routeId INTEGER NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  timestamp INTEGER NOT NULL,
  FOREIGN KEY (routeId) REFERENCES route_records (id)
);
```

### Konum Ziyaretleri Tablosu
```sql
CREATE TABLE location_visits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  routeId INTEGER NOT NULL,
  locationId INTEGER NOT NULL,
  visitTime INTEGER NOT NULL,
  locationName TEXT NOT NULL,
  FOREIGN KEY (routeId) REFERENCES route_records (id),
  FOREIGN KEY (locationId) REFERENCES locations (id)
);
```

## Örnek Konumlar

Uygulama ilk açıldığında varsayılan konumlar eklenmez. Kullanıcılar kendi konumlarını ekleyebilir:
Önerilen Test Konumları (Konya)
Konya Merkez: 37.872669888420376, 32.49263157763532
Selçuklu: 37.8715, 32.4846
Meram: 37.8364, 32.4643
Karatay: 37.8697, 32.4841

Ek Özellikler (Yaratıcılık)
Eklenen Özellikler
Renkli Daireler: Her konum için farklı renkli daireler
Konum Düzenleme: Mevcut konumları düzenleme özelliği
Rota Optimizasyonu: En kısa yol algoritması (Nearest Neighbor)
Hız Kontrolü: Rota oynatımında hız ayarlama
Arka Plan Takibi: Uygulama kapalıyken konum takibi
Misafir Modu: Hesap oluşturmadan kullanım
Firebase Entegrasyonu: Kimlik doğrulama ve veri senkronizasyonu
Debug Ekranı: Geliştirici araçları
Responsive Tasarım: Farklı ekran boyutlarına uyum

Kullanıcı Deneyimi İyileştirmeleri
Modern UI: Material Design 3 uyumlu arayüz
Animasyonlar: Yumuşak geçişler ve animasyonlar
Bildirimler: Konum girişi ve rota durumu bildirimleri
Offline Çalışma: İnternet bağlantısı olmadan çalışma
Çoklu Platform: Android ve iOS desteği

Ekran Görüntüleri
Harita Ekranı: Gerçek zamanlı konum takibi
Konumlar: Konum yönetimi ve düzenleme
Rota Planlama: Güzergah oluşturma
Geçmiş: Tamamlanan rotaların listesi
Oynatım: Animasyonlu rota izleme

Geliştirici Notları

Kod Kalitesi
Modüler Yapı: Provider pattern ile durum yönetimi
Temiz Kod: SOLID prensiplerine uygun yazım
Dokümantasyon: Kapsamlı kod açıklamaları
Hata Yönetimi: Try-catch blokları ve kullanıcı dostu hata mesajları

Performans Optimizasyonları
Lazy Loading: Gerektiğinde veri yükleme
Memory Management: Dispose pattern kullanımı
Database Optimization: Index'ler ve sorgu optimizasyonu
Background Processing: Arka plan işlemleri için ayrı servisler