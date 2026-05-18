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

  const RekomendasiCardWidget({super.key, required this.mqtt});

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
        // Perbaikan: gunakan 'error' bukan 'isError'
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
    if (_result == null) {
      _showMessage("Belum ada hasil perhitungan", error: true);
      return;
    }

    if (!widget.mqtt.isEspOnline) {
      _showMessage("ESP tidak aktif / offline", error: true);
      return;
    }

    widget.mqtt.setDosis(_result!.dosisPerTanaman);
    _showMessage("Dosis ${_result!.dosisPerTanaman} gram berhasil dikirim ke ESP");
  }

  @override
  void dispose() {
    _hst.dispose();
    _luas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ================= AI HEADER =================
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AI Fertilizer Recommendation System",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Sistem ini menganalisis jenis tanaman, umur tanaman (HST), luas lahan, jumlah tanaman, dan jenis pupuk untuk menghitung dosis optimal berbasis knowledge base agronomi.",
                style: TextStyle(fontSize: 12),
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
          ),
        ),

        const SizedBox(height: 10),

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
          ),
        ),

        const SizedBox(height: 10),

        // ================= LUAS =================
        TextField(
          controller: _luas,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Luas Lahan (m²)",
          ),
          onChanged: (_) => _generateRange(),
        ),

        const SizedBox(height: 10),

        // ================= HST =================
        TextField(
          controller: _hst,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "HST (hari)",
          ),
        ),

        const SizedBox(height: 20),

        // ================= SLIDER =================
        if (_showSlider && _minTanaman != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Jumlah Tanaman: $_selectedTanaman",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: (_selectedTanaman ?? 0).toDouble(),
                min: _minTanaman!.toDouble(),
                max: _maxTanaman!.toDouble(),
                divisions: 20,
                onChanged: (v) {
                  setState(() {
                    _selectedTanaman = v.round();
                  });
                },
              ),
            ],
          ),

        const SizedBox(height: 20),

        // ================= BUTTON =================
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _calculate,
            child: const Text("Hitung Rekomendasi"),
          ),
        ),

        const SizedBox(height: 20),

        // ================= RESULT =================
        if (_result != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade100),
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

                Container(width: 1, height: 50, color: Colors.grey.shade300),

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
                        "${_result!.dosisPerTanaman.toStringAsFixed(2)} g",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
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
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),

          const SizedBox(height: 12),

          // ================= ESP BUTTON =================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendToEsp,
              icon: const Icon(Icons.send),
              label: const Text("Kirim ke ESP"),
            ),
          ),
        ],
      ],
    );
  }
}