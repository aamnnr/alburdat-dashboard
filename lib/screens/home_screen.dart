import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/widgets/dosis_card_widget.dart';
import 'package:alburdat_dashboard/widgets/statistik_card_widget.dart';
import 'package:alburdat_dashboard/widgets/rekomendasi_card_widget.dart';
import 'package:alburdat_dashboard/widgets/manual_dosis_card_widget.dart';
import 'package:alburdat_dashboard/widgets/wifi_settings_card_widget.dart';
import 'package:alburdat_dashboard/screens/info_page.dart';
import 'package:alburdat_dashboard/screens/add_device_screen.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  // Variabel State Baru
  bool _isLoadingDevices = true;
  List<String> _deviceIds = [];
  String? _selectedDeviceId; // Untuk melacak alat mana yang sedang dilihat di Dashboard

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Daftarkan observer untuk memantau siklus hidup aplikasi
    WidgetsBinding.instance.addObserver(this);

    // Panggil fungsi penarikan data setelah frame pertama selesai di-render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserDevices();
    });
  }

  @override
  void dispose() {
    // Hapus observer saat keluar dari layar
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  // Pindahkan logika deteksi ke sini
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final mqtt = context.read<MqttService>();

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed - attempting to reconnect MQTT');
        // PASTIKAN alat sudah ditarik dari database sebelum mencoba konek ulang
        if (!mqtt.isConnected && !mqtt.isConnecting && _deviceIds.isNotEmpty) {
          mqtt.updateActiveDevices(_deviceIds);
          mqtt.connect();
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused - OS might kill the connection');
        break;
      default:
        break;
    }
  }

  /// Fungsi untuk menarik MAC Address dari Supabase dan memulai MQTT
  Future<void> _fetchUserDevices() async {
    try {
      final supabase = Supabase.instance.client;

      // Karena Row Level Security (RLS) aktif, query ini HANYA akan
      // mengembalikan alat yang dimiliki oleh user yang sedang login.
      final response = await supabase
          .from('devices')
          .select('mac_address');

      // Ekstraksi data JSON ke dalam List<String>
      final List<String> ids = (response as List)
          .map((item) => item['mac_address'] as String)
          .toList();

      if (mounted) {
        setState(() {
          _deviceIds = ids;
          _isLoadingDevices = false;
          if (ids.isNotEmpty) {
            _selectedDeviceId = ids.first; // Default tampilkan alat pertama
          }
        });

        // Injeksi ke MQTT Service dan mulai koneksi
        if (ids.isNotEmpty) {
          final mqtt = context.read<MqttService>();
          mqtt.updateActiveDevices(ids);
          mqtt.connect();
        } else {
          _showFeedback('Belum ada alat yang didaftarkan.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDevices = false);
        _showFeedback('Gagal memuat data alat: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    // Dapatkan status spesifik untuk alat yang sedang dipilih
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
              'FERTICORE AI',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Dashboard Sistem Pengontrol Dosis',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: AppTheme.surfaceLight,
        foregroundColor: AppTheme.textDark,
        actions: [_buildConnectionStatus(mqtt)],
      ),

      floatingActionButton: _isLoadingDevices 
          ? null // Sembunyikan tombol saat sedang memuat data
          : FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryBlue,
              onPressed: () async {
                // Pastikan Anda sudah meng-import AddDeviceScreen di bagian atas file
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
                );
                
                // Jika kembali dari layar tambah alat dengan status sukses (true)
                // Tarik ulang data dari database
                if (result == true) {
                  setState(() {
                    _isLoadingDevices = true;
                  });
                  _fetchUserDevices();
                }
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Tambah Alat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

      // Tampilkan indikator loading jika masih menarik data dari database
      body: _isLoadingDevices
          ? const Center(child: CircularProgressIndicator())
          : _deviceIds.isEmpty
              ? const Center(child: Text('Tidak ada alat terdaftar. Silakan tambah alat.'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Dosis Alat
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: Column(
                        children: [
                          // Widget Pemilih Alat (Dropdown) jika punya lebih dari 1 alat
                          if (_deviceIds.length > 1) _buildDeviceSelector(),
                          const SizedBox(height: AppTheme.spacingMD),

                          // Teruskan status alat spesifik ke Card
                          DosisCardWidget(status: activeStatus),
                          const SizedBox(height: AppTheme.spacingXL),
                          StatistikCardWidget(
                            status: activeStatus,
                            mqtt: mqtt,
                            activeDeviceId: _selectedDeviceId,
                          ),
                        ],
                      ),
                    ),
                    // Tab 2: Rekomendasi Dosis
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: RekomendasiCardWidget(
                        mqtt: mqtt,
                        activeDeviceId: _selectedDeviceId,
                      ),
                    ),
                    // Tab 3: Dosis Manual
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: ManualDosisCardWidget(
                        mqtt: mqtt,
                        activeDeviceId: _selectedDeviceId,
                      ),
                    ),
                    // Tab 4: WiFi Settings
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: WifiSettingsCardWidget(
                        mqtt: mqtt,
                        activeDeviceId: _selectedDeviceId,
                      ),
                    ),
                    // Tab 5: Informasi
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: InfoPage(
                        activeDeviceId: _selectedDeviceId,
                      ),
                    ),
                  ],
                ),
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
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
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

  // Widget tambahan untuk memilih alat jika pengguna memiliki banyak perangkat
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

  // Connection status indicator
  Widget _buildConnectionStatus(MqttService mqtt) {
    String statusText;
    Color color;
    IconData icon;

    // Menggunakan metode isEspOnline dinamis dari pembaruan sebelumnya
    bool isCurrentDeviceOnline = _selectedDeviceId != null ? mqtt.isEspOnline(_selectedDeviceId!) : false;

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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
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