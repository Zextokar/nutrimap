import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 1. Obtiene el nombre y la referencia del documento del usuario
  Future<Map<String, dynamic>> getUserData(String authUid) async {
    try {
      final query = await _db
          .collection('usuarios')
          .where('uid_auth', isEqualTo: authUid)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'name': 'Usuario', 'ref': null};
      }

      final doc = query.docs.first;
      final data = doc.data();
      final name = "${data['nombre'] ?? ''} ${data['apellido'] ?? ''}".trim();

      return {'name': name.isEmpty ? 'Usuario' : name, 'ref': doc.reference};
    } catch (e) {
      return {'name': 'Usuario', 'ref': null};
    }
  }

  /// 2. Obtiene los KMs de todo el mes para pintarlos en el calendario
  Future<Map<int, double>> getMonthKms(DocumentReference? userRef) async {
    if (userRef == null) return {};

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    try {
      final query = await userRef
          .collection('add_data')
          .where('fecha', isGreaterThanOrEqualTo: startOfMonth)
          .where('fecha', isLessThanOrEqualTo: endOfMonth)
          .get();

      Map<int, double> kmPerDay = {};

      // Inicializar días en 0
      for (int i = 1; i <= endOfMonth.day; i++) {
        kmPerDay[i] = 0.0;
      }

      for (var doc in query.docs) {
        final data = doc.data();
        final fecha = (data['fecha'] as Timestamp).toDate();
        final rawKm = data['kms'];

        double km = 0.0;
        if (rawKm is num) {
          km = rawKm.toDouble();
        } else if (rawKm is String) {
          km = double.tryParse(rawKm) ?? 0.0;
        }

        if (kmPerDay.containsKey(fecha.day)) {
          kmPerDay[fecha.day] = kmPerDay[fecha.day]! + km;
        }
      }
      return kmPerDay;
    } catch (e) {
      return {};
    }
  }

  /// 3. Guarda o Actualiza la actividad del día actual
  Future<void> saveDailyActivity({
    required String uid,
    required double kms,
    required int steps,
  }) async {
    // Buscar usuario por UID
    final userQuery = await _db
        .collection('usuarios')
        .where('uid_auth', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    final userRef = userQuery.docs.first.reference;

    // Normalizar fecha de HOY (sin hora)
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);

    // Buscar si ya existe dato hoy
    final activityQuery = await userRef
        .collection('add_data')
        .where('fecha', isEqualTo: Timestamp.fromDate(todayNormalized))
        .limit(1)
        .get();

    if (activityQuery.docs.isNotEmpty) {
      // Actualizar
      await activityQuery.docs.first.reference.update({
        'kms': kms,
        'pasos': steps,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      // Crear nuevo
      await userRef.collection('add_data').add({
        'fecha': Timestamp.fromDate(todayNormalized),
        'kms': kms,
        'pasos': steps,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Utilidad: Convierte pasos a KM (aprox)
  double stepsToKm(int steps) {
    return (steps * 0.762) / 1000;
  }
}
