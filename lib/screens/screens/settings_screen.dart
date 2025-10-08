import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required User user});

  // Colores del tema dark blue
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _lightBlue = Color(0xFF778DA9);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No user logged in");

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};

    String? institucionNombre = '-';
    if (data['institucionId'] != null) {
      final instDoc = await FirebaseFirestore.instance
          .collection('instituciones')
          .doc(data['institucionId'])
          .get();
      institucionNombre = instDoc.data()?['nombre'] ?? '-';
    }

    return {
      'displayName': '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}',
      'email': user.email ?? '',
      'telefono': data['telefono'] ?? '-',
      'institucion': institucionNombre,
    };
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: _accentBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _primaryDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryDark,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: _secondaryDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _accentBlue, width: 0.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentBlue,
            foregroundColor: _textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            local.settings,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w300,
              fontSize: 22,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: _lightBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _lightBlue,
                  strokeWidth: 2,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: _textSecondary),
                ),
              );
            }

            final userData = snapshot.data!;
            final user = FirebaseAuth.instance.currentUser;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header minimalista
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: _secondaryDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _accentBlue, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _accentBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: _lightBlue, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              (user?.email != null ? user!.email![0] : 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                color: _textPrimary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          userData['displayName'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: _textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData['email'],
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Información minimalista
                  Container(
                    decoration: BoxDecoration(
                      color: _secondaryDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _accentBlue, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.person_outline,
                          title: local.user,
                          value: userData['displayName'],
                          isFirst: true,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          title: local.email,
                          value: userData['email'],
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          title: local.phone,
                          value: userData['telefono'],
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.school_outlined,
                          title: local.institution,
                          value: userData['institucion'],
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botón logout minimalista
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentBlue, width: 1),
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, size: 20),
                      onPressed: () => _logout(context),
                      label: Text(
                        local.logout,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: _lightBlue,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accentBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _lightBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 0.5,
      color: _accentBlue.withOpacity(0.3),
    );
  }
}
