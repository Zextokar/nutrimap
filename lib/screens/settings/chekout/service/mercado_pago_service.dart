import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // Importante para enviar el ID del usuario

Future<String?> crearPreferenciaPago() async {
  // 1. Reemplaza con tu URL real de Vercel
  final url = Uri.parse('https://nutrimapbackend.vercel.app/api/index');

  try {
    // 2. Obtenemos el UID del usuario actual de Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // 3. Hacemos la petición a NUESTRO backend, no al de Mercado Pago directamente
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": user
            .uid, // Enviamos el UID para que el Webhook sepa a quién activar
      }),
    );

    // 4. Tu backend de Vercel devuelve 200 si todo sale bien (Mercado Pago devuelve 201)
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['init_point']; // El link para abrir el WebView
    } else {
      if (kDebugMode) {
        print('Error en el servidor: ${response.body}');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error de conexión con el backend: $e');
    }
    return null;
  }
}
