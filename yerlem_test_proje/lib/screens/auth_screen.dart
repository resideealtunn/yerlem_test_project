import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ve başlık
                const Icon(
                  Icons.location_on,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Yerlem',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Konum Takip Uygulaması',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 64),
                
                // Giriş butonları
                _buildAuthButton(
                  context,
                  'Giriş Yap',
                  Icons.login,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildAuthButton(
                  context,
                  'Kayıt Ol',
                  Icons.person_add,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildGoogleButton(context),
                const SizedBox(height: 16),
                
                _buildAuthButton(
                  context,
                  'Misafir Olarak İlerle',
                  Icons.person_outline,
                  () => _handleGuestSignIn(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2196F3),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    // Loading göstergesi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Google ile giriş yapılıyor...'),
            ],
          ),
        );
      },
    );
    
    final success = await authProvider.signInWithGoogle();
    
    // Loading dialog'unu kapat
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google girişi başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleGuestSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInAnonymously();
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Misafir girişi başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _handleGoogleSignIn(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2196F3),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.g_mobiledata,
              size: 24,
              color: Color(0xFF2196F3),
            ),
            const SizedBox(width: 12),
            const Text(
              'Google ile Devam Et',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2196F3),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 