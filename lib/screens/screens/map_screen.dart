import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:html_unescape/html_unescape.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

const String googleMapsApiKey = "TU_API_KEY_AQUI";

enum TravelMode { walking, bicycling, driving }

class RouteInfo {
  final double distance;
  final String duration;
  final double estimatedTimeMinutes;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.estimatedTimeMinutes,
  });
}

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
  const MapScreen({super.key, required this.user});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Colores del tema oscuro
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _accentGreen = Color(0xFF06A77D);
  static const Color _lightBlue = Color(0xFF778DA9);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _errorColor = Color(0xFFD90429);

  // Controladores y servicios
  GoogleMapController? _mapController;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final FlutterTts _flutterTts = FlutterTts();
  final HtmlUnescape _unescape = HtmlUnescape();

  // Estado de ubicación
  LocationData? _currentUserLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Estado de navegación
  bool _isCalculatingRoute = false;
  TravelMode _selectedTravelMode = TravelMode.walking;
  String _locationStatus = "Iniciando...";
  List<RouteStep> _routeSteps = [];
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  bool _routeIsPreview = false;
  RouteInfo? _currentRouteInfo;
  LatLng? _currentDestination;
  String? _currentDestinationName;

  // Control de sonido
  bool _isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _setupTts();
    await _getUserLocation();
    await _fetchLocationsFromFirestore();
  }

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _getUserLocation() async {
    try {
      if (mounted) setState(() => _locationStatus = "Verificando permisos...");

      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) {
          if (mounted)
            setState(() => _locationStatus = "Servicio de ubicación denegado");
          return;
        }
      }

      PermissionStatus permissionGranted = await _locationService
          .hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          if (mounted)
            setState(() => _locationStatus = "Permiso de ubicación denegado");
          return;
        }
      }

      if (mounted) setState(() => _locationStatus = "Obteniendo ubicación...");

      _currentUserLocation = await _locationService.getLocation();
      if (mounted) setState(() => _locationStatus = "Ubicación encontrada");

      _locationSubscription = _locationService.onLocationChanged.listen((
        LocationData newLocation,
      ) {
        if (!mounted) return;
        if (_currentUserLocation == null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(newLocation.latitude!, newLocation.longitude!),
              15,
            ),
          );
        }
        setState(() {
          _currentUserLocation = newLocation;
          _updateUserLocationMarker();
        });
        if (_isNavigating) {
          _updateCameraForNavigation(newLocation);
          _checkStepCompletion(newLocation);
        }
      });
    } catch (e) {
      if (kDebugMode) print("Error en _getUserLocation: $e");
      if (mounted) setState(() => _locationStatus = "Error de ubicación");
    }
  }

  Future<void> _createRoute(
    LatLng destination, {
    String? destinationName,
  }) async {
    if (_currentUserLocation == null) {
      _showSnackBar(
        'Aún no se detecta tu ubicación. Intenta de nuevo.',
        isError: true,
      );
      return;
    }

    _stopNavigation(clearRoute: true);

    setState(() {
      _isCalculatingRoute = true;
      _currentDestination = destination;
      _currentDestinationName = destinationName ?? 'Destino';
    });

    try {
      final origin = LatLng(
        _currentUserLocation!.latitude!,
        _currentUserLocation!.longitude!,
      );
      if (kDebugMode)
        print(
          "Calculando ruta: ${_selectedTravelMode.toString().split('.').last}",
        );
      await _getRouteData(origin, destination, _selectedTravelMode);
    } finally {
      if (mounted) setState(() => _isCalculatingRoute = false);
    }
  }

  Future<void> _getRouteData(
    LatLng origin,
    LatLng destination,
    TravelMode travelMode,
  ) async {
    String travelModeStr = travelMode.toString().split('.').last;
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$travelModeStr&key=$googleMapsApiKey',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final points = route['overview_polyline']['points'] as String;
          final decodedPoints = PolylinePoints.decodePolyline(points);
          final polylineCoordinates = decodedPoints
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();

          final leg = route['legs'][0];
          final duration = leg['duration']['text'] as String;
          final durationSeconds = leg['duration']['value'] as int;
          final distanceMeters = leg['distance']['value'] as int;

          final newRouteSteps = <RouteStep>[];
          for (var step in leg['steps']) {
            newRouteSteps.add(
              RouteStep(
                instruction: _unescape.convert(step['html_instructions']),
                startLocation: LatLng(
                  step['start_location']['lat'],
                  step['start_location']['lng'],
                ),
                endLocation: LatLng(
                  step['end_location']['lat'],
                  step['end_location']['lng'],
                ),
                distance: step['distance']['text'] as String,
                duration: step['duration']['text'] as String,
              ),
            );
          }

          final routeInfo = RouteInfo(
            distance: distanceMeters.toDouble(),
            duration: duration,
            estimatedTimeMinutes: durationSeconds / 60,
          );

          _previewRoute(polylineCoordinates, newRouteSteps, routeInfo);
        } else {
          _showSnackBar('Error de Google: ${data['status']}', isError: true);
        }
      } else {
        _showSnackBar('Error de red (${response.statusCode})', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error al procesar la ruta', isError: true);
    }
  }

  void _previewRoute(
    List<LatLng> polylineCoordinates,
    List<RouteStep> newRouteSteps,
    RouteInfo routeInfo,
  ) {
    if (!mounted || polylineCoordinates.isEmpty || newRouteSteps.isEmpty)
      return;

    Polyline routePolyline = Polyline(
      polylineId: const PolylineId("route"),
      color: _accentGreen,
      points: polylineCoordinates,
      width: 6,
      geodesic: true,
    );

    setState(() {
      _polylines.add(routePolyline);
      _routeSteps = newRouteSteps;
      _currentRouteInfo = routeInfo;
      _routeIsPreview = true;
      _currentStepIndex = 0;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(_createBounds(polylineCoordinates), 100),
    );
  }

  void _startNavigation() {
    if (!_routeIsPreview) return;
    setState(() {
      _isNavigating = true;
      _routeIsPreview = false;
    });
    _speakCurrentInstruction();
  }

  void _stopNavigation({bool clearRoute = true}) {
    if (!mounted) return;
    setState(() {
      _isNavigating = false;
      _routeIsPreview = false;
      if (clearRoute) {
        _polylines.clear();
        _routeSteps.clear();
        _currentRouteInfo = null;
        _currentStepIndex = 0;
        _currentDestination = null;
        _currentDestinationName = null;
      }
    });
  }

  void _speakCurrentInstruction() {
    if (_isSoundEnabled &&
        _isNavigating &&
        _routeSteps.isNotEmpty &&
        _currentStepIndex < _routeSteps.length) {
      _flutterTts.speak(_routeSteps[_currentStepIndex].instruction);
    }
  }

  void _checkStepCompletion(LocationData currentLocation) {
    if (_routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) return;

    final nextStep = _routeSteps[_currentStepIndex];
    final distanceToNextStep = _calculateDistance(
      currentLocation.latitude!,
      currentLocation.longitude!,
      nextStep.endLocation.latitude,
      nextStep.endLocation.longitude,
    );

    if (distanceToNextStep < 20) {
      if (_currentStepIndex < _routeSteps.length - 1) {
        setState(() => _currentStepIndex++);
        _speakCurrentInstruction();
      } else {
        if (_isSoundEnabled) _flutterTts.speak("Has llegado a tu destino.");
        _stopNavigation();
        _showSnackBar('¡Destino alcanzado!', isSuccess: true);
      }
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwest = positions.reduce(
      (v, e) => LatLng(
        v.latitude < e.latitude ? v.latitude : e.latitude,
        v.longitude < e.longitude ? v.longitude : e.longitude,
      ),
    );
    final northeast = positions.reduce(
      (v, e) => LatLng(
        v.latitude > e.latitude ? v.latitude : e.latitude,
        v.longitude > e.longitude ? v.longitude : e.longitude,
      ),
    );
    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  void _updateUserLocationMarker() {
    if (_currentUserLocation == null) return;
    final userLatLng = LatLng(
      _currentUserLocation!.latitude!,
      _currentUserLocation!.longitude!,
    );
    _markers.removeWhere((m) => m.markerId.value == 'userLocation');
    _markers.add(
      Marker(
        markerId: const MarkerId('userLocation'),
        position: userLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        rotation: _currentUserLocation!.heading ?? 0,
        flat: true,
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      ),
    );
  }

  void _updateCameraForNavigation(LocationData locationData) {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 18.5,
          tilt: 50.0,
          bearing: locationData.heading ?? 0,
        ),
      ),
    );
  }

  Future<void> _fetchLocationsFromFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore.collection('locations').get();
      final fetchedMarkers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final destinationLatLng = LatLng(
          data['position'].latitude,
          data['position'].longitude,
        );

        return Marker(
          markerId: MarkerId(doc.id),
          position: destinationLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: data['name'],
            snippet: 'Toca para trazar la ruta',
            onTap: () =>
                _createRoute(destinationLatLng, destinationName: data['name']),
          ),
        );
      }).toSet();

      if (mounted) setState(() => _markers.addAll(fetchedMarkers));
    } catch (e) {
      if (kDebugMode) print("Error al cargar ubicaciones: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    controller.setMapStyle(json.encode(_mapStyle));
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color bgColor = _accentBlue;
    if (isError) bgColor = _errorColor;
    if (isSuccess) bgColor = _accentGreen;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: _textPrimary)),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNavigating ? "Navegando a $_currentDestinationName" : "Rutas",
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryDark,
        elevation: 8,
        leading: _isNavigating
            ? IconButton(
                icon: Icon(Icons.close, color: _textPrimary),
                onPressed: () => _stopNavigation(clearRoute: true),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location, color: _textPrimary),
            onPressed: () {
              if (_currentUserLocation != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      _currentUserLocation!.latitude!,
                      _currentUserLocation!.longitude!,
                    ),
                    16.0,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
              color: _textPrimary,
            ),
            onPressed: () => setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
        ],
      ),
      backgroundColor: _primaryDark,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-33.4489, -70.6693),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),
          if (_isNavigating && _routeSteps.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildInstructionBanner(),
            ),
          if (_routeIsPreview)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildRoutePreviewInfo(),
            ),
          if (!_isNavigating && !_routeIsPreview)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildTravelModeSelector(),
            ),
          if (_isCalculatingRoute)
            Container(
              color: _primaryDark.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: _accentGreen,
                  strokeWidth: 3,
                ),
              ),
            ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _secondaryDark.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: _accentGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _locationStatus,
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _routeIsPreview
          ? FloatingActionButton.extended(
              onPressed: _startNavigation,
              label: Text(
                "Iniciar",
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: Icon(Icons.navigation, color: _textPrimary),
              backgroundColor: _accentGreen,
              elevation: 8,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInstructionBanner() {
    if (_currentStepIndex >= _routeSteps.length) return const SizedBox.shrink();

    final step = _routeSteps[_currentStepIndex];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: _secondaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  step.instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.info, color: _accentGreen),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${step.distance} • ${step.duration}",
                style: TextStyle(color: _lightBlue, fontSize: 12),
              ),
              Text(
                "Paso ${_currentStepIndex + 1}/${_routeSteps.length}",
                style: TextStyle(color: _lightBlue, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentStepIndex + 1) / _routeSteps.length,
              backgroundColor: _accentBlue.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(_accentGreen),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePreviewInfo() {
    if (_currentRouteInfo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoChip(
            Icons.social_distance,
            _currentRouteInfo!.distance > 1000
                ? "${(_currentRouteInfo!.distance / 1000).toStringAsFixed(1)} km"
                : "${_currentRouteInfo!.distance.toStringAsFixed(0)} m",
          ),
          _buildInfoChip(Icons.schedule, _currentRouteInfo!.duration),
          _buildInfoChip(
            Icons.timer,
            "${_currentRouteInfo!.estimatedTimeMinutes.toStringAsFixed(0)} min",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _accentGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTravelModeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTravelModeButton(
            TravelMode.walking,
            Icons.directions_walk,
            'Caminando',
          ),
          _buildTravelModeButton(
            TravelMode.bicycling,
            Icons.directions_bike,
            'Bicicleta',
          ),
          _buildTravelModeButton(
            TravelMode.driving,
            Icons.directions_car,
            'Auto',
          ),
        ],
      ),
    );
  }

  Widget _buildTravelModeButton(TravelMode mode, IconData icon, String label) {
    bool isSelected = _selectedTravelMode == mode;
    return GestureDetector(
      onTap: () {
        if (!_isNavigating) {
          setState(() => _selectedTravelMode = mode);
          if (_currentDestination != null)
            _createRoute(
              _currentDestination!,
              destinationName: _currentDestinationName,
            );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accentGreen : _accentBlue.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _accentGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _textPrimary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _mapStyle = [
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
      "featureType": "administrative.country",
      "elementType": "geometry.stroke",
      "stylers": [
        {"color": "#4b6878"},
      ],
    },
    {
      "featureType": "administrative.land_parcel",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#64779e"},
      ],
    },
    {
      "featureType": "administrative.province",
      "elementType": "geometry.stroke",
      "stylers": [
        {"color": "#4b6878"},
      ],
    },
    {
      "featureType": "landscape.man_made",
      "elementType": "geometry.stroke",
      "stylers": [
        {"color": "#334e87"},
      ],
    },
    {
      "featureType": "landscape.natural",
      "elementType": "geometry",
      "stylers": [
        {"color": "#023e58"},
      ],
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [
        {"color": "#28356f"},
      ],
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#6f9ba5"},
      ],
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.stroke",
      "stylers": [
        {"color": "#1d2c4d"},
      ],
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry.fill",
      "stylers": [
        {"color": "#023e58"},
      ],
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#3C7680"},
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
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#98a5be"},
      ],
    },
    {
      "featureType": "road",
      "elementType": "labels.text.stroke",
      "stylers": [
        {"color": "#1d2c4d"},
      ],
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {"color": "#2c6675"},
      ],
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [
        {"color": "#255763"},
      ],
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#b0d5ce"},
      ],
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.stroke",
      "stylers": [
        {"color": "#023e58"},
      ],
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#98a5be"},
      ],
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.stroke",
      "stylers": [
        {"color": "#1d2c4d"},
      ],
    },
    {
      "featureType": "transit.line",
      "elementType": "geometry.fill",
      "stylers": [
        {"color": "#28356f"},
      ],
    },
    {
      "featureType": "transit.station",
      "elementType": "geometry",
      "stylers": [
        {"color": "#3a4762"},
      ],
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {"color": "#0e1626"},
      ],
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#4e6d70"},
      ],
    },
  ];
}
