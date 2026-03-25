import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/models/device_status.dart';
import 'package:alburdat_dashboard/services/expert_system_service.dart';
import 'package:alburdat_dashboard/models/commodity.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Untuk rekomendasi
  Commodity? _selectedCommodity;
  final TextEditingController _hstController = TextEditingController();
  double? _recommendedDosis;
  String? _recommendationError;

  // Untuk dosis manual
  final TextEditingController _manualDosisController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Alburdat Presisi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [_buildConnectionStatus(mqtt)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Dosis Alat
            _buildDosisCard(mqtt.latestStatus),
            const SizedBox(height: 16),

            // Kartu Statistik
            _buildStatistikCard(mqtt.latestStatus, mqtt),
            const SizedBox(height: 16),

            // Rekomendasi Dosis Pupuk
            _buildRekomendasiCard(mqtt),
            const SizedBox(height: 16),

            // Pengatur Dosis Manual
            _buildManualDosisCard(mqtt),
            const SizedBox(height: 16),

            // Pengaturan WiFi
            _buildWifiCard(mqtt),
          ],
        ),
      ),
    );
  }

  // Indikator status koneksi
  Widget _buildConnectionStatus(MqttService mqtt) {
    String statusText;
    Color color;
    IconData icon;

    if (mqtt.isConnecting) {
      statusText = 'Menghubungkan...';
      color = Colors.orange;
      icon = Icons.sync;
    } else if (mqtt.isEspOnline) {
      statusText = 'ESP Online';
      color = Colors.green;
      icon = Icons.wifi;
    } else if (mqtt.isConnected) {
      statusText = 'Broker OK';
      color = Colors.orange;
      icon = Icons.cloud;
    } else {
      statusText = 'Offline';
      color = Colors.red;
      icon = Icons.wifi_off;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (!mqtt.isConnected && !mqtt.isConnecting) ...[
          Tooltip(
            message: 'Hubungkan ulang ke broker',
            child: IconButton(
              onPressed: () {
                mqtt.connect();
                _showFeedback('Menghubungkan kembali ke broker...');
              },
              icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Reconnect',
            ),
          ),
        ],
      ],
    );
  }

  // Kartu Dosis Alat
  Widget _buildDosisCard(DeviceStatus? status) {
    final dosis = status?.gramasi ?? 0.0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dosis Alat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${dosis.toStringAsFixed(2)} gram',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kartu Statistik dengan tombol reset
  Widget _buildStatistikCard(DeviceStatus? status, MqttService mqtt) {
    final totalVolume = status?.totalVolume ?? 0.0;
    final rataRata = status?.rataRata ?? 0.0;
    final totalSesi = status?.totalSesi ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Volume',
                  '${totalVolume.toStringAsFixed(2)} g',
                ),
                _buildStatItem('Rata-rata', '${rataRata.toStringAsFixed(2)} g'),
                _buildStatItem('Total Sesi', '$totalSesi'),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showResetStatsDialog(mqtt),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset Statistik'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Dialog konfirmasi reset statistik
  void _showResetStatsDialog(MqttService mqtt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Statistik'),
        content: const Text('Yakin ingin mereset semua statistik?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mqtt.isEspOnline) {
                _showFeedback('ESP tidak aktif', isError: true);
                return;
              }
              mqtt.resetStats();
              _showFeedback('Perintah reset statistik terkirim');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Kartu Rekomendasi Dosis
  Widget _buildRekomendasiCard(MqttService mqtt) {
    final commodities = ExpertSystemService.getAllCommodities();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rekomendasi Dosis Pupuk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Dropdown komoditas
            DropdownButtonFormField<Commodity>(
              initialValue: _selectedCommodity,
              hint: const Text('-- pilih komoditas --'),
              isExpanded: true,
              items: commodities.map((c) {
                return DropdownMenuItem<Commodity>(
                  value: c,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCommodity = val;
                  _recommendedDosis = null; // reset hasil
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Input HST
            TextField(
              controller: _hstController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Umur Tanaman (HST)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tombol Hitung
            ElevatedButton(
              onPressed: _hitungRekomendasi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Hitung Rekomendasi'),
            ),
            const SizedBox(height: 8),
            // Hasil rekomendasi (jika ada)
            if (_recommendationError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _recommendationError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_recommendedDosis != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dosis Rekomendasi:'),
                        Text(
                          '${_recommendedDosis!.toStringAsFixed(2)} gram',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (mqtt.isEspOnline) {
                          mqtt.setDosis(_recommendedDosis!);
                          _showFeedback('Dosis rekomendasi terkirim ke alat');
                        } else {
                          _showFeedback('ESP tidak aktif', isError: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Kirim'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _hitungRekomendasi() {
    setState(() {
      _recommendationError = null;
      _recommendedDosis = null;
    });

    if (_selectedCommodity == null) {
      setState(() {
        _recommendationError = 'Pilih komoditas terlebih dahulu';
      });
      return;
    }

    final hstText = _hstController.text;
    if (hstText.isEmpty) {
      setState(() {
        _recommendationError = 'Masukkan HST';
      });
      return;
    }

    final hst = int.tryParse(hstText);
    if (hst == null || hst < 0) {
      setState(() {
        _recommendationError = 'HST harus berupa angka positif';
      });
      return;
    }

    final dosis = ExpertSystemService.getDosis(
      commodityId: _selectedCommodity!.id,
      hst: hst,
    );

    if (dosis == null) {
      setState(() {
        _recommendationError = 'Tidak ada rekomendasi untuk HST tersebut';
      });
    } else {
      setState(() {
        _recommendedDosis = dosis;
      });
    }
  }

  // Kartu Pengatur Dosis Manual
  Widget _buildManualDosisCard(MqttService mqtt) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengatur Dosis Manual',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualDosisController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Masukkan Dosis Khusus (gram)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final text = _manualDosisController.text;
                final dosis = double.tryParse(text);
                if (dosis == null || dosis <= 0) {
                  _showFeedback('Masukkan dosis yang valid', isError: true);
                  return;
                }
                if (!mqtt.isEspOnline) {
                  _showFeedback('ESP tidak aktif', isError: true);
                  return;
                }
                mqtt.setDosis(dosis);
                _showFeedback('Dosis $dosis gram terkirim');
                _manualDosisController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Terapkan Dosis'),
            ),
          ],
        ),
      ),
    );
  }

  // Kartu Pengaturan WiFi
  Widget _buildWifiCard(MqttService mqtt) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan Wi-Fi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan fitur ini jika anda ingin memindahkan koneksi WiFi alat ke jaringan WiFi lain. Koneksi Alat akan terputus. Sambungkan handphone anda ke WiFi “ALBURDAT_CONFIG” dan akses browser 192.168.4.1 untuk mengatur koneksi WiFi baru.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showResetWifiDialog(mqtt),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Reset WiFi Alat'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetWifiDialog(MqttService mqtt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset WiFi'),
        content: const Text(
          'Alat akan mereset koneksi WiFi dan restart. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mqtt.isEspOnline) {
                _showFeedback('ESP tidak aktif', isError: true);
                return;
              }
              mqtt.resetWifi();
              _showFeedback('Perintah reset WiFi terkirim');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Feedback snackbar
  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
