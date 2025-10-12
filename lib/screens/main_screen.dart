import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/screens/screens/benefits_screen.dart';
import 'package:nutrimap/screens/screens/commerce_screen.dart';
import 'package:nutrimap/screens/screens/home_screen.dart';
import 'package:nutrimap/screens/screens/map_screen.dart';
import 'package:nutrimap/screens/screens/settings_screen.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  final User user; // ✅ Ahora es el User de Firebase
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(user: widget.user),
      MapScreen(user: widget.user),
      BenefitsScreen(user: widget.user),
      CommerceScreen(user: widget.user),
      SettingsScreen(user: widget.user),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: local.home),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: local.map),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: local.benefits,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: local.recipes,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: local.settings,
          ),
        ],
      ),
    );
  }
}
