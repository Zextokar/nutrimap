import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Colores del tema
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF06A77D);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _errorColor = Color(0xFFD90429);

  Future<String> _getUserName() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: widget.user.uid)
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
          .where('uid_auth', isEqualTo: widget.user.uid)
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
        scaffoldBackgroundColor: _primaryDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryDark,
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Mi Actividad",
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  DateFormat('MMM yyyy', 'es_ES').format(DateTime.now()),
                  style: const TextStyle(
                    color: _accentGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: FutureBuilder(
          future: Future.wait([_getUserName(), _getKmPerDay()]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: _accentGreen,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando datos...',
                      style: TextStyle(color: _textPrimary.withOpacity(0.6)),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: _errorColor, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar datos',
                      style: TextStyle(color: _textPrimary, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final name = snapshot.data?[0] ?? "Usuario";
            final kmPerDay = snapshot.data?[1] as Map<int, double>? ?? {};
            final totalKm = kmPerDay.values.fold<double>(0, (a, b) => a + b);
            final daysWithData = kmPerDay.values.where((km) => km > 0).length;
            final averageKm = daysWithData == 0 ? 0.0 : totalKm / daysWithData;
            final maxKm = kmPerDay.values.isEmpty
                ? 0.0
                : kmPerDay.values.reduce((a, b) => a > b ? a : b);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de bienvenida
                  _buildWelcomeCard(name),
                  const SizedBox(height: 28),

                  // Tarjetas de estadísticas principales
                  _buildMainStatsGrid(totalKm, daysWithData, averageKm, maxKm),
                  const SizedBox(height: 28),

                  // Gráfico de barras mensuales
                  _buildMonthlyChart(kmPerDay, maxKm),
                  const SizedBox(height: 28),

                  // Registro diario
                  _buildDailyRecordsHeader(),
                  const SizedBox(height: 12),
                  ...kmPerDay.entries.toList().reversed.map(
                    (e) => _buildDayCard(e.key, e.value, maxKm),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accentGreen, Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accentGreen.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "¡Bienvenido de vuelta!",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sigue registrando tus actividades',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsGrid(
    double totalKm,
    int daysWithData,
    double averageKm,
    double maxKm,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: [
        _buildStatCard(
          icon: Icons.route,
          label: "Total KM",
          value: totalKm.toStringAsFixed(1),
          color: _accentGreen,
          isPrimary: true,
        ),
        _buildStatCard(
          icon: Icons.calendar_today,
          label: "Días Activos",
          value: daysWithData.toString(),
          color: _accentBlue,
        ),
        _buildStatCard(
          icon: Icons.trending_up,
          label: "Promedio",
          value: averageKm.toStringAsFixed(1),
          color: Color(0xFF06A77D).withOpacity(0.8),
        ),
        _buildStatCard(
          icon: Icons.flash_on,
          label: "Máximo",
          value: maxKm.toStringAsFixed(1),
          color: Color(0xFFF4B942),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: _textPrimary.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(Map<int, double> kmPerDay, double maxKm) {
    if (kmPerDay.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: _secondaryDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentBlue.withOpacity(0.2), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Sin datos para mostrar',
            style: TextStyle(color: _textPrimary.withOpacity(0.6)),
          ),
        ),
      );
    }

    final normalizedMax = maxKm > 0 ? maxKm : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentBlue.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad Mensual',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: kmPerDay.length,
              itemBuilder: (context, index) {
                final entry = kmPerDay.entries.toList()[index];
                final day = entry.key;
                final km = entry.value;
                final height = (km / normalizedMax) * 100;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: height + 10,
                        decoration: BoxDecoration(
                          color: km > 0
                              ? _accentGreen.withOpacity(
                                  0.8 * (km / normalizedMax),
                                )
                              : _accentBlue.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day.toString(),
                        style: TextStyle(
                          color: _textPrimary.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecordsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.today, color: _accentGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Registro Diario',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(int day, double km, double maxKm) {
    final hasData = km > 0;
    final percentage = maxKm > 0 ? (km / maxKm) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasData
              ? _accentGreen.withOpacity(0.3)
              : _accentBlue.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: hasData
            ? [
                BoxShadow(
                  color: _accentGreen.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Fondo de progreso
            if (hasData)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width:
                      MediaQuery.of(context).size.width *
                      (percentage / 100) *
                      0.85,
                  decoration: BoxDecoration(
                    color: _accentGreen.withOpacity(0.1)
                  ),
                ),
              ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Día ${day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            hasData
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: hasData
                                ? _accentGreen
                                : _textPrimary.withOpacity(0.4),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasData ? 'Registrado' : 'Sin datos',
                            style: TextStyle(
                              color: hasData
                                  ? _accentGreen
                                  : _textPrimary.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${km.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: hasData
                              ? _accentGreen
                              : _textPrimary.withOpacity(0.5),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasData)
                        Text(
                          '${percentage.toStringAsFixed(0)}% del máx',
                          style: TextStyle(
                            color: _textPrimary.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
