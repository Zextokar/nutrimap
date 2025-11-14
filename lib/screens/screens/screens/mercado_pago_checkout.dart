import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MercadoPagoCheckoutPage extends StatefulWidget {
  final String url;

  const MercadoPagoCheckoutPage({required this.url, super.key});

  @override
  State<MercadoPagoCheckoutPage> createState() =>
      _MercadoPagoCheckoutPageState();
}

class _MercadoPagoCheckoutPageState extends State<MercadoPagoCheckoutPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('success')) {
              _handleSuccessPayment(context);
              return NavigationDecision.prevent;
            } else if (request.url.contains('failure')) {
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // Función para manejar la lógica de éxito
  Future<void> _handleSuccessPayment(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final rutUsuario = query.docs.first.id;
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(rutUsuario)
            .collection('suscripcion')
            .doc('detalle')
            .set({
              'suscripcion': true,
              'fecha_inicio': DateTime.now(),
              'fecha_termino': null,
              'codigo_usado': 'Pago Mercado Pago',
            });
      }
    } catch (e) {
      debugPrint('Error al actualizar la suscripción: $e');
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mercado Pago"),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
