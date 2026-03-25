import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/device_status.dart';

class MqttService extends ChangeNotifier {
  late MqttServerClient client;
  final String broker = 'broker.emqx.io';
  final int port = 8083;
  final String clientIdentifier =
      'AlburdatMobile_${DateTime.now().millisecondsSinceEpoch}';

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  DeviceStatus? _latestStatus;
  DateTime? _lastStatusTime;
  DeviceStatus? get latestStatus => _latestStatus;
  bool get isEspOnline =>
      _lastStatusTime != null &&
      DateTime.now().difference(_lastStatusTime!).inSeconds < 30;

  final _statusStreamController = StreamController<DeviceStatus>.broadcast();
  Stream<DeviceStatus> get statusStream => _statusStreamController.stream;

  static const String topicStatus = 'alburdat/status';
  static const String topicCommand = 'alburdat/command';

  // Untuk reconnection logic
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectInterval = Duration(seconds: 5);

  MqttService() {
    _initClient();
  }

  void _initClient() {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = 1883; // port TCP
    client.useWebSocket = false; // nonaktifkan WebSocket
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    _reconnectAttempts = 0;
    notifyListeners();
    debugPrint('Connecting to MQTT broker...');
    try {
      await client.connect();
    } catch (e) {
      debugPrint('Connection Exception: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      _scheduleReconnect();
      return;
    }
    _isConnecting = false;
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('MQTT connected');
      _isConnected = true;
      _reconnectAttempts = 0;
      notifyListeners();
      _subscribeToTopics();
    } else {
      debugPrint('Connection failed - disconnecting');
      client.disconnect();
      _isConnected = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _subscribeToTopics() {
    if (!_isConnected) return;
    client.subscribe(topicStatus, MqttQos.atLeastOnce);
    debugPrint('Subscribed to $topicStatus');
  }

  void _onConnected() {
    debugPrint('Connected to broker');
    _isConnected = true;
    _reconnectAttempts = 0;
    _cancelReconnectTimer();
    notifyListeners();
  }

  void _onDisconnected() {
    debugPrint('Disconnected');
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cancelReconnectTimer();
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint(
        'Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${_reconnectInterval.inSeconds}s',
      );
      _reconnectTimer = Timer(_reconnectInterval, () {
        if (!_isConnected && !_isConnecting) {
          connect();
        }
      });
    } else {
      debugPrint('Max reconnect attempts reached');
    }
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _onSubscribed(String topic) {
    debugPrint('Subscribed to $topic');
    client.updates!.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    final recMessage = messages[0].payload as MqttPublishMessage;
    final topic = messages[0].topic;
    final payload = MqttPublishPayload.bytesToStringAsString(
      recMessage.payload.message,
    );

    debugPrint('Received on $topic: $payload');

    if (topic == topicStatus) {
      try {
        final jsonData = jsonDecode(payload);
        final status = DeviceStatus.fromJson(jsonData);
        _latestStatus = status;
        _lastStatusTime = DateTime.now();
        _statusStreamController.add(status);
        notifyListeners();
      } catch (e) {
        debugPrint('JSON parse error: $e');
      }
    }
  }

  void _pong() => debugPrint('Pong received');

  void publishCommand(Map<String, dynamic> command) {
    if (!_isConnected) {
      debugPrint('Not connected');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(command));
    client.publishMessage(topicCommand, MqttQos.atLeastOnce, builder.payload!);
  }

  void setDosis(double value) => publishCommand({'set_dosis': value});
  void resetStats() => publishCommand({'reset_stats': true});
  void resetWifi() => publishCommand({'reset_wifi': true});

  void disconnect() {
    _cancelReconnectTimer();
    client.disconnect();
    _statusStreamController.close();
  }
}
