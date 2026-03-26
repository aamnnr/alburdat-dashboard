import 'package:flutter/material.dart';
import 'package:alburdat_dashboard/models/device_status.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatistikCardWidget extends StatefulWidget {
  final DeviceStatus? status;
  final MqttService mqtt;

  const StatistikCardWidget({
    super.key,
    required this.status,
    required this.mqtt,
  });

  @override
  State<StatistikCardWidget> createState() => _StatistikCardWidgetState();
}

class _StatistikCardWidgetState extends State<StatistikCardWidget> {
  void _showResetStatsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppTheme.warningColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
              Text(
                'Reset Statistik',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                'Yakin ingin mereset semua statistik? Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingLG),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (!widget.mqtt.isEspOnline) {
                          _showFeedback('ESP tidak aktif', isError: true);
                          return;
                        }
                        widget.mqtt.resetStats();
                        _showFeedback('Perintah reset statistik terkirim');
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalVolume = widget.status?.totalVolume ?? 0.0;
    final rataRata = widget.status?.rataRata ?? 0.0;
    final totalSesi = widget.status?.totalSesi ?? 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.surfaceLight,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          // Heading
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentGreen, Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingLG),
              Text(
                'Statistik Penggunaan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Stats Grid
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  'Total Volume',
                  '${totalVolume.toStringAsFixed(2)} g',
                  Icons.balance,
                ),
                Container(width: 1, height: 60, color: AppTheme.borderColor),
                _buildStatItem(
                  context,
                  'Rata-rata',
                  '${rataRata.toStringAsFixed(2)} g',
                  Icons.trending_up,
                ),
                Container(width: 1, height: 60, color: AppTheme.borderColor),
                _buildStatItem(
                  context,
                  'Total Sesi',
                  '$totalSesi',
                  Icons.repeat,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Reset Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showResetStatsDialog,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset Statistik'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
