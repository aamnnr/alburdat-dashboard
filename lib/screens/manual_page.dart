import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/manual_dosis_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class ManualPage extends StatelessWidget {
  final String? activeDeviceId;

  const ManualPage({
    super.key,
    required this.activeDeviceId,
  });

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: ManualDosisCardWidget(
        mqtt: mqtt,
        activeDeviceId: activeDeviceId,
      ),
    );
  }
}