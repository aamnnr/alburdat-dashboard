import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/manual_dosis_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class ManualPage extends StatelessWidget {
  final String? activeDeviceId; // Menerima ID alat yang sedang dipilih

  const ManualPage({
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
              'Dosis Manual',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Terapkan dosis khusus sesuai kebutuhan',
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
        child: ManualDosisCardWidget(
          mqtt: mqtt,
          activeDeviceId: activeDeviceId, // Teruskan ID ke komponen pengirim perintah
        ),
      ),
      backgroundColor: AppTheme.backgroundLight,
    );
  }
}