import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/screens/auth/login_screen.dart';
import 'package:nutrimap/screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading mientras se verifica
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Usuario logueado
        if (snapshot.hasData && snapshot.data != null) {
          return MainScreen(user: snapshot.data!);
        }

        // Usuario no logueado
        return const LoginScreen();
      },
    );
  }
}
