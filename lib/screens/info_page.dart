import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:alburdat_dashboard/screens/splash_screen.dart'; // Pastikan path ini sesuai
import 'package:google_fonts/google_fonts.dart';

class InfoPage extends StatelessWidget {
  final String? activeDeviceId; // Tambahan: Menerima ID alat yang sedang dipilih

  const InfoPage({
    super.key, 
    this.activeDeviceId,
  });

  // Fungsi untuk menangani proses logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // 1. Putuskan koneksi MQTT agar tidak berjalan di background
      context.read<MqttService>().disconnect();
      
      // 2. Hapus sesi token dari Supabase
      await Supabase.instance.client.auth.signOut();

      // 3. Arahkan kembali ke Splash Screen dan hapus riwayat navigasi
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar akun: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    // Cek status berdasarkan alat yang sedang aktif
    final bool isDeviceOnline = activeDeviceId != null 
        ? mqtt.isEspOnline(activeDeviceId!) 
        : false;
        
    final String deviceStatusText = activeDeviceId == null 
        ? 'Tidak ada alat' 
        : (isDeviceOnline ? 'Online' : 'Offline');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              'Tentang aplikasi dan status sistem',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: AppTheme.surfaceLight,
        foregroundColor: AppTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= APP INFO =================
            _appInfo(context),

            const SizedBox(height: AppTheme.spacingXL),

            // ================= AKUN PENGGUNA =================
            Text('Akun Pengguna', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLG),
            _buildAccountCard(context),

            const SizedBox(height: AppTheme.spacingXL),

            // ================= FEATURES =================
            Text('Fitur Utama', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLG),
            ..._buildFeatures(context),

            const SizedBox(height: AppTheme.spacingXL),

            // ================= STATUS =================
            Text('Status Sistem', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLG),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    title: 'MQTT Broker',
                    status: mqtt.isConnected ? 'Terhubung' : 'Tidak Terhubung',
                    isActive: mqtt.isConnected,
                    icon: Icons.cloud_rounded,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingLG),
                Expanded(
                  child: _buildStatusCard(
                    title: 'ESP Device',
                    status: deviceStatusText,
                    isActive: isDeviceOnline,
                    icon: Icons.router_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // ================= VERSION =================
            _versionCard(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
      backgroundColor: AppTheme.backgroundLight,
    );
  }

  Widget _appInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: const Icon(Icons.info_rounded, color: AppTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: AppTheme.spacingLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FERTICORE AI', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  'Sistem kontrol dan monitoring alat tabur pupuk berbasis IoT',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    // Mengambil data user yang sedang login dari Supabase
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Tidak diketahui';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.surfaceLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  color: AppTheme.textDark.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, color: AppTheme.textDark),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email Terdaftar', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(email, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
              label: const Text('Keluar Akun', style: TextStyle(color: AppTheme.errorColor)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorColor),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatures(BuildContext context) {
    final features = [
      ('Monitoring Dosis', 'Pantau dosis pupuk secara real-time', Icons.monitor_heart_rounded),
      ('Rekomendasi', 'Hitung dosis berbasis AI agronomi', Icons.lightbulb_rounded),
      ('Kontrol Manual', 'Atur dosis sesuai kebutuhan', Icons.touch_app_rounded),
      ('Pengaturan WiFi', 'Kelola koneksi jaringan', Icons.wifi_rounded),
      ('Statistik', 'Analisis penggunaan sistem', Icons.bar_chart_rounded),
    ];

    return features.map((feature) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingLG),
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.borderColor),
          color: AppTheme.surfaceLight,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Icon(feature.$3, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.$1, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    feature.$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatusCard({
    required String title,
    required String status,
    required bool isActive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: isActive
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? AppTheme.successColor : AppTheme.errorColor, size: 32),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: Colors.grey.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Versi Aplikasi', style: Theme.of(context).textTheme.bodySmall),
          Text('1.0.0', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}