import 'package:flutter/material.dart';

class WelcomeCard extends StatelessWidget {
  final String userName;
  final AnimationController animationController;

  const WelcomeCard({
    super.key,
    required this.userName,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    // DETECCIÓN DE IDIOMA
    final bool isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return FadeTransition(
      opacity: animationController,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF06A77D), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06A77D).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // TRADUCCIÓN: ¡Bienvenido de vuelta!
              isSpanish ? "¡Bienvenido de vuelta!" : "Welcome back!",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  // Agregado para evitar problemas de espacio con textos largos
                  child: Text(
                    // TRADUCCIÓN: Sigue registrando tus actividades
                    isSpanish
                        ? 'Sigue registrando tus actividades'
                        : 'Keep tracking your activities',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
