import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:alburdat_dashboard/services/device_onboarding_service.dart';

// Enum untuk melacak tahapan proses
enum OnboardingStep { scanQR, connectAP, inputWiFi, processing, success }

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  OnboardingStep _currentStep = OnboardingStep.scanQR;
  
  String _deviceId = '';
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  String _errorMessage = '';
  bool _obscureWifiPassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // --- LOGIKA EKSEKUSI ---
  Future<void> _executeProvisioning() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ssid = _ssidController.text.trim();
    final pass = _passwordController.text.trim();
    final name = _nameController.text.trim();

    setState(() {
      _currentStep = OnboardingStep.processing;
      _errorMessage = '';
    });

    try {
      final onboardingService = DeviceOnboardingService();
      
      // 1. Kirim HTTP POST ke IP ESP32 (192.168.4.1)
      await onboardingService.sendCredentialsToDevice(ssid, pass);
      
      // Beri waktu agar ESP32 sempat merespons sebelum HP terputus dari AP
      await Future.delayed(const Duration(seconds: 3));

      // 2. Daftar ke Supabase (Asumsi HP otomatis kembali ke data seluler/WiFi utama)
      await onboardingService.claimDeviceToCloud(_deviceId, name);
      
      if (mounted) {
        setState(() => _currentStep = OnboardingStep.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          // Kembali ke langkah input jika gagal
          _currentStep = OnboardingStep.inputWiFi; 
        });
      }
    }
  }

  void _copyToClipboard(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Text(
                '$label berhasil disalin!',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
    );
  }

  // --- PEMBANGUN ANTARMUKA (UI BUILDERS) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Tambah Alat Baru',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.surfaceLight,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: _buildCurrentStepWidget(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case OnboardingStep.scanQR:
        return _buildStepScanQR();
      case OnboardingStep.connectAP:
        return _buildStepConnectAP();
      case OnboardingStep.inputWiFi:
        return _buildStepInputWiFi();
      case OnboardingStep.processing:
        return _buildStepProcessing();
      case OnboardingStep.success:
        return _buildStepSuccess();
    }
  }

  // Langkah 1: Kamera Scanner QR dengan Frame Overlay
  Widget _buildStepScanQR() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pindai Kode QR',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Arahkan kamera ke stiker QR yang menempel pada badan perangkat FERTICORE Anda.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      final scannedCode = barcodes.first.rawValue!;
                      setState(() {
                        _deviceId = scannedCode;
                        _currentStep = OnboardingStep.connectAP;
                      });
                    }
                  },
                ),
              ),
              // Elegant techy overlay frame
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.15), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4), width: 1.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      ),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryBlue, width: 3),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Langkah 2: Instruksi Pindah Jaringan (AP)
  Widget _buildStepConnectAP() {
    final apSuffix = _deviceId.length >= 4 
        ? _deviceId.substring(_deviceId.length - 4) 
        : _deviceId;
    final ssid = 'FERTICORE_$apSuffix';
    const pass = '12345678';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wifi_tethering_rounded, size: 64, color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        Text(
          'Hubungkan ke Jaringan Alat',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Buka pengaturan WiFi ponsel Anda dan hubungkan ke jaringan Hotspot yang dipancarkan oleh alat Ferticore.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        
        Card(
          color: AppTheme.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            side: const BorderSide(color: AppTheme.borderColor, width: 1.2),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              boxShadow: AppTheme.shadowSM,
            ),
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              children: [
                _buildInfoRow('Nama Jaringan (SSID)', ssid),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
                  child: Divider(color: AppTheme.borderColor),
                ),
                _buildInfoRow('Kata Sandi Hotspot', pass),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXXL),
        ElevatedButton(
          onPressed: () {
            setState(() => _currentStep = OnboardingStep.inputWiFi);
          },
          child: const Text('SAYA SUDAH TERHUBUNG', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_all_rounded, color: AppTheme.primaryBlue, size: 20),
          onPressed: () => _copyToClipboard(label, value),
          tooltip: 'Salin $label',
        ),
      ],
    );
  }

  // Langkah 3: Formulir Input WiFi Router dengan Card layout
  Widget _buildStepInputWiFi() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Konfigurasi Jaringan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Masukkan kredensial WiFi Router utama Anda agar perangkat FERTICORE dapat terhubung ke internet dan tersinkronisasi dengan Cloud.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                margin: const EdgeInsets.only(bottom: AppTheme.spacingLG),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor),
                    const SizedBox(width: AppTheme.spacingSM),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Card(
              color: AppTheme.surfaceLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                side: const BorderSide(color: AppTheme.borderColor, width: 1.2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  boxShadow: AppTheme.shadowSM,
                ),
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        labelText: 'Nama Alat (Contoh: Kebun Tomat A)',
                        prefixIcon: Icon(Icons.label_outline_rounded, color: AppTheme.textGrey),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Harap tentukan nama untuk alat ini';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    
                    TextFormField(
                      controller: _ssidController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        labelText: 'Nama WiFi Router (SSID)',
                        prefixIcon: Icon(Icons.wifi_rounded, color: AppTheme.textGrey),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Harap masukkan nama WiFi Router';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureWifiPassword,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Router',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textGrey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureWifiPassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textGrey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureWifiPassword = !_obscureWifiPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap masukkan kata sandi WiFi Router';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    
                    ElevatedButton(
                      onPressed: _executeProvisioning,
                      child: const Text('SINKRONISASI ALAT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Langkah 4: Proses Loading dengan Text Deskriptif
  Widget _buildStepProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Text(
            'Mengirim Konfigurasi...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
            child: Text(
              'Harap tunggu. Ponsel Anda sedang mengirimkan data jaringan ke perangkat Ferticore. Pastikan ponsel berada dekat dengan alat.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );
  }

  // Langkah 5: Sukses dengan Visual Cohesive
  Widget _buildStepSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded, size: 80, color: AppTheme.successColor),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        Text(
          'Alat Berhasil Ditambahkan!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Perangkat Anda telah terdaftar dan berhasil terhubung ke server cloud Ferticore.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
        ),
        const SizedBox(height: AppTheme.spacingXXL),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('KEMBALI KE DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}