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
    // Detectamos el idioma del sistema
    final bool isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          icon: Icons.route_rounded,
          label: isSpanish
              ? "Total KM"
              : "Total KM", // Se mantiene igual o puedes usar "Total Distance"
          value: totalKm.toStringAsFixed(1),
          color: const Color(0xFF2D9D78),
        ),
        _buildStatCard(
          icon: Icons.calendar_today_rounded,
          label: isSpanish ? "Días Activos" : "Active Days",
          value: daysWithData.toString(),
          color: const Color(0xFF415A77),
        ),
        _buildStatCard(
          icon: Icons.trending_up_rounded,
          label: isSpanish ? "Promedio" : "Average",
          value: averageKm.toStringAsFixed(1),
          color: const Color(0xFF5D737E),
        ),
        _buildStatCard(
          icon: Icons.flash_on_rounded,
          label: isSpanish ? "Récord" : "Record",
          value: maxKm.toStringAsFixed(1),
          color: const Color(0xFFE29578),
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
    const secondaryDark = Color.fromARGB(255, 2, 32, 88);
    const textPrimary = Color(0xFFE0E1DD);

    return Container(
      decoration: BoxDecoration(
        color: secondaryDark,
        borderRadius: BorderRadius.circular(24),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  // Agregado para asegurar que el número no se corte
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
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
