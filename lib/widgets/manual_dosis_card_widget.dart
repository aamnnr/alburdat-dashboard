import 'package:flutter/material.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class ManualDosisCardWidget extends StatefulWidget {
  final MqttService mqtt;

  const ManualDosisCardWidget({super.key, required this.mqtt});

  @override
  State<ManualDosisCardWidget> createState() => _ManualDosisCardWidgetState();
}

class _ManualDosisCardWidgetState extends State<ManualDosisCardWidget> {
  final TextEditingController _manualDosisController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _manualDosisController.dispose();
    super.dispose();
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

  void _applyDosis() async {
    setState(() => _isLoading = true);

    final text = _manualDosisController.text;
    final dosis = double.tryParse(text);

    if (dosis == null || dosis <= 0) {
      _showFeedback('Masukkan dosis yang valid (angka positif)', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    if (!widget.mqtt.isEspOnline) {
      _showFeedback('ESP tidak aktif', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    widget.mqtt.setDosis(dosis);
    _showFeedback('Dosis $dosis gram telah dikirim');
    _manualDosisController.clear();

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                    colors: [AppTheme.infoColor, Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
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
                      'Pengatur Dosis Manual',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Terapkan dosis khusus sesuai kebutuhan',
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

          // Input field
          TextField(
            controller: _manualDosisController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Masukkan Dosis (gram)',
              hintText: 'Contoh: 50.5',
              prefixIcon: const Icon(Icons.scale_rounded),
              suffixText: 'g',
              errorText:
                  _manualDosisController.text.isNotEmpty &&
                      double.tryParse(_manualDosisController.text) == null
                  ? 'Format tidak valid'
                  : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Info section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: AppTheme.infoColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: AppTheme.infoColor, size: 18),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Text(
                    'Dosis akan langsung diterapkan pada alat jika ESP aktif',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _applyDosis,
              icon: _isLoading
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
                  : const Icon(Icons.send_rounded),
              label: Text(_isLoading ? 'Mengirim...' : 'Terapkan Dosis'),
            ),
          ),
        ],
      ),
    );
  }
}
