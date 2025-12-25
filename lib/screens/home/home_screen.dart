import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrimap/services/activity_service.dart';
import 'package:nutrimap/widgets/activity_calendar.dart';
import 'package:nutrimap/widgets/daily_info_card.dart';
import 'package:nutrimap/widgets/stats_grid.dart';
import 'package:nutrimap/widgets/step_counter_card.dart';

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

  static const Color _primaryDark = Color.fromARGB(235, 2, 70, 173);
  static const Color _secondaryDark = Color.fromARGB(213, 6, 76, 206);
  static const Color _accentGreen = Color.fromARGB(255, 255, 255, 255);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color.fromARGB(255, 255, 255, 255);

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
    // DETECCIÓN DE IDIOMA
    final bool isSpanish = Localizations.localeOf(context).languageCode == 'es';

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
                  SliverToBoxAdapter(child: _buildHomeHeader(isSpanish)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _HomeSection(
                          title: isSpanish ? "REGISTRO RÁPIDO" : "QUICK LOG",
                          backgroundColor: _secondaryDark,
                          child: StepCounterCard(
                            userUid: widget.user.uid,
                            onSaveSuccess: _loadData,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _HomeSection(
                          title: isSpanish ? "CALENDARIO" : "CALENDAR",
                          backgroundColor: _secondaryDark,
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
                        _HomeSection(
                          title: isSpanish
                              ? "ESTADÍSTICAS DEL MES"
                              : "MONTHLY STATS",
                          backgroundColor: _secondaryDark,
                          child: StatsGrid(
                            totalKm: totalKm,
                            daysWithData: daysWithData,
                            averageKm: averageKm,
                            maxKm: maxKm,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _HomeSection(
                          title: isSpanish ? "RESUMEN DEL DÍA" : "DAY SUMMARY",
                          backgroundColor: _secondaryDark,
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

  Widget _buildHomeHeader(bool isSpanish) {
    final String dateText = DateFormat(
      'EEEE d, MMMM',
      isSpanish ? 'es_ES' : 'en_US',
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
                    text: isSpanish ? 'Hola, ' : 'Hello, ',
                    style: const TextStyle(
                      fontSize: 28,
                      color: _textPrimary,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Poppins',
                    ),
                    children: [
                      TextSpan(
                        text: _userName.isEmpty
                            ? (isSpanish ? 'Usuario' : 'User')
                            : _userName.split(' ')[0],
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
              backgroundColor: Color.fromARGB(244, 1, 131, 40),
              child: Icon(Icons.person, color: Color.fromARGB(248, 6, 42, 201)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Color backgroundColor;

  const _HomeSection({
    required this.title,
    required this.child,
    required this.backgroundColor,
  });

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
              color: Color(0xFF9DB2BF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.2),
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
