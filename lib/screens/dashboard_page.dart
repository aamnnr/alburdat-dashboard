import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/dosis_card_widget.dart';
import 'package:alburdat_dashboard/widgets/statistik_card_widget.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoadingDevices = true;
  List<String> _deviceIds = [];
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    // Memanggil fungsi fetch setelah frame pertama selesai dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserDevices();
    });
  }

  Future<void> _fetchUserDevices() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Mengambil daftar alat milik user yang sedang login
      final response = await supabase.from('devices').select('mac_address');

      final List<String> ids = (response as List)
          .map((item) => item['mac_address'] as String)
          .toList();

      if (mounted) {
        setState(() {
          _deviceIds = ids;
          _isLoadingDevices = false;
          if (ids.isNotEmpty) {
            _selectedDeviceId = ids.first; // Set default ke alat pertama
          }
        });

        if (ids.isNotEmpty) {
          final mqtt = context.read<MqttService>();
          mqtt.updateActiveDevices(ids);
          mqtt.connect();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDevices = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data alat: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    // Ambil status spesifik berdasarkan alat yang dipilih di dropdown
    final activeStatus = _selectedDeviceId != null 
        ? mqtt.getDeviceStatus(_selectedDeviceId!) 
        : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FERTICORE AI Dashboard',
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
      body: _isLoadingDevices
          ? const Center(child: CircularProgressIndicator())
          : _deviceIds.isEmpty
              ? const Center(child: Text('Belum ada alat yang didaftarkan.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  child: Column(
                    children: [
                      // Tampilkan pemilih alat jika user punya lebih dari 1 alat
                      if (_deviceIds.length > 1) _buildDeviceSelector(),
                      if (_deviceIds.length > 1) 
                        const SizedBox(height: AppTheme.spacingMD),
                      
                      // Teruskan status alat yang aktif ke widget anak
                      DosisCardWidget(status: activeStatus),
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // Pastikan StatistikCardWidget di-update untuk menerima deviceId 
                      // jika di dalamnya terdapat tombol aksi spesifik alat
                      StatistikCardWidget(
                        status: activeStatus, 
                        mqtt: mqtt,
                        activeDeviceId: _selectedDeviceId, // Buka komen ini jika widget anak sudah diupdate
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDeviceSelector() {
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
          value: _selectedDeviceId,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryBlue),
          onChanged: (String? newValue) {
            setState(() {
              _selectedDeviceId = newValue;
            });
          },
          items: _deviceIds.map<DropdownMenuItem<String>>((String id) {
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

  Widget _buildConnectionStatus(BuildContext context, MqttService mqtt) {
    String statusText;
    Color color;
    IconData icon;

    // Cek status spesifik untuk alat yang sedang tampil di layar
    bool isCurrentDeviceOnline = _selectedDeviceId != null 
        ? mqtt.isEspOnline(_selectedDeviceId!) 
        : false;

    if (mqtt.isConnecting) {
      statusText = 'Menghubungkan...';
      color = AppTheme.warningColor;
      icon = Icons.sync;
    } else if (isCurrentDeviceOnline) {
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