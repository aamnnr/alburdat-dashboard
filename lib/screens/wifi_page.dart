import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/wifi_settings_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class WifiPage extends StatelessWidget {
  final String? activeDeviceId; // Menerima ID alat yang sedang dipilih

  const WifiPage({
    super.key,
    this.activeDeviceId, // Wajib disertakan saat memanggil halaman ini
  });

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WiFi Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Konfigurasi jaringan nirkabel',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: AppTheme.surfaceLight,
        foregroundColor: AppTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: WifiSettingsCardWidget(
          mqtt: mqtt,
          activeDeviceId: activeDeviceId, // Teruskan ID ke komponen pengaturan WiFi
        ),
      ),
      backgroundColor: AppTheme.backgroundLight,
    );
  }
}