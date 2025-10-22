import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.resetEmailSent ??
                'Se envió un correo para restablecer la contraseña.',
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );

      // Opcional: volver a la pantalla anterior después de un momento
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message =
              AppLocalizations.of(context)?.invalidEmail ?? 'Email no válido.';
          break;
        case 'user-not-found':
          message =
              AppLocalizations.of(context)?.userNotFound ??
              'No existe un usuario con ese email.';
          break;
        case 'user-disabled':
          message =
              AppLocalizations.of(context)?.userDisabled ??
              'Cuenta deshabilitada.';
          break;
        case 'too-many-requests':
          message =
              AppLocalizations.of(context)?.tooManyRequests ??
              'Demasiadas solicitudes. Intenta más tarde.';
          break;
        case 'network-request-failed':
          message =
              AppLocalizations.of(context)?.networkError ??
              'Error de red. Revisa tu conexión.';
          break;
        default:
          message =
              AppLocalizations.of(context)?.resetPasswordError ??
              'Error al enviar el correo. Intenta de nuevo.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(local?.forgotPasswordTitle ?? 'Olvidé mi contraseña'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              local?.forgotPasswordDescription ??
                  'Introduce tu correo y te enviaremos un enlace para restablecer la contraseña.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: local?.email ?? 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return local?.enterEmail ?? 'Ingresa tu email';
                  }
                  final pattern =
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'; // simple validación
                  if (!RegExp(pattern).hasMatch(v.trim())) {
                    return local?.invalidEmail ?? 'Email no válido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _sendResetEmail,
                      child: Text(
                        local?.sendResetLinkButton ?? 'Enviar enlace',
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(local?.backToLogin ?? 'Volver al Login'),
            ),
          ],
        ),
      ),
    );
  }
}
