import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrimap/screens/auth/login_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  String nombre = '';
  String apellido = '';
  String email = '';
  String password = '';
  String telefono = '';
  String? institucionId;
  List<String> dietasSeleccionadas = [];

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      // Crear usuario en Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'nombre': nombre,
            'apellido': apellido,
            'email': email,
            'telefono': telefono,
            'institucionId': institucionId,
            'dietas_preferidas': dietasSeleccionadas,
            'recetas_favoritas': [],
            'descuentos_favoritos': [],
            'fecha_registro': FieldValue.serverTimestamp(),
          });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario registrado con éxito 🚀")),
      );

      // Redirigir a Login después de 1 segundo
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al registrar: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Nombre"),
                onSaved: (val) => nombre = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Apellido"),
                onSaved: (val) => apellido = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Email"),
                onSaved: (val) => email = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                onSaved: (val) => password = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Teléfono"),
                onSaved: (val) => telefono = val!,
              ),

              SizedBox(height: 20),
              Text("Selecciona institución"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('instituciones')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  var instituciones = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: institucionId,
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

              SizedBox(height: 20),
              Text("Selecciona dietas preferidas"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('dietas')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  var dietas = snapshot.data!.docs;
                  return Column(
                    children: dietas.map((doc) {
                      return CheckboxListTile(
                        title: Text(doc['nombre']),
                        value: dietasSeleccionadas.contains(doc.id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              dietasSeleccionadas.add(doc.id);
                            } else {
                              dietasSeleccionadas.remove(doc.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerUser,
                child: Text("Registrarse"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
