import 'package:flutter/material.dart';
import 'package:alburdat_dashboard/screens/dashboard_page.dart';
import 'package:alburdat_dashboard/screens/rekomendasi_page.dart';
import 'package:alburdat_dashboard/screens/manual_page.dart';
import 'package:alburdat_dashboard/screens/wifi_page.dart';
import 'package:alburdat_dashboard/screens/info_page.dart';
import 'package:alburdat_dashboard/theme/theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    RekomendasiPage(),
    ManualPage(),
    WifiPage(),
    InfoPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_rounded),
            label: 'Rekomendasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake_rounded),
            label: 'Manual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi_rounded),
            label: 'WiFi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_rounded),
            label: 'Info',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textGrey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceLight,
        elevation: 8,
      ),
    );
  }
}
