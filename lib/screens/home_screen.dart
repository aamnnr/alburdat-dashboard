import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/dosis_card_widget.dart';
import 'package:alburdat_dashboard/widgets/statistik_card_widget.dart';
import 'package:alburdat_dashboard/widgets/rekomendasi_card_widget.dart';
import 'package:alburdat_dashboard/widgets/manual_dosis_card_widget.dart';
import 'package:alburdat_dashboard/widgets/wifi_settings_card_widget.dart';
import 'package:alburdat_dashboard/screens/info_page.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
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
        actions: [_buildConnectionStatus(mqtt)],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Dosis Alat
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              children: [
                DosisCardWidget(status: mqtt.latestStatus),
                const SizedBox(height: AppTheme.spacingXL),
                StatistikCardWidget(status: mqtt.latestStatus, mqtt: mqtt),
              ],
            ),
          ),
          // Tab 2: Rekomendasi Dosis
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: RekomendasiCardWidget(mqtt: mqtt),
          ),
          // Tab 3: Dosis Manual
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: ManualDosisCardWidget(mqtt: mqtt),
          ),
          // Tab 4: WiFi Settings
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: WifiSettingsCardWidget(mqtt: mqtt),
          ),
          // Tab 5: Informasi
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: const InfoPage(),
          ),
        ],
      ),
      // Modern Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          boxShadow: AppTheme.shadowMD,
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textGrey,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            Tab(icon: Icon(Icons.lightbulb_rounded), text: 'Rekomendasi'),
            Tab(icon: Icon(Icons.handshake_rounded), text: 'Manual'),
            Tab(icon: Icon(Icons.wifi_rounded), text: 'WiFi'),
            Tab(icon: Icon(Icons.info_rounded), text: 'Info'),
          ],
        ),
      ),
    );
  }

  // Connection status indicator
  Widget _buildConnectionStatus(MqttService mqtt) {
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
      child: Row(
        children: [
          Container(
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
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppTheme.spacingSM),
                Text(
                  statusText,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (!mqtt.isConnected && !mqtt.isConnecting) ...[
            const SizedBox(width: AppTheme.spacingMD),
            Tooltip(
              message: 'Hubungkan ulang ke broker',
              child: IconButton(
                onPressed: () {
                  mqtt.connect();
                  _showFeedback('Menghubungkan kembali ke broker...');
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Reconnect',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Feedback snackbar
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
}
