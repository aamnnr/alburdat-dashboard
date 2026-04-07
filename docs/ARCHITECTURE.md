# Arsitektur Alburdat Dashboard

Dokumentasi detail tentang arsitektur, design patterns, dan struktur kode proyek Alburdat Dashboard.

## 1. Overview Sistem

```
┌─────────────────────────────────────────────────────────────________─┐
│                         Flutter Dashboard App                         │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                   UI Layer (Screens & Widgets)               │   │
│  │  - Dashboard, Rekomendasi, Manual, Statistik, WiFi, Info    │   │
│  └────────────────────────┬─────────────────────────────────────┘   │
│                           │                                           │
│  ┌────────────────────────┴─────────────────────────────────────┐   │
│  │              Provider (State Management)                      │   │
│  │  - MqttService                                               │   │
│  │  - ExpertSystemService                                       │   │
│  └────────┬──────────────────────────────────────┬──────────────┘   │
│           │                                      │                   │
│  ┌────────┴────────────┐           ┌────────────┴────────────┐    │
│  │   MQTT Service      │           │ Expert System Service   │    │
│  │ - TCP Connection    │           │ - Knowledge Base        │    │
│  │ - Pub/Sub Topics    │           │ - Rule Matching        │    │
│  │ - Connection State  │           │ - Dosis Calculation    │    │
│  └────────┬────────────┘           └────────────────────────┘    │
│           │                                                       │
│  ┌────────┴──────────────────────────────────────────────────┐   │
│  │              Models (Data Structures)                      │   │
│  │  - DeviceStatus                                            │   │
│  │  - Commodity, Rule, Dosage                                 │   │
│  └────────┬──────────────────────────────────────────────────┘   │
│           │                                                       │
│           │                 MQTT Protocol                         │
│           │                (JSON over 1883/9001)                 │
│           │                                                       │
│           ↓                                                       │
│  ┌────────────────────────┐                                       │
│  │   MQTT Broker          │                                       │
│  │  (broker.emqx.io:1883) │                                       │
│  └────────┬───────────────┘                                       │
│           │                                                       │
└───────────┼─────────────────────────────────────────────────────┘
            │
            │        WiFi
            │
┌───────────┴──────────────────────────────────┐
│            ESP32 Device (Firmware)            │
│  ┌──────────────────────────────────────────┐│
│  │    Hardware Control                       ││
│  │  - Motor DC (Pin 26)                      ││
│  │  - Buttons (Pin 32, 33)                   ││
│  │  - OLED Display (I2C: Pin 21, 22)         ││
│  │  - WiFi Connection                        ││
│  └──────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────┐│
│  │    Firmware Logic                         ││
│  │  - MQTT Publishing (Status)                ││
│  │  - MQTT Subscribing (Commands)             ││
│  │  - Motor Control Logic                     ││
│  │  - Button Handler                          ││
│  └──────────────────────────────────────────┘│
└──────────────────────────────────────────────┘
```

## 2. Project Structure

```
lib/
├── main.dart                      # Entry point, Provider setup
│
├── models/                        # Data models
│   ├── device_status.dart        # Status alat (dosis, motor, statistik)
│   ├── commodity.dart             # Data komoditas (padi, jagung, dll)
│   └── rule.dart                  # Rule expert system
│
├── data/                          # Static data
│   └── knowledge_base.dart        # Knowledge base expert system
│
├── services/                      # Business logic
│   ├── mqtt_service.dart          # MQTT connection & communication
│   └── expert_system_service.dart # Expert system logic
│
├── screens/                       # UI Pages
│   ├── splash_screen.dart         # Loading screen
│   ├── main_screen.dart           # Main app shell
│   ├── home_screen.dart           # Home/dashboard
│   ├── dashboard_page.dart        # Device status display
│   ├── rekomendasi_page.dart      # Dosage recommendation
│   ├── manual_page.dart           # Manual control
│   ├── info_page.dart             # Info/settings
│   ├── wifi_page.dart             # WiFi config
│   └── main_navigation_screen.dart # Navigation setup
│
├── widgets/                       # Reusable UI components
│   ├── dosis_card_widget.dart    # Card untuk display dosis
│   ├── commodity_card.dart        # Card untuk komoditas
│   └── ...                        # Widgets lainnya
│
├── theme/                         # UI Theme
│   └── theme.dart                 # Color, font, styles
│
└── utils/                         # Utilities (jika ada)
    └── ...
```

