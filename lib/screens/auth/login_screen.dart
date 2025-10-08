import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrimap/l10n/app_localizations.dart';
import 'package:nutrimap/screens/main_screen.dart';
import 'package:nutrimap/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si el login es exitoso, navegamos al home
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => MainScreen(user: credential.user!)),
      );
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      String message = AppLocalizations.of(context)!.loginError;
      if (e.code == 'user-not-found') {
        // ignore: use_build_context_synchronously
        message = AppLocalizations.of(context)!.userNotFound;
      } else if (e.code == 'wrong-password') {
        message = AppLocalizations.of(context)!.wrongPassword;
      } else if (e.code == 'invalid-email') {
        message = AppLocalizations.of(context)!.invalidEmail;
      }

      // ignore: use_build_context_synchronously
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F0F23),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    Colors.indigo.shade800,
                    Colors.blue.shade600,
                    Colors.cyan.shade400,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 20.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height - MediaQuery.of(context).padding.vertical - 40,
              ),
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 1000),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Logo y título
                    Container(
                      margin: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.3 : 0.1,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.health_and_safety_rounded,
                              size: 60,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            local.loginTitle,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: isDark
                                  ? Colors.grey.shade100
                                  : Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            local.welcomeBack,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Formulario en tarjeta
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E2E).withOpacity(0.95)
                            : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: isDark
                            ? Border.all(
                                color: Colors.grey.shade700.withOpacity(0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Campo email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.grey.shade100
                                    : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: local.email,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: isDark
                                      ? Colors.blue.shade300
                                      : Colors.indigo.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey.shade800.withOpacity(0.5)
                                    : Colors.grey.shade50,
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return local.enterEmail;
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return local.invalidEmail;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Campo contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.grey.shade100
                                    : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: local.password,
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: isDark
                                      ? Colors.blue.shade300
                                      : Colors.indigo.shade600,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey.shade800.withOpacity(0.5)
                                    : Colors.grey.shade50,
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return local.enterPassword;
                                }
                                if (value.length < 6) {
                                  return local.shortPassword;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Olvidé mi contraseña
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Implementar recuperación de contraseña
                                },
                                child: Text(
                                  local.forgotPassword,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.blue.shade300
                                        : Colors.indigo.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Botón de login
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: _isLoading
                                  ? Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                                  Colors.blue.shade600,
                                                  Colors.blue.shade400,
                                                ]
                                              : [
                                                  Colors.indigo.shade600,
                                                  Colors.blue.shade500,
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isDark
                                                ? [
                                                    Colors.blue.shade600,
                                                    Colors.blue.shade400,
                                                  ]
                                                : [
                                                    Colors.indigo.shade600,
                                                    Colors.blue.shade500,
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Text(
                                            local.loginButton.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          local.noAccount,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navegar a la pantalla de registro
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            local.register,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
