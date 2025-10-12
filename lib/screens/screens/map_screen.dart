import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String googleMapsApiKey = "AIzaSyAaqSFpbIpmmrjm8tyweYhw-rayaC0O9lA";

class MapScreen extends StatefulWidget {
  final User user;
  const MapScreen({super.key, required this.user});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Colores del tema dark blue
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _lightBlue = Color(0xFF778DA9);
  static const Color _textPrimary = Color(0xFFE0E1DD);

  GoogleMapController? _mapController;
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-33.4489, -70.6693), // Santiago de Chile
    zoom: 12,
  );

  final Location _locationService = Location();
  LocationData? _currentUserLocation;
  StreamSubscription<LocationData>? _locationSubscription;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  TravelMode _selectedTravelMode = TravelMode.walking;

  @override
  void initState() {
    super.initState();
    _initLocationAndMarkers();
  }

  Future<void> _initLocationAndMarkers() async {
    await _getUserLocation();
    await _fetchLocationsFromFirestore();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationSubscription = _locationService.onLocationChanged.listen((
      locationData,
    ) {
      if (mounted) {
        setState(() {
          _currentUserLocation = locationData;
          _updateUserLocationMarker();
        });
      }
    });
  }

  void _updateUserLocationMarker() {
    if (_currentUserLocation != null) {
      final userLatLng = LatLng(
        _currentUserLocation!.latitude!,
        _currentUserLocation!.longitude!,
      );

      _markers.removeWhere((marker) => marker.markerId.value == 'userLocation');
      _markers.add(
        Marker(
          markerId: const MarkerId('userLocation'),
          position: userLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(title: 'Mi Ubicación'),
        ),
      );
    }
  }

  Future<void> _fetchLocationsFromFirestore() async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('locations').get();

    final fetchedMarkers = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final String name = data['name'] ?? 'Destino sin nombre';
      final GeoPoint position = data['position'];
      final destinationLatLng = LatLng(position.latitude, position.longitude);

      return Marker(
        markerId: MarkerId(doc.id),
        position: destinationLatLng,
        infoWindow: InfoWindow(
          title: name,
          snippet: 'Toca aquí para trazar una ruta',
        ),
        onTap: () {
          _createRoute(destinationLatLng);
        },
      );
    }).toSet();

    setState(() {
      _markers.addAll(fetchedMarkers);
    });
  }

  Future<void> _createRoute(LatLng destination) async {
    if (_currentUserLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede obtener tu ubicación actual.',
            style: TextStyle(color: _textPrimary),
          ),
          backgroundColor: _secondaryDark,
        ),
      );
      return;
    }

    final origin = LatLng(
      _currentUserLocation!.latitude!,
      _currentUserLocation!.longitude!,
    );
    await _getPolyline(origin, destination, _selectedTravelMode);
  }

  Future<void> _getPolyline(
    LatLng origin,
    LatLng destination,
    TravelMode travelMode,
  ) async {
    List<LatLng> polylineCoordinates = [];

    String travelModeStr = travelMode.toString().split('.').last;

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$travelModeStr&key=$googleMapsApiKey',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final result = PolylinePoints.decodePolyline(points);

          if (result.isNotEmpty) {
            polylineCoordinates.addAll(
              result.map((point) => LatLng(point.latitude, point.longitude)),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No se encontraron rutas.',
                style: TextStyle(color: _textPrimary),
              ),
              backgroundColor: _secondaryDark,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al obtener la ruta.',
              style: TextStyle(color: _textPrimary),
            ),
            backgroundColor: _secondaryDark,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Excepción al llamar a la API de Direcciones: $e');
      }
    }

    _addPolylineToMap(polylineCoordinates);
  }

  void _addPolylineToMap(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("route");
    Polyline polyline = Polyline(
      polylineId: id,
      color: _lightBlue,
      points: polylineCoordinates,
      width: 6,
    );
    setState(() {
      _polylines.clear();
      _polylines.add(polyline);
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa de Rutas", style: TextStyle(color: _textPrimary)),
        backgroundColor: _primaryDark,
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
        ],
      ),
      backgroundColor: _primaryDark,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              controller.setMapStyle(json.encode(_mapStyle));
            },
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildTravelModeSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelModeSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
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
        ],
      ),
    );
  }

  Widget _buildTravelModeButton(TravelMode mode, IconData icon, String label) {
    bool isSelected = _selectedTravelMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTravelMode = mode;
          _polylines.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Modo $label. Toca un destino para ver la ruta.',
              style: TextStyle(color: _textPrimary),
            ),
            backgroundColor: _secondaryDark,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: _textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textPrimary,
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
