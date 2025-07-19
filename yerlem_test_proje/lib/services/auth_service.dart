import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı durumu stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  // Email/Password ile kayıt
  Future<void> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      print('AuthService: Firebase kayıt işlemi başlatılıyor...');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('AuthService: Kullanıcı oluşturuldu, profil güncelleniyor...');
      // Kullanıcı profilini güncelle
      await result.user?.updateDisplayName(displayName);

      print('AuthService: Firestore kayıt atlanıyor (API etkinleştirilmemiş)');
      // Firestore kayıt işlemi atlanıyor çünkü API etkinleştirilmemiş
      // Sadece Firebase Authentication kullanılıyor

      print('AuthService: Kayıt işlemi başarılı: $email');
      // Kullanıcı otomatik olarak giriş yapmış durumda kalacak
    } catch (e) {
      print('AuthService: Kayıt hatası: $e');
      rethrow;
    }
  }

  // Email/Password ile giriş
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

  // Google ile giriş
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result =
          await _auth.signInWithCredential(credential);

      // Firestore kayıt işlemi atlanıyor (API etkinleştirilmemiş)
      print('AuthService: Google giriş - Firestore kayıt atlanıyor');

      return result;
    } catch (e) {
      print('Google giriş hatası: $e');
      rethrow;
    }
  }

  // Misafir girişi
  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();

      // Firestore kayıt işlemi atlanıyor (API etkinleştirilmemiş)
      print('AuthService: Misafir giriş - Firestore kayıt atlanıyor');

      return result;
    } catch (e) {
      print('Misafir giriş hatası: $e');
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Çıkış hatası: $e');
      rethrow;
    }
  }

  // Misafir kullanıcıyı kayıt et
  Future<UserCredential?> convertGuestToRegistered(
      String email, String password, String displayName) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null || !currentUser.isAnonymous) {
        throw Exception('Misafir kullanıcı değil');
      }

      // Email/Password credential oluştur
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);

      // Misafir kullanıcıyı güncelle
      UserCredential result = await currentUser.linkWithCredential(credential);

      // Kullanıcı profilini güncelle
      await result.user?.updateDisplayName(displayName);

      // Firestore güncelleme işlemi atlanıyor (API etkinleştirilmemiş)
      print('AuthService: Misafir dönüştürme - Firestore güncelleme atlanıyor');

      return result;
    } catch (e) {
      print('Misafir dönüştürme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı bilgilerini getir
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      // Firestore API etkinleştirilmemiş, null döndür
      print('AuthService: Kullanıcı bilgisi getirme atlanıyor (API etkinleştirilmemiş)');
      return null;
    } catch (e) {
      print('Kullanıcı bilgisi getirme hatası: $e');
      return null;
    }
  }

  // Kullanıcı misafir mi kontrol et
  bool isGuest() {
    return currentUser?.isAnonymous ?? false;
  }
} 