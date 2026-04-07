# Setup Development Environment - Alburdat Dashboard

Panduan lengkap untuk setup development environment Flutter untuk proyek Alburdat Dashboard.

## Persyaratan Sistem

- **OS**: Windows 10+, macOS 10.14+, atau Linux (Ubuntu 18.04+)
- **RAM**: Minimal 4GB (8GB recommended)
- **Disk**: 5GB free space

## 1. Install Flutter SDK

### Windows

1. Download Flutter SDK dari [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Extract ke folder (misal: `C:\src\flutter`)
3. Tambahkan ke PATH:
   - Buka "Environment Variables" (System Properties → Advanced → Environment Variables)
   - Pada "User variables", klik "New"
   - Variable name: `PATH`
   - Variable value: `C:\src\flutter\bin` (sesuaikan path Anda)
   - Klik OK
4. Tutup dan buka kembali Command Prompt/PowerShell
5. Verifikasi:
   ```bash
   flutter --version
   ```

### macOS

```bash
# Install via Homebrew (recommended)
brew install flutter

# Atau download manual dari https://flutter.dev
unzip ~/Downloads/flutter_macos_*.zip
export PATH="$PATH:~/flutter/bin"
```

### Linux

```bash
# Download Flutter
cd ~/development
tar xf ~/Downloads/flutter_linux_*.tar.xz

# Tambah ke PATH di ~/.bashrc atau ~/.zshrc
export PATH="$PATH:~/development/flutter/bin"

source ~/.bashrc  # atau source ~/.zshrc
```

## 2. Install Android Development

### Windows/macOS/Linux

1. Download Android Studio dari [developer.android.com](https://developer.android.com/studio)
2. Install Android Studio
3. Buka Android Studio → Setup Wizard
   - Install Android SDK
   - Install Android SDK Platform-Tools
   - Accept licenses:
     ```bash
     flutter doctor --android-licenses
     ```

4. Set ANDROID_SDK_ROOT:
   - **Windows**: Add to Environment Variables:
     ```
     ANDROID_SDK_ROOT = C:\Users\[YourUsername]\AppData\Local\Android\sdk
     ```
   - **macOS/Linux**: Add to ~/.bashrc or ~/.zshrc:
     ```bash
     export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk  # macOS
     export ANDROID_SDK_ROOT=$HOME/Android/Sdk           # Linux
     ```

## 3. Install iOS Development (macOS only)

```bash
# Install Xcode from App Store
# Or from terminal:
sudo xcode-select --install

# Install CocoaPods
sudo gem install cocoapods

# Verify
flutter doctor
```

## 4. Install Git

### Windows

```bash
# Download dari https://git-scm.com/download/win
# Atau gunakan Chocolatey:
choco install git
```

### macOS

```bash
brew install git
```

### Linux

```bash
sudo apt-get install git
```

## 5. Install IDE/Editor

### Option A: Android Studio (Full IDE)

```bash
# Sudah diinstall di step sebelumnya
# Buka Android Studio → Plugin MarketPlace
# Search "Flutter" dan "Dart"
# Install kedua plugin
```

### Option B: VS Code (Lightweight)

1. Download dari [code.visualstudio.com](https://code.visualstudio.com)
2. Install extensions:
   - "Flutter" (Dart Code)
   - "Dart" (Dart Code)

### Option C: IntelliJ IDEA

1. Download dari [jetbrains.com](https://www.jetbrains.com/idea/)
2. Install plugins:
   - Flutter
   - Dart

## 6. Verify Installation

Jalankan `flutter doctor` untuk memverifikasi semua dependencies:

```bash
flutter doctor
```

Output yang diharapkan:

```
✓ Flutter (version 3.11.1 atau lebih)
✓ Android toolchain
✓ Android Studio
✓ VS Code
✓ Dart SDK
```

Jika ada ✗, ikuti saran yang diberikan.

## 7. Clone Repository & Setup Project

```bash
# Clone repository
git clone <repository-url>
cd alburdat_dashboard

# Install dependencies
flutter pub get

# Format code (optional)
dart format lib/

# Analyze code
dart analyze

# Run tests
flutter test
```

## 8. Setup MQTT Broker

### Local Development (Mosquitto)

#### Windows

```bash
# Download dari https://mosquitto.org/download/
# Install .exe file
# Atau gunakan Chocolatey:
choco install mosquitto

# Test
mosquitto_pub -t alburdat/status -m '{"gramasi":10}'
mosquitto_sub -t alburdat/status
```

#### macOS

```bash
brew install mosquitto

# Start service
brew services start mosquitto

# Test
mosquitto_pub -t alburdat/status -m '{"gramasi":10}'
mosquitto_sub -t alburdat/status
```

#### Linux

```bash
sudo apt-get install mosquitto mosquitto-clients

# Start service
sudo systemctl start mosquitto
sudo systemctl enable mosquitto  # start on boot

# Test
mosquitto_pub -t alburdat/status -m '{"gramasi":10}'
mosquitto_sub -t alburdat/status
```

### Cloud MQTT (Production)

Gunakan:

- **EMQX Cloud**: https://www.emqx.com/en/cloud
- **HiveMQ Cloud**: https://www.hivemq.com/mqtt-cloud-broker/
- **AWS IoT Core**: https://aws.amazon.com/iot-core/

Ubah broker di `lib/services/mqtt_service.dart`:

```dart
final String broker = 'your-broker-address';
final int port = 1883;  // atau 8883 untuk secure
```

## 9. Configure MQTT Broker Address

Edit `lib/services/mqtt_service.dart`:

```dart
class MqttService extends ChangeNotifier {
  final String broker = 'broker.emqx.io';  // Ubah sesuai broker Anda
  final int port = 8083;  // WebSocket port (1883 untuk TCP)
  // ...
}
```

## 10. Run Development

### Android Emulator

```bash
# List available devices
flutter devices

# Run
flutter run -d emulator-5554

# Hot reload
r

# Hot restart
R

# Quit
q
```

### Physical Device

```bash
# Enable USB Debugging pada device
# Hubungkan via USB

# List devices
flutter devices

# Run
flutter run -d <device-id>
```

### Web (Chrome)

```bash
flutter run -d chrome

# Atau di Firefox
flutter run -d firefox

# Atau di Edge
flutter run -d edge
```

### Windows Desktop

```bash
flutter run -d windows
```

### macOS Desktop (macOS only)

```bash
flutter run -d macos
```

### Linux Desktop (Linux only)

```bash
flutter run -d linux
```

## 11. Build Production

### Android APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Split per ABI (lebih kecil)
flutter build apk --release --split-per-abi
# Output: build/app/outputs/flutter-apk/
```

### Android App Bundle (untuk Google Play)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS only)

```bash
# Build
flutter build ios --release

# Output akan di build/ios/iphoneos/Runner.app
# Buka di Xcode untuk upload ke App Store
open ios/Runner.xcworkspace
```

### Web

```bash
# Build
flutter build web --release

# Output: build/web/
# Deploy ke hosting (Firebase, Vercel, GitHub Pages, dll)
```

### Windows Desktop

```bash
flutter build windows --release
# Output: build/windows/runner/Release/alburdat_dashboard.exe
```

### Linux Desktop

```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

## 12. Environment Fixes

### Flutter Cache Issue

```bash
flutter clean
flutter pub get
```

### Gradle Build Fails (Android)

```bash
cd android
./gradlew clean
cd ..
flutter pub get
```

### Xcode Build Fails (iOS/macOS)

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### Pub Get Timeout

```bash
# Increase timeout
flutter pub get --verbose

# Atau edit ~/.pub-cache/hosted/pub.dev/ untuk clear cache
```

## 13. Essential Git Commands

```bash
# Clone repository
git clone <url>

# Create feature branch
git checkout -b feature/feature-name

# Commit changes
git add .
git commit -m "Describe your changes"

# Push to remote
git push origin feature/feature-name

# Create Pull Request
# Go to GitHub/GitLab and create PR

# Sync dengan main branch
git fetch origin
git rebase origin/main
```

## 14. Useful Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Dart Docs**: https://dart.dev/guides
- **MQTT Client**: https://pub.dev/packages/mqtt_client
- **Provider**: https://pub.dev/packages/provider
- **Flutter Community**: https://github.com/flutter/flutter
- **Stack Overflow**: Tag `flutter`, `dart`, `mqtt`

## Troubleshooting

| Problem                         | Solution                                          |
| ------------------------------- | ------------------------------------------------- |
| `flutter: command not found`    | Tambah Flutter ke PATH                            |
| `AndroidStudioSdkVersion` error | Run `flutter doctor --android-licenses`           |
| `Gradle build fails`            | Run `flutter clean && flutter pub get`            |
| `No devices found`              | Check `flutter devices` atau enable USB debugging |
| `MQTT connection timeout`       | Verify broker address dan port                    |
| `Hot reload tidak bekerja`      | Use hot restart atau build ulang                  |

---

Jika ada masalah, check `flutter doctor -v` untuk informasi detail.
