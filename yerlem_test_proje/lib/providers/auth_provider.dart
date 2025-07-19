import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _authService.isGuest();

  AuthProvider() {
    // Kullanıcı durumu değişikliklerini dinle
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Loading durumunu ayarla
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Hata mesajını ayarla
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Email/Password ile kayıt
  Future<bool> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      print('AuthProvider: Kayıt işlemi başlatılıyor...');
      _setLoading(true);
      _setError(null);
      
      await _authService.registerWithEmailAndPassword(email, password, displayName);
      
      print('AuthProvider: Kayıt işlemi başarılı');
      // Kayıt başarılı olduğunda true döndür
      return true;
    } catch (e) {
      print('AuthProvider: Kayıt hatası: $e');
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
      print('AuthProvider: Loading durumu: $_isLoading');
    }
  }

  // Email/Password ile giriş
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _authService.signInWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Google ile giriş
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final result = await _authService.signInWithGoogle();
      return result != null;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Misafir girişi
  Future<bool> signInAnonymously() async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _authService.signInAnonymously();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Misafir kullanıcıyı kayıt et
  Future<bool> convertGuestToRegistered(
      String email, String password, String displayName) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _authService.convertGuestToRegistered(email, password, displayName);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
    } catch (e) {
      _setError(_getErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // Hata mesajlarını Türkçe'ye çevir
  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Bu email adresi zaten kullanımda.';
    } else if (error.contains('weak-password')) {
      return 'Şifre çok zayıf. En az 6 karakter kullanın.';
    } else if (error.contains('user-not-found')) {
      return 'Bu email adresi ile kayıtlı kullanıcı bulunamadı.';
    } else if (error.contains('wrong-password')) {
      return 'Hatalı şifre.';
    } else if (error.contains('invalid-email')) {
      return 'Geçersiz email adresi.';
    } else if (error.contains('too-many-requests')) {
      return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
    } else if (error.contains('network-request-failed')) {
      return 'İnternet bağlantısı hatası.';
    } else if (error.contains('sign_in_canceled') || error.contains('sign_in_cancelled')) {
      return 'Google girişi iptal edildi.';
    } else if (error.contains('sign_in_failed')) {
      return 'Google girişi başarısız. Lütfen tekrar deneyin.';
    } else if (error.contains('network_error')) {
      return 'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.';
    } else if (error.contains('invalid_account')) {
      return 'Geçersiz Google hesabı.';
    } else {
      return 'Bir hata oluştu: $error';
    }
  }

  // Hata mesajını temizle
  void clearError() {
    _setError(null);
  }
} 