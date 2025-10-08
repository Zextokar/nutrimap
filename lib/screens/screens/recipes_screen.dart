import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipesScreen extends StatelessWidget {
  final User user;
  const RecipesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recetas")),
      body: Center(
        child: Text("Recetas recomendadas para ${user.email ?? "Usuario"}"),
      ),
    );
  }
}
