import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrimap/services/activity_service.dart';
import 'package:nutrimap/widgets/activity_calendar.dart';
import 'package:nutrimap/widgets/daily_info_card.dart';
import 'package:nutrimap/widgets/stats_grid.dart';
import 'package:nutrimap/widgets/step_counter_card.dart';
import 'package:nutrimap/widgets/welcome_card.dart';

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

  String _userName = "";
  Map<int, double> _kmPerDay = {};
  bool _isLoading = true;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    final userData = await _activityService.getUserData(widget.user.uid);
    final kms = await _activityService.getMonthKms(userData['ref']);

    if (!mounted) return;
    setState(() {
      _userName = userData['name'];
      _kmPerDay = kms;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalKm = _kmPerDay.values.fold<double>(0, (a, b) => a + b);
    final daysWithData = _kmPerDay.values.where((km) => km > 0).length;
    final averageKm = daysWithData == 0 ? 0.0 : totalKm / daysWithData;
    final maxKm = _kmPerDay.values.isEmpty
        ? 0.0
        : _kmPerDay.values.reduce((a, b) => a > b ? a : b);

    const primaryDark = Color(0xFF0D1B2A);
    const accentGreen = Color(0xFF06A77D);

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Mi Actividad",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E1DD),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                DateFormat(
                  'MMM yyyy',
                  'es_ES',
                ).format(DateTime.now()).toUpperCase(),
                style: const TextStyle(
                  color: accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: accentGreen,
              backgroundColor: const Color(0xFF1B263B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    WelcomeCard(
                      userName: _userName,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 20),

                    // Aquí pasamos el UID y el callback para recargar
                    StepCounterCard(
                      userUid: widget.user.uid,
                      onSaveSuccess: _loadData, // Al guardar, recarga todo
                    ),

                    const SizedBox(height: 28),
                    ActivityCalendar(
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                    ),
                    const SizedBox(height: 28),
                    StatsGrid(
                      totalKm: totalKm,
                      daysWithData: daysWithData,
                      averageKm: averageKm,
                      maxKm: maxKm,
                    ),
                    const SizedBox(height: 28),
                    DailyInfoCard(
                      day: _selectedDay,
                      km: _kmPerDay[_selectedDay.day] ?? 0.0,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