## 3. Core Services

### 3.1 MQTT Service (`mqtt_service.dart`)

**Tanggung jawab:**

- Establish & maintain connection ke MQTT broker
- Publish commands ke device
- Subscribe & listen status updates
- Handle reconnection logic
- Expose state via Provider (ChangeNotifier)

**Key Methods:**

```dart
// Connection management
Future<void> connect()
void disconnect()

// Device control
Future<void> setDosis(double gramasi)
Future<void> triggerPemupukan()
Future<void> resetStats()
Future<void> resetWifi()

// Getters & streams
DeviceStatus? get latestStatus
bool get isConnected
bool get isEspOnline
Stream<DeviceStatus> get statusStream
```

**MQTT Topics:**

| Topic              | Direction | Payload                                                                                                |
| ------------------ | --------- | ------------------------------------------------------------------------------------------------------ |
| `alburdat/status`  | ESP → App | `{"gramasi": 10.0, "isMotorRunning": false, "totalVolume": 150.5, "totalSesi": 15, "rataRata": 10.03}` |
| `alburdat/command` | App → ESP | `{"set_dosis": 15.0}` atau `{"reset_stats": true}` atau `{"reset_wifi": true}`                         |

**Connection Flow:**

```
1. Constructor: _initClient()
   ↓
2. connect()
   ├─ Set connection callbacks
   ├─ Try connect to broker
   ├─ If success: _onConnected() → _subscribeToTopics()
   └─ If fail: _scheduleReconnect() (retry setiap 5s, max 10x)
   ↓
3. Listen to statusStream
   ├─ _onMessageReceived()
   ├─ Parse JSON dari alburdat/status
   ├─ Update _latestStatus
   └─ notifyListeners() → rebuild widgets
   ↓
4. Send commands
   ├─ Build JSON payload
   ├─ Publish ke alburdat/command
```

### 3.2 Expert System Service (`expert_system_service.dart`)

**Tanggung jawab:**

- Provide recommendations based on commodity & HST (Hari Setelah Tanam)
- Match rules dari knowledge base
- Calculate optimal dosage

**Key Methods:**

```dart
// Get exact dosage
static double? getDosis({required int commodityId, required int hst})

// Get recommendation (throws if not found)
static double getRecommendedDosis(Commodity commodity, double hst)

// Get all commodities
static List<Commodity> getAllCommodities()

// Get commodity name by ID
static String? getCommodityName(int id)
```

**Knowledge Base Structure:**

```dart
// data/knowledge_base.dart
final Map<int, List<Rule>> knowledgeBase = {
  1: [ // Padi
    Rule(hstMin: 0, hstMax: 20, dosis: 5.0),
    Rule(hstMin: 21, hstMax: 40, dosis: 10.0),
    // ...
  ],
  2: [ // Jagung
    Rule(hstMin: 0, hstMax: 30, dosis: 8.0),
    // ...
  ],
};

final List<Commodity> commodities = [
  Commodity(id: 1, name: 'Padi'),
  Commodity(id: 2, name: 'Jagung'),
  // ...
];
```

## 4. Data Models

### 4.1 DeviceStatus

```dart
class DeviceStatus {
  final double gramasi;           // Current dosage (5-50g)
  final bool isMotorRunning;      // Motor status
  final double totalVolume;       // Total pupuk used (gram)
  final int totalSesi;            // Total sessions
  final double rataRata;          // Average dosage per session
}
```

### 4.2 Commodity

```dart
class Commodity {
  final int id;
  final String name;              // e.g., "Padi", "Jagung"
  final String? imageUrl;         // Optional image
}
```

### 4.3 Rule

```dart
class Rule {
  final int hstMin;               // Min HST (Hari Setelah Tanam)
  final int hstMax;               // Max HST
  final double dosis;             // Recommended dosage (gram)

  bool matches(int hst) => hst >= hstMin && hst <= hstMax;
}
```

## 5. State Management (Provider)

```dart
// main.dart setup
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => MqttService()..connect(),
    ),
    // Bisa tambah ExpertSystemService jika diperlukan
  ],
  child: MaterialApp(...)
)
```

**Usage dalam Widget:**

```dart
// Read (watch)
final status = context.watch<MqttService>().latestStatus;

// One-time read
final service = context.read<MqttService>();

// Perform action
Consumer<MqttService>(
  builder: (context, mqtt, _) {
    return FloatingActionButton(
      onPressed: () => mqtt.setDosis(15.0),
      child: Icon(Icons.add),
    );
  },
)
```

