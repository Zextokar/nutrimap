// ignore_for_file: unused_field
import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, min;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

class RouteStep {
  final String instruction;
  final LatLng startLocation;
  final LatLng endLocation;
  final String distance;
  final String duration;

  RouteStep({
    required this.instruction,
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.duration,
  });
}

class MapScreen extends StatefulWidget {
  final User user;
  final LatLng? initialDestination;
  final String? initialDestinationName;

  const MapScreen({
    super.key,
    required this.user,
    this.initialDestination,
    this.initialDestinationName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // --- UI ---
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _accentGreen = Color(0xFF00C853);
  static const Color _errorRed = Color(0xFFE53935);

  // --- MAP & LOCATION ---
  GoogleMapController? _mapController;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _currentUserLocation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _allRoutePoints = [];

  // --- NAVIGATION STATE ---
  bool _isCalculatingRoute = false;
  bool _isNavigating = false;
  bool _routeIsPreview = false;
  int _currentStepIndex = 0;
  List<RouteStep> _routeSteps = [];

  LatLng? _currentDestination;
  String? _currentDestinationName;

  final FlutterTts _flutterTts = FlutterTts();
  final HtmlUnescape _unescape = HtmlUnescape();

  @override
  void initState() {
    super.initState();
    _currentDestination = widget.initialDestination;
    _currentDestinationName = widget.initialDestinationName;
    _initServices();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initServices() async {
    await _setupTts();
    await _setupLocation();
  }

  // ================== LOGICA DE UBICACIÓN ==================

  Future<void> _setupLocation() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permission = await _locationService.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _locationService.requestPermission();
      if (permission != PermissionStatus.granted) return;
    }

    _locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000, // Actualización cada segundo para navegación fluida
      distanceFilter: 2,
    );

    // Obtener ubicación actual inmediatamente
    final loc = await _locationService.getLocation();
    _currentUserLocation = loc;

    // Si venimos de la pantalla de detalle, generar ruta automáticamente
    if (_currentDestination != null) {
      _createRoute(
        _currentDestination!,
        destinationName: _currentDestinationName,
      );
    }

    _locationSubscription = _locationService.onLocationChanged.listen(
      _onLocationUpdate,
    );
  }

