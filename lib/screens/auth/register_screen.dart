import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutrimap/screens/auth/login_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- PALETA DE COLORES (Global) ---
  static const Color _primaryDark = Color.fromARGB(172, 11, 78, 201);
  static const Color _secondaryDark = Color.fromARGB(50, 0, 0, 0);
  static const Color _accentGreen = Color.fromARGB(255, 1, 136, 30);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color.fromARGB(255, 255, 255, 255);
  static const Color _errorRed = Color(0xFFEF476F);

  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final TextEditingController _dateController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Variables de Datos
  String rut = '';
  String nombre = '';
  String apellido = '';
  String email = '';
  String password = '';
  String telefono = '';
  String? generoId;
  String? regionId;
  String? comunaId;
  String? institucionId;
  String? dietaId;
  DateTime? fechaNac;

  // ---------------- LÓGICA (Mantenida igual) ----------------

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      String rutLimpio = rut.replaceAll('.', '').replaceAll('-', '').trim();

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(rutLimpio)
          .set({
            'rut': rutLimpio,
            'uid_auth': cred.user!.uid,
            'email': email,
            'nombre': nombre,
            'apellido': apellido,
            'telefono': telefono,
            'genero_id': generoId,
            'fecha_nac': fechaNac != null
                ? Timestamp.fromDate(fechaNac!)
                : FieldValue.serverTimestamp(),
            'region_id': regionId,
            'comuna_id': comunaId,
            'inst_id': institucionId,
            'cod_dieta': dietaId,
            'fecha_registro': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      _showSnackBar("¡Usuario registrado con éxito! 🚀", isError: false);

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError ? _errorRed : _accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color.fromARGB(104, 218, 223, 222), // Color selección
              onPrimary: Colors.white,
              surface: Color.fromARGB(235, 11, 78, 201), // Fondo calendario
              onSurface: _textPrimary,
            ),
            dialogBackgroundColor: _primaryDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != fechaNac) {
      setState(() {
        fechaNac = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // ---------------- DISEÑO UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryDark,
      body: Stack(
        children: [
          // Fondo decorativo (Círculos difusos)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  195,
                  209,
                  223,
                  209,
                ).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header Personalizado
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "Crear Cuenta",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 48,
                      ), // Espacio para equilibrar el botón back
                    ],
                  ),
                ),

                // Formulario Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bienvenido a bordo",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Completa tus datos para comenzar tu viaje.",
                            style: TextStyle(
                              color: _textSecondary.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // === DATOS ACCESO ===
                          _buildSectionLabel("ACCESO"),
                          _buildTextField(
                            label: "Email",
                            icon: Icons.email_outlined,
                            inputType: TextInputType.emailAddress,
                            onSaved: (val) => email = val!.trim(),
                            validator: (val) =>
                                val!.contains('@') ? null : "Email inválido",
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Contraseña",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            onSaved: (val) => password = val!,
                            validator: (val) =>
                                val!.length < 6 ? "Mínimo 6 caracteres" : null,
                          ),

                          const SizedBox(height: 32),

                          // === DATOS PERSONALES ===
                          _buildSectionLabel("INFORMACIÓN PERSONAL"),
                          _buildTextField(
                            label: "RUT",
                            icon: Icons.badge_outlined,
                            hint: "12.345.678-9",
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(12),
                              RutFormatter(),
                            ],
                            onSaved: (val) => rut = val!.trim(),
                            validator: (val) =>
                                !esRutValido(val!) ? "RUT inválido" : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: "Nombre",
                                  icon: Icons.person_outline,
                                  onSaved: (val) => nombre = val!.trim(),
                                  validator: (val) =>
                                      val!.isEmpty ? "Requerido" : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  label: "Apellido",
                                  icon: Icons
                                      .person_outline, // Ocultar icono para ahorrar espacio si quieres
                                  onSaved: (val) => apellido = val!.trim(),
                                  validator: (val) =>
                                      val!.isEmpty ? "Requerido" : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Teléfono",
                            icon: Icons.phone_outlined,
                            inputType: TextInputType.phone,
                            onSaved: (val) => telefono = val!.trim(),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _seleccionarFecha(context),
                            child: AbsorbPointer(
                              child: _buildTextField(
                                controller: _dateController,
                                label: "Fecha Nacimiento",
                                icon: Icons.calendar_today_outlined,
                                validator: (val) =>
                                    val!.isEmpty ? "Requerido" : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownStream(
                            collection: 'generos',
                            hint: "Género",
                            icon: Icons.wc,
                            value: generoId,
                            onChanged: (val) => setState(() => generoId = val),
                          ),

                          const SizedBox(height: 32),

                          // === PERFIL ===
                          _buildSectionLabel("UBICACIÓN Y PERFIL"),
                          _buildDropdownStream(
                            collection: 'regiones',
                            hint: "Región",
                            icon: Icons.map_outlined,
                            value: regionId,
                            onChanged: (val) {
                              setState(() {
                                regionId = val;
                                comunaId = null;
                                institucionId = null;
                              });
                            },
                          ),
                          if (regionId != null) ...[
                            const SizedBox(height: 16),
                            _buildDropdownStream(
                              collection: 'comunas',
                              hint: "Comuna",
                              icon: Icons.location_city_outlined,
                              value: comunaId,
                              filterField: 'regionId',
                              filterValue: regionId,
                              onChanged: (val) =>
                                  setState(() => comunaId = val),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownStream(
                              collection: 'instituciones',
                              hint: "Institución",
                              icon: Icons.school_outlined,
                              value: institucionId,
                              filterField: 'regionId',
                              filterValue: regionId,
                              emptyMessage: "Sin instituciones aquí",
                              onChanged: (val) =>
                                  setState(() => institucionId = val),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildDropdownStream(
                            collection: 'tipo_dieta',
                            hint: "Tipo de Dieta",
                            icon: Icons.restaurant_menu_rounded,
                            value: dietaId,
                            onChanged: (val) => setState(() => dietaId = val),
                          ),

                          const SizedBox(height: 40),

                          // BOTÓN REGISTRO
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  209,
                                  26,
                                  86,
                                  196,
                                ),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: _accentGreen.withOpacity(0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "REGISTRARME",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS INTERNOS ESTILIZADOS ---

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: _textSecondary.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    String? label,
    IconData? icon,
    String? hint,
    TextEditingController? controller,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    List<TextInputFormatter>? inputFormatters,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: _textPrimary),
        onSaved: onSaved,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
          labelStyle: TextStyle(color: _textSecondary),
          prefixIcon: Icon(icon, color: _accentGreen),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _textSecondary,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 255, 255, 255),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 190, 2, 46),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownStream({
    required String collection,
    required String hint,
    required IconData icon,
    required String? value,
    required Function(String?) onChanged,
    String? filterField,
    dynamic filterValue,
    String? emptyMessage,
  }) {
    Query query = FirebaseFirestore.instance.collection(collection);
    if (filterField != null && filterValue != null) {
      query = query.where(filterField, isEqualTo: filterValue);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: _secondaryDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accentGreen,
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // Manejo de vacío
        if (docs.isEmpty && emptyMessage != null) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: _secondaryDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, color: _textSecondary),
                const SizedBox(width: 12),
                Text(emptyMessage, style: TextStyle(color: _textSecondary)),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: _secondaryDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: const Color.fromARGB(235, 11, 78, 201),
            style: const TextStyle(color: _textPrimary, fontSize: 16),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textSecondary,
            ),
            decoration: InputDecoration(
              labelText: hint,
              labelStyle: TextStyle(color: _textSecondary),
              prefixIcon: Icon(icon, color: _accentGreen),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
            onChanged: onChanged,
            items: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                value: doc.id,
                child: Text(
                  data['nombre'] ?? 'Opción',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            validator: (val) => val == null ? "Requerido" : null,
          ),
        );
      },
    );
  }
}

