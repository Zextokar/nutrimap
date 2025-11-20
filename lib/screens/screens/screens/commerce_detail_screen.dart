import 'package:flutter/material.dart';
import 'package:nutrimap/services/commerce_service.dart';
import 'package:nutrimap/widgets/menu_card.dart';

class CommerceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> commerceData;

  const CommerceDetailScreen({super.key, required this.commerceData});

  @override
  State<CommerceDetailScreen> createState() => _CommerceDetailScreenState();
}

class _CommerceDetailScreenState extends State<CommerceDetailScreen> {
  final CommerceService _commerceService = CommerceService();

  // Colores
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  late Future<List<Map<String, dynamic>>> _futureMenus;

  @override
  void initState() {
    super.initState();
    final commerceId = widget.commerceData['id'];

    if (commerceId != null) {
      _futureMenus = _commerceService.getMenusByCommerce(commerceId);
    } else {
      // Si por alguna razón no llega ID, retornamos lista vacía
      _futureMenus = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.commerceData;

    return Scaffold(
      backgroundColor: _primaryDark,
      body: CustomScrollView(
        slivers: [
          // 1. AppBar con efecto elástico
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: _primaryDark,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                data['nombre'] ?? 'Comercio',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Container(
                color: _secondaryDark,
                child: Center(
                  child: Icon(
                    Icons.storefront,
                    size: 80,
                    color: _textSecondary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // 2. Información del Comercio
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating y Etiqueta
                  Row(
                    children: [
                      if (data['rating'] != null) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          "${data['rating']}",
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accentGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Aliado Nutrimap",
                          style: TextStyle(color: _accentGreen, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Dirección
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: _textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['direccion'] ?? 'Sin dirección',
                          style: const TextStyle(color: _textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Descripción
                  const Text(
                    "Sobre este lugar",
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['descripcion'] ?? 'Sin descripción disponible.',
                    style: TextStyle(
                      color: _textPrimary.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: _textSecondary),
                  const SizedBox(height: 16),

                  const Text(
                    "Menú Disponible",
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Lista de Menús
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureMenus,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: _accentGreen),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      "Error cargando menú",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final menus = snapshot.data ?? [];

              // --- LÓGICA DE LISTA VACÍA ---
              if (menus.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.no_meals_rounded,
                          size: 60,
                          color: _textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No hay menús disponibles",
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Este comercio aún no ha cargado su carta digital.",
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // --- LISTA DE MENÚS ---
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: MenuCard(menuData: menus[index]),
                  );
                }, childCount: menus.length),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
