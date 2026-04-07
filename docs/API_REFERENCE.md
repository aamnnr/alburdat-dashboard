# API Reference - Alburdat Dashboard

Dokumentasi lengkap untuk semua services, models, dan public API dalam project Alburdat Dashboard.

## Daftar Isi

1. [MqttService](#mqttservice)
2. [ExpertSystemService](#expertsystemservice)
3. [Models](#models)
   - [DeviceStatus](#devicestatus)
   - [Commodity](#commodity)
   - [Rule](#rule)
4. [Constants](#constants)
5. [Error Handling](#error-handling)
6. [Usage Examples](#usage-examples)

---

## MqttService

**File**: `lib/services/mqtt_service.dart`

**Type**: `ChangeNotifier` (Provider state management)

**Description**: Mengelola MQTT connection ke broker, publishing commands, dan subscribing ke device status updates. Automatically handles reconnection dan provides real-time status stream.

### Properties

#### `isConnected`

```dart
bool get isConnected
```

Menunjukkan apakah app terhubung ke MQTT broker.

- **Type**: `bool`
- **Returns**: `true` jika MQTT connected, `false` jika disconnected

#### `isConnecting`

```dart
bool get isConnecting
```

Menunjukkan apakah sedang dalam proses connect.

- **Type**: `bool`
- **Returns**: `true` jika sedang attempting connection

#### `latestStatus`

```dart
DeviceStatus? get latestStatus
```

Status terbaru dari device ESP32.

- **Type**: `DeviceStatus?` (nullable, bisa null jika belum ada data)
- **Returns**: Latest device status, atau `null` jika never received

**Usage**:

```dart
final status = mqttService.latestStatus;
if (status != null) {
  print('Current dosis: ${status.gramasi}g');
}
```

#### `isEspOnline`

```dart
bool get isEspOnline
```

Mengecek apakah device ESP32 masih online (berdasarkan waktu terakhir menerima status).

- **Type**: `bool`
- **Logic**: `true` jika status diterima kurang dari 30 detik yang lalu
- **Returns**: `true` jika device considered online

**Usage**:

```dart
if (mqttService.isEspOnline) {
  print('Device is online');
} else {
  print('Device offline - last seen ${DateTime.now().difference(_lastStatusTime).inSeconds}s ago');
}
```

#### `statusStream`

```dart
Stream<DeviceStatus> get statusStream
```

Stream broadcast yang emit setiap kali status baru diterima dari device.

- **Type**: `Stream<DeviceStatus>` (broadcast stream)
- **Emits**: Setiap new `DeviceStatus` received via MQTT
- **Behavior**: Dapat disubscribe multiple listeners

**Usage**:

```dart
mqttService.statusStream.listen((status) {
  print('New status: ${status.gramasi}g');
});

// Atau dengan StreamBuilder di UI
StreamBuilder<DeviceStatus>(
  stream: mqttService.statusStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('Dosis: ${snapshot.data!.gramasi}g');
    }
    return Text('Loading...');
  },
)
```

#### MQTT Topics

```dart
static const String topicStatus = 'alburdat/status'
static const String topicCommand = 'alburdat/command'
```

---

### Methods

#### `connect()`

```dart
Future<void> connect()
```

Establish connection ke MQTT broker. Call ini di startup (dilakukan di `main.dart`).

- **Async**: Ya
- **Throws**: No (handles exceptions internally)
- **Side effects**:
  - Sets `isConnecting = true`
  - Updates `isConnected` status
  - Subscribes ke `topicStatus`
  - Starts auto-reconnect jika gagal

**Usage**:

```dart
// Di main.dart, sudah dilakukan via Provider
ChangeNotifierProvider(
  create: (_) => MqttService()..connect(),
)

// Manual connect jika perlu
await mqttService.connect();
```

**Flow**:

```
1. check isConnected/isConnecting
2. set isConnecting = true
3. client.connect() to broker
4. if success: _onConnected() → subscribe to topics
5. if fail: _scheduleReconnect() (retry max 10x, interval 5s)
6. set isConnecting = false
7. notifyListeners()
```

---

#### `disconnect()`

```dart
void disconnect()
```

Gracefully disconnect dari MQTT broker.

- **Async**: No
- **Side effects**:
  - Closes MQTT connection
  - Cancels reconnect timer
  - Updates `isConnected = false`
  - Notifies listeners

**Usage**:

```dart
// Saat app close atau switch network
await mqttService.disconnect();
```

---

#### `setDosis(double gramasi)`

```dart
Future<void> setDosis(double gramasi)
```

Set desired pupuk dosage di device.

- **Parameters**:
  - `gramasi` (double): Target dosis dalam gram (valid range: 5-50)
- **Async**: Yes
- **Throws**: Nothing (validates silently)
- **Side effects**:
  - Publishes JSON command ke `alburdat/command`
  - Device receives dan updates dosis
  - OLED display updates dalam ~1 detik

**Payload**:

```json
{ "set_dosis": 15.5 }
```

**Usage**:

```dart
// Set via slider
await mqttService.setDosis(15.0);

// Set via recommendation
final dosis = ExpertSystemService.getRecommendedDosis(commodity, hst);
await mqttService.setDosis(dosis);

// With error handling
try {
  await mqttService.setDosis(20.0);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Dosis set to 20.0g')),
  );
} catch (e) {
  print('Error: $e');
}
```

---

#### `resetStats()`

```dart
Future<void> resetStats()
```

Reset statistik perangkat (total volume, total sessions, average). Clear EEPROM di device.

- **Async**: Yes
- **Throws**: Nothing
- **Side effects**:
  - Publishes `{"reset_stats": true}` to `alburdat/command`
  - Device clears EEPROM storage
  - Numbers reset ke 0
  - Statistics screen akan show 0 setelah sync

**Payload**:

```json
{ "reset_stats": true }
```

**Usage**:

```dart
// Reset statistics (biasanya di tombol di Statistics page)
await mqttService.resetStats();

// With confirmation dialog
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Reset Statistik?'),
    content: Text('Data statistik akan dihapus dan tidak bisa dikembalikan.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Batal'),
      ),
      TextButton(
        onPressed: () async {
          await mqttService.resetStats();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Statistik berhasil direset')),
          );
        },
        child: Text('Reset'),
      ),
    ],
  ),
);
```

---

#### `resetWifi()`

```dart
Future<void> resetWifi()
```

Trigger WiFi reset di device. Device akan restart dan masuk ke WiFiManager config mode.

- **Async**: Yes
- **Throws**: Nothing
- **Side effects**:
  - Publishes `{"reset_wifi": true}` to `alburdat/command`
  - Device restart
  - WiFi hotspot `ALBURDAT_CONFIG` akan available
  - App akan disconnect dan need manual reconnect ke hotspot

**Payload**:

```json
{ "reset_wifi": true }
```

**Usage**:

```dart
// Reset WiFi configuration
await mqttService.resetWifi();

// Show instruction dialog
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Reset WiFi'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Device sedang restart dan akan membuat hotspot...'),
        SizedBox(height: 16),
        LinearProgressIndicator(),
      ],
    ),
  ),
);

// Instruction untuk user
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Langkah-langkah:', style: Theme.of(context).textTheme.headlineSmall),
        Text('1. Tunggu 10 detik sampai hotspot ALBURDAT_CONFIG muncul'),
        Text('2. Connect ke hotspot (password: petanisukses)'),
        Text('3. Buka http://192.168.4.1 di browser'),
        Text('4. Pilih WiFi rumah dan masuk password'),
        Text('5. Tunggu device restart'),
      ],
    ),
  ),
);
```

---

#### Internal Methods (Dokumentasi)

These methods are internal (private) pero dokumentasi untuk understanding:

```dart
// Called when MQTT connected
void _onConnected()

// Called when MQTT disconnected
void _onDisconnected()

// Called when subscribe successful
void _onSubscribed(dynamic subscription)

// Called when message received
void _onMessageReceived(MqttReceivedMessage<MqttMessage> message)

// Called when pong received (keep-alive)
void _pong()

// Schedule reconnection attempt
void _scheduleReconnect()

// Parse incoming message
void _handleStatusMessage(String payload)

// Publish message to topic
void _publish(String topic, String payload)
```

---

## ExpertSystemService

**File**: `lib/services/expert_system_service.dart`

**Type**: Service class (static methods)

**Description**: Provide dosage recommendations berdasarkan commodity dan HST (Hari Setelah Tanam) menggunakan knowledge base rules.

### Methods

#### `getDosis({required int commodityId, required int hst})`

```dart
static double? getDosis({
  required int commodityId,
  required int hst,
})
```

Get exact dosage dari knowledge base untuk commodity & HST tertentu.

- **Parameters**:
  - `commodityId` (int): ID komoditas (1=Padi, 2=Jagung, dll)
  - `hst` (int): Hari Setelah Tanam (0-150+)
- **Returns**: `double?` (gram, atau `null` jika tidak ada rule match)

**Usage**:

```dart
// Get dosis untuk Padi HST 30
final dosis = ExpertSystemService.getDosis(
  commodityId: 1,
  hst: 30,
);

if (dosis != null) {
  print('Recommended dosis: $dosis g');
} else {
  print('No recommendation found');
}
```

**Logic**:

```
1. Get rules dari knowledgeBase[commodityId]
2. If no rules found: return null
3. Loop through rules
4. If rule.matches(hst): return rule.dosis
5. If no match: return null
```

---

#### `getRecommendedDosis(Commodity commodity, double hst)`

```dart
static double getRecommendedDosis(
  Commodity commodity,
  double hst,
)
```

Get dosage recommendation (convenience method). Throws exception jika tidak ada dosis.

- **Parameters**:
  - `commodity` (Commodity): Commodity object dengan id & name
  - `hst` (double): Hari Setelah Tanam
- **Returns**: `double` (gram)
- **Throws**: `Exception` jika tidak ada recommendation

**Usage**:

```dart
final commodity = Commodity(id: 1, name: 'Padi');
final hst = 30.0;

try {
  final dosis = ExpertSystemService.getRecommendedDosis(
    commodity,
    hst,
  );
  print('Dosis: $dosis g');

  // Auto-set ke device
  await mqttService.setDosis(dosis);
} on Exception catch (e) {
  print('Error: $e');
  // Show error dialog to user
}
```

---

#### `getAllCommodities()`

```dart
static List<Commodity> getAllCommodities()
```

Get semua commodity yang tersedia dalam system.

- **Returns**: `List<Commodity>` (all varieties)

**Usage**:

```dart
final allCommodities = ExpertSystemService.getAllCommodities();

// Display dalam dropdown/list
ListView.builder(
  itemCount: allCommodities.length,
  itemBuilder: (context, index) {
    final commodity = allCommodities[index];
    return ListTile(
      title: Text(commodity.name),
      onTap: () => setState(() => selectedCommodity = commodity),
    );
  },
)
```

---

#### `getCommodityName(int id)`

```dart
static String? getCommodityName(int id)
```

Get commodity name dari ID.

- **Parameters**:
  - `id` (int): Commodity ID
- **Returns**: `String?` (name, atau `null` jika tidak found)

**Usage**:

```dart
final name = ExpertSystemService.getCommodityName(1);
print(name);  // "Padi"

// Gunakan dalam display
Text('Komoditas: ${ExpertSystemService.getCommodityName(commodity.id) ?? "Unknown"}')
```

---

## Models

### DeviceStatus

**File**: `lib/models/device_status.dart`

Data class yang represent current status dari ESP32 device.

#### Constructor

```dart
class DeviceStatus {
  final double gramasi;
  final bool isMotorRunning;
  final double totalVolume;
  final int totalSesi;
  final double rataRata;

  DeviceStatus({
    required this.gramasi,
    required this.isMotorRunning,
    required this.totalVolume,
    required this.totalSesi,
    required this.rataRata,
  });
}
```

#### Properties

| Property         | Type   | Description                          |
| ---------------- | ------ | ------------------------------------ |
| `gramasi`        | double | Current dosis (gram) range 5-50      |
| `isMotorRunning` | bool   | Motor sedang aktif?                  |
| `totalVolume`    | double | Total pupuk telah dikeluarkan (gram) |
| `totalSesi`      | int    | Total dispense sessions              |
| `rataRata`       | double | Average dosis per session (gram)     |

#### Factory Method

```dart
factory DeviceStatus.fromJson(Map<String, dynamic> json)
```

Parse dari JSON (dari MQTT message).

**Usage**:

```dart
final json = {
  'gramasi': 15.0,
  'isMotorRunning': false,
  'totalVolume': 150.5,
  'totalSesi': 15,
  'rataRata': 10.03
};

final status = DeviceStatus.fromJson(json);
print(status.gramasi);  // 15.0
```

#### Usage in Widgets

```dart
Consumer<MqttService>(
  builder: (context, mqtt, _) {
    final status = mqtt.latestStatus;

    if (status == null) {
      return Text('Waiting for device...');
    }

    return Column(
      children: [
        Text('Dosis: ${status.gramasi}g'),
        Text('Motor: ${status.isMotorRunning ? "Aktif" : "Siap"}'),
        Text('Total: ${status.totalVolume}g (${status.totalSesi} sesi)'),
        Text('Rata-rata: ${status.rataRata}g/sesi'),
      ],
    );
  },
)
```

---

### Commodity

**File**: `lib/models/commodity.dart`

Data class untuk represent jenis tanaman/komoditas.

#### Constructor

```dart
class Commodity {
  final int id;
  final String name;
  final String? imageUrl;  // Optional

  Commodity({
    required this.id,
    required this.name,
    this.imageUrl,
  });
}
```

#### Properties

| Property   | Type    | Description                   |
| ---------- | ------- | ----------------------------- |
| `id`       | int     | Unique identifier             |
| `name`     | String  | Commodity name (e.g., "Padi") |
| `imageUrl` | String? | Optional image URL            |

#### Usage

```dart
// Create commodity
final padi = Commodity(id: 1, name: 'Padi');
final jagung = Commodity(
  id: 2,
  name: 'Jagung',
  imageUrl: 'https://example.com/jagung.jpg',
);

// Get all commodities
final all = ExpertSystemService.getAllCommodities();

// Use in dropdown
DropdownButton<Commodity>(
  value: selectedCommodity,
  items: all.map((c) => DropdownMenuItem(
    value: c,
    child: Text(c.name),
  )).toList(),
  onChanged: (c) => setState(() => selectedCommodity = c),
)
```

---

### Rule

**File**: `lib/models/rule.dart`

Data class untuk expert system rules (HST range → dosis mapping).

#### Constructor

```dart
class Rule {
  final int hstMin;
  final int hstMax;
  final double dosis;

  Rule({
    required this.hstMin,
    required this.hstMax,
    required this.dosis,
  });

  bool matches(int hst) => hst >= hstMin && hst <= hstMax;
}
```

#### Properties

| Property | Type   | Description              |
| -------- | ------ | ------------------------ |
| `hstMin` | int    | Min HST (inclusive)      |
| `hstMax` | int    | Max HST (inclusive)      |
| `dosis`  | double | Recommended dosis (gram) |

#### Methods

```dart
bool matches(int hst)
```

Check apakah HST matches dengan rule ini.

**Usage**:

```dart
final rule = Rule(hstMin: 21, hstMax: 40, dosis: 10.0);
print(rule.matches(30));  // true
print(rule.matches(50));  // false

// Gunakan dalam getDosis logic
for (final rule in rules) {
  if (rule.matches(hst)) {
    return rule.dosis;  // 10.0
  }
}
```

---

## Constants

### Topics

```dart
class MqttService {
  static const String topicStatus = 'alburdat/status';
  static const String topicCommand = 'alburdat/command';
}
```

### Configuration

```dart
class MqttService {
  final String broker = 'broker.emqx.io';  // Change untuk custom broker
  final int port = 8083;                     // WebSocket port (1883 untuk TCP)
  final int keepAlivePeriod = 20;           // Seconds
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectInterval = Duration(seconds: 5);
}
```

### Dosis Constraints

```dart
// Hard limit di firmware
const double minGramasi = 5.0;
const double maxGramasi = 50.0;
const double dosisStep = 5.0;  // Each button press = 5g
```

---

## Error Handling

### MQTT Connection Errors

Device mungkin **tidak** throw exception, pero provide status via properties:

```dart
// Check connection status
if (!mqttService.isConnected) {
  // Handle offline state
  // Show snackbar atau retry button
}

// Check device online status
if (!mqttService.isEspOnline) {
  // Device not responding
  // Show timer sampai offline
}
```

### Expert System Errors

```dart
// getDosis returns null jika tidak ada rule
final dosis = ExpertSystemService.getDosis(
  commodityId: 999,  // Invalid id
  hst: 50,
);
if (dosis == null) {
  // Handle: no recommendation found
}

// getRecommendedDosis throws Exception
try {
  final dosis = ExpertSystemService.getRecommendedDosis(commodity, hst);
} on Exception catch (e) {
  print('Error: $e');
  // Handle error
}
```

### Validation

```dart
// In app, validate user input
if (hst < 0 || hst > 150) {
  throw Exception('HST must be 0-150');
}

if (gramasi < 5 || gramasi > 50) {
  throw Exception('Gramasi must be 5-50');
}
```

---

## Usage Examples

### Complete Example: Recommendation Flow

```dart
class RecomendationPage extends StatefulWidget {
  @override
  State<RecomendationPage> createState() => _RecomendationPageState();
}

class _RecomendationPageState extends State<RecomendationPage> {
  Commodity? selectedCommodity;
  int hst = 0;
  double? recommendedDosis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rekomendasi Dosis')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commodity selection
            Text('Pilih Komoditas:',
                style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 8),
            DropdownButton<Commodity>(
              value: selectedCommodity,
              hint: Text('Pilih komoditas...'),
              isExpanded: true,
              items: ExpertSystemService.getAllCommodities()
                  .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name),
                  ))
                  .toList(),
              onChanged: (commodity) =>
                  setState(() => selectedCommodity = commodity),
            ),

            SizedBox(height: 24),

            // HST input
            Text('HST (Hari Setelah Tanam):',
                style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masuk umur tanaman (hari)',
              ),
              onChanged: (value) =>
                  setState(() => hst = int.tryParse(value) ?? 0),
            ),

            SizedBox(height: 24),

            // Calculate button
            ElevatedButton(
              onPressed: selectedCommodity != null
                  ? () {
                    try {
                      final dosis =
                          ExpertSystemService.getRecommendedDosis(
                        selectedCommodity!,
                        hst.toDouble(),
                      );
                      setState(() => recommendedDosis = dosis);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                  : null,
              child: Text('Hitung Rekomendasi'),
            ),

            SizedBox(height: 24),

            // Result
            if (recommendedDosis != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hasil Rekomendasi:',
                      style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 8),
                  Card(
                    color: Colors.green[100],
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dosis optimal: $recommendedDosis gram',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                          SizedBox(height: 8),
                          Text(
                            'untuk ${selectedCommodity!.name} '
                            'umur $hst hari',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await context
                          .read<MqttService>()
                          .setDosis(recommendedDosis!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Dosis set to $recommendedDosis g',
                          ),
                        ),
                      );
                    },
                    child: Text('Set Dosis ke Device'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
```

### Complete Example: Dashboard with Real-time Status

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MqttService>(
      builder: (context, mqtt, _) {
        final status = mqtt.latestStatus;

        if (status == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to device...'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status
              Card(
                color: mqtt.isEspOnline
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        mqtt.isEspOnline
                            ? Icons.check_circle
                            : Icons.error_circle,
                        color: mqtt.isEspOnline
                            ? Colors.green
                            : Colors.red,
                      ),
                      SizedBox(width: 12),
                      Text(mqtt.isEspOnline
                          ? 'Device Online'
                          : 'Device Offline'),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Dosis display
              Text('Dosis Saat Ini',
                  style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${status.gramasi}g',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              )),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: status.isMotorRunning
                                  ? Colors.orange[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.isMotorRunning
                                  ? 'MEMUPUK...'
                                  : 'SIAP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status.isMotorRunning
                                    ? Colors.orange[900]
                                    : Colors.green[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Statistics
              Text('Statistik',
                  style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Total Pupuk',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('${status.totalVolume}g',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Total Sesi',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('${status.totalSesi}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Rata-rata',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('${status.rataRata}g',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Controls
              ElevatedButton.icon(
                onPressed: mqtt.isConnected
                    ? () => mqtt.resetStats()
                    : null,
                icon: Icon(Icons.refresh),
                label: Text('Reset Statistik'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

**Last Updated**: 2024  
**Version**: 1.0.0

Untuk dokumentasi lebih lanjut atau bila ada pertanyaan, buat issue di GitHub repository.
