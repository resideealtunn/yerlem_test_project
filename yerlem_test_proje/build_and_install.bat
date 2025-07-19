@echo off
echo Flutter APK Olusturma ve Kurma Scripti
echo ======================================

echo.
echo 1. Proje temizleniyor...
flutter clean

echo.
echo 2. Bagimliliklar yukleniyor...
flutter pub get

echo.
echo 3. APK olusturuluyor...
flutter build apk --release

echo.
echo 4. APK konumu:
echo build\app\outputs\flutter-apk\app-release.apk

echo.
echo 5. APK boyutu:
dir build\app\outputs\flutter-apk\app-release.apk

echo.
echo ======================================
echo APK hazir! Telefonunuza kurabilirsiniz.
echo ======================================

pause 