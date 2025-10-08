// lib/models/demo_user.dart

class User {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final List<String> dietasPreferidas;
  final List<String> recetasFavoritas;
  final List<String> descuentosFavoritos;

  User({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.dietasPreferidas,
    required this.recetasFavoritas,
    required this.descuentosFavoritos,
  });
}

// Usuario de prueba
final User demoUser = User(
  id: 'user_pedro',
  nombre: 'Pedro',
  apellido: 'González',
  email: 'pedro@example.com',
  dietasPreferidas: ['vegana', 'sin_gluten'],
  recetasFavoritas: ['rec_ensalada_quinoa', 'rec_batido_verde'],
  descuentosFavoritos: ['desc_10_vegano', 'desc_5_sin_gluten'],
);
