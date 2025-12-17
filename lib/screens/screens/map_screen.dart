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

const String googleMapsApiKey = "AIzaSyAaqSFpbIpmmrjm8tyweYhw-rayaC0O9lA";

enum TravelMode { walking, bicycling }

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
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _accentGreen = Color(0xFF00C853);
  static const Color _errorRed = Color(0xFFE53935);

  GoogleMapController? _mapController;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final FlutterTts _flutterTts = FlutterTts();
  final HtmlUnescape _unescape = HtmlUnescape();

  LocationData? _currentUserLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _allRoutePoints = [];

  bool _isCalculatingRoute = false;
  TravelMode _selectedTravelMode = TravelMode.walking;
  List<RouteStep> _routeSteps = [];
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  bool _routeIsPreview = false;
  LatLng? _currentDestination;
  String? _currentDestinationName;

  @override
  void initState() {
    super.initState();
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
    await _getUserLocation();
    await _fetchLocationsFromFirestore();
  }

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled)
      serviceEnabled = await _locationService.requestService();

    _locationSubscription = _locationService.onLocationChanged.listen((
      LocationData newLocation,
    ) {
      if (!mounted) return;
      setState(() {
        _currentUserLocation = newLocation;
        _updateUserLocationMarker();
      });
      if (_isNavigating) {
        _updateCameraForNavigation(newLocation);
        _updateNavigation(newLocation);
      }
    });
  }

  Future<void> _fetchLocationsFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('comercios')
          .get();
      final fetchedMarkers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final Map<String, dynamic> ubicacion = data['ubicacion'];
        final pos = LatLng(
          (ubicacion['lat'] as num).toDouble(),
          (ubicacion['lng'] as num).toDouble(),
        );
        final nombre = data['nombre'] ?? 'Comercio';

        return Marker(
          markerId: MarkerId(doc.id),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: nombre,
            snippet: 'Toca para iniciar ruta',
            onTap: () => _createRoute(pos, destinationName: nombre),
          ),
        );
      }).toSet();
      setState(() => _markers.addAll(fetchedMarkers));
    } catch (e) {
      if (kDebugMode) print("Error Firestore: $e");
    }
  }

  Future<void> _createRoute(
    LatLng destination, {
    String? destinationName,
  }) async {
    if (_currentUserLocation == null) return;
    setState(() {
      _isCalculatingRoute = true;
      _currentDestination = destination;
      _currentDestinationName = destinationName;
    });

    final origin = LatLng(
      _currentUserLocation!.latitude!,
      _currentUserLocation!.longitude!,
    );
    String mode = _selectedTravelMode == TravelMode.walking
        ? "walking"
        : "bicycling";

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$mode&language=es&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final points = PolylinePoints.decodePolyline(
            route['overview_polyline']['points'],
          );
          _allRoutePoints = points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();

          final steps = <RouteStep>[];
          for (var s in leg['steps']) {
            String cleanText = _unescape
                .convert(s['html_instructions'])
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();

            steps.add(
              RouteStep(
                instruction: cleanText,
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
              ),
            );
          }

          setState(() {
            _routeSteps = steps;
            _currentStepIndex = 0;
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId("r"),
                points: _allRoutePoints,
                color: _accentGreen,
                width: 6,
              ),
            );
            _routeIsPreview = true;
            _isCalculatingRoute = false;
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(_createBounds(_allRoutePoints), 80),
          );
        }
      }
    } catch (e) {
      setState(() => _isCalculatingRoute = false);
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
  }

  void _updateNavigation(LocationData current) {
    if (_routeSteps.isEmpty) return;
    final step = _routeSteps[_currentStepIndex];
    double d = _calculateDistance(
      current.latitude!,
      current.longitude!,
      step.endLocation.latitude,
      step.endLocation.longitude,
    );

    if (d < 15 && _currentStepIndex < _routeSteps.length - 1) {
      setState(() => _currentStepIndex++);
      _flutterTts.speak(_routeSteps[_currentStepIndex].instruction);
    }
  }

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
            initialCameraPosition: const CameraPosition(
              target: LatLng(-35.4333, -71.6218),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
          ),

          // --- UI DE CABECERA (Modo y Cancelar) ---
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (!_isNavigating && !_routeIsPreview) _buildModeSelector(),
                if (_isNavigating) _buildNavigationBanner(),
              ],
            ),
          ),

          // --- BOTONES LATERALES ---
          Positioned(
            right: 15,
            bottom: 150,
            child: Column(
              children: [
                if (_isNavigating)
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: _primaryDark,
                    onPressed: () =>
                        _updateCameraForNavigation(_currentUserLocation!),
                    child: const Icon(Icons.my_location, color: _accentGreen),
                  ),
                const SizedBox(height: 10),
                if (_isNavigating)
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: _errorRed,
                    onPressed: _stopNavigation,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
              ],
            ),
          ),

          if (_routeIsPreview) _buildPreviewCard(),
          if (_isCalculatingRoute)
            const Center(child: CircularProgressIndicator(color: _accentGreen)),
        ],
      ),
      floatingActionButton: _routeIsPreview
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isNavigating = true;
                  _routeIsPreview = false;
                });
                _flutterTts.speak(_routeSteps[0].instruction);
              },
              label: const Text("INICIAR"),
              icon: const Icon(Icons.navigation),
              backgroundColor: _accentGreen,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _primaryDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(TravelMode.walking, Icons.directions_walk),
          const SizedBox(width: 10),
          _modeButton(TravelMode.bicycling, Icons.directions_bike),
        ],
      ),
    );
  }

  Widget _modeButton(TravelMode mode, IconData icon) {
    bool isSelected = _selectedTravelMode == mode;
    return IconButton(
      icon: Icon(icon, color: isSelected ? _accentGreen : Colors.white54),
      onPressed: () => setState(() => _selectedTravelMode = mode),
    );
  }

  Widget _buildNavigationBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _primaryDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _accentGreen, width: 2),
      ),
      child: Text(
        _routeSteps[_currentStepIndex].instruction,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Card(
        color: _primaryDark,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Destino: $_currentDestinationName",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Modo: ${_selectedTravelMode == TravelMode.walking ? 'Caminando' : 'Bicicleta'}",
                style: const TextStyle(color: _accentGreen),
              ),
              TextButton(
                onPressed: () => setState(() => _routeIsPreview = false),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---
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
    final sw = LatLng(
      positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
      positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
    );
    final ne = LatLng(
      positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
      positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
    );
    return LatLngBounds(southwest: sw, northeast: ne);
  }

  void _updateUserLocationMarker() {
    _markers.removeWhere((m) => m.markerId.value == 'me');
    _markers.add(
      Marker(
        markerId: const MarkerId('me'),
        position: LatLng(
          _currentUserLocation!.latitude!,
          _currentUserLocation!.longitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
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

  final String _customMapStyle = jsonEncode([
    {
      "elementType": "geometry",
      "stylers": [
        {"color": "#242f3e"},
      ],
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#746855"},
      ],
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {"color": "#38414e"},
      ],
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#9ca5b3"},
      ],
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {"color": "#17263c"},
      ],
    },
  ]);
}
