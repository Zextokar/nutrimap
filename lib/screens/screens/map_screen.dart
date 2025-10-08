import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatelessWidget {
  final User user;
  const MapScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mapa")),
      body: Center(
        child: Text("Mapa personalizado para ${user.email ?? "Usuario"}"),
      ),
    );
  }
}
