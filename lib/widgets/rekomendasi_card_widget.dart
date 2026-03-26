import 'package:flutter/material.dart';
import 'package:alburdat_dashboard/models/commodity.dart';
import 'package:alburdat_dashboard/services/expert_system_service.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class RekomendasiCardWidget extends StatefulWidget {
  final MqttService mqtt;

  const RekomendasiCardWidget({super.key, required this.mqtt});

  @override
  State<RekomendasiCardWidget> createState() => _RekomendasiCardWidgetState();
}

class _RekomendasiCardWidgetState extends State<RekomendasiCardWidget> {
  Commodity? _selectedCommodity;
  final TextEditingController _hstController = TextEditingController();
  double? _recommendedDosis;
  String? _recommendationError;
  bool _isCalculating = false;
  bool _isSending = false;

  @override
  void dispose() {
    _hstController.dispose();
    super.dispose();
  }

  void _hitungRekomendasi() async {
    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (_selectedCommodity == null) {
      setState(() {
        _recommendationError = 'Pilih komoditas terlebih dahulu';
        _recommendedDosis = null;
        _isCalculating = false;
      });
      return;
    }

    final hstText = _hstController.text.trim();
    if (hstText.isEmpty) {
      setState(() {
        _recommendationError = 'Masukkan umur tanaman (HST)';
        _recommendedDosis = null;
        _isCalculating = false;
      });
      return;
    }

    final hst = double.tryParse(hstText);
    if (hst == null || hst <= 0) {
      setState(() {
        _recommendationError = 'Umur tanaman harus berupa angka positif';
        _recommendedDosis = null;
        _isCalculating = false;
      });
      return;
    }

    try {
      final dosis = ExpertSystemService.getRecommendedDosis(
        _selectedCommodity!,
        hst,
      );
      setState(() {
        _recommendedDosis = dosis;
        _recommendationError = null;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _recommendationError = e.toString();
        _recommendedDosis = null;
        _isCalculating = false;
      });
    }
  }

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

  void _kirimDosis() async {
    setState(() => _isSending = true);

    if (!widget.mqtt.isEspOnline) {
      _showFeedback('ESP tidak aktif', isError: true);
      setState(() => _isSending = false);
      return;
    }

    if (_recommendedDosis != null) {
      widget.mqtt.setDosis(_recommendedDosis!);
      _showFeedback(
        'Dosis ${_recommendedDosis!.toStringAsFixed(2)} gram telah dikirim ke alat',
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final commodities = ExpertSystemService.getAllCommodities();

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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentGreen, Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rekomendasi Dosis Pupuk',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Hitung dosis berdasarkan komoditas & umur tanaman',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Commodity Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Komoditas',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              DropdownButtonFormField<Commodity>(
                initialValue: _selectedCommodity,
                hint: Text(
                  'Pilih komoditas',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
                ),
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
                    _recommendedDosis = null;
                    _recommendationError = null;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.agriculture_rounded),
                  hintText: 'Pilih komoditas',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),

          // HST Input
          TextField(
            controller: _hstController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Umur Tanaman (HST)',
              hintText: 'Contoh: 30',
              prefixIcon: const Icon(Icons.calendar_month_rounded),
              suffixText: 'hari',
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCalculating ? null : _hitungRekomendasi,
              icon: _isCalculating
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : const Icon(Icons.calculate_rounded),
              label: Text(
                _isCalculating ? 'Menghitung...' : 'Hitung Rekomendasi',
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),

          // Error Message
          if (_recommendationError != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_rounded,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Text(
                      _recommendationError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Result Card
          if (_recommendedDosis != null) ...[
            const SizedBox(height: AppTheme.spacingLG),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withValues(alpha: 0.15),
                    Color(0xFF16A34A).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: AppTheme.accentGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dosis Rekomendasi',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textGrey),
                          ),
                          const SizedBox(height: AppTheme.spacingSM),
                          Text(
                            '${_recommendedDosis!.toStringAsFixed(2)} gram',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLG),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.accentGreen,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _kirimDosis,
                      icon: _isSending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSending ? 'Mengirim...' : 'Kirim Dosis ke Alat',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
