# Konum Takip Uygulaması

Bu Flutter uygulaması, kullanıcıların konumlarını takip etmelerine, rota kaydetmelerine ve geçmiş rotalarını görüntülemelerine olanak sağlayan kapsamlı bir mobil uygulamadır.

## Özellikler

### 1. Konumlar Sayfası
- Kullanıcılar yeni konumlar ekleyebilir
- Her konum için yarıçap (50m, 100m, 200m, 500m) seçilebilir
- Konumlar yerel SQLite veritabanında saklanır
- Konumları silme özelliği

### 2. Harita Ekranı
- Google Maps entegrasyonu
- Konya koordinatlarına odaklanmış başlangıç konumu
- Eklenen konumlar daire ile gösterilir
- Gerçek zamanlı konum takibi
- Rota kaydetme (Başlat/Bitir)
- Konum ziyaretlerinde bildirim gösterimi

### 3. Geçmiş Rotalar
- Tamamlanan rotaların listesi
- Rota detayları (başlangıç, bitiş, süre)
- Ziyaret edilen konumların listesi
- Rota oynatım özelliği

## Teknik Gereksinimler

### Bağımlılıklar
- Flutter (en güncel kararlı sürüm)
- google_maps_flutter: ^2.6.0
- geolocator: ^11.0.0
- sqflite: ^2.3.2
- path: ^1.9.0
- provider: ^6.1.2
- flutter_local_notifications: ^17.2.2
- http: ^1.2.1

### Platform Desteği
- Android (API 21+)
- iOS (12.0+)

## Kurulum

### 1. Projeyi Klonlayın
```bash
git clone <repository-url>
cd yerlem_test_proje
```

### 2. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 3. Google Maps API Anahtarı
Android ve iOS için Google Maps API anahtarı almanız gerekiyor:

#### Adım 1: Google Cloud Console'da Proje Oluşturma
1. [Google Cloud Console](https://console.cloud.google.com/)'a gidin
2. Google hesabınızla giriş yapın
3. Yeni proje oluşturun veya mevcut projeyi seçin

#### Adım 2: Billing (Faturalandırma) Ayarlama
1. Sol menüden "Billing" seçin
2. "Link a billing account" tıklayın
3. Kredi kartı bilgilerinizi girin (Google Maps API ücretsiz kullanım kotası var)

#### Adım 3: API'leri Etkinleştirme
1. Sol menüden "APIs & Services" > "Library" seçin
2. Aşağıdaki API'leri arayın ve "Enable" tıklayın:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**

#### Adım 4: API Key Oluşturma
1. Sol menüden "APIs & Services" > "Credentials" seçin
2. "Create Credentials" > "API Key" tıklayın
3. Oluşturulan API key'i kopyalayın

#### Adım 5: API Key'i Kısıtla (Güvenlik için)
1. Oluşturulan API key'e tıklayın
2. "Application restrictions" altında "Android apps" seçin
3. Package name: `com.example.yerlem_test_proje`
4. SHA-1 fingerprint almak için:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

#### Android için:
`android/app/src/main/AndroidManifest.xml` dosyasında:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="BURAYA_API_KEY_YAPISTIRIN" />
```

#### iOS için:
`ios/Runner/Info.plist` dosyasında:
```xml
<key>GMSApiKey</key>
<string>BURAYA_API_KEY_YAPISTIRIN</string>
```

### 4. Uygulamayı Çalıştırın
```bash
flutter run
```

## Veritabanı Yapısı

### Tablolar

#### 1. locations
- id (INTEGER PRIMARY KEY)
- name (TEXT)
- latitude (REAL)
- longitude (REAL)
- radius (REAL)
- createdAt (INTEGER)

#### 2. route_records
- id (INTEGER PRIMARY KEY)
- startTime (INTEGER)
- endTime (INTEGER)

#### 3. route_points
- id (INTEGER PRIMARY KEY)
- routeId (INTEGER FOREIGN KEY)
- latitude (REAL)
- longitude (REAL)
- timestamp (INTEGER)

#### 4. location_visits
- id (INTEGER PRIMARY KEY)
- routeId (INTEGER FOREIGN KEY)
- locationId (INTEGER FOREIGN KEY)
- visitTime (INTEGER)
- locationName (TEXT)

## Kullanım

### Konum Ekleme
1. "Konumlar" sekmesine gidin
2. Sağ alt köşedeki "+" butonuna tıklayın
3. Konum adı, enlem, boylam ve yarıçap bilgilerini girin
4. "Ekle" butonuna tıklayın

### Rota Kaydetme
1. "Harita" sekmesine gidin
2. "Başlat" butonuna tıklayın
3. Konumunuzu takip etmeye başlayın
4. "Bitir" butonuna tıklayarak kaydı durdurun

### Geçmiş Rotaları Görüntüleme
1. "Geçmiş" sekmesine gidin
2. Tamamlanan rotaları görüntüleyin
3. "Oynat" butonuna tıklayarak rotayı animasyonlu olarak izleyin

## Özellikler

### Bildirimler
- Konum ziyaretlerinde otomatik bildirim
- Rota başlatma/bitirme bildirimleri

### Harita Özellikleri
- Gerçek zamanlı konum takibi
- Konum daireleri görselleştirme
- Rota çizgisi gösterimi
- Otomatik harita odaklama

### Veri Yönetimi
- Yerel SQLite veritabanı
- Offline çalışma desteği
- Veri kalıcılığı

## Geliştirme Notları

### Mimari
- Provider pattern ile durum yönetimi
- Modüler kod yapısı
- Servis tabanlı mimari

### Güvenlik
- Konum izinleri kontrolü
- API anahtarı güvenliği
- Veri doğrulama

### Performans
- Verimli veritabanı sorguları
- Optimize edilmiş harita güncellemeleri
- Bellek yönetimi

## Sorun Giderme

### Yaygın Sorunlar

1. **Konum izinleri çalışmıyor**
   - Android: Ayarlar > Uygulamalar > İzinler
   - iOS: Ayarlar > Gizlilik > Konum

2. **Harita yüklenmiyor**
   - Google Maps API anahtarını kontrol edin
   - İnternet bağlantısını kontrol edin

3. **Bildirimler gelmiyor**
   - Bildirim izinlerini kontrol edin
   - Uygulama ayarlarından bildirimleri etkinleştirin

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## İletişim

Proje hakkında sorularınız için issue açabilirsiniz.
