import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. Import Supabase
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:alburdat_dashboard/screens/home_screen.dart';
import 'package:alburdat_dashboard/screens/login_screen.dart'; // Asumsi Anda akan membuat layar ini
import 'package:alburdat_dashboard/screens/splash_screen.dart'; // Import SplashScreen

void main() async {
  // Wajib ditambahkan agar inisialisasi async berjalan sebelum UI digambar
  WidgetsFlutterBinding.ensureInitialized();

  // Ambil URL dan Anon Key Supabase secara aman dari compile-time environment variables
  const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const String supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Inisialisasi koneksi Cloud ke Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 4. HAPUS ..connect() di sini. 
        // MQTT hanya boleh connect SETELAH user login dan kita tahu MAC Address alatnya.
        ChangeNotifierProvider(create: (_) => MqttService()),
      ],
      child: MaterialApp(
        title: 'FERTICORE AI Dashboard',
        theme: AppTheme.lightTheme,
        // Tampilkan SplashScreen terlebih dahulu saat aplikasi dibuka
        home: const SplashScreen(), 
      ),
    );
  }
}

// --- GERBANG OTENTIKASI (AUTH GATE) ---
// Komponen ini memantau status login secara real-time.
// Jika sesi aktif -> masuk HomeScreen. Jika tidak -> masuk LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Tampilkan indikator loading saat aplikasi mengecek token lokal
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Cek apakah token sesi (JWT) ditemukan dan valid
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User sudah login
          return const HomeScreen();
        } else {
          // User belum login, arahkan ke layar pendaftaran/masuk
          // return const LoginScreen(); 
          
          // Placeholder sebelum LoginScreen dibuat:
          return const LoginScreen();
        }
      },
    );
  }
}