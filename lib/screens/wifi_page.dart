import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/wifi_settings_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class WifiPage extends StatelessWidget {
  final String? activeDeviceId;

  const WifiPage({
    super.key,
    required this.activeDeviceId,
  });

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: WifiSettingsCardWidget(
        mqtt: mqtt,
        activeDeviceId: activeDeviceId,
      ),
    );
  }
}