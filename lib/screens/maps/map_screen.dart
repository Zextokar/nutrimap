// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, min;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

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

  // --- NAVIGATION ---
  static const double _maxDeviationMeters = 50;
  bool _isCalculatingRoute = false;
  bool _isNavigating = false;
  bool _routeIsPreview = false;

  final TravelMode _selectedTravelMode = TravelMode.walking;
  List<RouteStep> _routeSteps = [];
  int _currentStepIndex = 0;

  LatLng? _currentDestination;
  String? _currentDestinationName;

  // --- TTS ---
  final FlutterTts _flutterTts = FlutterTts();
  final HtmlUnescape _unescape = HtmlUnescape();

  @override
  void initState() {
    super.initState();
    _initServices();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDestination != null) {
        _createRoute(
          widget.initialDestination!,
          destinationName: widget.initialDestinationName,
        );
      }
    });
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

  // ================== LOCATION ==================

  Future<void> _getUserLocation() async {
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
      interval: 2000,
      distanceFilter: 5,
    );

    _locationSubscription = _locationService.onLocationChanged.listen(
      _onLocationUpdate,
    );
  }

  void _onLocationUpdate(LocationData loc) {
    if (!mounted) return;

    _currentUserLocation = loc;
    _updateUserLocationMarker();

    if (_isNavigating) {
      _updateCameraForNavigation(loc);
      _updateNavigation(loc);
      _checkRouteDeviation(loc);
    }
  }

  void _updateUserLocationMarker() {
    if (_currentUserLocation == null) return;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'me');
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
    });
  }

  void _centerOnUser() {
    if (_currentUserLocation == null || _mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentUserLocation!.latitude!,
            _currentUserLocation!.longitude!,
          ),
          zoom: _isNavigating ? 19 : 16,
          tilt: _isNavigating ? 60 : 0,
          bearing: _currentUserLocation!.heading ?? 0,
        ),
      ),
    );
  }

  // ================== FIRESTORE ==================

  Future<void> _fetchLocationsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('comercios')
          .get();

      final markers = snapshot.docs.map((doc) {
        final data = doc.data();
        final ubicacion = data['ubicacion'];

        final pos = LatLng(
          (ubicacion['lat'] as num).toDouble(),
          (ubicacion['lng'] as num).toDouble(),
        );

        return Marker(
          markerId: MarkerId(doc.id),
          position: pos,
          infoWindow: InfoWindow(
            title: data['nombre'],
            snippet: 'Toca para iniciar ruta',
            onTap: () => _createRoute(pos, destinationName: data['nombre']),
          ),
        );
      }).toSet();

      setState(() => _markers.addAll(markers));
    } catch (e) {
      if (kDebugMode) {
        print('Firestore error: $e');
      }
    }
  }

  // ================== ROUTING ==================

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

    final mode = _selectedTravelMode == TravelMode.walking
        ? 'walking'
        : 'bicycling';

    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$mode&language=es&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final leg = route['legs'][0];

        _allRoutePoints = PolylinePoints.decodePolyline(
          route['overview_polyline']['points'],
        ).map((p) => LatLng(p.latitude, p.longitude)).toList();

        _routeSteps = leg['steps'].map<RouteStep>((s) {
          final cleanText = _unescape
              .convert(s['html_instructions'])
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();

          return RouteStep(
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
          );
        }).toList();

        setState(() {
          _polylines
            ..clear()
            ..add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: _allRoutePoints,
                color: _accentGreen,
                width: 6,
              ),
            );
          _routeIsPreview = true;
          _isCalculatingRoute = false;
          _currentStepIndex = 0;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(_createBounds(_allRoutePoints), 80),
        );
      }
    } catch (_) {
      setState(() => _isCalculatingRoute = false);
    }
  }

  void _checkRouteDeviation(LocationData loc) {
    if (_allRoutePoints.isEmpty) return;

    final current = LatLng(loc.latitude!, loc.longitude!);
    final minDistance = _allRoutePoints
        .map(
          (p) => _calculateDistance(
            current.latitude,
            current.longitude,
            p.latitude,
            p.longitude,
          ),
        )
        .reduce(min);

    if (minDistance > _maxDeviationMeters) {
      _recalculateRoute();
    }
  }

  Future<void> _recalculateRoute() async {
    if (_currentDestination == null) return;
    await _flutterTts.speak("Recalculando ruta");
    await _createRoute(
      _currentDestination!,
      destinationName: _currentDestinationName,
    );
    setState(() {
      _isNavigating = true;
      _routeIsPreview = false;
    });
  }

  void _updateNavigation(LocationData loc) {
    final step = _routeSteps[_currentStepIndex];
    final distance = _calculateDistance(
      loc.latitude!,
      loc.longitude!,
      step.endLocation.latitude,
      step.endLocation.longitude,
    );

    if (distance < 15 && _currentStepIndex < _routeSteps.length - 1) {
      setState(() => _currentStepIndex++);
      _flutterTts.speak(_routeSteps[_currentStepIndex].instruction);
    }
  }

  // ignore: unused_element
  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _routeIsPreview = false;
      _polylines.clear();
      _routeSteps.clear();
    });
    _flutterTts.stop();
  }

  // ================== UI ==================

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
          ),

          Positioned(
            right: 15,
            bottom: _isNavigating ? 220 : 120,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: _primaryDark,
              onPressed: _centerOnUser,
              child: const Icon(Icons.my_location, color: _accentGreen),
            ),
          ),

          if (_routeIsPreview) _buildPreviewCard(),
          if (_isCalculatingRoute)
            const Center(child: CircularProgressIndicator(color: _accentGreen)),
        ],
      ),
      floatingActionButton: _routeIsPreview
          ? FloatingActionButton.extended(
              backgroundColor: _accentGreen,
              icon: const Icon(Icons.navigation),
              label: const Text("INICIAR"),
              onPressed: () {
                setState(() {
                  _isNavigating = true;
                  _routeIsPreview = false;
                });
                _flutterTts.speak(_routeSteps.first.instruction);
              },
            )
          : null,
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

  // ================== HELPERS ==================

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
    return 12742 * asin(sqrt(a)) * 1000;
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
  ]);
}
