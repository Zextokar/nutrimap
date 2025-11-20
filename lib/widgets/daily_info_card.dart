import 'package:flutter/material.dart';

class DailyInfoCard extends StatelessWidget {
  final DateTime day;
  final double km;

  // Colores constantes
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF06A77D);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _textPrimary = Color(0xFFE0E1DD);

  const DailyInfoCard({super.key, required this.day, required this.km});

  @override
  Widget build(BuildContext context) {
    final hasData = km > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData
              ? _accentGreen.withOpacity(0.3)
              : _accentBlue.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Día ${day.day.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                hasData ? Icons.directions_run : Icons.info_outline,
                size: 16,
                color: hasData ? _accentGreen : _textPrimary.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                hasData
                    ? 'Distancia recorrida: ${km.toStringAsFixed(1)} km'
                    : 'Sin datos para este día',
                style: TextStyle(
                  color: _textPrimary.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
