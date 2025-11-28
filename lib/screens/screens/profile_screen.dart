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
  // Colors (same palette as Settings)
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  // ignore: unused_field
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _accentGreen = Color(0xFF2D9D78);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _textSecondary = Color(0xFF9DB2BF);
  static const Color _errorRed = Color(0xFFEF476F);

  final rutFormatter = MaskedInputFormatter('##.###.###-#');

  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String? _userDocId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ---------------- LOAD USER DATA ----------------
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

      // Parallel loading
      final results = await Future.wait([
        _getDocName('instituciones', data['inst_id']),
        _getDocName('tipo_dieta', data['cod_dieta']),
        _getDocName('regiones', data['region_id']),
        _getDocName('comunas', data['comuna_id']),
      ]);

      final institucionNombre = results[0];
      final dietaNombre = results[1];
      final regionNombre = results[2];
      final comunaNombre = results[3];

      String telefono = data['telefono'] != null
          ? '+56 ${data['telefono']}'
          : '-';
      String rut = data['rut'] ?? '-';

      // Format RUT
      if (rut != '-' && rut.isNotEmpty) {
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
      if (kDebugMode) print("Error: $e");
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
    } catch (_) {
      return '-';
    }
  }

  // ---------------- UPDATE DATA ----------------
  Future<void> _updateUserData(String field, dynamic value) async {
    final local = AppLocalizations.of(context)!;

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
          SnackBar(
            content: Text(local.profileUpdated),
            backgroundColor: _accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(local.errorOccurred(e.toString())),
            backgroundColor: _errorRed,
          ),
        );
      }
    }
  }

  // ---------------- EDIT TEXT FIELD ----------------
  Future<void> _showEditTextField({
    required String title,
    required String fieldKey,
    String? currentValue,
  }) async {
    final local = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _secondaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          local.editTitle(title),
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: _primaryDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  prefixText: '+56 ',
                  prefixStyle: const TextStyle(
                    color: _accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: local.phoneHint,
                  hintStyle: const TextStyle(color: _textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLength: 9,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              local.cancel,
              style: const TextStyle(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final newValue = controller.text.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
              if (newValue.isNotEmpty) {
                _updateUserData(fieldKey, newValue);
                Navigator.pop(context);
              }
            },
            child: Text(
              local.save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SELECTION SHEET ----------------
  Future<void> _showSelectionSheet({
    required String title,
    required String fieldKey,
    required String collection,
    String? filterField,
    String? filterValue,
  }) async {
    final local = AppLocalizations.of(context)!;

    if (filterField != null && filterValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(local.selectFirstRegion),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      backgroundColor: _secondaryDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    local.selectTitle(title),
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: _getDropdownData(
                      collection,
                      filterField,
                      filterValue,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: _accentGreen),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            local.noOptions,
                            style: const TextStyle(color: _textSecondary),
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: controller,
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          return InkWell(
                            onTap: () {
                              _updateUserData(fieldKey, doc.id);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _primaryDark,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                doc['nombre'],
                                style: const TextStyle(color: _textPrimary),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        title: Text(
          local.userProfile,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryDark,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accentGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),

                  // ----- PERSONAL INFO -----
                  _ProfileSection(
                    title: local.personalInfo,
                    children: [
                      _ProfileInfoTile(
                        title: local.phone,
                        value: _userData['telefono'] ?? '-',
                        icon: Icons.phone_rounded,
                        isEditable: true,
                        onTap: () => _showEditTextField(
                          title: local.phone,
                          fieldKey: 'telefono',
                          currentValue: _userData['telefono_raw'],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 20,
                        color: Colors.black12,
                      ),
                      _ProfileInfoTile(
                        title: local.rut,
                        value: _userData['rut'] ?? '-',
                        icon: Icons.badge_rounded,
                        isEditable: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ----- LOCATION -----
                  _ProfileSection(
                    title: local.location,
                    children: [
                      _ProfileInfoTile(
                        title: local.region,
                        value: _userData['region'] ?? '-',
                        icon: Icons.map_rounded,
                        isEditable: true,
                        onTap: () => _showSelectionSheet(
                          title: local.region,
                          fieldKey: 'region_id',
                          collection: 'regiones',
                        ),
                      ),
                      const Divider(height: 1, indent: 60, endIndent: 20),
                      _ProfileInfoTile(
                        title: local.commune,
                        value: _userData['comuna'] ?? '-',
                        icon: Icons.location_city_rounded,
                        isEditable: true,
                        onTap: () => _showSelectionSheet(
                          title: local.commune,
                          fieldKey: 'comuna_id',
                          collection: 'comunas',
                          filterField: 'region_id',
                          filterValue: _userData['region_id'],
                        ),
                      ),
                      const Divider(height: 1, indent: 60, endIndent: 20),
                      _ProfileInfoTile(
                        title: local.institution,
                        value: _userData['institucion'] ?? '-',
                        icon: Icons.school_rounded,
                        isEditable: true,
                        onTap: () => _showSelectionSheet(
                          title: local.institution,
                          fieldKey: 'inst_id',
                          collection: 'instituciones',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ----- PREFERENCES -----
                  _ProfileSection(
                    title: local.preferences,
                    children: [
                      _ProfileInfoTile(
                        title: local.diet,
                        value: _userData['dieta'] ?? '-',
                        icon: Icons.restaurant_menu_rounded,
                        isEditable: true,
                        onTap: () => _showSelectionSheet(
                          title: local.diet,
                          fieldKey: 'cod_dieta',
                          collection: 'tipo_dieta',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildProfileHeader() {
    final initials = (_userData['displayName']?.isNotEmpty ?? false)
        ? _userData['displayName'][0].toUpperCase()
        : 'U';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _accentGreen, width: 2),
            boxShadow: [
              BoxShadow(
                color: _accentGreen.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: _secondaryDark,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _userData['displayName'] ?? '-',
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _userData['email'] ?? '-',
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

// ---------------- SECTION TILE ----------------
class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

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
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ---------------- INFO TILE ----------------
class _ProfileInfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isEditable;
  final VoidCallback? onTap;

  const _ProfileInfoTile({
    required this.title,
    required this.value,
    required this.icon,
    this.isEditable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEditable ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF415A77).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF2D9D78), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF9DB2BF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFFE0E1DD),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isEditable)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D9D78).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF2D9D78),
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
