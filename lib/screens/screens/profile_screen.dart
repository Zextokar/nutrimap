import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:nutrimap/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Colores del tema mejorado
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);

  final rutFormatter = MaskedInputFormatter('##.###.###-#');

  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String? _userDocId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid_auth', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userDoc = query.docs.first;
      _userDocId = userDoc.id;
      final data = userDoc.data();

      final institucionNombre = await _getDocName(
        'instituciones',
        data['inst_id'],
      );
      final dietaNombre = await _getDocName('tipo_dieta', data['cod_dieta']);
      final regionNombre = await _getDocName('regiones', data['region_id']);
      final comunaNombre = await _getDocName('comunas', data['comuna_id']);

      String telefono = data['telefono'] != null
          ? '+56 ${data['telefono']}'
          : '-';
      String rut = data['rut'] ?? '-';
      if (rut != '-') {
        rut = toNumericString(rut);
        if (rut.length >= 8) {
          rut = rutFormatter
              .formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: rut),
              )
              .text;
        }
      }

      if (mounted) {
        setState(() {
          _userData = {
            'displayName': '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}',
            'email': user.email ?? '',
            'telefono': telefono,
            'telefono_raw': data['telefono'] ?? '',
            'rut': rut,
            'region': regionNombre,
            'comuna': comunaNombre,
            'institucion': institucionNombre,
            'dieta': dietaNombre,
            'region_id': data['region_id'],
            'comuna_id': data['comuna_id'],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error al obtener usuario: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getDocName(String collection, String? docId) async {
    if (docId == null || docId.isEmpty) return '-';
    try {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .get();
      return doc.exists ? doc['nombre'] : '-';
    } catch (e) {
      return '-';
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserData(String field, dynamic value) async {
    if (_userDocId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .update({field: value});

      if (field == 'region_id') {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_userDocId)
            .update({'comuna_id': null});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dato actualizado con éxito'),
            backgroundColor: _accentGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog({
    required String title,
    required String fieldKey,
    String? currentValue,
    String collection = '',
    String? filterField,
    String? filterValue,
  }) async {
    final TextEditingController textController = TextEditingController();
    dynamic selectedValue;

    Widget content;

    if (collection.isEmpty) {
      textController.text = currentValue ?? '';
      content = TextFormField(
        controller: textController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          prefixText: '+56 ',
          hintText: '9 1234 5678',
          hintStyle: const TextStyle(color: _textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentBlue, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentGreen, width: 2),
          ),
          counterText: '',
          filled: true,
          fillColor: _secondaryDark,
        ),
        style: const TextStyle(color: _textPrimary),
        maxLength: 9,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      );
    } else {
      content = FutureBuilder<QuerySnapshot>(
        future: _getDropdownData(collection, filterField, filterValue),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _accentGreen),
            );
          }
          final items = snapshot.data!.docs.map((doc) {
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                doc['nombre'],
                style: const TextStyle(color: _textPrimary),
              ),
            );
          }).toList();

          return DropdownButtonFormField<String>(
            items: items,
            onChanged: (value) => selectedValue = value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accentBlue, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accentGreen, width: 2),
              ),
              filled: true,
              fillColor: _secondaryDark,
            ),
            hint: Text(
              'Seleccionar $title',
              style: const TextStyle(color: _textSecondary),
            ),
            dropdownColor: _secondaryDark,
          );
        },
      );
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _secondaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Editar $title',
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentGreen,
              foregroundColor: _textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final newValue = collection.isEmpty
                  ? textController.text.replaceAll(RegExp(r'[^0-9]'), '')
                  : selectedValue;

              if (newValue != null && newValue.toString().isNotEmpty) {
                _updateUserData(fieldKey, newValue);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot> _getDropdownData(
    String collection,
    String? filterField,
    String? filterValue,
  ) {
    Query query = FirebaseFirestore.instance.collection(collection);
    if (filterField != null && filterValue != null) {
      query = query.where(filterField, isEqualTo: filterValue);
    }
    return query.orderBy('nombre').get();
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
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            local.userProfile,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _accentGreen,
                  strokeWidth: 3,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de perfil mejorada
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_accentBlue, _secondaryDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _accentGreen.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _accentGreen.withAlpha(80),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: _accentGreen,
                              child: Text(
                                _userData['displayName']?.isNotEmpty == true
                                    ? _userData['displayName'][0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userData['displayName'] ?? '-',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _userData['email'] ?? '-',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: _textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sección de información personal
                    Text(
                      'Información Personal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEditableInfoTile(
                      title: local.phone,
                      value: _userData['telefono'] ?? '-',
                      icon: Icons.phone_rounded,
                      onEdit: () => _showEditDialog(
                        title: local.phone,
                        fieldKey: 'telefono',
                        currentValue: _userData['telefono_raw'],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoTile(
                      local.rut,
                      _userData['rut'] ?? '-',
                      Icons.badge_rounded,
                    ),
                    const SizedBox(height: 28),

                    // Sección de ubicación
                    Text(
                      'Ubicación',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEditableInfoTile(
                      title: local.region,
                      value: _userData['region'] ?? '-',
                      icon: Icons.map_rounded,
                      onEdit: () => _showEditDialog(
                        title: local.region,
                        fieldKey: 'region_id',
                        collection: 'regiones',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildEditableInfoTile(
                      title: local.commune,
                      value: _userData['comuna'] ?? '-',
                      icon: Icons.location_city_rounded,
                      onEdit: () {
                        if (_userData['region_id'] == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Por favor, seleccione una región primero.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        _showEditDialog(
                          title: local.commune,
                          fieldKey: 'comuna_id',
                          collection: 'comunas',
                          filterField: 'region_id',
                          filterValue: _userData['region_id'],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildEditableInfoTile(
                      title: local.institution,
                      value: _userData['institucion'] ?? '-',
                      icon: Icons.school_rounded,
                      onEdit: () => _showEditDialog(
                        title: local.institution,
                        fieldKey: 'inst_id',
                        collection: 'instituciones',
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sección de preferencias
                    Text(
                      'Preferencias',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildEditableInfoTile(
                      title: local.diet,
                      value: _userData['dieta'] ?? '-',
                      icon: Icons.restaurant_menu_rounded,
                      onEdit: () => _showEditDialog(
                        title: local.diet,
                        fieldKey: 'cod_dieta',
                        collection: 'tipo_dieta',
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Botón de logout mejorado
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
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
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentBlue.withAlpha(150), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentBlue.withAlpha(100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accentGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: _secondaryDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accentBlue.withAlpha(150), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentBlue.withAlpha(100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _accentGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentGreen.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: _accentGreen,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