## 6. Screen Flow

```
┌─────────────────┐
│  SplashScreen   │ (2-3 detik)
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────────┐
│     MainScreen (BottomNavBar)        │
├─────────────────────────────────────┤
│ - Home/Dashboard (selected by default)
│ - Rekomendasi
│ - Manual Control
│ - Statistik
│ - WiFi Settings
│ - Info
└───────────┬─────────────────────────┘
            │
    ┌───────┴────────┬──────────┬──────────┬────────────┐
    ↓                ↓          ↓          ↓            ↓
┌────────┐   ┌──────────────┐  ┌──────┐ ┌──────┐ ┌────────┐
│ Home   │   │ Rekomendasi  │  │Manual│ │ Info │ │WiFi    │
├────────┤   ├──────────────┤  ├──────┤ ├──────┤ ├────────┤
│Show    │   │Select        │  │Geser │ │MQTT  │ │Reset   │
│status  │   │komoditas &   │  │dosis │ │status│ │koneksi │
│real-   │   │HST → get     │  │+ set │ │verb  │ │        │
│time    │   │rekomendasi   │  │      │ │      │ │        │
└────────┘   └──────────────┘  └──────┘ └──────┘ └────────┘
```

## 7. Data Flow

### 7.1 Receive Status (Push dari ESP)

```
ESP Device
  ↓ MQTT Publish (alburdat/status)
  │
MQTT Broker
  ↓
Flutter App (MqttService)
  ├─ _onMessageReceived()
  ├─ Parse JSON → DeviceStatus
  ├─ _latestStatus = new status
  ├─ _statusStreamController.add()
  ├─ notifyListeners() (Provider)
  │
  ↓ Widget rebuild
Consumer<MqttService> / watch<MqttService>
  ├─ Build UI with latest status
  └─ Display gramasi, isMotorRunning, etc.
```

### 7.2 Send Command (Pull dari App)

```
User tap button (setDosis, triggerPemupukan, resetStats, resetWifi)
  ↓
MqttService.setDosis(15.0) / resetStats() / etc.
  ├─ Build JSON payload
  └─ client.publishMessage(alburdat/command, payload)
  ↓
MQTT Broker
  ↓
ESP Device
  ├─ mqttCallback receives command
  └─ Execute action (motor run, reset EEPROM, etc.)
```

### 7.3 Recommendation Flow

```
User select komoditas (e.g., Padi) & HST (30)
  ↓
Manual call: ExpertSystemService.getRecommendedDosis()
  ├─ getDosis(commodityId: 1, hst: 30)
  ├─ Loop through knowledgeBase[1]
  ├─ Find rule where hst >= 21 && hst <= 40
  └─ Return dosis (10.0 gram)
  ↓
UI Display: "Rekomendasi: 10.0 gram"
  ↓
User confirm → setDosis(10.0) → MQTT publish
```

## 8. Theme & Styling

**File:** `lib/theme/theme.dart`

```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Color(0xFF4CAF50),  // Green
      scaffoldBackgroundColor: Colors.white,
      // ... Define all colors, fonts, etc.
    );
  }
}
```

**Usage:**

```dart
// main.dart
MaterialApp(
  theme: AppTheme.lightTheme,
  home: SplashScreen(),
)

// In widgets
Container(
  color: Theme.of(context).primaryColor,
)
```

## 9. Adding New Features

### 9.1 Add New Commodity

1. Edit `lib/data/knowledge_base.dart`:

   ```dart
   final List<Commodity> commodities = [
     Commodity(id: 1, name: 'Padi'),
     // Add new commodity
     Commodity(id: 3, name: 'Cabai'),
   ];

   final Map<int, List<Rule>> knowledgeBase = {
     // ... existing rules
     3: [ // Cabai
       Rule(hstMin: 0, hstMax: 25, dosis: 5.0),
       Rule(hstMin: 26, hstMax: 50, dosis: 12.0),
     ],
   };
   ```

### 9.2 Add New MQTT Command

1. Edit `lib/services/mqtt_service.dart`:

   ```dart
   Future<void> customCommand(String value) async {
     final payload = jsonEncode({'custom_command': value});
     client.publishMessage(topicCommand, MqttMessage(payload));
   }
   ```

2. Update ESP32 firmware `mqttCallback()` to handle new command.

### 9.3 Add New Screen

