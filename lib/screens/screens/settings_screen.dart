import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/l10n/app_localizations.dart';
import 'package:nutrimap/screens/screens/profile_screen.dart';
import 'package:nutrimap/screens/screens/screens/terms_condi.dart';
import 'package:nutrimap/widgets/settings_tile.dart'; // Importamos el widget nuevo

class SettingsScreen extends StatefulWidget {
  final User user;
  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Colores definidos centralmente
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  // ---------------- LOGICA DE NEGOCIO ----------------

  /// Lógica para cerrar sesión
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _secondaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: _textPrimary),
        ),
        content: const Text(
          'Se cerrará tu sesión en la aplicación.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } catch (e) {
        _showSnackBar('Error al cerrar sesión: $e', isError: true);
      }
    }
  }

  /// Lógica para cambio de contraseña (Firebase)
  Future<void> _changePassword() async {
    final email = widget.user.email;
    if (email == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _secondaryDark,
        title: const Text(
          "Cambiar Contraseña",
          style: TextStyle(color: _textPrimary),
        ),
        content: Text(
          "Enviaremos un enlace a $email para restablecer tu contraseña.",
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentGreen),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );
                _showSnackBar("Correo enviado. Revisa tu bandeja de entrada.");
              } catch (e) {
                _showSnackBar("Error al enviar correo: $e", isError: true);
              }
            },
            child: const Text(
              "Enviar Correo",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Lógica visual para selector de idioma
  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Seleccionar Idioma",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption("Español", true),
            _buildLanguageOption(
              "English",
              false,
            ), // Aquí conectarías tu Provider de idioma
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String lang, bool isSelected) {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: isSelected ? _accentGreen : _textSecondary,
      ),
      title: Text(
        lang,
        style: TextStyle(color: isSelected ? _accentGreen : _textSecondary),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: _accentGreen)
          : null,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          _showSnackBar("Cambio de idioma a $lang (Simulado)");
          // Aquí llamarías a tu provider: context.read<LocaleProvider>().setLocale(...)
        }
      },
    );
  }

  /// Diálogo de "Acerca de"
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "Nutrimap",
      applicationVersion: "1.0.0",
      applicationIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _accentGreen.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.map, color: _accentGreen),
      ),
      children: [
        const Text(
          "Nutrimap te ayuda a llevar un control de tu actividad física y nutrición.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 10),
        const Text(
          "Desarrollado con Flutter & Firebase.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : _accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------- INTERFAZ (BUILD) ----------------

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        title: Text(
          local.settings,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        backgroundColor: _primaryDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: _accentGreen,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN CUENTA
            _buildSectionHeader('Cuenta'),
            SettingsTile(
              icon: Icons.person_rounded,
              title: local.profile,
              subtitle: 'Ver y editar tu perfil',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // SECCIÓN SEGURIDAD
            _buildSectionHeader('Seguridad'),
            SettingsTile(
              icon: Icons.lock_reset_rounded, // Icono más apropiado
              title: 'Cambiar contraseña',
              subtitle: 'Enviar correo de restablecimiento',
              onTap: _changePassword, // Conectado a la lógica real
            ),

            const SizedBox(height: 24),

            // SECCIÓN PREFERENCIAS
            _buildSectionHeader('Preferencias'),
            SettingsTile(
              icon: Icons.notifications_active_rounded,
              title: 'Notificaciones',
              subtitle: 'Gestionar alertas y recordatorios',
              onTap: () {
                // Podrías abrir un SwitchListTile en un Dialog o navegar a una pantalla de settings
                _showSnackBar("Configuración de notificaciones próximamente");
              },
            ),
            const SizedBox(height: 12),
            SettingsTile(
              icon: Icons.language_rounded,
              title: 'Idioma',
              subtitle: 'Español (Predeterminado)',
              onTap: _showLanguageSelector, // Conectado al selector
            ),

            const SizedBox(height: 24),

            // SECCIÓN SUSCRIPCIÓN
            _buildSectionHeader('Suscripción'),
            SettingsTile(
              icon: Icons.workspace_premium_rounded,
              title: 'Nutrimap Premium',
              subtitle: 'Elimina anuncios y desbloquea beneficios',
              iconColor: const Color(0xFFF4B942), // Color dorado para premium
              onTap: () => Navigator.pushNamed(context, '/subscription'),
            ),

            const SizedBox(height: 24),

            // SECCIÓN INFORMACIÓN
            _buildSectionHeader('Información'),
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Acerca de',
              subtitle: 'Versión 1.0.0',
              onTap: _showAboutDialog, // Diálogo nativo de Flutter
            ),
            const SizedBox(height: 12),
            SettingsTile(
              icon: Icons.description_rounded,
              title: 'Términos y Condiciones',
              subtitle: 'Lee nuestros términos legales',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsAndConditionsScreen(),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // BOTÓN LOGOUT
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700.withOpacity(
                    0.2,
                  ), // Fondo suave
                  foregroundColor: Colors.red.shade300, // Texto rojo claro
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.red.shade700.withOpacity(0.5),
                    ), // Borde rojo
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  local.logout,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _logout,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