// ==========================================
// UTILIDADES RUT (Sin cambios)
// ==========================================
class RutFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String rut = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
    if (rut.isEmpty) return newValue.copyWith(text: '');
    if (rut.length < 2) return newValue.copyWith(text: rut);
    String cuerpo = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1);
    String cuerpoFormateado = '';
    int contador = 0;
    for (int i = cuerpo.length - 1; i >= 0; i--) {
      cuerpoFormateado = cuerpo[i] + cuerpoFormateado;
      contador++;
      if (contador == 3 && i != 0) {
        cuerpoFormateado = '.$cuerpoFormateado';
        contador = 0;
      }
    }
    String rutFinal = '$cuerpoFormateado-$dv';
    return TextEditingValue(
      text: rutFinal,
      selection: TextSelection.collapsed(offset: rutFinal.length),
    );
  }
}

bool esRutValido(String rut) {
  if (rut.isEmpty || !rut.contains('-')) return false;
  String rutLimpio = rut.replaceAll('.', '').toUpperCase();
  List<String> partes = rutLimpio.split('-');
  if (partes.length != 2) return false;
  String num = partes[0];
  String dv = partes[1];
  if (num.isEmpty || dv.isEmpty) return false;
  int suma = 0;
  int multiplicador = 2;
  for (int i = num.length - 1; i >= 0; i--) {
    suma += int.parse(num[i]) * multiplicador;
    multiplicador++;
    if (multiplicador == 8) multiplicador = 2;
  }
  int resto = suma % 11;
  String dvCalculado = (resto == 0)
      ? '0'
      : (resto == 1)
      ? 'K'
      : (11 - resto).toString();
  return dvCalculado == dv;
}
