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
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: [
        _buildStatCard(
          icon: Icons.route,
          label: "Total KM",
          value: totalKm.toStringAsFixed(1),
          color: const Color(0xFF06A77D),
          isPrimary: true,
        ),
        _buildStatCard(
          icon: Icons.calendar_today,
          label: "Días Activos",
          value: daysWithData.toString(),
          color: const Color(0xFF415A77),
        ),
        _buildStatCard(
          icon: Icons.trending_up,
          label: "Promedio",
          value: averageKm.toStringAsFixed(1),
          color: const Color(0xFF06A77D).withOpacity(0.8),
        ),
        _buildStatCard(
          icon: Icons.flash_on,
          label: "Máximo",
          value: maxKm.toStringAsFixed(1),
          color: const Color(0xFFF4B942),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isPrimary = false,
  }) {
    const secondaryDark = Color(0xFF1B263B);
    const textPrimary = Color(0xFFE0E1DD);

    return Container(
      decoration: BoxDecoration(
        color: secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: textPrimary.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
