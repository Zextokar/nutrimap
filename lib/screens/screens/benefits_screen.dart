import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class BenefitsScreen extends StatefulWidget {
  final User user;
  const BenefitsScreen({super.key, required this.user});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  // --- PALETA DE COLORES ---
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);
  static const Color _gold = Color(0xFFFFD700);

  // Publicidad
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Estado
  bool _isPremium = false;
  bool _loading = true;
  double _monthlyKm = 0.0;
  List<Map<String, dynamic>> _milestones = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _fetchBenefitsConfig();
    await _checkPremiumAndLoadData();
  }

  Future<void> _fetchBenefitsConfig() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('beneficios')
          .orderBy('target', descending: false)
          .get();

      if (mounted) {
        setState(() {
          _milestones = query.docs.map((doc) {
            final data = doc.data();
            return {
              'target': data['target'] ?? 0,
              'title': data['title'] ?? 'Nivel',
              'reward': data['reward'] ?? 'Recompensa sorpresa',
              'icon': _getIconFromName(data['icon_name'] ?? 'star'),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("❌ Error cargando beneficios: $e");
    }
  }

  IconData _getIconFromName(String iconName) {
    const icons = {
      'local_drink': Icons.local_drink_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'local_shipping': Icons.local_shipping_rounded,
      'health_and_safety': Icons.health_and_safety_rounded,
      'checkroom': Icons.checkroom_rounded,
      'star': Icons.star_rounded,
      'restaurant': Icons.restaurant_rounded,
      'card_giftcard': Icons.card_giftcard_rounded,
      'discount': Icons.percent_rounded,
    };
    return icons[iconName] ?? Icons.lock_open_rounded;
  }

  Future<void> _checkPremiumAndLoadData() async {
    try {
      final user = widget.user;
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userDoc = query.docs.first;
        final rutUsuario = userDoc.id;

        // Verificar Premium
        final suscripcionDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(rutUsuario)
            .collection('suscripcion')
            .doc('detalle')
            .get();

        bool premiumStatus =
            suscripcionDoc.exists &&
            suscripcionDoc.data()?['suscripcion'] == true;

        // Calcular KMs
        double totalKm = await _calculateMonthlyKm(userDoc.reference);

        if (mounted) {
          setState(() {
            _isPremium = premiumStatus;
            _monthlyKm = totalKm;
            _loading = false;
          });
        }

        if (!premiumStatus) _loadBannerAd();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<double> _calculateMonthlyKm(DocumentReference userRef) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final query = await userRef
        .collection('add_data')
        .where(
          'fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    double total = 0.0;
    for (var doc in query.docs) {
      final val = doc.data()['kms'];
      total += (val is num)
          ? val.toDouble()
          : (double.tryParse(val.toString()) ?? 0.0);
    }
    return total;
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ID de prueba Google
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  // ---------------- UI PRINCIPAL ----------------

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final currentMonthName = DateFormat('MMMM', 'es_ES').format(DateTime.now());

    // Encontrar el próximo objetivo
    int nextTarget = 0;
    for (var m in _milestones) {
      if (m['target'] > _monthlyKm) {
        nextTarget = m['target'];
        break;
      }
    }
    if (nextTarget == 0 && _milestones.isNotEmpty)
      nextTarget = _milestones.last['target'];

    return Scaffold(
      backgroundColor: _primaryDark,
      body: Stack(
        children: [
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _accentGreen),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // --- APP BAR ELÁSTICA ---
                    SliverAppBar(
                      expandedHeight: 320.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: _primaryDark,
                      elevation: 0,
                      centerTitle: true,
                      title: Text(
                        local.benefits,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 10),
                          ],
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildProgressHeader(
                          currentMonthName,
                          nextTarget,
                        ),
                      ),
                    ),

                    // --- LISTA TIMELINE DE BENEFICIOS ---
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final milestone = _milestones[index];
                          final isFirst = index == 0;
                          final isLast = index == _milestones.length - 1;
                          return _buildTimelineItem(milestone, isFirst, isLast);
                        }, childCount: _milestones.length),
                      ),
                    ),
                  ],
                ),

          // --- PUBLICIDAD FLOTANTE ---
          if (!_isPremium && _isAdLoaded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- HEADER CORREGIDO ----------------
  Widget _buildProgressHeader(String month, int nextTarget) {
    double progressPercent = nextTarget > 0
        ? (_monthlyKm / nextTarget).clamp(0.0, 1.0)
        : 0.0;
    if (_monthlyKm > nextTarget) progressPercent = 1.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_secondaryDark, _primaryDark],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: kToolbarHeight + 16), // Espacio AppBar
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progressPercent,
                  strokeWidth: 12,
                  backgroundColor: _primaryDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(_accentGreen),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: _primaryDark.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentGreen.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _monthlyKm.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "KM",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Progreso de ${month.toUpperCase()}",
            style: const TextStyle(
              color: _textSecondary,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.workspace_premium, color: _gold, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "PREMIUM MEMBER",
                    style: TextStyle(
                      color: _gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              "Siguiente meta: $nextTarget KM",
              style: TextStyle(
                color: _textPrimary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- TIMELINE ITEM ----------------
  Widget _buildTimelineItem(
    Map<String, dynamic> milestone,
    bool isFirst,
    bool isLast,
  ) {
    final int target = milestone['target'];
    final bool isUnlocked = _monthlyKm >= target;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Columna de línea de tiempo
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 3,
                    color: isFirst
                        ? Colors.transparent
                        : (isUnlocked
                              ? _accentGreen
                              : _accentBlue.withOpacity(0.3)),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUnlocked ? _accentGreen : _secondaryDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked
                          ? _accentGreen
                          : _accentBlue.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: _accentGreen.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isUnlocked ? Icons.check : Icons.lock_outline_rounded,
                    size: 20,
                    color: isUnlocked ? Colors.white : _textSecondary,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 3,
                    color: isLast
                        ? Colors.transparent
                        : (isUnlocked
                              ? _accentGreen
                              : _accentBlue.withOpacity(0.3)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? _accentGreen.withOpacity(0.05)
                      : _secondaryDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUnlocked
                        ? _accentGreen.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            milestone['icon'],
                            color: isUnlocked ? _accentGreen : _textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              milestone['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? Colors.white
                                    : _textSecondary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isUnlocked ? _accentGreen : _primaryDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${milestone['target']} KM",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? Colors.white
                                    : _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        milestone['reward'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnlocked
                              ? _textPrimary
                              : _textSecondary.withOpacity(0.6),
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_monthlyKm / milestone['target']).clamp(
                              0.0,
                              1.0,
                            ),
                            backgroundColor: Colors.black26,
                            color: _accentBlue,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Faltan ${(milestone['target'] - _monthlyKm).toStringAsFixed(1)} km",
                          style: TextStyle(
                            fontSize: 10,
                            color: _textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(
                              Icons.celebration,
                              size: 14,
                              color: _accentGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "¡Disponible!",
                              style: TextStyle(
                                color: _accentGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
