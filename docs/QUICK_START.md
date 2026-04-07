# Quick Start Guide - Alburdat Dashboard

**Panduan cepat untuk developer baru yang ingin Setup dan Run project dalam 15 menit.**

## ⚡ Prerequisites (5 menit)

```bash
# 1. Verify Flutter installed
flutter --version
# Expected: Flutter 3.11.1+

# 2. Verify Docker/Mosquitto available (untuk test locally)
mosquitto -h
# Atau skip jika pakai cloud broker
```

Jika belum install, ikuti [SETUP.md](SETUP.md).

---

## 🚀 Setup Project (10 menit)

### 1. Clone Repository

```bash
git clone <repository-url>
cd alburdat_dashboard
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure MQTT Broker

Pilih salah satu:

**Option A: Cloud Broker (Recommended for testing)**

```
Default sudah `broker.emqx.io`
Tidak perlu konfigurasi
```

**Option B: Local Broker**

```bash
# macOS
brew install mosquitto
brew services start mosquitto

# Linux
sudo apt-get install mosquitto
sudo systemctl start mosquitto

# Windows
# Download & install dari https://mosquitto.org/download/

# Edit lib/services/mqtt_service.dart
final String broker = 'localhost';  // or 127.0.0.1
final int port = 1883;  // TCP port
```

### 4. Run App

```bash
# Default: Android/iOS emulator
flutter run

# Web (Chrome)
flutter run -d chrome

# Desktop
flutter run -d windows  # or macos, linux

# Specific device
flutter devices
flutter run -d <device-id>
```

**Expected Result**:

- App starts dengan splash screen
- MQTT connects (takes ~5-10 detik)
- Akan show "Waiting for device..." jika device belum online

---

## 🧪 Verify Setup Works

### Test 1: MQTT Connection

```bash
# Terminal 1: Monitor messages
mosquitto_sub -v -t 'alburdat/#'

# Terminal 2: Publish test status
mosquitto_pub -t alburdat/status \
  -m '{"gramasi":10,"isMotorRunning":false,"totalVolume":100,"totalSesi":10,"rataRata":10}'

# Expected: App dashboard shows status
```

### Test 2: Hot Reload

```bash
# In running app terminal:
r             # Hot reload (preserve state)
R             # Hot restart (clear state)
q             # Quit
```

### Test 3: MQTT Command

```bash
# Terminal 1: Subscribe to commands (simulate device)
mosquitto_sub -t alburdat/command

# Terminal 2: In app, set dosis via slider
# Or publish manually:
mosquitto_pub -t alburdat/command -m '{"set_dosis":20.0}'

# Expected: See command in Terminal 1
```

---

## 📁 Understanding Project Structure

```
lib/
├── main.dart                    ← Entry point (start here!)
├── models/
│   ├── device_status.dart      ← Device status model
│   ├── commodity.dart           ← Commodity/tanaman model
│   └── rule.dart                ← Expert system rule
├── data/
│   └── knowledge_base.dart     ← Dosage recommendations
├── services/
│   ├── mqtt_service.dart       ← MQTT logic (main business logic)
│   └── expert_system_service.dart ← Recommendation logic
├── screens/
│   ├── home_screen.dart        ← Home/dashboard
│   ├── rekomendasi_page.dart   ← Recommendation page
│   ├── manual_page.dart        ← Manual control
│   ├── info_page.dart          ← App info
│   └── ... (other screens)
├── widgets/                     ← Reusable UI components
├── theme/
│   └── theme.dart              ← Colors, fonts, styles
└── utils/                       ← Helper functions
```

---

## 💡 Common Tasks

### Add New Commodity (Tanaman Baru)

1. Open `lib/data/knowledge_base.dart`
2. Add to `commodities` list:
   ```dart
   Commodity(id: 3, name: 'Cabai'),
   ```
3. Add rules ke `knowledgeBase`:
   ```dart
   3: [
     Rule(hstMin: 0, hstMax: 25, dosis: 5.0),
     Rule(hstMin: 26, hstMax: 50, dosis: 12.0),
   ],
   ```
4. Hot reload (press `r`)
5. Done! New commodity available di app

### Read Device Status in Widget

```dart
// Watch status (auto rebuild on change)
Consumer<MqttService>(
  builder: (context, mqtt, _) {
    final status = mqtt.latestStatus;
    if (status == null) return Text('Offline');
    return Text('Dosis: ${status.gramasi}g');
  },
)
```

### Send Command to Device

```dart
// Set dosis
await context.read<MqttService>().setDosis(15.0);

// Reset statistics
await context.read<MqttService>().resetStats();

// Reset WiFi
await context.read<MqttService>().resetWifi();
```

### Get Dosage Recommendation

```dart
try {
  final commodity = Commodity(id: 1, name: 'Padi');
  final dosis = ExpertSystemService.getRecommendedDosis(commodity, 30);
  print('Recommended: $dosis g');
} catch (e) {
  print('Error: $e');
}
```

---

## 🛠️ Useful Commands

```bash
# Code formatting
dart format lib/

# Code analysis
dart analyze

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Build web
flutter build web --release

# Clean everything
flutter clean && flutter pub get

# Get package info
flutter pub outdated
```

---

## 📚 Documentation Reference

- **[SETUP.md](SETUP.md)** — Full environment setup guide
- **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** — Complete dev documentation
- **[USER_GUIDE.md](USER_GUIDE.md)** — End-user manual
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — System architecture & design
- **[API_REFERENCE.md](API_REFERENCE.md)** — Complete API documentation
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** — Problem solving guide
- **[README.md](../README.md)** — Project overview

---

## 🆘 If Something Goes Wrong

1. **App crashes?**

   ```bash
   flutter clean && flutter pub get && flutter run -v
   ```

2. **MQTT not connecting?**

   ```bash
   # Check device logs
   flutter logs

   # Test broker manually
   mosquitto_pub -h broker.emqx.io -t test -m hello
   ```

3. **Hot reload not working?**

   ```
   Press 'R' untuk hot restart (atau `Ctrl+Shift+R`)
   ```

4. **Still stuck?**
   - Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
   - Or create GitHub issue dengan `flutter doctor -v` output

---

## 📖 Next Steps

1. ✅ Run app successfully
2. 📖 Read [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) untuk understand architecture
3. 💻 Explore `lib/services/mqtt_service.dart` untuk understand MQTT logic
4. 🎯 Try adding new feature (e.g., new commodity)
5. 🚀 Read [SETUP.md](SETUP.md#build--deployment) untuk build & deployment

---

**Estimated time**: 15 minutes (+ debugging if needed)

Selamat! Anda sudah siap development. Happy coding! 🎉
