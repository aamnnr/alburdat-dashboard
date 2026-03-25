import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alburdat_dashboard/services/mqtt_service.dart';
import 'package:alburdat_dashboard/screens/main_screen.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MqttService()..connect()),
      ],
      child: MaterialApp(
        title: 'ALBURDAT Dashboard',
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}