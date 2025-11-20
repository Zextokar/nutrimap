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
  // Publicidad
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Estado
  bool _isPremium = false;
  bool _loading = true;
  double _monthlyKm = 0.0;

  // Lista dinámica de beneficios
  List<Map<String, dynamic>> _milestones = [];

  // Colores
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _lockedGrey = Color(0xFF415A77);
  static const Color _textPrimary = Color(0xFFE0E1DD);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 1. Cargar la configuración de beneficios (Metas y Premios)
    await _fetchBenefitsConfig();

    // 2. Cargar el progreso del usuario
    await _checkPremiumAndLoadData();
  }

  /// Obtiene la lista de beneficios desde Firestore
  Future<void> _fetchBenefitsConfig() async {
    try {
      // Consulta a la colección 'beneficios' ordenada por meta
      final query = await FirebaseFirestore.instance
          .collection('beneficios')
          .orderBy('target', descending: false)
          .get();

      if (query.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _milestones = query.docs.map((doc) {
              final data = doc.data();
              return {
                'target': data['target'] ?? 0,
                'title': data['title'] ?? 'Nivel',
                'reward': data['reward'] ?? 'Recompensa sorpresa',
                // Convertimos el string del nombre del icono a un IconData real
                'icon': _getIconFromName(data['icon_name'] ?? 'star'),
              };
            }).toList();
          });
        }
      } else {
        debugPrint("⚠️ Colección 'beneficios' vacía.");
        if (mounted) setState(() => _milestones = []);
      }
    } catch (e) {
      debugPrint("❌ Error cargando configuración de beneficios: $e");
      // En caso de error, lista vacía (sin datos por defecto)
      if (mounted) setState(() => _milestones = []);
    }
  }

  /// Mapea nombres de iconos (String) a IconData de Flutter
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'local_drink':
        return Icons.local_drink;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'checkroom':
        return Icons.checkroom;
      case 'star':
        return Icons.star;
      case 'restaurant':
        return Icons.restaurant;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'discount':
        return Icons.percent;
      default:
        return Icons.lock_open;
    }
  }

  Future<void> _checkPremiumAndLoadData() async {
    try {
      final user = widget.user;

      // Buscar usuario
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

        // Calcular KMs del mes actual
        double totalKm = await _calculateMonthlyKm(userDoc.reference);

        if (mounted) {
          setState(() {
            _isPremium = premiumStatus;
            _monthlyKm = totalKm;
            _loading = false;
          });
        }

        if (!premiumStatus) {
          _loadBannerAd();
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ Error cargando datos usuario: $e');
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
      final data = doc.data();
      final rawKm = data['kms'];
      double km = 0.0;
      if (rawKm is num) {
        km = rawKm.toDouble();
      } else if (rawKm is String) {
        km = double.tryParse(rawKm) ?? 0.0;
      }
      total += km;
    }
    return total;
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Error cargando anuncio: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final currentMonthName = DateFormat('MMMM', 'es_ES').format(DateTime.now());

    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        title: Text(
          local.benefits,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accentGreen))
          : Column(
              children: [
                // 🔹 CABECERA DE PROGRESO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _secondaryDark,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Progreso de ${currentMonthName.toUpperCase()}",
                        style: TextStyle(
                          color: _textPrimary.withOpacity(0.7),
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_monthlyKm.toStringAsFixed(1)} KM",
                        style: const TextStyle(
                          color: _accentGreen,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPremium ? "✨ Usuario Premium" : "Usuario Estándar",
                        style: TextStyle(
                          color: _isPremium
                              ? Colors.amber
                              : _textPrimary.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 LISTA DE BENEFICIOS
                Expanded(
                  child: _milestones.isEmpty
                      ? Center(
                          child: Text(
                            "No hay beneficios configurados.",
                            style: TextStyle(
                              color: _textPrimary.withOpacity(0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _milestones.length,
                          itemBuilder: (context, index) {
                            final milestone = _milestones[index];
                            return _buildMilestoneCard(milestone);
                          },
                        ),
                ),

                // 🔹 ANUNCIO
                if (!_isPremium && _isAdLoaded)
                  Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: _bannerAd!.size.height.toDouble(),
                    color: Colors.black,
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    final int target = milestone['target']; // Meta en KM
    final bool isUnlocked = _monthlyKm >= target;
    final double progress = (_monthlyKm / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isUnlocked ? _accentGreen.withOpacity(0.1) : _secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? _accentGreen : _lockedGrey.withOpacity(0.3),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked ? _accentGreen : _lockedGrey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked
                    ? (milestone['icon'] as IconData)
                    : Icons.lock_outline,
                color: isUnlocked
                    ? Colors.white
                    : _textPrimary.withOpacity(0.5),
              ),
            ),
            title: Text(
              milestone['title'],
              style: TextStyle(
                color: isUnlocked ? _accentGreen : _textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  milestone['reward'],
                  style: TextStyle(
                    color: isUnlocked
                        ? Colors.white
                        : _textPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$target KM",
                  style: TextStyle(
                    color: isUnlocked
                        ? _accentGreen
                        : _textPrimary.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (!isUnlocked)
                  Text(
                    "Faltan ${(target - _monthlyKm).toStringAsFixed(1)}",
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),

          if (!isUnlocked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.black26,
                  color: _accentGreen.withOpacity(0.7),
                  minHeight: 6,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: _accentGreen,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                "¡DESBLOQUEADO!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
