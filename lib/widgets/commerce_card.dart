import 'package:flutter/material.dart';

class CommerceCard extends StatelessWidget {
  final Map<String, dynamic> data;

  static const Color _secondaryDark = Color.fromARGB(143, 42, 88, 187);
  static const Color _accentBlue = Color.fromARGB(255, 215, 230, 2);
  static const Color _textPrimary = Color.fromARGB(255, 255, 255, 255);
  static const Color _textSecondary = Color.fromARGB(255, 255, 255, 255);

  const CommerceCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentBlue, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['nombre'] ?? 'Comercio',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data['rating'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${data['rating']}",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Descripción
          Text(
            data['descripcion'] ?? 'Sin descripción disponible',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Dirección
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: _accentBlue,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['direccion'] ?? 'Dirección no especificada',
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
