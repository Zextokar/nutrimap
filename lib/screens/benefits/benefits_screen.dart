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
  static const Color _primaryDark = Color.fromARGB(206, 5, 81, 221);
  static const Color _secondaryDark = Color.fromARGB(123, 1, 180, 10);
  static const Color _accentGreen = Color.fromARGB(206, 0, 180, 120);
  static const Color _accentBlue = Color.fromARGB(255, 2, 129, 12); // lineas
  static const Color _textPrimary = Color.fromARGB(255, 255, 255, 255);
  static const Color _textSecondary = Color.fromARGB(255, 255, 255, 255);

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
    setState(() => _loading = true);
    try {
      await Future.wait([_fetchBenefitsConfig(), _checkPremiumAndLoadData()]);
    } catch (e) {
      debugPrint("❌ Error inicializando datos: $e");
    }
    if (mounted) setState(() => _loading = false);
  }

  // ---------------- FIRESTORE ----------------
  Future<void> _fetchBenefitsConfig() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('beneficios')
          .orderBy('target', descending: false)
          .get();

      if (!mounted) return;

      setState(() {
        _milestones = query.docs.map((doc) {
          final data = doc.data();
          final rawTarget = data['target'] ?? 0;
          final target = (rawTarget is num) ? rawTarget.toDouble() : 0.0;

          // ✅ viene desde tu seed: premium_only: ...
          final bool premiumOnly = data['premium_only'] == true;

          return {
            'target': target,

            // textos base ES (los que ya tienes)
            'title': data['title'] ?? 'Nivel',
            'reward': data['reward'] ?? 'Recompensa sorpresa',

            // ✅ textos EN (si los agregas en Firestore)
            'title_en': data['title_en'],
            'reward_en': data['reward_en'],

            'icon': _getIconFromName(data['icon_name'] ?? 'star'),
            'premiumOnly': premiumOnly,
          };
        }).toList();
      });
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

        final suscripcionDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(rutUsuario)
            .collection('suscripcion')
            .doc('detalle')
            .get();

        final bool premiumStatus =
            suscripcionDoc.exists &&
            suscripcionDoc.data()?['suscripcion'] == true;

        final double totalKm = await _calculateMonthlyKm(userDoc.reference);

        if (mounted) {
          setState(() {
            _isPremium = premiumStatus;
            _monthlyKm = totalKm;
            _loading = false;
          });
        }

        // ✅ Mantener anuncios para FREE
        if (!premiumStatus) _loadBannerAd();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("❌ Error verificando usuario: $e");
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
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          debugPrint("❌ Error cargando banner: $error");
          ad.dispose();
        },
      ),
    )..load();
  }

  // ---------------- PREMIUM UI ----------------
  BoxDecoration _lockedPremiumDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(255, 1, 109, 19).withOpacity(0.85),
          const Color.fromARGB(255, 12, 12, 12).withOpacity(0.90),
          const Color.fromARGB(255, 0, 0, 0).withOpacity(0.92),
        ],
        stops: const [0.0, 0.55, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  String _pickText({
    required bool isEnglish,
    required dynamic es,
    required dynamic en,
    required String fallback,
  }) {
    final esText = (es is String && es.trim().isNotEmpty) ? es : fallback;
    final enText = (en is String && en.trim().isNotEmpty) ? en : null;
    return isEnglish ? (enText ?? esText) : esText;
  }

  // ---------------- UTILIDADES ----------------
  List<Map<String, dynamic>> _milestonesWithStatus() {
    return _milestones.map((m) {
      final target = (m['target'] is num)
          ? (m['target'] as num).toDouble()
          : 0.0;

      final bool premiumOnly = (m['premiumOnly'] == true);
      final bool unlockedByKm = (_monthlyKm + 0.0001) >= target;
      final bool lockedByPremium = premiumOnly && !_isPremium;
      final bool isUnlocked = unlockedByKm && !lockedByPremium;

      return {
        ...m,
        'target': target,
        'isUnlocked': isUnlocked,
        'lockedByPremium': lockedByPremium,
      };
    }).toList();
  }

  int _nextTarget() {
    // no considerar premium_only si NO es premium
    for (final m in _milestonesWithStatus()) {
      final target = (m['target'] as num).toDouble();
      final lockedByPremium = m['lockedByPremium'] == true;
      if (lockedByPremium) continue;
      if (_monthlyKm < target) return target.toInt();
    }
    return _milestones.isNotEmpty
        ? (_milestones.last['target'] as num).toInt()
        : 0;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    final localeCode = Localizations.localeOf(context).languageCode;
    final bool isSpanish = localeCode == 'es';
    final bool isEnglish = localeCode == 'en';

    final currentMonthName = DateFormat(
      'MMMM',
      isSpanish ? 'es_ES' : 'en_US',
    ).format(DateTime.now());

    final milestonesWithStatus = _milestonesWithStatus();
    final nextTarget = _nextTarget();

    return Scaffold(
      backgroundColor: _primaryDark,
      body: RefreshIndicator(
        color: _accentGreen,
        onRefresh: _initData,
        child: Stack(
          children: [
            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _accentGreen),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
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
                            month: currentMonthName,
                            nextTarget: nextTarget,
                            isSpanish: isSpanish,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final milestone = milestonesWithStatus[index];
                            final isFirst = index == 0;
                            final isLast =
                                index == milestonesWithStatus.length - 1;

                            return _buildTimelineItem(
                              milestone,
                              isFirst,
                              isLast,
                              isSpanish: isSpanish,
                              isEnglish: isEnglish,
                            );
                          }, childCount: milestonesWithStatus.length),
                        ),
                      ),
                    ],
                  ),

            // ✅ ADS (se mantienen)
            if (!_isPremium && _isAdLoaded)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: Colors.black,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    alignment: Alignment.center,
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader({
    required String month,
    required int nextTarget,
    required bool isSpanish,
  }) {
    double progressPercent = nextTarget > 0
        ? (_monthlyKm / nextTarget).clamp(0.0, 1.0)
        : 0.0;
    if (_monthlyKm >= nextTarget) progressPercent = 1.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(115, 2, 67, 165),
            Color.fromARGB(255, 38, 78, 151),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: kToolbarHeight + 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progressPercent,
                  strokeWidth: 12,
                  backgroundColor: const Color.fromARGB(206, 255, 255, 255),
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
            isSpanish
                ? "PROGRESO DE ${month.toUpperCase()}"
                : "PROGRESS OF ${month.toUpperCase()}",
            style: const TextStyle(
              color: _textSecondary,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSpanish
                ? "Siguiente meta: $nextTarget KM"
                : "Next goal: $nextTarget KM",
            style: TextStyle(
              color: _textPrimary.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    Map<String, dynamic> milestone,
    bool isFirst,
    bool isLast, {
    required bool isSpanish,
    required bool isEnglish,
  }) {
    final int target = (milestone['target'] as num).toInt();
    final bool isUnlocked = milestone['isUnlocked'] as bool;
    final bool lockedByPremium = milestone['lockedByPremium'] == true;

    // ✅ Textos según idioma (si tienes title_en/reward_en, los usará)
    final title = _pickText(
      isEnglish: isEnglish,
      es: milestone['title'],
      en: milestone['title_en'],
      fallback: 'Nivel',
    );
    final reward = _pickText(
      isEnglish: isEnglish,
      es: milestone['reward'],
      en: milestone['reward_en'],
      fallback: 'Recompensa',
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    isUnlocked
                        ? Icons.check
                        : (lockedByPremium
                              ? Icons.lock_rounded
                              : Icons.lock_outline_rounded),
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
                decoration: lockedByPremium
                    ? _lockedPremiumDecoration()
                    : BoxDecoration(
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
                            color: isUnlocked
                                ? _accentGreen
                                : (lockedByPremium
                                      ? Colors.white.withOpacity(0.65)
                                      : _textSecondary),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? Colors.white
                                    : Colors.white.withOpacity(
                                        lockedByPremium ? 0.85 : 1.0,
                                      ),
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
                              "$target KM",
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
                        reward,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnlocked
                              ? _textPrimary
                              : _textSecondary.withOpacity(
                                  lockedByPremium ? 0.70 : 0.6,
                                ),
                        ),
                      ),
                      if (lockedByPremium) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isSpanish
                                    ? "Se necesita suscripción para acceder a beneficios"
                                    : "Subscription required to access benefits",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!isUnlocked && !lockedByPremium) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_monthlyKm / target).clamp(0.0, 1.0),
                            backgroundColor: Colors.black26,
                            color: _accentBlue,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSpanish
                              ? "Faltan ${(_monthlyKm < target ? target - _monthlyKm : 0).toStringAsFixed(1)} km"
                              : "${(_monthlyKm < target ? target - _monthlyKm : 0).toStringAsFixed(1)} km remaining",
                          style: TextStyle(
                            fontSize: 10,
                            color: _textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ] else if (isUnlocked) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.celebration,
                              size: 14,
                              color: _accentGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSpanish ? "¡Disponible!" : "Available!",
                              style: const TextStyle(
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
