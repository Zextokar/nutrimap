import 'dart:async'; // <--- IMPORTANTE: Necesario para el Timer
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/activity_service.dart';

class StepCounterCard extends StatefulWidget {
  final String userUid;
  final VoidCallback? onSaveSuccess;

  const StepCounterCard({super.key, required this.userUid, this.onSaveSuccess});

  @override
  State<StepCounterCard> createState() => _StepCounterCardState();
}

class _StepCounterCardState extends State<StepCounterCard> {
  final ActivityService _activityService = ActivityService();

  Stream<StepCount>? _stepCountStream;
  Stream<PedestrianStatus>? _pedestrianStatusStream;

  // Timer para la simulación
  Timer? _timer;

  String _steps = "0";
  int _stepsInt = 0;
  double _kmCalculated = 0.0;
  bool _isSaving = false;
  bool _hasPermission = false;
  bool _isSimulating = false; // Flag para saber si estamos simulando

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // <--- IMPORTANTE: Cancelar timer al salir
    super.dispose();
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      if (!mounted) return;
      setState(() => _hasPermission = true);

      try {
        _stepCountStream = Pedometer.stepCountStream;
        _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

        _stepCountStream?.listen(_onStepCount).onError(_onStepError);
        _pedestrianStatusStream
            ?.listen(_onPedestrianStatus)
            .onError(_onStatusError);
      } catch (e) {
        // Si falla la inicialización (común en emulador), arrancamos simulación
        debugPrint("Error inicializando sensor: $e. Iniciando simulación.");
        _startEmulatorSimulation();
      }
    }
  }

  // --- LÓGICA DE SIMULACIÓN ---
  void _startEmulatorSimulation() {
    if (_isSimulating) return; // Evitar duplicar timers

    setState(() => _isSimulating = true);

    // Suma 1 paso cada 2 segundos
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _stepsInt++; // Aumentamos pasos
        _steps = _stepsInt.toString();
        _kmCalculated = _activityService.stepsToKm(_stepsInt);
        // Simulamos estado caminando visualmente
      });
    });
  }

  void _onStepCount(StepCount event) {
    if (!mounted) return;
    setState(() {
      _stepsInt = event.steps;
      _steps = event.steps.toString();
      _kmCalculated = _activityService.stepsToKm(event.steps);
    });
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    // Aquí podrías cambiar íconos si está caminando o parado
  }

  void _onStepError(error) {
    debugPrint('Error pasos (Sensor no encontrado): $error');
    // Si el stream da error, activamos la simulación
    _startEmulatorSimulation();
  }

  void _onStatusError(error) {
    debugPrint('Error estado: $error');
  }

  Future<void> _saveToFirebase() async {
    if (_stepsInt == 0) return;
    setState(() => _isSaving = true);

    try {
      await _activityService.saveDailyActivity(
        uid: widget.userUid,
        kms: _kmCalculated,
        steps: _stepsInt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Actividad registrada exitosamente!"),
            backgroundColor: Color(0xFF06A77D),
          ),
        );
        widget.onSaveSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: const Text(
          "Se requiere permiso de actividad física",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF06A77D).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF06A77D).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSimulating ? Icons.developer_mode : Icons.directions_walk,
                  color: const Color(0xFF06A77D),
                  size: 32,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _steps,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isSimulating ? "Pasos (Simulado)" : "Pasos (Sensor)",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${_kmCalculated.toStringAsFixed(2)} km",
                    style: const TextStyle(
                      color: Color(0xFFF4B942),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Estimado",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveToFirebase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06A77D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isSaving ? "Guardando..." : "Registrar Actividad de Hoy",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
