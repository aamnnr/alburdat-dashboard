import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/dosis_card_widget.dart';
import 'package:alburdat_dashboard/widgets/statistik_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class DashboardPage extends StatelessWidget {
  final String? activeDeviceId;
  final List<String> deviceIds;
  final ValueChanged<String?> onDeviceChanged;

  const DashboardPage({
    super.key,
    required this.activeDeviceId,
    required this.deviceIds,
    required this.onDeviceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);
    final activeStatus = activeDeviceId != null 
        ? mqtt.getDeviceStatus(activeDeviceId!) 
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        children: [
          // Widget Pemilih Alat (Dropdown) jika punya lebih dari 1 alat
          if (deviceIds.length > 1) 
            _buildDeviceSelector(context),
          if (deviceIds.length > 1) 
            const SizedBox(height: AppTheme.spacingMD),

          // Teruskan status alat spesifik ke Card
          DosisCardWidget(status: activeStatus),
          const SizedBox(height: AppTheme.spacingXL),
          
          StatistikCardWidget(
            status: activeStatus,
            mqtt: mqtt,
            activeDeviceId: activeDeviceId,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: activeDeviceId,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryBlue),
          onChanged: onDeviceChanged,
          items: deviceIds.map<DropdownMenuItem<String>>((String id) {
            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                'Alat: $id', 
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}