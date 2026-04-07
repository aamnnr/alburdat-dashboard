# Troubleshooting Guide - Alburdat Dashboard

Panduan lengkap untuk mengatasi masalah yang mungkin terjadi selama pengembangan dan operasional Alburdat Dashboard.

## Daftar Isi

1. [Setup & Installation Issues](#setup--installation-issues)
2. [MQTT Connection Problems](#mqtt-connection-problems)
3. [Aplikasi/UI Issues](#aplikasiui-issues)
4. [Hardware/Device Issues](#hardwaredevice-issues)
5. [Build & Deployment Issues](#build--deployment-issues)
6. [Performance Issues](#performance-issues)
7. [Data & Synchronization Issues](#data--synchronization-issues)
8. [Getting Help](#getting-help)

---

## Setup & Installation Issues

### Flutter Not Found / Command Not Found

**Problem**:

```
flutter: command not found
Command 'flutter' not found
```

**Root Cause**: Flutter SDK tidak di PATH atau belum diinstall.

**Diagnosis**:

```bash
# Check if Flutter installed
which flutter  # macOS/Linux
where flutter  # Windows

# Check PATH
echo $PATH  # macOS/Linux
echo %PATH%  # Windows

# Check Flutter version
flutter --version
```

**Solutions**:

1. **Install Flutter SDK**:
   - [Download](https://flutter.dev/docs/get-started/install) sesuai OS
   - Extract ke folder tertentu
   - Add to PATH:

     ```bash
     # macOS/Linux: Add to ~/.bashrc or ~/.zshrc
     export PATH="$PATH:/path/to/flutter/bin"

     # Windows: System Environmental Variables
     # Add: C:\path\to\flutter\bin
     ```

   - Restart terminal
   - Verify: `flutter --version`

2. **Verify installation**:

   ```bash
   flutter doctor
   flutter doctor -v  # untuk detail
   ```

3. **If using multiple Flutter versions**:
   - Use Flutter Version Manager (FVM)
   ```bash
   brew install fvm
   fvm install 3.11.1
   fvm use 3.11.1
   ```

---

### Flutter Doctor Shows ✗ Problems

**Diagnosis**:

```bash
flutter doctor -v
```

**Contoh output dengan issues**:

```
✓ Flutter (version 3.11.1)
✗ Android toolchain - develop for Android devices
  ✗ Google Play services not installed
✗ iOS toolchain
✗ Xcode
```

**Solutions untuk umum issues**:

#### Missing Android SDK

```bash
# Accept Android licenses
flutter doctor --android-licenses

# Set ANDROID_SDK_ROOT
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk  # macOS
export ANDROID_SDK_ROOT=$HOME/Android/Sdk           # Linux
# Windows: Set via Environment Variables

# Download SDK
# Open Android Studio > Tools > SDK Manager > Install Android 13+
```

#### Missing iOS/Xcode (macOS only)

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Or full Xcode
# Download dari App Store

# Verify
xcode-select -p
```

#### Missing IDE plugins

```bash
# Android Studio: Plugins > Marketplace > Search Flutter & Dart > Install
# VS Code: Extensions > Search Flutter & Dart > Install
# IntelliJ IDEA: Plugins > Marketplace > Flutter & Dart > Install
```

---

### pub get Fails with Network Error

**Problem**:

```
Failed to connect to pub.dev
Connection timeout
```

**Root Cause**: Network issue atau package server down.

**Solutions**:

1. **Check internet connection**:

   ```bash
   ping pub.dev
   ping google.com
   ```

2. **Try pub get dengan verbose**:

   ```bash
   flutter pub get -v
   ```

3. **Clear pub cache**:

   ```bash
   flutter pub cache clean
   flutter pub get
   ```

4. **Use alternate pub mirror (China)**:

   ```bash
   export PUB_HOSTED_URL=https://pub.flutter-io.cn
   export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
   flutter pub get
   ```

5. **Wait and retry**:
   - pub.dev might be temporarily down
   - Wait 5-10 minutes, try again

---

## MQTT Connection Problems

### MQTT Offline - App Shows "Connecting..."

**Problem**:

- Status: "Connecting..." (forever)
- MQTT indicator: Red/Offline
- No device status updates

**Diagnosis**:

```bash
# 1. Check broker is running
mosquitto -v  # if local Mosquitto

# 2. Test broker connectivity
mosquitto_pub -h broker.emqx.io -p 1883 -t test/ping -m "hello"
mosquitto_sub -h broker.emqx.io -p 1883 -t test/ping

# 3. Check MQTT logs in app
flutter logs  # lihat error output
```

**Solutions**:

1. **Verify broker address**:
   - Edit `lib/services/mqtt_service.dart`

   ```dart
   final String broker = 'broker.emqx.io';  // Verify correct address
   final int port = 8083;  // Correct port
   ```

   - Common brokers:
     - `broker.emqx.io:1883` (TCP)
     - `broker.emqx.io:8083` (WebSocket)
     - `broker.hivemq.com:1883`
     - `localhost:1883` (local Mosquitto)

2. **Check internet connection**:

   ```bash
   ping broker.emqx.io
   # If fails: Check WiFi, mobile data
   ```

3. **Firewall blocking**:

   ```bash
   # macOS
   sudo pfctl -f /etc/pf.conf

   # Linux
   sudo ufw allow 1883/tcp
   sudo ufw allow 8083/tcp

   # Windows
   # Windows Defender Firewall > Allow app through
   ```

4. **Try different broker**:
   - Test dengan public broker EMQX (sudah default)
   - Atau setup local Mosquitto untuk testing:

   ```bash
   # macOS
   brew install mosquitto
   brew services start mosquitto
   mosquitto_sub -t alburdat/#  # Monitor di terminal lain

   # Edit mqtt_service.dart
   final String broker = 'localhost';  # or '127.0.0.1'
   ```

5. **Check app logs**:

   ```bash
   flutter logs
   # Look untuk "MQTT" error messages
   ```

6. **Reduce connection timeout** untuk faster feedback:
   ```dart
   // Di MqttService
   client.connectTimeoutPeriod = Duration(seconds: 5);
   ```

---

### Device Shows "MQTT: OFF" di OLED, Tapi App Connected

**Problem**:

- App: "MQTT: ✓"
- Device OLED: "MQTT: ✗"
- App tidak bisa control device

**Root Cause**: Device dan app terhubung ke broker berbeda atau device belum subscribe.

**Solutions**:

1. **Verify both use same broker**:
   - App: Check `mqtt_service.dart`
   - Device firmware: Check `const char* mqtt_server`
   - Match broker address & port

2. **Device WiFi tidak connect**:
   - Check device OLED: "WiFi: ?" atau "WiFi: ✗"
   - Fix WiFi:
     - App WiFi tab > "Reset WiFi"
     - Atau tekan Btn +5g + Btn Trigger 5 detik
     - Reconfigure ke WiFi yang sama dengan app

3. **Device firmware issue**:
   - Device mungkin perlu upload firmware baru
   - Test manual trigger (buttons on device work?)
   - If buttons work tapi MQTT tidak, firmware bug
   - Contact maintainer atau upload latest firmware

4. **MQTT message not reaching device**:

   ```bash
   # Monitor command topic
   mosquitto_sub -h broker.emqx.io -t alburdat/command -v

   # Publish test command
   mosquitto_pub -h broker.emqx.io -t alburdat/command -m '{"set_dosis":15.0}'

   # Device should receive & respond
   ```

---

### Status Updates Very Slow (Delay 10+ detik)

**Problem**:

- MQTT connected tapi status updates lambat
- Dosis slider digeser tapi update dengan delay

**Root Cause**: Network latency, message queue backlog, atau broker performance.

**Diagnosis**:

```bash
# Check MQTT message flow
mosquitto_sub -v -t 'alburdat/#'
# Measure time antara publish dan receive

# Check WiFi signal strength
# Lihat signal strength di device OLED atau app
```

**Solutions**:

1. **Improve WiFi signal**:
   - Move device closer to router (< 5 meter)
   - Remove obstacles (walls, metal)
   - Switch to 5GHz WiFi band (if router support)

2. **Reduce message frequency**:
   - Device publishes status every 1-2 detik
   - If broker overloaded, increase interval
   - Edit firmware: `publishInterval`

3. **Clear message queue**:

   ```bash
   # Clear local MQTT queue
   flutter clean
   flutter pub get
   # Restart app
   ```

4. **Switch broker** (if using cloud):
   - broker.emqx.io might be overloaded
   - Try `broker.hivemq.com` atau local broker

5. **Optimize network**:
   - Reduce WiFi interference
   - Check device CPU/RAM (reboot if needed)
   - Reduce other network activity

---

## Aplikasi/UI Issues

### App Crashes on Startup

**Problem**:

```
[FATAL:flutter/runtime/dart_vm_isolate.cc(###)] Exiting due to an exception.
Unhandled Exception: ...
```

**Root Cause**: Dependency conflict, missing permission, atau state management issue.

**Diagnosis**:

```bash
# Run dengan verbose untuk error details
flutter run -v

# Atau check logs
flutter logs

# Check pubspec.yaml untuk dependency conflicts
flutter pub get --verbose
```

**Solutions**:

1. **Clean & rebuild**:

   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Update dependencies**:

   ```bash
   flutter pub upgrade
   # atau untuk specific package
   flutter pub upgrade mqtt_client
   ```

3. **Check for permission issues**:
   - Android: Check `AndroidManifest.xml` untuk permissions
   - iOS: Check `Info.plist` untuk NSLocalNetworkUsageDescription
   - Web: Check browser console

4. **Check for MqttService initialization**:
   ```dart
   // Verify di main.dart
   MultiProvider(
     providers: [
       ChangeNotifierProvider(
         create: (_) => MqttService()..connect(),  // ← Ensure connect() called
       ),
     ],
     child: MaterialApp(...),
   )
   ```

---

### Widgets Rebuild Terlalu Sering / Performance Lag

**Problem**:

- UI feels slow/laggy
- Smooth scroll jadi janky
- Battery drain cepat

**Root Cause**: Excessive rebuilds atau expensive computation.

**Diagnosis**:

```bash
# Enable performance overlay
# Di Flutter DevTools: Performance > Show Performance Overlay

# Check widget rebuild stats
# Flutter DevTools: Inspector > Timeline > Record
```

**Solutions**:

1. **Optimize Consumer widget**:

   ```dart
   // ❌ Bad - rebuilds whole tree
   Consumer<MqttService>(
     builder: (context, mqtt, _) {
       return Column(
         children: [
           ExpensiveWidget(),        // rebuilds unnecessarily
           Text(mqtt.latestStatus?.gramasi.toString() ?? 'N/A'),
         ],
       );
     },
   )

   // ✅ Good - selective rebuild
   Column(
     children: [
       ExpensiveWidget(),  // outside Consumer
       Consumer<MqttService>(
         builder: (context, mqtt, _) {
           return Text(mqtt.latestStatus?.gramasi.toString() ?? 'N/A');
         },
       ),
     ],
   )
   ```

2. **Reduce rebuild frequency**:

   ```dart
   // Use StreamBuilder dengan filtering
   StreamBuilder<DeviceStatus>(
     stream: mqttService.statusStream
       .distinct()  // Only emit if value changed
       .throttleTime(Duration(seconds: 1)),  // Reduce frequency
     builder: (context, snapshot) { ... }
   )
   ```

3. **Use const constructors**:

   ```dart
   // ✅ Good
   const SizedBox(height: 16);

   // ❌ Bad
   SizedBox(height: 16);
   ```

4. **Profile dengan DevTools**:

   ```bash
   # Open DevTools
   flutter pub global activate devtools
   devtools

   # Or dalam app
   flutter run
   # Press 'w' untuk DevTools (if available)
   ```

---

### Hot Reload Tidak Bekerja

**Problem**:

```
lib/main.dart: error: ... cannot be used with hot reload
Hot reload not possible... Performing full restart instead
```

**Root Cause**: Code change tidak compatible dengan hot reload (misal: global variable, class definition).

**Solutions**:

1. **Use hot restart**:

   ```
   Press 'R' untuk full restart (menghapus state)
   ```

2. **For const changes**:
   - Const values require full restart
   - Use hot reload untuk UI/logic changes aja

3. **Know limitations**:
   - Hot reload tidak bisa update:
     - `main()` function
     - Global/static variables
     - Class definitions (struktural changes)
   - Bisa update:
     - Widget UI code
     - Method logic
     - Local variables

---

### App Shows "Waiting for Device..." Forever

**Problem**:

- App starts, shows "Connecting..."
- Tidak pernah connect ke device
- MQTT header terus loading

**Root Cause**: Device offline, MQTT broker unreachable, atau MQTT service tidak initialize properly.

**Solutions**:

1. **Check device status**:
   - Device powered on?
   - LEDs blinking? (check device documentation)
   - OLED showing something?

2. **Check MQTT connection**:
   - `app Info tab > Status MQTT`
   - Should show "Connected: ✓"

3. **Verify app initialization**:

   ```dart
   // In main.dart
   ChangeNotifierProvider(
     create: (_) => MqttService()..connect(),  // ← Must have ..connect()
   )
   ```

4. **Check logs**:

   ```bash
   flutter logs
   # Look untuk "MqttService" atau "MQTT" messages
   ```

5. **Try manual MQTT test**:

   ```bash
   # Publish test message
   mosquitto_pub -h broker.emqx.io -t alburdat/status \
     -m '{"gramasi":10,"isMotorRunning":false,"totalVolume":100,"totalSesi":10,"rataRata":10}'

   # Check if app receives it
   ```

---

## Hardware/Device Issues

### Motor Doesn't Spin / No Output

**Problem**:

- Tap "Trigger" atau trigger di app
- Motor tidak berputar
- Tidak ada pupuk keluar

**Root Cause**: Motor error, hopper macet, firmware issue, atau power problem.

**Diagnosis**:

```
1. Check power: LED menyala?
2. Check OLED display: Show normal status?
3. Check hopper: Pupuk ada?
4. Test manual button: Motor respond?
```

**Solutions**:

1. **Power issue**:

   ```
   - Check power adapter connected
   - Check micro USB port tidak loose
   - Try different USB cable
   - Try different power source
   ```

2. **Hopper macet**:

   ```
   1. Lepas hopper dari device
   2. Bersihkan sisa pupuk (bisa sudah hardened)
   3. Cek kaliper lubang dispense tidak tersumbat
   4. Gunakan pupuk yang lebih halus
   5. Pasang kembali
   6. Test lagi
   ```

3. **Motor issue**:

   ```
   1. Test motor direct: jumper motor pin ke power
   2. Should spin if motor OK
   3. If no spin: motor rusak, perlu replace
   ```

4. **Firmware issue**:
   - Device sudah lama, mungkin ada bug
   - Upload latest firmware
   - Contact maintainer

---

### OLED Display Not Showing / Blank

**Problem**:

- Device power on (LED menyala)
- OLED blank/tidak tampil apa-apa
- Atau show garbage characters

**Root Cause**: I2C connection issue, OLED address wrong, atau OLED rusak.

**Solutions**:

1. **Check I2C connections**:
   - Pin 21 (SDA) ↔ OLED SDA
   - Pin 22 (SCL) ↔ OLED SCL
   - Verify tidak loose

2. **Check OLED address**:
   - Most OLED: 0x3C
   - Some: 0x3D
   - Edit firmware: `#define OLED_ADDRESS 0x3C`

3. **OLED initialization**:
   - Check Arduino sketch mengcall `display.begin()` dan `display.display()`

4. **Reset OLED**:
   - Power off device 10 detik
   - Power on

5. **OLED replace**:
   - If still blank: OLED might be dead
   - Try different SSD1306 OLED module

---

### Buttons Don't Respond / Sticky

**Problem**:

- Press Btn +5g atau Btn Trigger
- No response, atau delayed response
- Atau stuck (seemingly pressed)

**Root Cause**: Pin connection loose, button debounce issue, atau button failure.

**Solutions**:

1. **Check physical connection**:
   - Pin 32 (Btn +5g) → Button → GND
   - Pin 33 (Btn Trigger) → Button → GND
   - Verify tidak loose

2. **Clean button**:
   - Dust/debris menyebabkan poor contact
   - Blow out dengan compressed air
   - Atau lightly clean dengan tissue

3. **Debounce**:
   - Edit firmware: `#define DEBOUNCE_DELAY 20  // millis`
   - Increase nilai jika still janky

4. **Button replacement**:
   - If still tidak respond: button might be broken
   - Replace dengan identic push button

---

## Build & Deployment Issues

### Build APK Fails

**Problem**:

```
FAILURE: Build failed with an exception.
Could not find ... dependency
```

**Root Cause**: Dependency conflict, Gradle cache issue, atau SDK version mismatch.

**Solutions**:

1. **Clean Gradle cache**:

   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. **Update build.gradle**:

   ```
   android/app/build.gradle
   - compileSdkVersion: 34
   - minSdkVersion: 21
   - targetSdkVersion: 34
   ```

3. **Resolve dependency conflict**:

   ```bash
   flutter pub get -v
   # Check output untuk "conflict" messages
   ```

4. **Try different approach**:
   ```bash
   flutter build apk --debug  # Try debug build first
   flutter build apk --release
   flutter build appbundle --release  # For Google Play
   ```

---

### Build Web Fails

**Problem**:

```
Error: Server error (404)
No such file or directory: 'web/index.html'
```

**Root Cause**: Web folder structure rusak atau missing files.

**Solutions**:

1. **Regenerate web folder**:

   ```bash
   flutter create . --platforms web
   flutter pub get
   flutter build web
   ```

2. **Check web/index.html**:
   - Must exist
   - Check tidak corrupted

3. **Clear web build**:
   ```bash
   rm -rf build/web
   flutter clean
   flutter build web --release
   ```

---

### iOS Build Issue (macOS only)

**Problem**:

```
Error: Xcode project already exists
Error: Pod install failed
```

**Solutions**:

1. **Clean pods**:

   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter clean
   ```

2. **Update Xcode**:
   - Xcode > Settings > Updates
   - Or update via command line:

   ```bash
   sudo xcode-select --reset
   ```

3. **Delete build artifacts**:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock xcworkspace
   pod install
   cd ..
   ```

---

## Performance Issues

### App Uses Too Much Memory / Crashes on Older Devices

**Problem**:

- App runs slow pada device dengan RAM rendah
- Crash dengan "Out of Memory"

**Solutions**:

1. **Reduce image memory usage**:

   ```dart
   // Resize images
   Image.asset(
     'assets/logo.png',
     width: 100,
     height: 100,
   )
   ```

2. **Use image caching**:

   ```dart
   imageCache.maximumSize = 100;  // Reduce cache size
   ```

3. **Lazy load data**:

   ```dart
   // Don't load all statistics at once
   // Load paginated atau on-demand
   ```

4. **Target minimum Android version**:
   - Set minSdkVersion higher (21+)
   - Allows use of modern APIs

---

### Bluetooth / WiFi Scanning Too Slow

**Problem**: If app implements WiFi scanning untuk config.

**Solutions**:

1. **Implement timeout**:

   ```dart
   final Future timeout = Future.delayed(Duration(seconds: 15));
   final result = await Future.any([
     scanWiFi(),
     timeout,
   ]);
   ```

2. **Scan in background**:
   - Use Isolate jika heavy computation
   - Don't block UI thread

---

## Data & Synchronization Issues

### Statistics Don't Update / Show Stale Data

**Problem**:

- Trigger dispense, tapi statistik tidak berubah
- Atau statistik update lambat

**Solutions**:

1. **Force refresh**:
   - Pull-to-refresh (swipe down) di Statistics tab
   - Atau switch tab, kembali ke Statistics

2. **Restart app**:

   ```bash
   flutter run --full-restart
   ```

3. **Check device save data**:
   - Device mungkin tidak menyimpan stats to EEPROM
   - Setiap device restart → stats reset to 0
   - Need firmware update untuk add EEPROM persistence

4. **Verify MQTT message received**:

   ```bash
   # Monitor status updates
   mosquitto_sub -v -t alburdat/status

   # Check if totalVolume/totalSesi incrementing
   ```

---

### Data Lost After App Restart

**Problem**:

- Statistics cleared atau reset after app close & reopen

**Root Cause**: Data hanya stored di device (EEPROM), bukan di app local storage.

**Solutions**:

1. **Implement local storage** (if want persist app-side):

   ```dart
   // Add package: shared_preferences
   // Save recommendation history, etc
   final prefs = await SharedPreferences.getInstance();
   await prefs.setInt('last_dosis', 15);
   ```

2. **Backup statistics**:
   - Export CSV dari Statistics tab
   - Simpan ke cloud atau local drive

3. **Sync dengan device**:
   - Always trust device EEPROM sebagai source of truth
   - App adalah UI untuk device

---

## Getting Help

### Where to Report Issues

1. **GitHub Issues**:
   - Go to repository > Issues > New Issue
   - Include:
     - Device OS (Android/iOS/Web/Desktop)
     - Flutter version: `flutter --version`
     - Error message & stack trace
     - Steps to reproduce
     - Logs: `flutter logs`

2. **Email Support**:
   - support@alburdat.io

3. **Community Discussion**:
   - GitHub Discussions (jika tersedia)
   - Stack Overflow (tag: flutter, mqtt_client, alburdat)

### Useful Debugging Commands

```bash
# Get Flutter info
flutter doctor -v

# Get device logs
flutter logs -f

# Run dengan verbose output
flutter run -v

# Profile app
flutter pub global activate devtools
devtools

# Clean everything
flutter clean
flutter pub get

# Check package versions
flutter pub outdated

# Get pub dependencies tree
flutter pub deps

# Format code
dart format lib/

# Analyze code
dart analyze
```

### Useful Tools

- **Flutter DevTools**: `devtools` (UI profiler, debugger)
- **MQTT Test Client**: `mosquitto_pub`, `mosquitto_sub`
- **Network Monitor**: Wireshark untuk capture MQTT traffic
- **Device Monitor**: Android Studio untuk device logs
- **VS Code Extensions**: Flutter, Dart, MQTT Scout

---

**Last Updated**: 2024  
**Version**: 1.0.0

Jika solusi di dokumentasi ini tidak mengatasi masalah Anda, silahkan buat GitHub issue dengan informasi lengkap.
