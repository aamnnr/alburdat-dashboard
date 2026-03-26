import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/dosis_card_widget.dart';
import 'package:alburdat_dashboard/widgets/statistik_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alburdat Presisi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Dashboard Sistem Pengontrol Dosis',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: AppTheme.surfaceLight,
        foregroundColor: AppTheme.textDark,
        actions: [_buildConnectionStatus(context, mqtt)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          children: [
            DosisCardWidget(status: mqtt.latestStatus),
            const SizedBox(height: AppTheme.spacingXL),
            StatistikCardWidget(status: mqtt.latestStatus, mqtt: mqtt),
          ],
        ),
      ),
      backgroundColor: AppTheme.backgroundLight,
    );
  }

  Widget _buildConnectionStatus(BuildContext context, MqttService mqtt) {
    String statusText;
    Color color;
    IconData icon;

    if (mqtt.isConnecting) {
      statusText = 'Menghubungkan...';
      color = AppTheme.warningColor;
      icon = Icons.sync;
    } else if (mqtt.isEspOnline) {
      statusText = 'ESP Online';
      color = AppTheme.successColor;
      icon = Icons.wifi;
    } else if (mqtt.isConnected) {
      statusText = 'Broker OK';
      color = AppTheme.warningColor;
      icon = Icons.cloud;
    } else {
      statusText = 'Offline';
      color = AppTheme.errorColor;
      icon = Icons.wifi_off;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppTheme.spacingSM),
            Text(
              statusText,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
