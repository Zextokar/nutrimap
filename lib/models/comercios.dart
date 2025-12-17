import 'package:latlong2/latlong.dart';

class Comercio {
  final String id;
  final String nombre;
  final String direccion;
  final LatLng ubicacion;

  Comercio({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ubicacion,
  });

  factory Comercio.fromFirestore(Map<String, dynamic> data) {
    return Comercio(
      id: data['id'],
      nombre: data['nombre'],
      direccion: data['direccion'],
      ubicacion: LatLng(
        data['ubicacion']['lat'],
        data['ubicacion']['lng'],
      ),
    );
  }
}
