import 'package:flutter/material.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class WifiSettingsCardWidget extends StatefulWidget {
  final MqttService mqtt;
  final String? activeDeviceId; // Tambahan: Menerima ID alat aktif

  const WifiSettingsCardWidget({
    super.key, 
    required this.mqtt,
    required this.activeDeviceId, // Wajib diisi dari pemanggil (HomeScreen/WifiPage)
  });

  @override
  State<WifiSettingsCardWidget> createState() => _WifiSettingsCardWidgetState();
}

class _WifiSettingsCardWidgetState extends State<WifiSettingsCardWidget> {
  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
    );
  }

  void _showResetWifiDialog() {
    // Validasi awal sebelum menampilkan popup
    if (widget.activeDeviceId == null) {
      _showFeedback('Tidak ada alat yang dipilih.', isError: true);
      return;
    }

    // Mengambil 4 digit terakhir MAC Address untuk mencocokkan SSID AP
    final String deviceId = widget.activeDeviceId!;
    final String apSuffix = deviceId.length >= 4 
        ? deviceId.substring(deviceId.length - 4) 
        : deviceId;

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
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppTheme.errorColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
              Text(
                'Reset Koneksi WiFi',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                'Tindakan ini akan mereset koneksi WiFi dan alat akan restart. Anda perlu menghubungkan ke WiFi "FERTICORE_$apSuffix" dengan password "12345678" dan konfigurasi ulang melalui fitur Tambah Alat.',
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
                        
                        // Validasi status online menggunakan ID alat spesifik
                        if (!widget.mqtt.isEspOnline(widget.activeDeviceId!)) {
                          _showFeedback('Alat sedang offline', isError: true);
                          return;
                        }
                        
                        // Mengirim perintah menggunakan format Map yang diharapkan MqttService
                        widget.mqtt.publishCommand(widget.activeDeviceId!, {'reset_wifi': true});
                        
                        _showFeedback('Perintah reset WiFi telah dikirim');
                      },
                      child: const Text('Reset WiFi', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    // Mengekstrak suffix untuk ditampilkan di instruksi UI
    final String apSuffix = widget.activeDeviceId != null && widget.activeDeviceId!.length >= 4 
        ? widget.activeDeviceId!.substring(widget.activeDeviceId!.length - 4) 
        : 'XXXX';

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
                child: const Icon(
                  Icons.wifi_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengaturan Wi-Fi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Konfigurasi ulang jaringan nirkabel',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Info section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Text(
                        'Langkah-langkah reset WiFi:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildListItem('1.', 'Klik tombol "Reset WiFi Alat" di bawah'),
                const SizedBox(height: AppTheme.spacingSM),
                _buildListItem(
                  '2.',
                  'Alat akan restart dan memancarkan WiFi baru bernama "FERTICORE_$apSuffix"',
                ),
                const SizedBox(height: AppTheme.spacingSM),
                _buildListItem('3.', 'Gunakan fitur "Tambah Alat" di Dashboard utama untuk menghubungkan ulang alat ke router Anda.'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Reset button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showResetWifiDialog,
              icon: const Icon(Icons.router_rounded, color: Colors.white),
              label: const Text('Reset WiFi Alat', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMD),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
          ),
        ),
      ],
    );
  }
}