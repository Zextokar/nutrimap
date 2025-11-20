import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CommerceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtiene los comercios compatibles con la dieta del usuario
  Future<List<Map<String, dynamic>>> getComerciosByUser(String uid) async {
    try {
      // 1. Obtener el usuario para saber su código de dieta
      final queryUser = await _db
          .collection('usuarios')
          .where('uid_auth', isEqualTo: uid)
          .limit(1)
          .get();

      if (queryUser.docs.isEmpty) return [];

      final userData = queryUser.docs.first.data();
      final codDieta = userData['cod_dieta'];

      if (codDieta == null || codDieta.toString().isEmpty) {
        debugPrint("⚠️ El usuario no tiene dieta asignada");
        return [];
      }

      // 2. Consultar comercios compatibles
      final comercioQuery = await _db
          .collection('comercios')
          .where('dietas_compatibles', arrayContains: codDieta)
          .get();

      // 3. Mapear documentos a lista INCLUYENDO EL ID
      return comercioQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] =
            doc.id; // IMPORTANTE: Guardamos el ID para buscar menús después
        return data;
      }).toList();
    } catch (e) {
      debugPrint("❌ Error en getComerciosByUser: $e");
      return [];
    }
  }

  /// Obtiene los menús de un comercio específico (Subcolección)
  Future<List<Map<String, dynamic>>> getMenusByCommerce(
    String commerceId,
  ) async {
    try {
      final menuQuery = await _db
          .collection('comercios')
          .doc(commerceId)
          .collection('menus') // Busca en la subcolección
          .get();

      return menuQuery.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("❌ Error en getMenusByCommerce: $e");
      return [];
    }
  }
}
