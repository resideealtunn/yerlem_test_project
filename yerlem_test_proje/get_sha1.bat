@echo off
echo Google Sign-In için SHA-1 sertifika parmak izi alınıyor...
echo.

cd android
echo Debug SHA-1:
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

echo.
echo Release SHA-1 (eğer varsa):
keytool -list -v -keystore "%USERPROFILE%\.android\release.keystore" -alias android -storepass android -keypass android

echo.
echo Bu SHA-1 değerlerini Firebase Console'da Google Sign-In ayarlarına eklemeyi unutmayın!
pause 