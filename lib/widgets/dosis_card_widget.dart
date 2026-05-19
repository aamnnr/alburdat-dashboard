import 'package:flutter/material.dart';
import 'package:alburdat_dashboard/models/device_status.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DosisCardWidget extends StatelessWidget {
  final DeviceStatus? status;

  const DosisCardWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Ambil data dari status, gunakan default jika null (belum ada data masuk)
    final double dosis = status?.gramasi ?? 0.0;
    
    // Ganti logika pengecekan dari dosis > 0 menjadi status putaran motor
    final bool isMotorRunning = status?.isMotorRunning ?? false;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.surfaceLight,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlueLight, AppTheme.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.scale, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dosis Saat Ini',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Pengaturan Alat Presisi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Value (Nilai Dosis)
          Center(
            child: Column(
              children: [
                Text(
                  dosis.toStringAsFixed(1), // Ubah jadi 1 desimal agar sesuai OLED ESP32
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  'gram per sesi',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Status indicator (Motor Running Status)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingSM,
            ),
            decoration: BoxDecoration(
              color: (isMotorRunning ? AppTheme.successColor : AppTheme.textGrey)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  // Ubah ikon agar lebih dinamis: gear berputar vs ceklis diam
                  isMotorRunning ? Icons.settings_backup_restore : Icons.check_circle,
                  size: 14,
                  color: isMotorRunning ? AppTheme.successColor : AppTheme.textGrey,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Text(
                  // Sesuaikan teks dengan status asli dari ESP32
                  isMotorRunning ? 'Sedang Memupuk' : 'Mesin Siap',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isMotorRunning ? AppTheme.successColor : AppTheme.textGrey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}