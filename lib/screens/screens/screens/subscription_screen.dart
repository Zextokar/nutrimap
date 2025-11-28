import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Asegúrate de que estos archivos existen en tu proyecto o ajusta los imports
import 'mercado_pago_checkout.dart';
import 'mercado_pago_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // --- PALETA DE COLORES ---
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);
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

  // --- LÓGICA (Mantenida intacta) ---

  Future<void> _checkIfUserIsPremium() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted)
          setState(() {
            _checkingStatus = false;
            _isPremium = false;
          });
        return;
      }
      final userQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted)
          setState(() {
            _checkingStatus = false;
            _isPremium = false;
          });
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

    if (url != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MercadoPagoCheckoutPage(url: url)),
      );
    } else {
      _showSnackBar("Error al iniciar el pago.", isError: true);
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
    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Membresía",
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
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
                        _buildMembershipCard(),

                        const SizedBox(height: 40),

                        // 2. TÍTULO DE BENEFICIOS
                        Text(
                          _isPremium
                              ? "TUS BENEFICIOS ACTIVOS"
                              : "¿POR QUÉ SER PREMIUM?",
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
                          "Experiencia sin anuncios",
                          "Navega sin interrupciones.",
                        ),
                        _buildBenefitItem(
                          Icons.insights_rounded,
                          "Estadísticas Avanzadas",
                          "Histórico completo de tus actividades.",
                        ),
                        _buildBenefitItem(
                          Icons.restaurant_menu_rounded,
                          "Recetas Exclusivas",
                          "Acceso al catálogo completo de nutrición.",
                        ),
                        _buildBenefitItem(
                          Icons.support_agent_rounded,
                          "Soporte Prioritario",
                          "Atención al cliente 24/7.",
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. BOTÓN DE ACCIÓN (Sticky Bottom)
                _buildBottomAction(),
              ],
            ),
    );
  }

  Widget _buildMembershipCard() {
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
                      _isPremium ? "Miembro Premium" : "Plan Gratuito",
                      style: TextStyle(
                        color: _isPremium ? Colors.white : _textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isPremium
                          ? "Acceso total desbloqueado"
                          : "Actualiza para más beneficios",
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

  Widget _buildBottomAction() {
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
            const Text(
              "¡Gracias por tu apoyo!",
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              "Suscripción Activa",
              style: TextStyle(
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
            children: const [
              Text(
                "\$50", // Precio ejemplo
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                " / mes",
                style: TextStyle(color: _textSecondary, fontSize: 14),
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
                  : const Text(
                      "OBTENER PREMIUM",
                      style: TextStyle(
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
