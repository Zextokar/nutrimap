import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mercado_pago_checkout.dart';
import 'mercado_pago_service.dart';

class VerificarCodigoPage extends StatefulWidget {
  const VerificarCodigoPage({super.key});

  @override
  State<VerificarCodigoPage> createState() => _VerificarCodigoPageState();
}

class _VerificarCodigoPageState extends State<VerificarCodigoPage> {
  bool _isLoading = false;
  bool _isPremium = false;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsPremium();
  }

  Future<void> _checkIfUserIsPremium() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
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

      if (suscripcionDoc.exists &&
          suscripcionDoc.data()?['suscripcion'] == true) {
        setState(() {
          _isPremium = true;
          _checkingStatus = false;
        });
      } else {
        setState(() {
          _isPremium = false;
          _checkingStatus = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      setState(() => _checkingStatus = false);
    }
  }

  void _customSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pagarPremium() async {
    setState(() => _isLoading = true);
    final url = await crearPreferenciaPago();
    setState(() => _isLoading = false);

    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MercadoPagoCheckoutPage(url: url)),
      );
    } else {
      _customSnackBar("Error al iniciar el pago.", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.deepPurpleAccent),
              const SizedBox(height: 15),
              Text(
                "Verificando estado Premium...",
                style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        title: const Text("Activar Premium"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: _isPremium
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amberAccent, size: 60),
                        const SizedBox(height: 12),
                        Text(
                          "✨ Tu cuenta ya es PREMIUM",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "¡Gracias por tu apoyo!",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Compra tu suscripción Premium",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[200],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.deepPurpleAccent,
                                  ),
                                )
                              : ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.payment,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Comprar Premium",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurpleAccent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _pagarPremium,
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
