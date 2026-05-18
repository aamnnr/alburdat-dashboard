import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

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
        padding: const EdgeInsets.all(16), // beri padding merata
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= APP INFO =================
            _appInfo(context),

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
                    status: mqtt.isEspOnline ? 'Online' : 'Offline',
                    isActive: mqtt.isEspOnline,
                    icon: Icons.router_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // ================= VERSION =================
            _versionCard(context),

            // Tidak ada Spacer atau apapun, scroll alami
            const SizedBox(height: 24), // sedikit ruang bawah opsional
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