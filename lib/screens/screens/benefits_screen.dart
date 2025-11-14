import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class BenefitsScreen extends StatefulWidget {
  final User user;
  const BenefitsScreen({super.key, required this.user});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isPremium = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final user = widget.user;

      // 🔍 Busca por uid_auth (no por el doc ID)
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userDoc = query.docs.first;
        final rutUsuario = userDoc.id;

        // 🔥 Verificar si tiene suscripción activa
        final suscripcionDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(rutUsuario)
            .collection('suscripcion')
            .doc('detalle')
            .get();

        setState(() {
          _isPremium =
              suscripcionDoc.exists &&
              suscripcionDoc.data()?['suscripcion'] == true;
          _loading = false;
        });

        if (!_isPremium) {
          _loadBannerAd();
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ Error verificando premium: $e');
      setState(() => _loading = false);
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // 👈 Banner de prueba
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
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

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(local.benefits)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Text(
                _isPremium
                    ? "✨ ${local.user} ${widget.user.email ?? ''} es usuario PREMIUM"
                    : local.benefitsUser(widget.user.email ?? local.user),
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (!_isPremium && _isAdLoaded)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
