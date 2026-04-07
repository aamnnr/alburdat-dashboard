# Alburdat Presisi - Sistem Pupuk IoT

[![Flutter](https://flutter.dev/images/flutter-logo-sharing.png)](https://flutter.dev)

**Alburdat Presisi** adalah sistem IoT lengkap untuk kontrol dan monitoring perangkat pemberi pupuk presisi berbasis ESP32. Terdiri dari firmware ESP32, aplikasi Flutter Dashboard (multi-platform), dan MQTT komunikasi real-time.

## 📚 Dokumentasi

### Untuk Pengguna Akhir

- **[USER_GUIDE.md](docs/USER_GUIDE.md)** — Panduan lengkap untuk petani/pengguna
  - Setup hardware
  - Konfigurasi WiFi
  - Menggunakan aplikasi
  - Fitur-fitur detail
  - Troubleshooting

### Untuk Developer / Engineer

- **[QUICK_START.md](docs/QUICK_START.md)** — Setup & run dalam 15 menit ⚡
- **[SETUP.md](docs/SETUP.md)** — Environment setup detail untuk semua OS
- **[DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** — Panduan development komprehensif
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** — Arsitektur sistem & design patterns
- **[API_REFERENCE.md](docs/API_REFERENCE.md)** — Complete API documentation
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** — Problem solving guide

---

## ⚡ Quick Start (Developers)

```bash
# 1. Clone repository
git clone <repository-url>
cd alburdat_dashboard

# 2. Install dependencies
flutter pub get

# 3. Run (Web/Android/iOS/Desktop)
flutter run -d chrome  # Web
flutter run             # Android/iOS

# 4. MQTT is already configured (broker.emqx.io)
# App will auto-connect and wait for device
```

Detail setup → [QUICK_START.md](docs/QUICK_START.md) | [SETUP.md](docs/SETUP.md)

---

## ✨ Fitur Utama

- **📊 Monitoring Real-time**: Pantau status device (dosis, motor, statistik) secara langsung
- **🧠 Sistem Rekomendasi**: Rekomendasi dosis otomatis berdasarkan jenis tanaman & umur tanaman (HST)
- **⚙️ Kontrol Manual**: Atur dosis pupuk secara manual via slider atau input numerik
- **📈 Statistik Terperinci**: Tracking penggunaan pupuk dengan chart & analytics
- **🌐 Manajemen WiFi**: Reset konfigurasi WiFi device via aplikasi
- **💻 Multi-platform**: Android, iOS, Web, Windows, macOS, Linux
- **🔄 Real-time Sync**: MQTT communication untuk update status instant

## 🏗️ Arsitektur Sistem

```
┌──────────────────────────────────┐
│   Flutter Dashboard (Multi-OS)   │  ← Anda sedang di sini
│  (Android, iOS, Web, Desktop)    │
└──────────────────┬───────────────┘
                   │ MQTT (Port 1883)
┌──────────────────┴───────────────┐
│       MQTT Broker/Server         │
│ (broker.emqx.io, Mosquitto, dll) │
└──────────────────┬───────────────┘
                   │ WiFi
┌──────────────────┴───────────────┐
│      ESP32 Device (Firmware)     │  ← Hardware/Firmware terpisah
│  - Motor DC controller           │
│  - OLED display                  │
│  - WiFi & MQTT client            │
└──────────────────────────────────┘
```

**Tech Stack**:

- **FrontEnd**: Flutter 3.11.1+ dengan Provider state management
- **Communication**: MQTT + JSON over TCP/WebSocket
- **Databases**: Device EEPROM (untuk statistik)
- **Backend**: Tidak ada (P2P via MQTT broker)

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── device_status.dart        # Device status model (dosis, motor, stats)
│   ├── commodity.dart             # Jenis tanaman (Padi, Jagung, etc)
│   └── rule.dart                  # Expert system rules (HST → dosis mapping)
├── data/
│   └── knowledge_base.dart        # Knowledge base für rekomendasi
├── services/
│   ├── mqtt_service.dart          # MQTT connectivity & commands
│   └── expert_system_service.dart # Dosage recommendation logic
├── screens/
│   ├── home_screen.dart           # Home/dashboard
│   ├── rekomendasi_page.dart      # Recommendation page
│   ├── manual_page.dart           # Manual control
│   ├── info_page.dart             # App info & settings
│   ├── wifi_page.dart             # WiFi configuration
│   └── ...
├── widgets/                       # Reusable UI components
├── theme/
│   └── theme.dart                 # App colors, fonts, styles
└── utils/                         # Helper functions (if any)
```

## 🔧 Dependencies

| Package          | Version  | Purpose                      |
| ---------------- | -------- | ---------------------------- |
| **mqtt_client**  | ^10.11.9 | Real-time MQTT communication |
| **provider**     | ^6.1.1   | State management             |
| **fl_chart**     | ^1.1.1   | Statistics charts            |
| **google_fonts** | ^8.0.2   | Typography                   |
| **lottie**       | ^3.0.0   | Animations                   |
| **flutter_svg**  | ^2.0.9   | SVG support                  |
| **intl**         | 0.20.2   | Localization                 |
| **video_player** | ^2.9.3   | Video playback               |

Lihat [pubspec.yaml](pubspec.yaml) untuk dependencies lengkap.

## 🤝 Kontribusi

**Ingin berkontribusi?** Ikuti workflow ini:

1. Fork repository
2. Buat feature branch:
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. Commit perubahan dengan pesan jelas:
   ```bash
   git commit -m "Add amazing feature"
   ```
4. Push ke branch:
   ```bash
   git push origin feature/AmazingFeature
   ```
5. Buat Pull Request dengan deskripsi detail

**Development Guidelines**:

- Ikuti [DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)
- Gunakan meaningful commit messages
- Test sebelum submit PR
- Update dokumentasi jika ada API changes

## 📖 Dokumentasi Lengkap

### Untuk Pengguna Akhir

- **[USER_GUIDE.md](docs/USER_GUIDE.md)** — Panduan lengkap penggunaan sistem

### Untuk Developer

- **[QUICK_START.md](docs/QUICK_START.md)** — Setup & run dalam 15 menit
- **[SETUP.md](docs/SETUP.md)** — Setup environment detail
- **[DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** — Panduan development
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** — Desain sistem & patterns
- **[API_REFERENCE.md](docs/API_REFERENCE.md)** — API documentation
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** — Problem solving

## 🆘 Getting Help

**Jika ada masalah:**

1. **Check dokumentasi** → [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. **Run flutter doctor**:
   ```bash
   flutter doctor -v
   ```
3. **Check app logs**:
   ```bash
   flutter logs
   ```
4. **Create GitHub issue** dengan:
   - Flutter version
   - Device OS
   - Error message & stacktrace
   - Steps to reproduce

## 📞 Resources

- **Flutter Docs**: https://flutter.dev
- **Dart Docs**: https://dart.dev
- **MQTT Docs**: https://mqtt.org
- **mqtt_client Package**: https://pub.dev/packages/mqtt_client
- **Provider Pattern**: https://pub.dev/packages/provider

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

---

## 🙏 Ucapan Terima Kasih

Terima kasih kepada:

- Tim pengembang **Flutter** & komunitas open source
- **MQTT** broker providers (EMQX, HiveMQ, Mosquitto)
- Semua kontributor yang telah membantu

---

## 📊 Project Status

| Component          | Status           | Version  |
| ------------------ | ---------------- | -------- |
| **Flutter App**    | ✅ Stable        | 1.0.1    |
| **Documentation**  | ✅ Complete      | 2024     |
| **ESP32 Firmware** | ⚠️ Separate repo | See docs |
| **MQTT Protocol**  | ✅ Stable        | v3.1.1   |

---

**⭐ Jika project ini bermanfaat, please star repository!**

**Last Updated**: 2024  
**Maintainer**: [Aamiin / Development Team]

---

_Untuk developer yang melanjutkan project ini setelah saya tidak disini lagi: Silahkan baca [DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) terlebih dahulu untuk memahami seluruh project structure dan development workflow. Dokumentasi sudah lengkap untuk memandu Anda. Sukses! 🚀_
