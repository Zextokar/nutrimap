import 'dart:async';
import 'dart:convert';
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

// Clave de API de Google Maps
const String GOOGLE_MAPS_API_KEY = "AIzaSyAaqSFpbIpmmrjm8tyweYhw-rayaC0O9lA";

class MapScreen extends StatefulWidget {
  final User user;
  const MapScreen({super.key, required this.user});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class RouteStep {
  final String instruction;
  final LatLng startLocation;
  final LatLng endLocation;
  RouteStep({required this.instruction, required this.startLocation, required this.endLocation});
}

class _MapScreenState extends State<MapScreen> {
  // --- Colores y Estilos ---
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _lightBlue = Color(0xFF778DA9);
  static const Color _textPrimary = Color(0xFFE0E1DD);
  static const Color _errorColor = Color(0xFFD90429);


  // --- Controladores y Servicios ---
  GoogleMapController? _mapController;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final FlutterTts _flutterTts = FlutterTts();
  final HtmlUnescape _unescape = HtmlUnescape();

  // --- Estado del Mapa y Navegación ---
  LocationData? _currentUserLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isCalculatingRoute = false;
  TravelMode _selectedTravelMode = TravelMode.walking;
  
  String _locationStatus = "Iniciando...";

  // --- Lógica de Navegación Paso a Paso ---
  List<RouteStep> _routeSteps = [];
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  bool _routeIsPreview = false; 

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
  }

  Future<void> _getUserLocation() async {
    try {
      if(mounted) setState(() { _locationStatus = "Verificando permisos..."; });
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) {
           if(mounted) setState(() { _locationStatus = "Servicio de ubicación denegado"; });
           return;
        }
      }

