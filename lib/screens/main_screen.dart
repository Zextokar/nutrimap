import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/screens/screens/benefits_screen.dart';
import 'package:nutrimap/screens/screens/commerce_screen.dart';
import 'package:nutrimap/screens/screens/home_screen.dart';
import 'package:nutrimap/screens/screens/map_screen.dart';
import 'package:nutrimap/screens/screens/settings_screen.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  final User user; // ✅ Usuario autenticado, no puede ser null
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
    // ✅ Aseguramos que el usuario se pase correctamente a cada pantalla
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
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: local.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: local.map,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.health_and_safety),
            label: local.benefits,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            label: local.recipes,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: local.settings,
          ),
        ],
      ),
    );
  }
}
