import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/screens/home_screen.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final mqtt = context.read<MqttService>();

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed - attempting to reconnect MQTT');
        if (!mqtt.isConnected && !mqtt.isConnecting) {
          mqtt.connect();
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: HomeScreen());
  }
}