      PermissionStatus permissionGranted = await _locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          if(mounted) setState(() { _locationStatus = "Permiso de ubicación denegado"; });
          return;
        }
      }
      
      if(mounted) setState(() { _locationStatus = "Obteniendo ubicación..."; });
      _currentUserLocation = await _locationService.getLocation();
      if(mounted) setState(() { _locationStatus = "Ubicación encontrada"; });

      _locationSubscription = _locationService.onLocationChanged.listen((LocationData newLocation) {
        if (!mounted) return;
        if(_currentUserLocation == null && _mapController != null){ // Centrar mapa en la primera ubicación
            _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(newLocation.latitude!, newLocation.longitude!), 15));
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
      print("Error crítico en _getUserLocation: $e");
      if(mounted) setState(() { _locationStatus = "Error de ubicación"; });
    }
  }
  
  Future<void> _createRoute(LatLng destination) async {
    // --- INICIO DE DIAGNÓSTICO ---
    print("1. Intento de crear ruta iniciado.");
    if (_currentUserLocation == null) {
      print("2. FALLO: La ubicación del usuario es nula. No se puede crear la ruta.");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aún no se detecta tu ubicación. Intenta de nuevo.', style: TextStyle(color: _textPrimary)), backgroundColor: _accentBlue));
      return;
    }
    
    print("3. Ubicación del usuario OK. Limpiando rutas anteriores.");
    _stopNavigation(clearRoute: true);
    
    print("4. Mostrando indicador de carga.");
    setState(() { _isCalculatingRoute = true; });

    try {
      final origin = LatLng(_currentUserLocation!.latitude!, _currentUserLocation!.longitude!);
      print("5. Solicitando ruta desde $origin hasta $destination.");
      await _getRouteData(origin, destination, _selectedTravelMode);
    } finally {
       if (mounted) {
         print("6. Proceso de creación de ruta finalizado. Ocultando carga.");
         setState(() { _isCalculatingRoute = false; });
       }
    }
     // --- FIN DE DIAGNÓSTICO ---
  }

  Future<void> _getRouteData(LatLng origin, LatLng destination, TravelMode travelMode) async {
    String travelModeStr = travelMode.toString().split('.').last;
    final uri = Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$travelModeStr&key=$GOOGLE_MAPS_API_KEY');
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          print("7. Respuesta de la API de Google OK.");
          final route = data['routes'][0];
          final points = route['overview_polyline']['points'] as String;
          final decodedPoints = PolylinePoints.decodePolyline(points);
          final polylineCoordinates = decodedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

          final leg = route['legs'][0];
          final newRouteSteps = <RouteStep>[];
          for (var step in leg['steps']) {
            newRouteSteps.add(RouteStep(instruction: _unescape.convert(step['html_instructions']), startLocation: LatLng(step['start_location']['lat'], step['start_location']['lng']), endLocation: LatLng(step['end_location']['lat'], step['end_location']['lng'])));
          }
          _previewRoute(polylineCoordinates, newRouteSteps);
        } else {
          String error = data['error_message'] ?? 'Ruta no encontrada.';
          print("8. FALLO API: ${data['status']} - $error");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de Google: ${data['status']}', style: TextStyle(color: _textPrimary)), backgroundColor: _errorColor));
        }
      } else {
         print("8. FALLO RED: Código ${response.statusCode}");
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de red (${response.statusCode}). Revisa tu conexión.', style: TextStyle(color: _textPrimary)), backgroundColor: _errorColor));
      }
    } catch (e) {
      print("8. FALLO CRÍTICO en _getRouteData: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al procesar la ruta.', style: TextStyle(color: _textPrimary)), backgroundColor: _errorColor));
    }
  }
  
  void _previewRoute(List<LatLng> polylineCoordinates, List<RouteStep> newRouteSteps) {
    if (!mounted || polylineCoordinates.isEmpty || newRouteSteps.isEmpty) {
        print("9. FALLO: No se puede mostrar la vista previa, datos inválidos.");
        return;
    };
    print("9. Mostrando vista previa de la ruta.");
    Polyline routePolyline = Polyline(polylineId: const PolylineId("route"), color: _lightBlue, points: polylineCoordinates, width: 6);
    setState(() {
      _polylines.add(routePolyline);
      _routeSteps = newRouteSteps;
      _routeIsPreview = true;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(_createBounds(polylineCoordinates), 50));
  }
  
  void _startNavigation() {
    if (!_routeIsPreview) return;
    print("10. Iniciando navegación paso a paso.");
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
        _currentStepIndex = 0;
      }
    });
  }

  void _speakCurrentInstruction() {
    if (_isNavigating && _routeSteps.isNotEmpty && _currentStepIndex < _routeSteps.length) {
      _flutterTts.speak(_routeSteps[_currentStepIndex].instruction);
    }
  }

  void _checkStepCompletion(LocationData currentLocation) {
    if (_routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) return;
    final nextStep = _routeSteps[_currentStepIndex];
    final distanceToNextStep = _calculateDistance(currentLocation.latitude!, currentLocation.longitude!, nextStep.endLocation.latitude, nextStep.endLocation.longitude);

    if (distanceToNextStep < 20) {
      if (_currentStepIndex < _routeSteps.length - 1) {
        setState(() { _currentStepIndex++; });
        _speakCurrentInstruction();
      } else {
        _flutterTts.speak("Has llegado a tu destino.");
        _stopNavigation();
      }
    }
  }

  double _calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p)/2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwest = positions.reduce((v, e) => LatLng(v.latitude < e.latitude ? v.latitude : e.latitude, v.longitude < e.longitude ? v.longitude : e.longitude));
    final northeast = positions.reduce((v, e) => LatLng(v.latitude > e.latitude ? v.latitude : e.latitude, v.longitude > e.longitude ? v.longitude : e.longitude));
    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  void _updateUserLocationMarker() {
     if (_currentUserLocation == null) return;
    final userLatLng = LatLng(_currentUserLocation!.latitude!, _currentUserLocation!.longitude!);
    _markers.removeWhere((m) => m.markerId.value == 'userLocation');
    _markers.add(Marker(markerId: const MarkerId('userLocation'), position: userLatLng, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan), anchor: const Offset(0.5, 0.5), rotation: _currentUserLocation!.heading ?? 0, flat: true));
  }

  void _updateCameraForNavigation(LocationData locationData) {
    if (_mapController == null) return;
    _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(locationData.latitude!, locationData.longitude!), zoom: 18.5, tilt: 60.0, bearing: locationData.heading ?? 0)));
  }

  Future<void> _fetchLocationsFromFirestore() async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('locations').get();
    final fetchedMarkers = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final destinationLatLng = LatLng(data['position'].latitude, data['position'].longitude);
      // --- CAMBIO CLAVE: El evento ahora está en la ventana de información ---
      return Marker(
        markerId: MarkerId(doc.id), 
        position: destinationLatLng, 
        infoWindow: InfoWindow(
          title: data['name'], 
          snippet: 'Toca aquí para trazar la ruta',
          onTap: () {
            print("--- Ventana de información tocada para ${data['name']} ---");
            _createRoute(destinationLatLng);
          }
        )
      );
    }).toSet();
    if(mounted) setState(() { _markers.addAll(fetchedMarkers); });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    controller.setMapStyle(json.encode(_mapStyle));
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
        title: Text(_isNavigating ? "Navegando..." : "Mapa de Rutas", style: TextStyle(color: _textPrimary)),
        backgroundColor: _primaryDark,
        leading: _isNavigating ? IconButton(icon: Icon(Icons.close, color: _textPrimary), onPressed: () => _stopNavigation(clearRoute: true)) : null,
        actions: [
          if (!_isNavigating)
            IconButton(
              icon: Icon(Icons.my_location, color: _textPrimary),
              onPressed: () {
                if (_currentUserLocation != null && _mapController != null) {
                  _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_currentUserLocation!.latitude!, _currentUserLocation!.longitude!), 16.0));
                }
              },
            ),
        ],
      ),
      backgroundColor: _primaryDark,
      body: Stack(
        children: [
          GoogleMap(onMapCreated: _onMapCreated, initialCameraPosition: const CameraPosition(target: LatLng(-33.4489, -70.6693), zoom: 12), markers: _markers, polylines: _polylines, myLocationEnabled: false, myLocationButtonEnabled: false, zoomControlsEnabled: false, compassEnabled: false),
          if (_isNavigating && _routeSteps.isNotEmpty)
            Positioned(top: 0, left: 0, right: 0, child: _buildInstructionBanner()),
          
          if (!_isNavigating && !_routeIsPreview)
            Positioned(bottom: 20, left: 20, right: 20, child: _buildTravelModeSelector()),

          if (_isCalculatingRoute)
            Container(color: _primaryDark.withOpacity(0.7), child: const Center(child: CircularProgressIndicator(color: _lightBlue))),
          
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _secondaryDark.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                child: Text(_locationStatus, style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _routeIsPreview
        ? FloatingActionButton.extended(onPressed: _startNavigation, label: Text("Iniciar Navegación", style: TextStyle(color: _textPrimary)), icon: Icon(Icons.navigation_outlined, color: _textPrimary), backgroundColor: _accentBlue)
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  Widget _buildInstructionBanner() {
    if (_currentStepIndex >= _routeSteps.length) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: _secondaryDark, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)]),
      child: Text(_routeSteps[_currentStepIndex].instruction, textAlign: TextAlign.center, style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTravelModeSelector() {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _secondaryDark, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildTravelModeButton(TravelMode.walking, Icons.directions_walk, 'Caminando'),
        _buildTravelModeButton(TravelMode.bicycling, Icons.directions_bike, 'Bicicleta'),
      ]));
  }

  Widget _buildTravelModeButton(TravelMode mode, IconData icon, String label) {
    bool isSelected = _selectedTravelMode == mode;
    return GestureDetector(
      onTap: () { if (!_isNavigating && !_routeIsPreview) setState(() { _selectedTravelMode = mode; }); },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: isSelected ? _accentBlue : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [Icon(icon, color: _textPrimary), const SizedBox(width: 8), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary))])),
    );
  }
  
  final List<Map<String, dynamic>> _mapStyle = [ { "elementType": "geometry", "stylers": [ { "color": "#1d2c4d" } ] }, { "elementType": "labels.text.fill", "stylers": [ { "color": "#8ec3b9" } ] }, { "elementType": "labels.text.stroke", "stylers": [ { "color": "#1a3646" } ] }, { "featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [ { "color": "#4b6878" } ] }, { "featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [ { "color": "#64779e" } ] }, { "featureType": "administrative.province", "elementType": "geometry.stroke", "stylers": [ { "color": "#4b6878" } ] }, { "featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [ { "color": "#334e87" } ] }, { "featureType": "landscape.natural", "elementType": "geometry", "stylers": [ { "color": "#023e58" } ] }, { "featureType": "poi", "elementType": "geometry", "stylers": [ { "color": "#28356f" } ] }, { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#6f9ba5" } ] }, { "featureType": "poi", "elementType": "labels.text.stroke", "stylers": [ { "color": "#1d2c4d" } ] }, { "featureType": "poi.park", "elementType": "geometry.fill", "stylers": [ { "color": "#023e58" } ] }, { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [ { "color": "#3C7680" } ] }, { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#304a7d" } ] }, { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#98a5be" } ] }, { "featureType": "road", "elementType": "labels.text.stroke", "stylers": [ { "color": "#1d2c4d" } ] }, { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#2c6675" } ] }, { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [ { "color": "#255763" } ] }, { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [ { "color": "#b0d5ce" } ] }, { "featureType": "road.highway", "elementType": "labels.text.stroke", "stylers": [ { "color": "#023e58" } ] }, { "featureType": "transit", "elementType": "labels.text.fill", "stylers": [ { "color": "#98a5be" } ] }, { "featureType": "transit", "elementType": "labels.text.stroke", "stylers": [ { "color": "#1d2c4d" } ] }, { "featureType": "transit.line", "elementType": "geometry.fill", "stylers": [ { "color": "#28356f" } ] }, { "featureType": "transit.station", "elementType": "geometry", "stylers": [ { "color": "#3a4762" } ] }, { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#0e1626" } ] }, { "featureType": "water", "elementType": "labels.text.fill", "stylers": [ { "color": "#4e6d70" } ] } ];
}

