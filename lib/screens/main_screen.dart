import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:nutrimap/l10n/app_localizations.dart';
import 'package:nutrimap/screens/benefits/benefits_screen.dart';
import 'package:nutrimap/screens/commerce/commerce_screen.dart';
import 'package:nutrimap/screens/home/home_screen.dart';
import 'package:nutrimap/screens/maps/map_screen.dart';
import 'package:nutrimap/screens/settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final User user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  bool _adsInitialized = false;

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

    // Inicializa Ads después del primer frame (no bloquea UI)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAds();
    });
  }

  Future<void> _initAds() async {
    if (_adsInitialized) return;
    _adsInitialized = true;

    await MobileAds.instance.initialize();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
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
        selectedItemColor: const Color.fromARGB(148, 23, 192, 1),
        unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
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
