import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceOnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Alamat IP statis bawaan ESP32 saat memancarkan WiFi (Mode AP)
  final String _espIpAddress = '192.168.4.1'; 

  /// Langkah 1: Mengirim Kredensial WiFi ke ESP32 secara Lokal
  /// HP harus terhubung ke jaringan "FERTICORE_XXXX" saat fungsi ini dipanggil
  Future<void> sendCredentialsToDevice(String homeSsid, String homePassword) async {
    final url = Uri.parse('http://$_espIpAddress/setup-wifi');

    try {
      final response = await http.post(
        url,
        body: {
          'ssid': homeSsid,
          'password': homePassword,
        },
      ).timeout(const Duration(seconds: 10)); // Batas waktu 10 detik agar tidak hang

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] != 'success') {
          throw Exception('ESP32 merespons, namun terjadi kegagalan internal pada alat.');
        }
      } else {
        throw Exception('Gagal mengirim data. Alat merespons dengan kode HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
        'Tidak dapat terhubung ke alat fisik.\n\n'
        'Pastikan WiFi ponsel Anda saat ini sedang terhubung ke jaringan alat (FERTICORE_...) '
        'dan bukan terhubung ke internet rumah/data seluler.\n\nDetail: $e'
      );
    }
  }

  /// Langkah 2: Mendaftarkan Kepemilikan Alat ke Cloud Database
  /// HP harus kembali terhubung ke internet normal saat fungsi ini dipanggil
  Future<void> claimDeviceToCloud(String deviceId, String customName) async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user == null) {
        throw Exception('Sesi pengguna tidak valid. Silakan login ulang.');
      }

      // Langsung menggunakan metode Insert ke database.
      // Aturan RLS di Supabase akan memastikan data ini aman.
      await _supabase.from('devices').insert({
        'mac_address': deviceId,
        'name': customName,
        'user_id': user.id, // Kolom ini sekarang valid sesuai tabel baru kita
      });

    } on PostgrestException catch (e) {
      // Menangkap error jika alat dengan MAC Address tersebut sudah pernah didaftarkan
      if (e.code == '23505') { 
        throw Exception('Alat dengan kode MAC ini sudah didaftarkan sebelumnya.');
      }
      throw Exception('Gagal mendaftarkan alat ke database: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menghubungi server database. Pastikan koneksi internet normal Anda sudah kembali aktif. Detail: $e');
    }
  }
}