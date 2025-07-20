import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Authentication işlemlerini yöneten servis sınıfı.
/// Bu sınıf şunları yönetir:
/// - Email/şifre ile kayıt ve giriş
/// - Google hesabı ile giriş
/// - Misafir girişi
/// - Kullanıcı oturum yönetimi
class AuthService {
  // Firebase Auth örneği
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Google Sign-In örneği
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // Firestore örneği (şu an kullanılmıyor, gelecekteki genişletmeler için)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcının oturum durumundaki değişiklikleri dinlemek için stream.
  /// Widget'lar bu stream'i dinleyerek kullanıcı giriş/çıkış durumuna tepki verebilir.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Şu an oturum açmış kullanıcıyı döndürür.
  /// Eğer kullanıcı giriş yapmamışsa null döner.
  User? get currentUser => _auth.currentUser;

  /// Email ve şifre ile yeni kullanıcı kaydı oluşturur.
  /// [email]: Kullanıcı email adresi
  /// [password]: Kullanıcı şifresi
  /// [displayName]: Kullanıcının görünen adı
  Future<void> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      print('AuthService: Firebase kayıt işlemi başlatılıyor...');
      
      // Firebase'e yeni kullanıcı kaydı oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('AuthService: Kullanıcı oluşturuldu, profil güncelleniyor...');
      
      // Kullanıcı profilini güncelle (displayName ekle)
      await result.user?.updateDisplayName(displayName);

      print('AuthService: Firestore kayıt atlanıyor (API etkinleştirilmemiş)');
      // Firestore'a ek veri kaydetme işlemi şu an devre dışı
      // İleride kullanıcıya ait ek bilgileri kaydetmek için kullanılabilir

      print('AuthService: Kayıt işlemi başarılı: $email');
      // Başarılı kayıt sonrası kullanıcı otomatik olarak giriş yapmış olur
    } catch (e) {
      print('AuthService: Kayıt hatası: $e');
      rethrow; // Hata yakalanıp uygun şekilde işlenmesi için yeniden fırlat
    }
  }

  /// Email ve şifre ile giriş yapar.
  /// Başarılı giriş durumunda UserCredential, hata durumunda exception döner.
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow; // Hata UI katmanında gösterilmek üzere iletilir
    }
  }

  /// Google hesabı ile giriş yapar.
  /// Kullanıcı Google hesabını seçmezse null döner.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google hesap seçim ekranını açar
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı iptal etti

      // Google hesap doğrulama bilgilerini al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase için kimlik bilgisi oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      UserCredential result = await _auth.signInWithCredential(credential);

      // Firestore'a kullanıcı bilgisi kaydetme işlemi şu an devre dışı
      print('AuthService: Google giriş - Firestore kayıt atlanıyor');

      return result;
    } catch (e) {
      print('Google giriş hatası: $e');
      rethrow;
    }
  }

  /// Misafir olarak giriş yapar.
  /// Kullanıcıya geçici anonim bir hesap oluşturur.
  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();

      // Firestore işlemleri şu an devre dışı
      print('AuthService: Misafir giriş - Firestore kayıt atlanıyor');
      return result;
    } catch (e) {
      print('Misafir giriş hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı oturumunu kapatır.
  /// Hem Google hem de Firebase oturumunu sonlandırır.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Google oturumunu kapat
      await _auth.signOut(); // Firebase oturumunu kapat
    } catch (e) {
      print('Çıkış hatası: $e');
      rethrow;
    }
  }

  /// Misafir kullanıcıyı kalıcı hesaba dönüştürür.
  /// [email]: Yeni email adresi
  /// [password]: Yeni şifre
  /// [displayName]: Kullanıcı görünen adı
  Future<UserCredential?> convertGuestToRegistered(
      String email, String password, String displayName) async {
    try {
      User? currentUser = _auth.currentUser;
      
      // Sadece misafir kullanıcılar için bu işlem yapılabilir
      if (currentUser == null || !currentUser.isAnonymous) {
        throw Exception('Misafir kullanıcı değil');
      }

      // Email/şifre kimlik bilgisi oluştur
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);

      // Misafir hesabını kalıcı hesaba bağla
      UserCredential result = await currentUser.linkWithCredential(credential);

      // Kullanıcı profilini güncelle
      await result.user?.updateDisplayName(displayName);

      // Firestore güncellemesi şu an devre dışı
      print('AuthService: Misafir dönüştürme - Firestore güncelleme atlanıyor');

      return result;
    } catch (e) {
      print('Misafir dönüştürme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı bilgilerini getirir (şu an devre dışı).
  /// [uid]: Kullanıcı Firebase ID'si
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      // Firestore entegrasyonu şu an aktif değil
      print('AuthService: Kullanıcı bilgisi getirme atlanıyor (API etkinleştirilmemiş)');
      return null;
    } catch (e) {
      print('Kullanıcı bilgisi getirme hatası: $e');
      return null;
    }
  }

  /// Kullanıcının misafir olup olmadığını kontrol eder.
  bool isGuest() {
    return currentUser?.isAnonymous ?? false;
  }
}