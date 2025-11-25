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
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  // Controladores
  final TextEditingController _dateController = TextEditingController();

  // Variables de Estado
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

  // --- Colores Dark Mode ---
  final Color _primaryColor = const Color(0xFF4CAF50); // Verde Nutrimap
  final Color _backgroundColor = const Color(0xFF121212); // Fondo muy oscuro
  final Color _surfaceColor = const Color(0xFF1E1E1E); // Fondo de inputs
  final Color _textColor = Colors.white;
  final Color _hintColor = Colors.grey[500]!;

  // Estilo de los Inputs para Modo Oscuro
  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _hintColor),
      prefixIcon: Icon(icon, color: _hintColor),
      hintStyle: TextStyle(color: Colors.grey[700]),

      // Bordes
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide
            .none, // Sin borde por defecto en dark mode (estilo moderno)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[800]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),

      filled: true,
      fillColor: _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // --- Lógica de Registro (Misma lógica, ID limpio) ---
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 1. LIMPIEZA DEL RUT
      String rutLimpio = rut.replaceAll('.', '').replaceAll('-', '').trim();

      // 2. Crear usuario en Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 3. Guardar en Firestore
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "¡Usuario registrado con éxito! 🚀",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: ${e.toString()}",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      // Tema Oscuro para el Calendario
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _primaryColor,
              onPrimary: Colors.black,
              surface: _surfaceColor,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: _backgroundColor,
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

  @override
  Widget build(BuildContext context) {
    // Estilo de texto común para inputs
    const TextStyle inputTextStyle = TextStyle(color: Colors.white);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Crear Cuenta",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bienvenido a NutriMap",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Completa tus datos para empezar.",
                  style: TextStyle(color: _hintColor),
                ),
                const SizedBox(height: 30),

                // === SECCIÓN DE ACCESO ===
                _buildSectionTitle("Datos de Acceso"),
                TextFormField(
                  style: inputTextStyle, // Texto blanco al escribir
                  decoration: _inputStyle("Email", Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (val) => email = val!.trim(),
                  validator: (val) =>
                      val!.contains('@') ? null : "Email inválido",
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: inputTextStyle,
                  decoration: _inputStyle("Contraseña", Icons.lock_outline)
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _hintColor,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                  obscureText: _obscurePassword,
                  onSaved: (val) => password = val!,
                  validator: (val) =>
                      val!.length < 6 ? "Mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 24),

                // === SECCIÓN PERSONAL ===
                _buildSectionTitle("Información Personal"),
                TextFormField(
                  style: inputTextStyle,
                  decoration: _inputStyle(
                    "RUT",
                    Icons.badge_outlined,
                  ).copyWith(hintText: "12.345.678-9"),
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(12),
                    RutFormatter(),
                  ],
                  onSaved: (val) => rut = val!.trim(),
                  validator: (val) {
                    if (val!.isEmpty) return "El RUT es obligatorio";
                    if (!esRutValido(val)) return "RUT inválido";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        style: inputTextStyle,
                        decoration: _inputStyle("Nombre", Icons.person_outline),
                        onSaved: (val) => nombre = val!.trim(),
                        validator: (val) => val!.isEmpty ? "Requerido" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        style: inputTextStyle,
                        decoration: _inputStyle(
                          "Apellido",
                          Icons.person_outline,
                        ),
                        onSaved: (val) => apellido = val!.trim(),
                        validator: (val) => val!.isEmpty ? "Requerido" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: inputTextStyle,
                  decoration: _inputStyle("Teléfono", Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  onSaved: (val) => telefono = val!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: inputTextStyle,
                  controller: _dateController,
                  readOnly: true,
                  decoration: _inputStyle(
                    "Fecha de Nacimiento",
                    Icons.calendar_today_outlined,
                  ),
                  onTap: () => _seleccionarFecha(context),
                  validator: (val) =>
                      val!.isEmpty ? "Selecciona una fecha" : null,
                ),
                const SizedBox(height: 16),
                _buildDropdownStream(
                  collection: 'generos',
                  hint: "Género",
                  icon: Icons.wc,
                  value: generoId,
                  onChanged: (val) => setState(() => generoId = val),
                ),
                const SizedBox(height: 24),

                // === SECCIÓN UBICACIÓN Y PERFIL ===
                _buildSectionTitle("Ubicación y Perfil"),
                _buildDropdownStream(
                  collection: 'regiones',
                  hint: "Región",
                  icon: Icons.map,
                  value: regionId,
                  onChanged: (val) {
                    setState(() {
                      regionId = val;
                      comunaId = null;
                      institucionId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (regionId != null) ...[
                  _buildDropdownStream(
                    collection: 'comunas',
                    hint: "Comuna",
                    icon: Icons.location_city,
                    value: comunaId,
                    filterField: 'regionId',
                    filterValue: regionId,
                    onChanged: (val) => setState(() => comunaId = val),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownStream(
                    collection: 'instituciones',
                    hint: "Institución",
                    icon: Icons.school,
                    value: institucionId,
                    filterField: 'regionId',
                    filterValue: regionId,
                    emptyMessage: "No hay instituciones aquí",
                    onChanged: (val) => setState(() => institucionId = val),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildDropdownStream(
                  collection: 'tipo_dieta',
                  hint: "Tipo de Dieta",
                  icon: Icons.restaurant,
                  value: dietaId,
                  onChanged: (val) => setState(() => dietaId = val),
                ),
                const SizedBox(height: 40),

                // Botón de Registro
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors
                          .black, // Texto negro sobre verde es más legible
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "REGISTRARSE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 1,
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
          return IgnorePointer(
            child: TextFormField(
              // Usamos un textformfield simulado para el loading
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle(hint, icon).copyWith(
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty && emptyMessage != null) {
          return TextFormField(
            enabled: false,
            style: const TextStyle(color: Colors.white),
            decoration: _inputStyle(emptyMessage, icon),
          );
        }

        return DropdownButtonFormField<String>(
          value: value,
          dropdownColor: _surfaceColor, // Fondo del menú desplegable oscuro
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ), // Texto de las opciones
          decoration: _inputStyle(hint, icon),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: _hintColor),
          onChanged: onChanged,
          items: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = data.containsKey('nombre')
                ? data['nombre']
                : 'Opción';
            return DropdownMenuItem(
              value: doc.id,
              child: Text(nombre, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          validator: (val) => val == null ? "Campo requerido" : null,
        );
      },
    );
  }
}

// ==========================================
// UTILIDADES PARA EL RUT (Sin cambios)
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