  void _onLocationUpdate(LocationData loc) {
    if (!mounted) return;
    setState(() {
      _currentUserLocation = loc;
      _updateMarkers();
    });

    if (_isNavigating) {
      _updateCameraForNavigation(loc);
      _checkStepProgress(loc);
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Marcador de Usuario (Azul)
    if (_currentUserLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(
            _currentUserLocation!.latitude!,
            _currentUserLocation!.longitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // Marcador de Destino (Rojo)
    if (_currentDestination != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dest'),
          position: _currentDestination!,
          infoWindow: InfoWindow(title: _currentDestinationName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  // ================== GOOGLE DIRECTIONS API ==================

  Future<void> _createRoute(LatLng dest, {String? destinationName}) async {
    if (_currentUserLocation == null) return;

    setState(() {
      _isCalculatingRoute = true;
      _polylines.clear();
      _routeSteps.clear();
    });

    final origin =
        "${_currentUserLocation!.latitude},${_currentUserLocation!.longitude}";
    final destination = "${dest.latitude},${dest.longitude}";

    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin&destination=$destination'
        '&mode=walking&language=es&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final leg = route['legs'][0];

        // Decodificar polilínea para dibujo
        _allRoutePoints = PolylinePoints.decodePolyline(
          route['overview_polyline']['points'],
        ).map((p) => LatLng(p.latitude, p.longitude)).toList();

        // Guardar pasos para el TTS y las instrucciones superiores
        _routeSteps = (leg['steps'] as List).map<RouteStep>((s) {
          return RouteStep(
            instruction: _unescape
                .convert(s['html_instructions'])
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .trim(),
            startLocation: LatLng(
              s['start_location']['lat'],
              s['start_location']['lng'],
            ),
            endLocation: LatLng(
              s['end_location']['lat'],
              s['end_location']['lng'],
            ),
            distance: s['distance']['text'],
            duration: s['duration']['text'],
          );
        }).toList();

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _allRoutePoints,
              color: _accentGreen,
              width: 7,
            ),
          );
          _routeIsPreview = true;
          _isCalculatingRoute = false;
        });

        // Enfocar la ruta completa al inicio
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(_createBounds(_allRoutePoints), 80),
        );
      }
    } catch (e) {
      setState(() => _isCalculatingRoute = false);
    }
  }

  // ================== NAVEGACIÓN ACTIVA ==================

  void _checkStepProgress(LocationData loc) {
    if (_routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) return;

    final nextStep = _routeSteps[_currentStepIndex];
    final distanceToTurn = _calculateDistance(
      loc.latitude!,
      loc.longitude!,
      nextStep.endLocation.latitude,
      nextStep.endLocation.longitude,
    );

    // Si estamos a menos de 10-15 metros del final del paso actual, avanzar
    if (distanceToTurn < 12 && _currentStepIndex < _routeSteps.length - 1) {
      setState(() => _currentStepIndex++);
      _flutterTts.speak(_routeSteps[_currentStepIndex].instruction);
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _routeIsPreview = false;
      _polylines.clear();
      _routeSteps.clear();
    });

    _flutterTts.stop();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ================== INTERFAZ DE USUARIO ==================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryDark,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              c.setMapStyle(_customMapStyle);
            },
            onTap: (LatLng tappedPosition) {
              setState(() {
                _currentDestination = tappedPosition;
                _currentDestinationName = "Destino seleccionado";
              });
              _createRoute(
                tappedPosition,
                destinationName: "Destino seleccionado",
              );
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(-35.843, -71.597),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            padding: EdgeInsets.only(top: _isNavigating ? 140 : 0),
          ),

          // 1. Cabecera de Instrucción (Solo en Navegación)
          if (_isNavigating && _routeSteps.isNotEmpty)
            Positioned(
              top: 50,
              left: 15,
              right: 15,
              child: _buildInstructionBanner(),
            ),

          // 2. Card de Previsualización Inferior (Antes de iniciar)
          if (_routeIsPreview) _buildPreviewFooter(),

          // 3. Botón flotante para cancelar (Solo en Navegación)
          if (_isNavigating)
            Positioned(
              bottom: 30,
              left: 80,
              right: 80,
              child: FloatingActionButton.extended(
                backgroundColor: _errorRed,
                label: const Text(
                  "SALIR",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _stopNavigation,
              ),
            ),

          if (_isCalculatingRoute)
            const Center(child: CircularProgressIndicator(color: _accentGreen)),
        ],
      ),
    );
  }

  Widget _buildInstructionBanner() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, size: 35, color: _primaryDark),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _routeSteps[_currentStepIndex].instruction,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewFooter() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: _primaryDark.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const Icon(Icons.location_on, color: _accentGreen),
              title: Text(
                _currentDestinationName ?? "Destino",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                "Ruta directa calculada",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: const Text(
                "INICIAR CÓMO LLEGAR",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                setState(() {
                  _isNavigating = true;
                  _routeIsPreview = false;
                  _currentStepIndex = 0;
                });
                _flutterTts.speak(_routeSteps.first.instruction);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================== CÁLCULOS TÉCNICOS ==================

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Distancia en metros
  }

  LatLngBounds _createBounds(List<LatLng> pos) {
    final sw = LatLng(
      pos.map((p) => p.latitude).reduce(min),
      pos.map((p) => p.longitude).reduce(min),
    );
    final ne = LatLng(
      pos.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
      pos.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
    );
    return LatLngBounds(southwest: sw, northeast: ne);
  }

  void _updateCameraForNavigation(LocationData loc) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(loc.latitude!, loc.longitude!),
          zoom: 19,
          tilt: 60,
          bearing: loc.heading ?? 0,
        ),
      ),
    );
  }

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setSpeechRate(0.5);
  }

  final String _customMapStyle = jsonEncode([
    {
      "elementType": "geometry",
      "stylers": [
        {"color": "#1d2c4d"},
      ],
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#8ec3b9"},
      ],
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {"color": "#1a3646"},
      ],
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {"color": "#304a7d"},
      ],
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {"color": "#0e1626"},
      ],
    },
  ]);
}
