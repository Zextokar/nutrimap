import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepService {
  Stream<StepCount>? _stepCountStream;
  Stream<PedestrianStatus>? _pedestrianStatusStream;

  /// Inicializa y solicita permisos
  Future<bool> initSensors() async {
    final status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      return true;
    } else {
      // Manejar el caso de permiso denegado
      return false;
    }
  }

  Stream<StepCount>? get stepStream => _stepCountStream;
  Stream<PedestrianStatus>? get statusStream => _pedestrianStatusStream;

  // Cálculo aproximado: Pasos a Metros
  // Promedio: 0.762 metros por paso (ajustable según altura del usuario)
  double stepsToKm(int steps) {
    return (steps * 0.762) / 1000;
  }
}
