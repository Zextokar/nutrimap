import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/screens/settings/chekout/providers/mercado_pago_checkout.dart';
import 'package:nutrimap/screens/settings/chekout/service/mercado_pago_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // --- PALETA DE COLORES ---
  static const Color _primaryDark = Color.fromARGB(197, 3, 68, 165);
  static const Color _secondaryDark = Color.fromARGB(255, 2, 49, 136);
  static const Color _accentGreen = Color.fromARGB(255, 3, 160, 37);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color.fromARGB(255, 212, 212, 212);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _goldDark = Color(0xFFFFA000);

  bool _isLoading = false;
  bool _isPremium = false;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsPremium();
  }

  // --- LÓGICA ---
  Future<void> _checkIfUserIsPremium() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _checkingStatus = false;
            _isPremium = false;
          });
        }
        return;
      }

      final userQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _checkingStatus = false;
            _isPremium = false;
          });
        }
        return;
      }

      final rutUsuario = userQuery.docs.first.id;
      final suscripcionDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(rutUsuario)
          .collection('suscripcion')
          .doc('detalle')
          .get();

      if (mounted) {
        setState(() {
          _isPremium =
              suscripcionDoc.exists &&
              suscripcionDoc.data()?['suscripcion'] == true;
          _checkingStatus = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  Future<void> _pagarPremium() async {
    setState(() => _isLoading = true);
    final url = await crearPreferenciaPago(); // Tu función existente
    setState(() => _isLoading = false);

    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    if (url != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MercadoPagoCheckoutPage(url: url)),
      );
    } else {
      _showSnackBar(
        isSpanish ? "Error al iniciar el pago." : "Failed to start payment.",
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError ? const Color(0xFFEF476F) : _accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ---------------- UI DISEÑADA ----------------
  @override
  Widget build(BuildContext context) {
    final bool isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isSpanish ? "Membresía" : "Membership",
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _checkingStatus
          ? const Center(child: CircularProgressIndicator(color: _accentGreen))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // 1. LA TARJETA DIGITAL (Hero Widget)
                        _buildMembershipCard(isSpanish),

                        const SizedBox(height: 40),

                        // 2. TÍTULO DE BENEFICIOS
                        Text(
                          _isPremium
                              ? (isSpanish
                                    ? "TUS BENEFICIOS ACTIVOS"
                                    : "YOUR ACTIVE BENEFITS")
                              : (isSpanish
                                    ? "¿POR QUÉ SER PREMIUM?"
                                    : "WHY GO PREMIUM?"),
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. LISTA DE BENEFICIOS
                        _buildBenefitItem(
                          Icons.block_rounded,
                          isSpanish
                              ? "Experiencia sin anuncios"
                              : "Ad-free experience",
                          isSpanish
                              ? "Navega sin interrupciones."
                              : "Browse without interruptions.",
                        ),
                        _buildBenefitItem(
                          Icons.insights_rounded,
                          isSpanish
                              ? "Estadísticas Avanzadas"
                              : "Advanced statistics",
                          isSpanish
                              ? "Histórico completo de tus actividades."
                              : "Full history of your activities.",
                        ),
                        _buildBenefitItem(
                          Icons.restaurant_menu_rounded,
                          isSpanish
                              ? "Recetas Exclusivas"
                              : "Exclusive recipes",
                          isSpanish
                              ? "Acceso al catálogo completo de nutrición."
                              : "Access the full nutrition catalog.",
                        ),
                        _buildBenefitItem(
                          Icons.support_agent_rounded,
                          isSpanish
                              ? "Soporte Prioritario"
                              : "Priority support",
                          isSpanish
                              ? "Atención al cliente 24/7."
                              : "24/7 customer support.",
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. BOTÓN DE ACCIÓN (Sticky Bottom)
                _buildBottomAction(isSpanish),
              ],
            ),
    );
  }

  Widget _buildMembershipCard(bool isSpanish) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _isPremium
                ? _gold.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isPremium
              ? [_gold, _goldDark] // Gradiente Dorado
              : [_secondaryDark, _primaryDark], // Gradiente Oscuro
        ),
      ),
      child: Stack(
        children: [
          // Patrón decorativo de fondo (Círculos sutiles)
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),

          // Contenido de la tarjeta
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo o Nombre App
                    Row(
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          color: _isPremium ? Colors.white : _textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "NUTRIMAP",
                          style: TextStyle(
                            color: _isPremium ? Colors.white : _textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    // Chip de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        _isPremium ? "GOLD" : "FREE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPremium
                          ? (isSpanish ? "Miembro Premium" : "Premium Member")
                          : (isSpanish ? "Plan Gratuito" : "Free Plan"),
                      style: TextStyle(
                        color: _isPremium ? Colors.white : _textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isPremium
                          ? (isSpanish
                                ? "Acceso total desbloqueado"
                                : "Full access unlocked")
                          : (isSpanish
                                ? "Actualiza para más beneficios"
                                : "Upgrade for more benefits"),
                      style: TextStyle(
                        color: _isPremium
                            ? Colors.white.withOpacity(0.9)
                            : _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _secondaryDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPremium ? _gold.withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              color: _isPremium ? _gold : _accentGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_isPremium)
            const Icon(Icons.check_circle_rounded, color: _gold, size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isSpanish) {
    if (_isPremium) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _secondaryDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              isSpanish ? "¡Gracias por tu apoyo!" : "Thanks for your support!",
              style: const TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              isSpanish ? "Suscripción Activa" : "Active Subscription",
              style: const TextStyle(
                color: _accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "\$50",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isSpanish ? " / mes" : " / month",
                style: const TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _pagarPremium,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isSpanish ? "OBTENER PREMIUM" : "GET PREMIUM",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
