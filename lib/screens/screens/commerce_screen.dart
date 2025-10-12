import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommerceScreen extends StatelessWidget {
  final User user;
  const CommerceScreen({super.key, required this.user});

  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  Future<List<Map<String, dynamic>>> _getComerciosByDieta() async {
    try {
      // 1. Obtener datos del usuario
      final queryUser = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (queryUser.docs.isEmpty) return [];

      final userData = queryUser.docs.first.data();
      final codDieta = userData['cod_dieta'];
      if (codDieta == null) return [];

      // 2. Buscar comercios compatibles
      final dietaQuery = await FirebaseFirestore.instance
          .collection('comercio_dieta')
          .where('cod_dieta', isEqualTo: codDieta)
          .get();

      if (dietaQuery.docs.isEmpty) return [];

      // 3. Obtener detalles de los comercios
      List<Map<String, dynamic>> comercios = [];
      for (var doc in dietaQuery.docs) {
        final comercioId = doc['id_comercio'];
        final comercioDoc = await FirebaseFirestore.instance
            .collection('comercios')
            .doc(comercioId.toString())
            .get();

        if (comercioDoc.exists) {
          comercios.add(comercioDoc.data() ?? {});
        }
      }

      return comercios;
    } catch (e) {
      debugPrint("Error al obtener comercios: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _primaryDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryDark,
          centerTitle: true,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text("Comercios")),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getComerciosByDieta(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _accentBlue),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: _textSecondary),
                ),
              );
            }

            final comercios = snapshot.data ?? [];

            if (comercios.isEmpty) {
              return const Center(
                child: Text(
                  '-',
                  style: TextStyle(color: _textPrimary, fontSize: 18),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: comercios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = comercios[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentBlue, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['nombre'] ?? '-',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tel: ${c['telefono'] ?? '-'}",
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Web: ${c['web'] ?? '-'}",
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
