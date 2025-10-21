import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommerceScreen extends StatefulWidget {
  final User user;
  const CommerceScreen({super.key, required this.user});

  @override
  State<CommerceScreen> createState() => _CommerceScreenState();
}

class _CommerceScreenState extends State<CommerceScreen> {
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  late Future<List<Map<String, dynamic>>> _futureComercios;

  @override
  void initState() {
    super.initState();
    _futureComercios = _getComerciosByDieta();
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureComercios = _getComerciosByDieta();
    });
  }

  Future<List<Map<String, dynamic>>> _getComerciosByDieta() async {
    try {
      // 1️⃣ Obtener el usuario actual
      final queryUser = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: widget.user.uid)
          .limit(1)
          .get();

      if (queryUser.docs.isEmpty) return [];

      final userData = queryUser.docs.first.data();
      final codDieta = userData['cod_dieta'];

      if (codDieta == null || codDieta.isEmpty) return [];

      // 2️⃣ Consultar comercios compatibles
      final comercioQuery = await FirebaseFirestore.instance
          .collection('comercios')
          .where('dietas_compatibles', arrayContains: codDieta)
          .get();

      // 3️⃣ Convertir a lista
      return comercioQuery.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("❌ Error al obtener comercios: $e");
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
        appBar: AppBar(
          title: const Text("Comercios"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureComercios,
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
              return RefreshIndicator(
                color: _accentBlue,
                onRefresh: _refreshData,
                child: ListView(
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        'No se encontraron comercios compatibles con tu dieta.',
                        style: TextStyle(color: _textPrimary, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ✅ Aquí añadimos el RefreshIndicator
            return RefreshIndicator(
              color: _accentBlue,
              onRefresh: _refreshData,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: comercios.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = comercios[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _secondaryDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentBlue, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['nombre'] ?? '-',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['descripcion'] ?? '',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c['direccion'] ?? '-',
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (c['rating'] != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  Text(
                                    "${c['rating']}",
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
