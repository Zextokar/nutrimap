import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CommerceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtiene los comercios compatibles con la dieta del usuario
  Future<List<Map<String, dynamic>>> getComerciosByUser(String uid) async {
    try {
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

      final comercioQuery = await _db
          .collection('comercios')
          .where('dietas_compatibles', arrayContains: codDieta)
          .get();

      return comercioQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Guardamos el ID del documento
        return data;
      }).toList();
    } catch (e) {
      debugPrint("❌ Error en getComerciosByUser: $e");
      return [];
    }
  }

  /// Obtiene los menús de un comercio específico
  Future<List<Map<String, dynamic>>> getMenusByCommerce(String commerceId) async {
    try {
      final menuQuery = await _db
          .collection('comercios')
          .doc(commerceId)
          .collection('menus')
          .get();

      return menuQuery.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("❌ Error en getMenusByCommerce: $e");
      return [];
    }
  }

  /// Califica un comercio y recalcula el promedio automáticamente usando Transacciones
  Future<bool> rateCommerce({
    required String commerceId,
    required String userUid,
    required double rating,
  }) async {
    try {
      final commerceRef = _db.collection('comercios').doc(commerceId);
      final ratingRef = commerceRef.collection('calificaciones').doc(userUid);

      await _db.runTransaction((transaction) async {
        final commerceSnapshot = await transaction.get(commerceRef);
        final ratingSnapshot = await transaction.get(ratingRef);

        if (!commerceSnapshot.exists) {
          throw Exception("El comercio no existe");
        }

        // 1. Verificar si es voto nuevo o actualización
        bool esVotoNuevo = !ratingSnapshot.exists;
        double ratingAnteriorUsuario = 0;

        if (!esVotoNuevo) {
          ratingAnteriorUsuario = ratingSnapshot.data()?['rating']?.toDouble() ?? 0.0;
        }

        // 2. Obtener datos actuales del comercio (si son nulos, inician en 0)
        double currentRating = commerceSnapshot.data()?['rating']?.toDouble() ?? 0.0;
        int cantidadVotos = commerceSnapshot.data()?['cantidad_votos'] ?? 0;

        double nuevoPromedio;
        int nuevaCantidadVotos;

        // 3. Calcular matemáticas del promedio
        if (esVotoNuevo) {
          // Fórmula: ((PromedioActual * TotalVotos) + NuevoVoto) / (TotalVotos + 1)
          double sumaTotal = (currentRating * cantidadVotos) + rating;
          nuevaCantidadVotos = cantidadVotos + 1;
          nuevoPromedio = sumaTotal / nuevaCantidadVotos;
        } else {
          // Fórmula: ((PromedioActual * TotalVotos) - VotoViejo + VotoNuevo) / TotalVotos
          double sumaTotal = (currentRating * cantidadVotos) - ratingAnteriorUsuario + rating;
          nuevaCantidadVotos = cantidadVotos; // No aumenta la cantidad, solo cambia el valor
          nuevoPromedio = sumaTotal / nuevaCantidadVotos;
        }

        // 4. Guardar voto individual (Historial)
        transaction.set(ratingRef, {
          'rating': rating,
          'fecha': FieldValue.serverTimestamp(),
          'uid': userUid,
        });

        // 5. Actualizar comercio con nuevo promedio
        transaction.update(commerceRef, {
          'rating': double.parse(nuevoPromedio.toStringAsFixed(1)), // Redondear a 1 decimal
          'cantidad_votos': nuevaCantidadVotos,
        });
      });

      return true;
    } catch (e) {
      debugPrint("❌ Error al calificar: $e");
      return false;
    }
  }
}