1. Create `lib/screens/new_page.dart`:

   ```dart
   class NewPage extends StatefulWidget {
     @override
     State<NewPage> createState() => _NewPageState();
   }

   class _NewPageState extends State<NewPage> {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('New Page')),
         body: Center(child: Text('Content')),
       );
     }
   }
   ```

2. Add to navigation di `lib/screens/main_navigation_screen.dart`.

### 9.4 Add New Widget

1. Create `lib/widgets/new_widget.dart`:

   ```dart
   class NewWidget extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Container(
         // ...
       );
     }
   }
   ```

2. Import & use di screens.

## 10. Testing

### 10.1 Unit Tests

```bash
flutter test
```

**Example test file:** `test/models/device_status_test.dart`

```dart
void main() {
  test('DeviceStatus.fromJson should parse correctly', () {
    final json = {
      'gramasi': 15.0,
      'isMotorRunning': true,
      'totalVolume': 100.0,
      'totalSesi': 10,
      'rataRata': 10.0
    };

    final status = DeviceStatus.fromJson(json);
    expect(status.gramasi, 15.0);
    expect(status.isMotorRunning, true);
  });
}
```

### 10.2 Widget Tests

```dart
testWidgets('Dashboard displays status', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.byType(DosisCardWidget), findsOneWidget);
});
```

### 10.3 Integration Tests

```dart
// test_driver/app.dart
void main() => enableFlutterDriverExtension();

// test_driver/app_test.dart
import 'package:flutter_driver/flutter_driver.dart';

void main() {
  group('Alburdat App', () {
    final doscisFinder = find.byType('Text');

    test('Display dosage', () async {
      final driver = await FlutterDriver.connect();
      expect(await driver.getText(doscisFinder), '10.0');
      await driver.close();
    });
  });
}
```

## 11. Performance Optimization

### 11.1 Widget Rebuilds

```dart
// ❌ Bad - rebuilds whole tree
Consumer<MqttService>(
  builder: (context, mqtt, _) {
    return Column(
      children: [
        ExpensiveWidget(),  // Rebuilds unnecessarily
        Text(mqtt.latestStatus?.toString() ?? 'N/A'),
      ],
    );
  },
)

// ✅ Good - selective rebuild
Consumer<MqttService>(
  builder: (context, mqtt, _) {
    return Text(mqtt.latestStatus?.toString() ?? 'N/A');
  },
)
```

### 11.2 MQTT Message Filtering

```dart
// Di MqttService, hanya process messages yang penting
if (_latestStatus == newStatus) {
  // Skip if data identical
  return;
}
```

### 11.3 Image Caching

```dart
CachedNetworkImage(
  imageUrl: 'https://...',
  cacheManager: CacheManager.instance,
)
```

## 12. Security Considerations

### 12.1 MQTT Broker Security

```dart
// Use TLS/SSL jika possible
client.port = 8883;  // Secure port
client.secure = true;
client.onBadCertificate = (dynamic cert) => true;  // Production: validate cert
```

### 12.2 API Keys & Secrets

```dart
// ❌ JANGAN hardcode di code
const String API_KEY = 'secret123';

// ✅ Gunakan environment variables atau config file
// lib/config/config.dart
const String broker = String.fromEnvironment('MQTT_BROKER', defaultValue: 'broker.emqx.io');
```

### 12.3 Permission Handling

```dart
// Android: AndroidManifest.xml
// iOS: Info.plist
// Implement permission checks di code
```

## 13. Debugging Tips

### 13.1 MQTT Debugging

```bash
# Monitoring MQTT messages
mosquitto_sub -v -t 'alburdat/#'

# Publish test message
mosquitto_pub -t alburdat/status -m '{"gramasi":10.0,"isMotorRunning":false,"totalVolume":150.5,"totalSesi":15,"rataRata":10.03}'
```

### 13.2 Flutter Debugging

```bash
# Verbose logging
flutter run -v

# Enabled debug mode in code
flutter run --debug

# DevTools
flutter pub global activate devtools
devtools

# Debugger
flutter run --debug
# Then press 'v' in terminal for Dart DevTools
```

### 13.3 Logs

```dart
// Print logs
debugPrint('Message');  // Only shows in debug mode

// Error logging
try {
  // code
} catch (e, stackTrace) {
  debugPrint('Error: $e');
  debugPrintStack(stackTrace: stackTrace);
}
```

---

**Last Updated:** 2024
**Maintainer:** [Your Name/Team]
