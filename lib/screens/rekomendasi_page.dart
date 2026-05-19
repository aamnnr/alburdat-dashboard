import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/rekomendasi_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class RekomendasiPage extends StatelessWidget {
  final String? activeDeviceId; // Menerima ID alat yang sedang dipilih

  const RekomendasiPage({
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
              'Rekomendasi Dosis',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Perhitungan dosis berbasis sistem ahli',
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
        child: RekomendasiCardWidget(
          mqtt: mqtt,
          activeDeviceId: activeDeviceId, // Teruskan ID ke komponen perhitungan
        ),
      ),
      backgroundColor: AppTheme.backgroundLight,
    );
  }
}