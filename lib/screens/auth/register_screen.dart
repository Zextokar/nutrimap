import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
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

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      // Crear usuario en Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Crear documento del usuario con su RUT como ID
      await FirebaseFirestore.instance.collection('usuarios').doc(rut).set({
        'rut': rut,
        'uid_auth': cred.user!.uid, // vínculo con FirebaseAuth
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario registrado con éxito 🚀")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    } catch (e) {
      if (kDebugMode) print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al registrar: $e")));
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != fechaNac) {
      setState(() {
        fechaNac = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Datos personales ===
              TextFormField(
                decoration: const InputDecoration(labelText: "RUT"),
                onSaved: (val) => rut = val!.trim(),
                validator: (val) => val!.isEmpty ? "Ingresa tu RUT" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Nombre"),
                onSaved: (val) => nombre = val!.trim(),
                validator: (val) => val!.isEmpty ? "Ingresa tu nombre" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Apellido"),
                onSaved: (val) => apellido = val!.trim(),
                validator: (val) => val!.isEmpty ? "Ingresa tu apellido" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                onSaved: (val) => email = val!.trim(),
                validator: (val) =>
                    val!.contains('@') ? null : "Email no válido",
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                onSaved: (val) => password = val!,
                validator: (val) =>
                    val!.length < 6 ? "Mínimo 6 caracteres" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Teléfono"),
                onSaved: (val) => telefono = val!.trim(),
              ),
              const SizedBox(height: 20),

              // === Fecha de nacimiento ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fechaNac == null
                        ? "Fecha de nacimiento: no seleccionada"
                        : "Nacimiento: ${DateFormat('dd/MM/yyyy').format(fechaNac!)}",
                  ),
                  TextButton(
                    onPressed: () => _seleccionarFecha(context),
                    child: const Text("Seleccionar"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === Género ===
              const Text("Selecciona tu género"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('generos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final generos = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: generoId,
                    onChanged: (val) => setState(() => generoId = val),
                    items: generos.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['nombre']),
                      );
                    }).toList(),
                    hint: const Text("Selecciona un género"),
                  );
                },
              ),

              const SizedBox(height: 20),

              // === Región ===
              const Text("Selecciona tu región"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('regiones')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final regiones = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: regionId,
                    hint: const Text("Selecciona una región"),
                    onChanged: (val) {
                      setState(() {
                        regionId = val;
                        comunaId = null;
                        institucionId = null;
                      });
                    },
                    items: regiones.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['nombre']),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // === Comuna (filtrada por región) ===
              const Text("Selecciona tu comuna"),
              if (regionId == null)
                const Text("Selecciona primero una región")
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('comunas')
                      .where('regionId', isEqualTo: regionId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    final comunas = snapshot.data!.docs;
                    if (comunas.isEmpty)
                      return const Text("No hay comunas disponibles");
                    return DropdownButtonFormField<String>(
                      key: ValueKey(
                        regionId,
                      ), // Reconstruye dropdown al cambiar región
                      value: comunaId,
                      hint: const Text("Selecciona una comuna"),
                      onChanged: (val) {
                        setState(() {
                          comunaId = val;
                          institucionId = null;
                        });
                      },
                      items: comunas.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['nombre']),
                        );
                      }).toList(),
                    );
                  },
                ),

              const SizedBox(height: 20),

              // === Institución (filtrada por región y comuna) ===
              const Text("Selecciona institución"),
              if (regionId == null || comunaId == null)
                const Text("Selecciona región y comuna primero")
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('instituciones')
                      .where('regionId', isEqualTo: regionId)
                      .where('comunaId', isEqualTo: comunaId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    final instituciones = snapshot.data!.docs;
                    if (instituciones.isEmpty)
                      return const Text("No hay instituciones disponibles");
                    return DropdownButtonFormField<String>(
                      key: ValueKey(
                        comunaId,
                      ), // Reconstruye dropdown al cambiar comuna
                      value: institucionId,
                      hint: const Text("Selecciona institución"),
                      onChanged: (val) => setState(() => institucionId = val),
                      items: instituciones.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['nombre']),
                        );
                      }).toList(),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // === Tipo de dieta ===
              const Text("Selecciona tu tipo de dieta"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tipo_dieta')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final dietas = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: dietaId,
                    onChanged: (val) => setState(() => dietaId = val),
                    items: dietas.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['nombre']),
                      );
                    }).toList(),
                    hint: const Text("Selecciona tu dieta"),
                  );
                },
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: _registerUser,
                  child: const Text("Registrarse"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
