# Alburdat Dashboard - Sistem Pupuk Presisi IoT

[![Flutter](https://flutter.dev/images/flutter-logo-sharing.png)](https://flutter.dev)

**Alburdat Presisi** adalah aplikasi dashboard Flutter untuk mengontrol dan memonitor perangkat IoT pemberi pupuk presisi berbasis ESP32. Aplikasi ini terhubung via MQTT untuk kontrol real-time dosis pupuk, monitoring status alat, rekomendasi dosis berdasarkan expert system, dan manajemen statistik.

## ✨ Fitur Utama

- **📊 Monitoring Real-time**: Status perangkat (dosis saat ini, total volume, rata-rata, jumlah sesi)
- **🧠 Sistem Rekomendasi**: Hitung dosis pupuk optimal berdasarkan komoditas tanaman dan umur (HST)
- **⚙️ Kontrol Manual**: Atur dosis pupuk secara manual
- **📈 Statistik Lengkap**: Lihat dan reset statistik aplikasi pupuk
- **🌐 Manajemen WiFi**: Reset koneksi WiFi perangkat untuk konfigurasi jaringan baru
- **✅ Multi-platform**: Android, iOS, Web, Desktop (Windows, macOS, Linux)

## 🏗️ Arsitektur

```
Flutter Dashboard (MQTT Client)
         ↓ MQTT Broker
    ESP32 Device (Publisher)
```

- **Provider** untuk state management
- **MQTT Client** untuk komunikasi real-time
- **Expert System** untuk rekomendasi dosis pupuk

## 📱 Screenshot

<!-- Placeholder untuk screenshot -->
*Tambahkan screenshot aplikasi di sini*

## 🚀 Cara Menjalankan

1. Clone repository
2. Jalankan `flutter pub get`
3. Konfigurasi MQTT broker di `lib/services/mqtt_service.dart`
4. Jalankan `flutter run`

### Persyaratan
- Flutter SDK >= 3.11.1
- MQTT Broker (misal: Mosquitto, EMQX, atau cloud service)

## 📁 Struktur Proyek

```
lib/
├── main.dart              # Entry point & Provider setup
├── data/                  # Data models & knowledge base
├── models/                # DeviceStatus, Rule, Commodity
├── screens/               # UI Screens
├── services/              # MQTT & Expert System
└── theme/                 # Custom theme
```

## 🔧 Dependencies

| Package | Purpose |
|---------|---------|
| mqtt_client | Komunikasi MQTT real-time |
| provider | State management |
| fl_chart | Grafik statistik |
| google_fonts | Typography |
| lottie | Animasi |

## 🤝 Kontribusi

1. Fork repository
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

## 🙏 Terima Kasih

Terima kasih kepada tim pengembang Flutter dan komunitas open source!

---

⭐ Star repository jika bermanfaat! 🚀

