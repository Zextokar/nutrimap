import 'dart:async';
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

  Timer? _timer;

  String _steps = "0";
  int _stepsInt = 0;
  double _kmCalculated = 0.0;
  bool _isSaving = false;
  bool _hasPermission = false;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        _startEmulatorSimulation();
      }
    }
  }

  void _startEmulatorSimulation() {
    if (_isSimulating) return;
    setState(() => _isSimulating = true);

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _stepsInt++;
        _steps = _stepsInt.toString();
        _kmCalculated = _activityService.stepsToKm(_stepsInt);
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

  void _onPedestrianStatus(PedestrianStatus event) {}

  // ignore: strict_top_level_inference
  void _onStepError(error) {
    _startEmulatorSimulation();
  }

  // ignore: strict_top_level_inference
  void _onStatusError(error) {}

  Future<void> _saveToFirebase() async {
    if (_stepsInt == 0) return;
    final bool isSpanish = Localizations.localeOf(context).languageCode == 'es';

    setState(() => _isSaving = true);

    try {
      await _activityService.saveDailyActivity(
        uid: widget.userUid,
        kms: _kmCalculated,
        steps: _stepsInt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpanish
                  ? "¡Actividad registrada exitosamente!"
                  : "Activity recorded successfully!",
            ),
            backgroundColor: const Color.fromARGB(255, 3, 184, 48),
          ),
        );
        widget.onSaveSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${isSpanish ? 'Error' : 'Error'}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // DETECCIÓN DE IDIOMA
    final bool isSpanish = Localizations.localeOf(context).languageCode == 'es';

    if (!_hasPermission) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Text(
          isSpanish
              ? "Se requiere permiso de actividad física"
              : "Physical activity permission is required",
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(172, 11, 78, 201),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color.fromARGB(172, 11, 78, 201).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 1, 206, 52).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSimulating ? Icons.developer_mode : Icons.directions_walk,
                  color: const Color.fromARGB(255, 3, 219, 21),
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
                    _isSimulating
                        ? (isSpanish ? "Pasos (Simulado)" : "Steps (Simulated)")
                        : (isSpanish ? "Pasos (Sensor)" : "Steps (Sensor)"),
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
                  Text(
                    isSpanish ? "Estimado" : "Estimated",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                backgroundColor: const Color.fromARGB(197, 12, 145, 41),
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
                _isSaving
                    ? (isSpanish ? "Guardando..." : "Saving...")
                    : (isSpanish
                          ? "Registrar Actividad de Hoy"
                          : "Log Today's Activity"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
