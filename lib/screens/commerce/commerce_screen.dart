import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/screens/commerce/details/commerce_detail_screen.dart';
import 'package:nutrimap/services/commerce_service.dart';
import 'package:nutrimap/widgets/commerce_card.dart';

class CommerceScreen extends StatefulWidget {
  final User user;
  const CommerceScreen({super.key, required this.user});

  @override
  State<CommerceScreen> createState() => _CommerceScreenState();
}

class _CommerceScreenState extends State<CommerceScreen> {
  final CommerceService _commerceService = CommerceService();

  static const Color _primaryDark = Color.fromARGB(206, 3, 64, 177);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  late Future<List<Map<String, dynamic>>> _futureComercios;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureComercios = _commerceService.getComerciosByUser(widget.user.uid);
    });
  }

  Future<void> _refreshData() async {
    _loadData();
    await _futureComercios;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Detecta idioma actual: "es" o "en"
    final localeCode = Localizations.localeOf(context).languageCode;
    final bool isSpanish = localeCode == 'es';

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _primaryDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryDark,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isSpanish ? "Comercios Aliados" : "Partner Businesses",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureComercios,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 5, 87, 180),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  isSpanish ? 'Error al cargar datos' : 'Error loading data',
                  style: const TextStyle(color: _textSecondary),
                ),
              );
            }

            final comercios = snapshot.data ?? [];

            if (comercios.isEmpty) {
              return RefreshIndicator(
                color: const Color.fromARGB(255, 255, 255, 255),
                onRefresh: _refreshData,
                child: ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 60,
                            color: _textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isSpanish
                                ? 'No encontramos comercios para tu dieta.'
                                : "We couldn't find businesses for your diet.",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: _accentBlue,
              onRefresh: _refreshData,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: comercios.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final comercio = comercios[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CommerceDetailScreen(commerceData: comercio),
                        ),
                      );
                    },
                    child: CommerceCard(data: comercio),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
