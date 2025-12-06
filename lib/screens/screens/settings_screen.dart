import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:nutrimap/screens/screens/screens/maps_free.dart';
import 'package:provider/provider.dart';
import 'package:nutrimap/l10n/app_localizations.dart';
import 'package:nutrimap/providers/locale_provider.dart';
import 'package:nutrimap/screens/screens/profile_screen.dart';
import 'package:nutrimap/screens/screens/screens/terms_condi.dart';

class SettingsScreen extends StatefulWidget {
  final User user;
  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);
  static const Color _errorRed = Color(0xFFEF476F);

  bool _notificationsEnabled = true;
  String? _userRut;

  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: widget.user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty && mounted) {
        final data = query.docs.first.data();
        setState(() {
          _notificationsEnabled = data['recibir_notificaciones'] ?? true;
          _userRut = query.docs.first.id;
        });
      }
    } catch (e) {
      debugPrint("Error cargando preferencias: $e");
    }
  }

  void _handleSecretAccess() {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) > const Duration(seconds: 1)) {
      _secretTapCount = 0;
    }

    setState(() {
      _lastTapTime = now;
      _secretTapCount++;
    });

    if (_secretTapCount >= 5) {
      setState(() => _secretTapCount = 0);
      HapticFeedback.heavyImpact();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    if (_userRut == null) return;

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_userRut).set(
        {'recibir_notificaciones': value},
        SetOptions(merge: true),
      );
    } catch (e) {
      if (mounted) setState(() => _notificationsEnabled = !value);
      debugPrint("Error actualizando notificaciones: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _errorRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _getErrorMessage(dynamic error, AppLocalizations local) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return local.userNotFound;
        case 'invalid-email':
          return local.invalidEmail;
        case 'network-request-failed':
          return local.networkError;
        default:
          return error.message ?? local.unknownError;
      }
    }
    return local.unknownError;
  }

  void _showLanguageSelector() {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLocale = provider.locale;
    final local = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                local.language,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(
                label: local.spanish,
                code: 'es',
                isSelected: currentLocale.languageCode == 'es',
                onTap: () {
                  provider.setLocale(const Locale('es'));
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                label: local.english,
                code: 'en',
                isSelected: currentLocale.languageCode == 'en',
                onTap: () {
                  provider.setLocale(const Locale('en'));
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? _accentGreen.withOpacity(0.1) : _primaryDark,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: _accentGreen) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  code.toUpperCase(),
                  style: const TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? _accentGreen : _textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: _accentGreen),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final local = AppLocalizations.of(context)!;
    if (_userRut == null) return;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userRut)
          .get();

      if (!query.exists) {
        if (mounted) Navigator.pop(context);
        _showError(local.userNotFound);
        return;
      }

      final email = query.data()?['email'];
      if (email == null || email.isEmpty) {
        if (mounted) Navigator.pop(context);
        _showError(local.emailNotFound);
        return;
      }

      await FirebaseAuth.instance.setLanguageCode(
        Localizations.localeOf(context).languageCode,
      );
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(local.passwordResetSent),
            backgroundColor: _accentGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _showError('${local.error}: ${_getErrorMessage(e, local)}');
      }
    }
  }

  Future<void> _logout() async {
    final local = AppLocalizations.of(context)!;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _secondaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(local.logout, style: const TextStyle(color: _textPrimary)),
        content: Text(
          local.logoutBody,
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              local.cancel,
              style: const TextStyle(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              local.logout,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {}

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        title: Text(local.settingsTitle),
        backgroundColor: _primaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _SettingsSection(
              title: local.sectionAccount,
              children: [
                _SettingsTile(
                  icon: Icons.person_rounded,
                  title: local.profile,
                  subtitle: local.profileSubtitle,
                  color: Colors.blueAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
                const Divider(
                  height: 1,
                  color: Colors.black12,
                  indent: 60,
                  endIndent: 20,
                ),
                _SettingsTile(
                  icon: Icons.lock_rounded,
                  title: local.security,
                  subtitle: local.changePassword,
                  color: Colors.orangeAccent,
                  onTap: _resetPassword,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: local.sectionPreferences,
              children: [
                _SettingsTile(
                  icon: _notificationsEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  title: local.notifications,
                  subtitle: _notificationsEnabled
                      ? local.notificationsOn
                      : local.notificationsOff,
                  color: Colors.purpleAccent,
                  trailing: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _notificationsEnabled,
                      activeColor: _accentGreen,
                      onChanged: _toggleNotifications,
                    ),
                  ),
                  onTap: () {},
                ),
                const Divider(
                  height: 1,
                  color: Colors.black12,
                  indent: 60,
                  endIndent: 20,
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: local.language,
                  subtitle: Localizations.localeOf(context).languageCode == 'es'
                      ? local.spanish
                      : local.english,
                  color: Colors.tealAccent,
                  onTap: _showLanguageSelector,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: local.sectionOthers,
              children: [
                _SettingsTile(
                  icon: Icons.workspace_premium_rounded,
                  title: local.premium,
                  color: const Color(0xFFF4B942),
                  onTap: () => Navigator.pushNamed(context, '/subscription'),
                ),
                const Divider(
                  height: 1,
                  color: Colors.black12,
                  indent: 60,
                  endIndent: 20,
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: local.about,
                  color: _textSecondary,
                  onTap: _handleSecretAccess,
                ),
                const Divider(
                  height: 1,
                  color: Colors.black12,
                  indent: 60,
                  endIndent: 20,
                ),
                _SettingsTile(
                  icon: Icons.description_rounded,
                  title: local.terms,
                  color: _textSecondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsAndConditionsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                foregroundColor: _errorRed,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: _errorRed.withOpacity(0.3), width: 1),
                ),
                backgroundColor: _errorRed.withOpacity(0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    local.logout,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9DB2BF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B263B),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFE0E1DD),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: const Color(0xFFE0E1DD).withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF9DB2BF).withOpacity(0.5),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
