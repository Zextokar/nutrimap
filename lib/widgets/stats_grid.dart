import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  final double totalKm;
  final int daysWithData;
  final double averageKm;
  final double maxKm;

  const StatsGrid({
    super.key,
    required this.totalKm,
    required this.daysWithData,
    required this.averageKm,
    required this.maxKm,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16, // Espaciado un poco mayor
      mainAxisSpacing: 16,
      childAspectRatio: 1.1, // Tarjetas ligeramente más anchas
      children: [
        _buildStatCard(
          icon: Icons.route_rounded,
          label: "Total KM",
          value: totalKm.toStringAsFixed(1),
          color: const Color(0xFF2D9D78), // Verde menta
        ),
        _buildStatCard(
          icon: Icons.calendar_today_rounded,
          label: "Días Activos",
          value: daysWithData.toString(),
          color: const Color(0xFF415A77), // Azul grisáceo
        ),
        _buildStatCard(
          icon: Icons.trending_up_rounded,
          label: "Promedio",
          value: averageKm.toStringAsFixed(1),
          color: const Color(0xFF5D737E), // Gris azulado suave
        ),
        _buildStatCard(
          icon: Icons.flash_on_rounded,
          label: "Récord",
          value: maxKm.toStringAsFixed(1),
          color: const Color(0xFFE29578), // Naranja suave (Terra cotta)
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Colores base del tema oscuro
    const secondaryDark = Color.fromARGB(255, 2, 32, 88);
    const textPrimary = Color(0xFFE0E1DD);

    return Container(
      decoration: BoxDecoration(
        color: secondaryDark,
        borderRadius: BorderRadius.circular(24), // Bordes más redondeados
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fondo decorativo (gradiente muy sutil)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end, // Texto abajo
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color:
                        color, // El número toma el color del tema de la tarjeta
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: textPrimary.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Icono flotante en la esquina
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
