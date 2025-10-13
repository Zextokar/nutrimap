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

  Future<Map<int, double>> _getKmPerDay() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final userQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return {};

      final userDoc = userQuery.docs.first;

      final addDataQuery = await userDoc.reference
          .collection('add_data')
          .where('fecha', isGreaterThanOrEqualTo: startOfMonth)
          .where('fecha', isLessThanOrEqualTo: endOfMonth)
          .get();

      final Map<int, double> kmPerDay = {};
      for (int i = 1; i <= endOfMonth.day; i++) {
        kmPerDay[i] = 0;
      }

      for (var doc in addDataQuery.docs) {
        final data = doc.data();
        final fecha = (data['fecha'] as Timestamp).toDate();
        final kmString = data['kms'] ?? "0";
        final km = double.tryParse(kmString.toString()) ?? 0.0;
        kmPerDay[fecha.day] = kmPerDay[fecha.day]! + km;
      }

      return kmPerDay;
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F3A),
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Mis Registros",
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        body: FutureBuilder(
          future: Future.wait([_getUserName(), _getKmPerDay()]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              );
            }

            final name = snapshot.data?[0] ?? "Usuario";
            final kmPerDay = snapshot.data?[1] as Map<int, double>? ?? {};
            final totalKm = kmPerDay.values.fold<double>(0, (a, b) => a + b);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de bienvenida
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bienvenido",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Estadísticas
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Estadísticas del Mes",
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem(
                              "Total KM",
                              totalKm.toStringAsFixed(2),
                            ),
                            _buildStatItem("Días", kmPerDay.length.toString()),
                            _buildStatItem(
                              "Promedio",
                              (kmPerDay.isEmpty ? 0 : totalKm / kmPerDay.length)
                                  .toStringAsFixed(2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detalles por día
                  const Text(
                    "Registro Diario",
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...kmPerDay.entries.map((e) => _buildDayCard(e.key, e.value)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDayCard(int day, double km) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: Color(
              0xFF10B981,
            ).withAlpha((255 * (km / 100).clamp(0, 1)).toInt()),
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Día $day",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                km > 0 ? "Registrado" : "Sin datos",
                style: TextStyle(
                  color: km > 0 ? const Color(0xFF10B981) : Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            "${km.toStringAsFixed(2)} km",
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
