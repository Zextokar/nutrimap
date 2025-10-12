import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatelessWidget {
  final User user;
  const MapScreen({super.key, required this.user});

  // Colores del tema dark blue
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _lightBlue = Color(0xFF778DA9);
  static const Color _textPrimary = Color(0xFFE0E1DD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa"), backgroundColor: _primaryDark),
      backgroundColor: _primaryDark,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 400, // altura del recuadro donde irá el mapa
          decoration: BoxDecoration(
            color: _secondaryDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accentBlue, width: 1),
          ),
          child: Center(
            child: Text(
              "Mapa personalizado para ${user.email ?? "Usuario"}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
