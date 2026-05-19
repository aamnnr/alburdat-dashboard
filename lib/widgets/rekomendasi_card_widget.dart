import 'package:flutter/material.dart';
import 'package:alburdat_dashboard/models/commodity.dart';
import 'package:alburdat_dashboard/models/fertilizer.dart';
import 'package:alburdat_dashboard/models/calculation_input.dart';
import 'package:alburdat_dashboard/models/calculation_result.dart';
import 'package:alburdat_dashboard/services/expert_system_service.dart';
import 'package:alburdat_dashboard/data/knowledge_base.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class RekomendasiCardWidget extends StatefulWidget {
  final MqttService mqtt;
  final String? activeDeviceId; // Menerima ID alat yang aktif

  const RekomendasiCardWidget({
    super.key, 
    required this.mqtt,
    required this.activeDeviceId, // Wajib disertakan saat memanggil widget
  });

  @override
  State<RekomendasiCardWidget> createState() =>
      _RekomendasiCardWidgetState();
}

class _RekomendasiCardWidgetState extends State<RekomendasiCardWidget> {
  Commodity? _commodity;
  Fertilizer? _fertilizer;

  final TextEditingController _hst = TextEditingController();
  final TextEditingController _luas = TextEditingController();

  int? _minTanaman;
  int? _maxTanaman;
  int? _selectedTanaman;

  bool _showSlider = false;

  CalculationResult? _result;

  // =========================
  // FEEDBACK
  // =========================
  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
    );
  }

  // =========================
  // AI EXPLANATION
  // =========================
  String _generateExplanation() {
    return "AI menganalisis komoditas ${_commodity?.name}, "
        "HST ${_hst.text}, luas lahan ${_luas.text} m² "
        "untuk menghasilkan rekomendasi dosis pupuk optimal.";
  }

  // =========================
  // RANGE TANAMAN
  // =========================
  void _generateRange() {
    if (_commodity == null) return;

    final luas = double.tryParse(_luas.text);
    if (luas == null || luas <= 0) return;

    final base =
        luas / (_commodity!.jarakTanam * _commodity!.jarakTanam);

    setState(() {
      _minTanaman = (base * 0.9).floor();
      _maxTanaman = (base * 1.1).ceil();
      _selectedTanaman = _minTanaman;
      _showSlider = true;
    });
  }

  // =========================
  // HITUNG DOSIS
  // =========================
  void _calculate() {
    final hst = double.tryParse(_hst.text);

    if (_commodity == null) {
      _showMessage("Pilih komoditas terlebih dahulu", error: true);
      return;
    }

    if (_fertilizer == null) {
      _showMessage("Pilih pupuk terlebih dahulu", error: true);
      return;
    }

    if (_selectedTanaman == null) {
      _showMessage("Jumlah tanaman belum dipilih", error: true);
      return;
    }

    if (hst == null) {
      _showMessage("HST tidak valid", error: true);
      return;
    }

    final result = ExpertSystemService.calculate(
      CalculationInput(
        commodityId: _commodity!.id,
        hst: hst,
        luasLahan: double.tryParse(_luas.text) ?? 0,
        jumlahTanaman: _selectedTanaman!,
        fertilizerId: _fertilizer!.id,
      ),
    );

    setState(() {
      _result = result;
    });

    _showMessage("Perhitungan berhasil");
  }

  // =========================
  // SEND TO ESP
  // =========================
  void _sendToEsp() {
    // 1. Validasi pemilihan alat dari Dropdown atas (activeDeviceId)
    if (widget.activeDeviceId == null) {
      _showMessage("Tidak ada alat yang dipilih.", error: true);
      return;
    }

    if (_result == null) {
      _showMessage("Belum ada hasil perhitungan", error: true);
      return;
    }

    // 2. Cek status koneksi spesifik untuk alat ini
    if (!widget.mqtt.isEspOnline(widget.activeDeviceId!)) {
      _showMessage("ESP tidak aktif / offline", error: true);
      return;
    }

    // 3. Eksekusi pengiriman dosis dengan menyertakan ID alat target
    widget.mqtt.setDosis(widget.activeDeviceId!, _result!.dosisPerTanaman);
    
    _showMessage("Dosis ${_result!.dosisPerTanaman.toStringAsFixed(1)} gram berhasil dikirim ke ESP");
  }

  @override
  void dispose() {
    _hst.dispose();
    _luas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Membungkus (wrap) seluruh komponen di dalam Container dengan style kartu
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.surfaceLight,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= AI HEADER =================
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.psychology_rounded, color: AppTheme.infoColor, size: 28),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Fertilizer Recommendation",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Sistem ini menganalisis jenis tanaman, umur (HST), luas lahan, dan pupuk untuk menghitung dosis optimal berbasis knowledge base agronomi.",
                        style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= COMMODITY =================
          DropdownButtonFormField<Commodity>(
            initialValue: _commodity,
            items: commodities
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() => _commodity = v);
              _generateRange();
            },
            decoration: const InputDecoration(
              labelText: "Pilih Komoditas",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.grass_rounded),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // ================= FERTILIZER =================
          DropdownButtonFormField<Fertilizer>(
            initialValue: _fertilizer,
            items: fertilizers
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() => _fertilizer = v);
            },
            decoration: const InputDecoration(
              labelText: "Pilih Pupuk",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.science_rounded),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // ================= LUAS =================
          TextFormField(
            controller: _luas,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Luas Lahan (m²)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.aspect_ratio_rounded),
            ),
            onChanged: (_) => _generateRange(),
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // ================= HST =================
          TextFormField(
            controller: _hst,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Umur Tanaman (HST)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_month_rounded),
              suffixText: 'hari',
            ),
          ),

          const SizedBox(height: AppTheme.spacingXL),

          // ================= SLIDER =================
          if (_showSlider && _minTanaman != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jumlah Tanaman: $_selectedTanaman batang",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: (_selectedTanaman ?? 0).toDouble(),
                  min: _minTanaman!.toDouble(),
                  max: _maxTanaman!.toDouble(),
                  divisions: 20,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (v) {
                    setState(() {
                      _selectedTanaman = v.round();
                    });
                  },
                ),
              ],
            ),

          const SizedBox(height: AppTheme.spacingXL),

          // ================= BUTTON =================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _calculate,
              child: const Text("Hitung Rekomendasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          // ================= RESULT =================
          if (_result != null) ...[
            const SizedBox(height: AppTheme.spacingXL),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  // LEFT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Kebutuhan",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_result!.totalPupukKg.toStringAsFixed(2)} kg",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  Container(width: 1, height: 50, color: Colors.grey.shade400),

                  // RIGHT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Dosis per Titik",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_result!.dosisPerTanaman.toStringAsFixed(1)} g",
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _generateExplanation(),
              style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),

            const SizedBox(height: 16),

            // ================= ESP BUTTON =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _sendToEsp,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text("Kirim Dosis ke ESP", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}