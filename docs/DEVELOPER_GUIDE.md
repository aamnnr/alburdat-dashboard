# Panduan Developer Alburdat Dashboard

> **Dokumentasi lengkap untuk engineer/developer yang akan melanjutkan project ini**

Dokumen ini menjelaskan arsitektur, teknologi, workflow, dan cara extend Alburdat Dashboard.

## 📋 Daftar Isi

1. [Overview](#overview)
2. [Prasyarat](#prasyarat)
3. [Setup Development](#setup-development)
4. [Struktur Project](#struktur-project)
5. [MQTT Protocol](#mqtt-protocol)
6. [Flutter Dashboard](#flutter-dashboard)
7. [ESP32 Firmware](#esp32-firmware)
8. [Development Workflow](#development-workflow)
9. [Build & Deployment](#build--deployment)
10. [Adding Features](#adding-features)
11. [Troubleshooting](#troubleshooting)
12. [Resources](#resources)

---

## Overview

**Alburdat Presisi** adalah sistem IoT untuk kontrol dan monitoring perangkat pemberi pupuk presisi. Terdiri dari:

- **Hardware**: ESP32 + Motor DC + OLED + Buttons
- **Firmware ESP32**: Komunikasi WiFi, MQTT pubsub, kontrol motor
- **Dashboard Flutter**: UI untuk monitoring, rekomendasi dosis, manual control, statistik

```
[Flutter App (Multi-platform)] ←MQTT→ [MQTT Broker] ←→ [ESP32 Device]
```

**Tech Stack**:

- **Frontend**: Flutter 3.11.1+, Dart
- **Backend**: None (device controlled via MQTT)
- **Communication**: MQTT (Message Queuing Telemetry Transport)
- **State Management**: Provider
- **Device**: ESP32, Motor DC, OLED Display
- **Firmware**: Arduino C/C++

---

## Prasyarat

Sebelum memulai, pastikan Anda sudah:

1. **Install Flutter SDK** (≥ 3.11.1)

   ```bash
   flutter --version
   ```

2. **Install platform-specific tools**:
   - Android: Android SDK + emulator/device
   - iOS: Xcode (macOS only)
   - Web: Chrome/Firefox

3. **Install MQTT Broker** (untuk development):

   ```bash
   # macOS
   brew install mosquitto
   brew services start mosquitto

   # Linux
   sudo apt-get install mosquitto mosquitto-clients
   sudo systemctl start mosquitto

   # Windows (atau gunakan cloud broker)
   # https://mosquitto.org/download/
   ```

4. **Clone repository**:
   ```bash
   git clone <repository-url>
   cd alburdat_dashboard
   ```

Untuk detail lebih lengkap, lihat [docs/SETUP.md](SETUP.md).

---

## Setup Development

### 1. Konfigurasi MQTT Broker

Edit `lib/services/mqtt_service.dart`:

```dart
class MqttService extends ChangeNotifier {
  final String broker = 'broker.emqx.io';  // Ubah ke broker Anda
  final int port = 8083;                     // WebSocket (1883 untuk TCP)
  // ...
}
```

**Opsi Broker**:

- **Local**: `localhost:1883` (Mosquitto)
- **EMQX Cloud**: https://www.emqx.com/en/cloud
- **HiveMQ Cloud**: https://www.hivemq.com/mqtt-cloud-broker/
- **AWS IoT Core**: https://aws.amazon.com/iot-core/

### 2. Install Dependencies

```bash
flutter pub get
flutter pub upgrade  # (optional) untuk update ke versi terbaru
```

### 3. Verify Setup

```bash
flutter doctor
flutter pub get
dart analyze
```

### 4. Configure Device (ESP32)

Upload firmware ESP32 sesuai README firmware.

---

## Struktur Project

```
alburdat_dashboard/
├── android/                      # Android native code
├── ios/                          # iOS native code
├── web/                          # Web version
├── windows/                      # Windows desktop
├── macos/                        # macOS desktop
├── linux/                        # Linux desktop
├── lib/
│   ├── main.dart                 # ✅ Entry point, Provider setup
│   ├── models/
│   │   ├── device_status.dart    # ✅ Status model (gramasi, motor, stats)
│   │   ├── commodity.dart        # ✅ Commodity (Padi, Jagung, etc)
│   │   └── rule.dart             # ✅ Expert system rule
│   ├── data/
│   │   └── knowledge_base.dart   # ✅ Knowledge base untuk rekomendasi
│   ├── services/
│   │   ├── mqtt_service.dart     # ✅ MQTT connectivity & state management
│   │   └── expert_system_service.dart # ✅ Dosage recommendation logic
│   ├── screens/
│   │   ├── splash_screen.dart    # ✅ Loading screen (2-3s)
│   │   ├── main_screen.dart      # ✅ Main app with navigation
│   │   ├── home_screen.dart      # ✅ Dashboard/Home
│   │   ├── dashboard_page.dart   # ✅ Display status real-time
│   │   ├── rekomendasi_page.dart # ✅ Dosage recommendation
│   │   ├── manual_page.dart      # ✅ Manual dosage control
│   │   ├── info_page.dart        # ✅ App info & MQTT status
│   │   ├── wifi_page.dart        # ✅ ESP WiFi reset
│   │   └── main_navigation_screen.dart # ✅ Navigation setup
│   ├── widgets/
│   │   ├── dosis_card_widget.dart  # ✅ Dosage card
│   │   ├── commodity_card.dart     # ✅ Commodity selection card
│   │   └── ... (reusable UI components)
│   ├── theme/
│   │   └── theme.dart              # ✅ Custom colors, fonts, styles
│   └── utils/
│       └── ... (helper functions, constants)
├── test/
│   ├── widget_test.dart            # Widget tests
│   └── ... (unit tests, integration tests)
├── pubspec.yaml                  # ✅ Dependencies & project config
├── analysis_options.yaml         # Lint rules
├── README.md                     # Project overview
└── docs/
    ├── SETUP.md                  # Setup development environment
    ├── ARCHITECTURE.md           # Detailed architecture & design
    ├── DEVELOPER_GUIDE.md        # Ini (development guide)
    └── USER_GUIDE.md             # User manual
```

---

## MQTT Protocol

### Message Format

**Topic: `alburdat/status`** (ESP → App, published every 1-2 seconds)

```json
{
  "gramasi": 15.0,
  "isMotorRunning": false,
  "totalVolume": 150.5,
  "totalSesi": 15,
  "rataRata": 10.03
}
```

| Field            | Type   | Range | Description                       |
| ---------------- | ------ | ----- | --------------------------------- |
| `gramasi`        | double | 5-50  | Current dosage setting (gram)     |
| `isMotorRunning` | bool   | -     | Motor active?                     |
| `totalVolume`    | double | 0-∞   | Total pupuk dispensed (gram)      |
| `totalSesi`      | int    | 0-∞   | Total dispense sessions           |
| `rataRata`       | double | 0-∞   | Average dosage per session (gram) |

**Topic: `alburdat/command`** (App → ESP, on-demand)

```json
{
  "set_dosis": 15.0
}
```

```json
{
  "reset_stats": true
}
```

```json
{
  "reset_wifi": true
}
```

| Command       | Payload       | Effect                                 |
| ------------- | ------------- | -------------------------------------- |
| `set_dosis`   | double (5-50) | Set desired dosage gram                |
| `reset_stats` | true          | Clear totalVolume, totalSesi, rataRata |
| `reset_wifi`  | true          | Trigger WiFiManager config             |
| `trigger`     | true          | Manual trigger dispense (if needed)    |

### Connection Details

- **Broker**: Configurable (default: `broker.emqx.io`)
- **Port**:
  - WebSocket: `8083`
  - TCP: `1883`
  - TLS/Secure: `8883, 8884`
- **QoS**: 1 (at-least-once delivery)
- **Retain**: false (messages not persisted)
- **Auth**: None (optional untuk production)

---

## Flutter Dashboard

### Architecture Overview

```
┌─────────────────────────────────────────┐
│          UI Layer (Screens)              │
│  Dashboard, Rekomendasi, Manual, etc    │
└──────────────────┬──────────────────────┘
                   │ watch<MqttService>()
┌──────────────────┴──────────────────────┐
│   Provider (State Management)            │
│  - MqttService (ChangeNotifier)         │
│  - latestStatus stream                  │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────┴──────────────────────┐
│   Services Layer                        │
│  - MQTT Client & connection logic      │
│  - Expert system (recommendations)     │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────┴──────────────────────┐
│   Data Models                           │
│  - DeviceStatus, Commodity, Rule       │
└──────────────────┬──────────────────────┘
                   │
                MQTT Protocol
                   │
        ┌──────────┴───────────┐
        ↓                      ↓
   MQTT Broker          ESP32 Device
```

### Quick Start

1. **Install dependencies**:

   ```bash
   cd alburdat_dashboard
   flutter pub get
   ```

2. **Run on device/emulator**:

   ```bash
   # Android/iOS
   flutter run

   # Web (Chrome)
   flutter run -d chrome

   # Desktop
   flutter run -d windows  # atau macos, linux
   ```

3. **Hot reload** (saat developing):
   Press `r` di terminal untuk reload kode (state preserved)
   Press `R` untuk hot restart (state cleared)

### Key Services

#### MqttService (`lib/services/mqtt_service.dart`)

Manage MQTT connection dan device state.

**Public Methods**:

```dart
// Connection management
Future<void> connect()
void disconnect()

// Device control
Future<void> setDosis(double gramasi)
Future<void> resetStats()
Future<void> resetWifi()

// State access
bool get isConnected
bool get isEspOnline  // true jika status received <30s ago
DeviceStatus? get latestStatus
Stream<DeviceStatus> get statusStream
```

**Usage**:

```dart
// Watch status changes
Consumer<MqttService>(
  builder: (context, mqtt, child) {
    if (mqtt.latestStatus == null) {
      return Text('Waiting for device...');
    }
    return Text('Dosis: ${mqtt.latestStatus!.gramasi}g');
  },
)

// Perform action
context.read<MqttService>().setDosis(20.0);
```

#### ExpertSystemService (`lib/services/expert_system_service.dart`)

Provide dosage recommendations based on commodity & HST.

**Public Methods**:

```dart
// Get dosage for specific commodity & HST
static double? getDosis({required int commodityId, required int hst})

// Get all commodities
static List<Commodity> getAllCommodities()

// Get commodity name by ID
static String? getCommodityName(int id)
```

**Usage**:

```dart
// Get recommendation
final commodity = Commodity(id: 1, name: 'Padi');
final hst = 30;  // Hari Setelah Tanam
try {
  final dosis = ExpertSystemService.getRecommendedDosis(commodity, hst);
  print('Recommended: $dosis gram');
} catch (e) {
  print('No recommendation: $e');
}
```

### Data Models

```dart
// DeviceStatus - status dari ESP32
class DeviceStatus {
  final double gramasi;
  final bool isMotorRunning;
  final double totalVolume;
  final int totalSesi;
  final double rataRata;

  factory DeviceStatus.fromJson(Map<String, dynamic> json) { ... }
}

// Commodity - jenis tanaman
class Commodity {
  final int id;
  final String name;
  final String? imageUrl;
}

// Rule - aturan expert system
class Rule {
  final int hstMin;
  final int hstMax;
  final double dosis;

  bool matches(int hst) => hst >= hstMin && hst <= hstMax;
}
```

---

## ESP32 Firmware

Firmware ini tidak termasuk dalam repo Flutter. Untuk upload firmware:

1. **Install Arduino IDE** dengan ESP32 board
2. **Libraries yang diperlukan**:
   - WiFiManager
   - PubSubClient (MQTT)
   - ArduinoJson
   - Adafruit_SSD1306
   - Adafruit_GFX

3. **Key Configuration** (di firmware):

   ```cpp
   // MQTT
   const char* mqtt_server = "broker.emqx.io";
   int mqtt_port = 1883;

   // Hardware calibration (adjust sesuai device)
   int waktuPer5Gram = 3000;  // millisecond untuk dispense 5 gram
   float maxGramasi = 50.0;    // max dosage

   // Pins
   #define MOTOR_PIN 26
   #define BTN_GRAMASI 32
   #define BTN_TRIGGER 33
   ```

4. **MQTT Callback** (handle commands):
   ```cpp
   void mqttCallback(char* topic, byte* payload, unsigned int length) {
     // Parse JSON command
     // if set_dosis: set motor speed
     // if reset_stats: clear EEPROM
     // if reset_wifi: trigger WiFiManager
   }
   ```

Untuk detail firmware, lihat dokumentasi ESP32 terpisah (jika ada).

---

## Development Workflow

### Daily Development

1. **Start broker** (jika local):

   ```bash
   brew services start mosquitto  # macOS
   # atau systemctl start mosquitto (Linux)
   ```

2. **Edit code**:

   ```bash
   flutter run -d <device>
   ```

3. **Hot reload kode** (saat developing):

   ```
   Press 'r' untuk reload & preserv state
   Press 'R' untuk restart & clear state
   Press 'q' untuk quit
   ```

4. **Test MQTT** (dari terminal terpisah):

   ```bash
   # Monitor status
   mosquitto_sub -v -t 'alburdat/#'

   # Inject test message
   mosquitto_pub -t alburdat/status -m '{"gramasi":10.0,...}'
   ```

### Feature Development Checklist

- [ ] Create feature branch: `git checkout -b feature/feature-name`
- [ ] Write unit tests di `test/`
- [ ] Test on multiple devices/platforms
- [ ] Update documentation jika ada perubahan API
- [ ] Code review sebelum merge
- [ ] Delete branch setelah merge

### Git Workflow

```bash
# Update main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes
git add .
git commit -m "Add amazing feature"

# Push & create PR
git push origin feature/amazing-feature

# Pull request review → Merge → Delete branch
```

---

## Build & Deployment

### Debug Build (for testing)

```bash
# Android
flutter build apk --debug

# iOS (macOS only)
flutter build ios

# Web
flutter build web --debug

# Desktop
flutter build windows  # atau macos, linux
```

### Release Build

```bash
# Android APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle (untuk Google Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab

# iOS (macOS only)
flutter build ios --release
# Upload via Xcode/TestFlight/App Store Connect

# Web
flutter build web --release
# Output: build/web/
# Deploy ke Firebase Hosting, Vercel, etc

# Windows
flutter build windows --release
# Output: build/windows/runner/Release/

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

### Platform-Specific Setup

**Android**:

- Siapkan signing key: `keytool -genkey -v -keystore ~/.android/release-key.jks ...`
- Update `android/app/build.gradle` dengan key info
- Upload ke Google Play Store

**iOS**:

- Siapkan Apple Developer account
- Create App ID & Provisioning Profile
- Upload via Xcode atau Transporter

**Web**:

- Deploy hasil `build/web/` ke hosting (Firebase, GitHub Pages, Vercel, etc)
- Konfigurasi custom domain

---

## Adding Features

### Add New Commodity

1. Edit `lib/data/knowledge_base.dart`:

```dart
// Tambah ke commodities list
final List<Commodity> commodities = [
  Commodity(id: 1, name: 'Padi'),
  Commodity(id: 2, name: 'Jagung'),
  Commodity(id: 3, name: 'Cabai'),  // ← NEW
];

// Tambah rules di knowledgeBase
final Map<int, List<Rule>> knowledgeBase = {
  3: [  // Cabai (ID 3)
    Rule(hstMin: 0, hstMax: 25, dosis: 5.0),
    Rule(hstMin: 26, hstMax: 50, dosis: 12.0),
    Rule(hstMin: 51, hstMax: 80, dosis: 15.0),
  ],
};
```

2. Data akan otomatis tersedia di `ExpertSystemService`.

### Add New MQTT Command

1. Edit `lib/services/mqtt_service.dart`:

```dart
Future<void> customAction(String value) async {
  final payload = jsonEncode({'custom_action': value});
  final msg = MqttPublishMessage()
    ..payload = MqttPublishPayload.bytesPayload(utf8.encode(payload))
    ..qos = MqttQos.atLeastOnce;

  client.publishMessage(topicCommand, msg);
}
```

2. Update ESP32 firmware `mqttCallback()` untuk handle command baru

3. Gunakan di widget:

```dart
ElevatedButton(
  onPressed: () => context.read<MqttService>().customAction('value'),
  child: Text('Custom Action'),
)
```

### Add New Screen

1. Create `lib/screens/new_feature_page.dart`:

```dart
class NewFeaturePage extends StatefulWidget {
  @override
  State<NewFeaturePage> createState() => _NewFeaturePageState();
}

class _NewFeaturePageState extends State<NewFeaturePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Feature')),
      body: Consumer<MqttService>(
        builder: (context, mqtt, _) {
          return Center(
            child: Text('Status: ${mqtt.latestStatus}'),
          );
        },
      ),
    );
  }
}
```

2. Add ke navigation di `lib/screens/main_navigation_screen.dart`:

```dart
// Di BottomNavigationBar items
BottomNavigationBarItem(
  icon: Icon(Icons.star),
  label: 'New Feature',
)

// Di page selector
case 5:
  return NewFeaturePage();
```

### Add New Widget

1. Create `lib/widgets/my_widget.dart`
2. Import & use di screens

---

## Troubleshooting

### MQTT Connection Issues

**Gejala**: "MQTT OFF" di app

**Solution**:

```bash
# 1. Check broker availability
ping broker.emqx.io

# 2. Verify broker adalah running
mosquitto -v

# 3. Check firewall
sudo ufw allow 1883/tcp  # Linux

# 4. Verify broker address di mqtt_service.dart
final String broker = 'broker.emqx.io';

# 5. Check internet connection
flutter logs  # untuk lihat error details
```

### ESP32 Offline

**Gejala**: "ESP Offline" status di app

**Solution**:

1. Check WiFi connection ESP32 (lihat OLED display)
2. Verify MQTT broker setting di firmware sama dengan app
3. Upload firmware ulang
4. Reset WiFi via app → WiFi page

### Hot Reload Tidak Bekerja

**Solution**:

```bash
# Use hot restart
flutter run -v  # untuk lihat detail
# Press R untuk hot restart

# atau rebuild
flutter clean
flutter pub get
flutter run
```

### Build Fails

```bash
# Android
cd android && ./gradlew clean && cd ..
flutter pub get
flutter build apk

# iOS (macOS)
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter clean
flutter pub get
flutter build ios

# Web
flutter clean
flutter build web --release

# Desktop
flutter clean
flutter pub get
flutter build windows  # atau macos/linux
```

---

## Resources

- **Flutter**: https://flutter.dev/docs
- **Dart**: https://dart.dev/guides
- **MQTT Protocol**: https://mqtt.org/
- **mqtt_client package**: https://pub.dev/packages/mqtt_client
- **Provider state management**: https://pub.dev/packages/provider
- **Chat/Issues**: GitHub Discussions atau Issues

---

**Last Updated**: 2024
**Version**: 1.0.0
**Maintainer**: [Your Name/Team]

Untuk pertanyaan atau issues, buat issue di GitHub repository atau hubungi maintainer.
