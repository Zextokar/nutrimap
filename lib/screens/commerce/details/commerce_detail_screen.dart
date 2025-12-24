import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/screens/maps/map_screen.dart';
import 'package:nutrimap/services/commerce_service.dart';
import 'package:nutrimap/widgets/menu_card.dart';
import 'package:nutrimap/theme/app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CommerceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> commerceData;
  const CommerceDetailScreen({super.key, required this.commerceData});

  @override
  State<CommerceDetailScreen> createState() => _CommerceDetailScreenState();
}

class _CommerceDetailScreenState extends State<CommerceDetailScreen> {
  final CommerceService _commerceService = CommerceService();
  late Future<List<Map<String, dynamic>>> _futureMenus;
  late double _currentDisplayRating;
  static const Color _gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _currentDisplayRating = (widget.commerceData['rating'] ?? 0.0).toDouble();
    if (widget.commerceData['id'] != null) {
      _futureMenus = _commerceService.getMenusByCommerce(
        widget.commerceData['id'],
      );
    } else {
      _futureMenus = Future.value([]);
    }
  }

  void _goToMap(BuildContext context) {
    final ubicacion = widget.commerceData['ubicacion'];
    if (ubicacion == null) return;

    final destination = LatLng(
      (ubicacion['lat'] as num).toDouble(),
      (ubicacion['lng'] as num).toDouble(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          user: FirebaseAuth.instance.currentUser!,
          initialDestination: destination,
          initialDestinationName: widget.commerceData['nombre'],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String commerceId) {
    int selectedStars = 5;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(239, 0, 86, 247),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              title: const Text(
                "Calificar Experiencia",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "¿Qué tal estuvo tu visita?",
                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () =>
                            setStateDialog(() => selectedStars = index + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < selectedStars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: _gold,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    selectedStars == 5
                        ? "¡Excelente!"
                        : selectedStars > 3
                        ? "Muy bien"
                        : "Podría mejorar",
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actionsPadding: const EdgeInsets.only(
                bottom: 20,
                left: 20,
                right: 20,
                top: 10,
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 1, 71, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 1, 71, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    Navigator.pop(context);
                    final success = await _commerceService.rateCommerce(
                      commerceId: commerceId,
                      userUid: user.uid,
                      rating: selectedStars.toDouble(),
                    );
                    if (mounted && success) {
                      setState(
                        () => _currentDisplayRating = selectedStars.toDouble(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("¡Gracias por tu opinión!"),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Enviar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.commerceData;

    return Scaffold(
      backgroundColor: const Color.fromARGB(80, 3, 96, 196),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- APP BAR TIPO BENEFICIOS ---
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: const Color.fromARGB(
              255,
              6,
              115,
              204,
            ), //fondo detail
            centerTitle: true,
            title: Text(
              data['nombre'] ?? 'Comercio',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Color.fromARGB(181, 7, 116, 241),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color.fromARGB(207, 19, 95, 236)), //
                  Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 100,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color.fromARGB(96, 2, 48, 92), //degradados
                          const Color.fromARGB(255, 3, 45, 90).withOpacity(0.3),
                          const Color.fromARGB(255, 8, 37, 68),
                        ],
                        stops: const [0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 1, 100, 31),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "RESTAURANTE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['nombre'] ?? 'Comercio',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                data['direccion'] ?? 'Ubicación no disponible',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta Rating tipo “Beneficios”
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(147, 2, 112, 2),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            4,
                            181,
                            235,
                          ).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: _gold,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currentDisplayRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => data['id'] != null
                                ? _showRatingDialog(context, data['id'])
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(155, 1, 60, 100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromARGB(
                                    136,
                                    11,
                                    112,
                                    1,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                "Dejar Calificación",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(113, 6, 187, 82),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: const Text(
                        "Cómo llegar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        _goToMap(context);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "Sobre el lugar",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(193, 2, 134, 13),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      data['descripcion'] ?? 'Sin descripción disponible.',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "MENÚ DISPONIBLE",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureMenus,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ),
                );
              }

              final menus = snapshot.data ?? [];
              if (menus.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        5,
                        72,
                        197,
                      ).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_meals_rounded,
                          size: 60,
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No hay menú disponible",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Este comercio aún no ha cargado su carta digital.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: MenuCard(menuData: menus[index]),
                    ),
                    childCount: menus.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
