import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alburdat_dashboard/screens/home_screen.dart';
import 'package:alburdat_dashboard/screens/login_screen.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Memberikan jeda waktu agar Splash Screen terlihat (misalnya 2 detik)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Mengecek apakah ada sesi aktif di Supabase
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Jika token aktif, arahkan langsung ke Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Jika tidak ada token (belum login), arahkan ke halaman Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue, // Menggunakan warna utama tema profesional
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bisa diganti dengan Image.asset('assets/logo.png') jika ada logo
            const Icon(
              Icons.agriculture_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'FERTICORE AI',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Sistem Pengontrol Dosis Otomatis',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}