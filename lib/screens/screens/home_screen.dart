import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  Future<String> _getUserName() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return "Usuario";

      final data = query.docs.first.data();
      return "${data['nombre'] ?? ''} ${data['apellido'] ?? ''}".trim();
    } catch (e) {
      return "Usuario";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: FutureBuilder<String>(
          future: _getUserName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            final name = snapshot.data ?? "Usuario";
            return Text(
              "Bienvenido, $name",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            );
          },
        ),
      ),
    );
  }
}
