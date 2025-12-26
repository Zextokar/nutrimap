import 'package:flutter/material.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      // fondo
      backgroundColor: Color.fromARGB(115, 2, 67, 165),

      appBar: AppBar(
        backgroundColor: Color.fromARGB(115, 2, 67, 165),
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
        title: Text(localizations.about),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              "NutriMap",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32),
              ),
            ),

            // Descripción
            Text(
              localizations.aboutDescription,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 32.0),

            // Información
            _buildInfoRow(
              icon: Icons.info_outline,
              text: "Versión 0.0.3",
              theme: theme,
            ),
            const SizedBox(height: 8.0),
            _buildInfoRow(
              icon: Icons.copyright,
              text: "© 2025 NutriMap",
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8.0),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
