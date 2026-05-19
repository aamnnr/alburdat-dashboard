import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/rekomendasi_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class RekomendasiPage extends StatelessWidget {
  final String? activeDeviceId;

  const RekomendasiPage({
    super.key,
    required this.activeDeviceId,
  });

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: RekomendasiCardWidget(
        mqtt: mqtt,
        activeDeviceId: activeDeviceId,
      ),
    );
  }
}