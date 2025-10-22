import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Datos cargados
  late String _userName = "";
  Map<int, double> _kmPerDay = {};
  bool _isLoading = true;

  // Día seleccionado en el calendario
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Colores
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF06A77D);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _errorColor = Color(0xFFD90429);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _userName = await _getUserName();
    _kmPerDay = await _getKmPerDay();
    setState(() => _isLoading = false);
  }

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

      Map<int, double> kmPerDay = {};
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalKm = _kmPerDay.values.fold<double>(0, (a, b) => a + b);
    final daysWithData = _kmPerDay.values.where((km) => km > 0).length;
    final averageKm = daysWithData == 0 ? 0.0 : totalKm / daysWithData;
    final maxKm = _kmPerDay.values.isEmpty
        ? 0.0
        : _kmPerDay.values.reduce((a, b) => a > b ? a : b);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
                  DateFormat('MMM yyyy', 'es_ES').format(now),
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
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _accentGreen),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(_userName),
                      const SizedBox(height: 28),
                      _buildCalendar(),
                      const SizedBox(height: 28),
                      _buildMainStatsGrid(
                        totalKm,
                        daysWithData,
                        averageKm,
                        maxKm,
                      ),
                      const SizedBox(height: 28),
                      _buildDailyInfo(_selectedDay),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ---------------- Widget Bienvenida ----------------
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Calendario ----------------
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime(DateTime.now().year, DateTime.now().month, 1),
      lastDay: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: _accentGreen,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: _accentBlue,
          shape: BoxShape.circle,
        ),
        defaultTextStyle: TextStyle(color: _textPrimary),
        weekendTextStyle: TextStyle(color: _textPrimary.withOpacity(0.7)),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
    );
  }

  // ---------------- Estadísticas Principales ----------------
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
          color: _accentGreen.withOpacity(0.8),
        ),
        _buildStatCard(
          icon: Icons.flash_on,
          label: "Máximo",
          value: maxKm.toStringAsFixed(1),
          color: const Color(0xFFF4B942),
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

  // ---------------- Info Diario ----------------
  Widget _buildDailyInfo(DateTime day) {
    final km = _kmPerDay[day.day] ?? 0.0;
    final hasData = km > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData
              ? _accentGreen.withOpacity(0.3)
              : _accentBlue.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Día ${day.day.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'Distancia recorrida: ${km.toStringAsFixed(1)} km'
                : 'Sin datos para este día',
            style: TextStyle(
              color: _textPrimary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
