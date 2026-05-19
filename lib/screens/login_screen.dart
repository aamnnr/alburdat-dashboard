import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alburdat_dashboard/theme/theme.dart';
import 'package:alburdat_dashboard/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Khusus untuk mode daftar
  
  bool _isLoading = false;
  bool _isLoginMode = true; // Toggle antara Masuk (true) dan Daftar (false)
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      if (_isLoginMode) {
        // --- LOGIKA MASUK (SIGN IN) ---
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // --- LOGIKA DAFTAR (SIGN UP) ---
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name}, // Data ini akan ditangkap oleh Trigger SQL Supabase
        );
      }

      if (mounted) {
        _showFeedback(
          _isLoginMode ? 'Selamat datang kembali!' : 'Pendaftaran berhasil! Silakan periksa email Anda.',
          isError: false,
        );
        
        // Arahkan ke Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showFeedback(e.message, isError: true);
    } catch (e) {
      if (mounted) _showFeedback('Terjadi kesalahan koneksi atau sistem.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingLG),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXL,
              vertical: AppTheme.spacingXXL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon Ferticore AI yang cantik
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      size: 48,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  
                  // Label & Branding
                  Text(
                    'FERTICORE AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Sistem Pengontrol Dosis Presisi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Card Box untuk Form Login/Register
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
                          Text(
                            _isLoginMode ? 'Masuk ke Akun' : 'Daftar Akun Baru',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            _isLoginMode
                                ? 'Silakan masuk untuk mengelola perangkat Anda'
                                : 'Lengkapi formulir di bawah untuk bergabung',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textGrey,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingXL),

                          // Form Nama Lengkap (Mode Daftar)
                          if (!_isLoginMode) ...[
                            TextFormField(
                              controller: _nameController,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap',
                                prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textGrey),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Harap masukkan nama lengkap Anda';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                          ],

                          // Form Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textGrey),
                              hintText: 'nama@domain.com',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                  return 'Harap masukkan email Anda';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Harap masukkan format email yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMD),

                          // Form Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textGrey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textGrey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                  return 'Harap masukkan kata sandi Anda';
                              }
                              if (value.length < 6) {
                                  return 'Kata sandi minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingXL),

                          // Button Submit
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitAuth,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _isLoginMode ? 'MASUK' : 'DAFTAR',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),

                  // Button Switch Mode
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _emailController.clear();
                        _passwordController.clear();
                        _nameController.clear();
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isLoginMode
                          ? 'Belum punya akun? Daftar sekarang'
                          : 'Sudah punya akun? Masuk di sini',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}