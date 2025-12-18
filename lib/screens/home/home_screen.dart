import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrimap/services/activity_service.dart';
import 'package:nutrimap/widgets/activity_calendar.dart';
import 'package:nutrimap/widgets/daily_info_card.dart';
import 'package:nutrimap/widgets/stats_grid.dart';
import 'package:nutrimap/widgets/step_counter_card.dart';
// Note: WelcomeCard removed in favor of integrated header design

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ActivityService _activityService = ActivityService();
  late AnimationController _animationController;

  // Colors
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  String _userName = "";
  Map<int, double> _kmPerDay = {};
  bool _isLoading = true;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userData = await _activityService.getUserData(widget.user.uid);
      final kms = await _activityService.getMonthKms(userData['ref']);

      if (!mounted) return;
      setState(() {
        _userName = userData['name'] ?? 'Usuario';
        _kmPerDay = kms;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculations
    final totalKm = _kmPerDay.values.fold<double>(0, (a, b) => a + b);
    final daysWithData = _kmPerDay.values.where((km) => km > 0).length;
    final averageKm = daysWithData == 0 ? 0.0 : totalKm / daysWithData;
    final maxKm = _kmPerDay.values.isEmpty
        ? 0.0
        : _kmPerDay.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: _primaryDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accentGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _accentGreen,
              backgroundColor: _secondaryDark,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. HEADER INTEGRADO
                  SliverToBoxAdapter(child: _buildHomeHeader()),

                  // 2. CONTENIDO PRINCIPAL
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Sección: Registro Rápido (Step Counter)
                        _HomeSection(
                          title: "REGISTRO RÁPIDO",
                          child: StepCounterCard(
                            userUid: widget.user.uid,
                            onSaveSuccess: _loadData,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sección: Calendario
                        _HomeSection(
                          title: "CALENDARIO",
                          child: ActivityCalendar(
                            focusedDay: _focusedDay,
                            selectedDay: _selectedDay,
                            onDaySelected: (selected, focused) {
                              setState(() {
                                _selectedDay = selected;
                                _focusedDay = focused;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sección: Estadísticas del Mes
                        _HomeSection(
                          title: "ESTADÍSTICAS DEL MES",
                          child: StatsGrid(
                            totalKm: totalKm,
                            daysWithData: daysWithData,
                            averageKm: averageKm,
                            maxKm: maxKm,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sección: Info del Día Seleccionado
                        _HomeSection(
                          title: "RESUMEN DEL DÍA",
                          child: DailyInfoCard(
                            day: _selectedDay,
                            km: _kmPerDay[_selectedDay.day] ?? 0.0,
                          ),
                        ),

                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHomeHeader() {
    final String dateText = DateFormat(
      'EEEE d, MMMM',
      'es_ES',
    ).format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText.toUpperCase(),
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    text: 'Hola, ',
                    style: const TextStyle(
                      fontSize: 28,
                      color: _textPrimary,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Poppins',
                    ),
                    children: [
                      TextSpan(
                        text: _userName.split(' ')[0], // Solo el primer nombre
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _accentGreen.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: _secondaryDark,
              child: Icon(Icons.person, color: _textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- WIDGETS DE DISEÑO INTERNOS ----------------

class _HomeSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _HomeSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9DB2BF), // _textSecondary
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        // Envolvemos el widget hijo en un contenedor estilizado "burbuja"
        // Esto unifica el diseño de los widgets importados (Calendar, Stats, etc.)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B263B), // _secondaryDark
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: child,
          ),
        ),
      ],
    );
  }
}
