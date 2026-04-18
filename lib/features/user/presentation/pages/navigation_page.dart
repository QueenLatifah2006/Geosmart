import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/utils/coordinate_parser.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:geolocator/geolocator.dart';

import 'dart:async';
import 'package:geosmart/core/services/api_service.dart';
import 'package:flutter/foundation.dart';

class NavigationPage extends StatefulWidget {
  final Map<String, dynamic> destination;
  final String transportType;
  final String mapStyle;

  const NavigationPage({
    Key? key,
    required this.destination,
    required this.transportType,
    required this.mapStyle,
  }) : super(key: key);

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  ml.LatLng? _currentPosition;
  ml.MapLibreMapController? _mapController;
  bool _isStyleLoaded = false;
  final ApiService _apiService = ApiService();
  StreamSubscription<Position>? _positionSubscription;
  List<ml.LatLng> _routePoints = [];
  double _distance = 0.0;
  String _estimatedTime = "--:--";

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Get initial position
    final position = await Geolocator.getCurrentPosition();
    _updatePosition(position);

    // Listen for updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Reduced for smoother real-time tracking
      ),
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position position) {
    setState(() {
      _currentPosition = ml.LatLng(position.latitude, position.longitude);
    });
    
    _mapController?.animateCamera(ml.CameraUpdate.newLatLng(_currentPosition!));
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null) return;

    // Use CoordinateParser for destination lat/lng
    double? destLat;
    double? destLng;

    if (widget.destination['lat'] != null) {
      destLat = widget.destination['lat'] is String 
          ? CoordinateParser.parse(widget.destination['lat']) 
          : (widget.destination['lat'] as num).toDouble();
    }
    
    if (widget.destination['lng'] != null) {
      destLng = widget.destination['lng'] is String 
          ? CoordinateParser.parse(widget.destination['lng']) 
          : (widget.destination['lng'] as num).toDouble();
    }

    if (destLat == null || destLng == null) return;

    final routeData = await _apiService.getRoute(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      destLat!,
      destLng!,
    );

    if (routeData.isNotEmpty) {
      setState(() {
        _routePoints = routeData.map((p) => ml.LatLng(p['lat']!, p['lng']!)).toList();
        
        _distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          destLat!,
          destLng!,
        ) / 1000;

        // Estimate time based on transport type
        double speedKmh = 40; // Default car
        if (widget.transportType == 'Pied') speedKmh = 5;
        if (widget.transportType == 'Vélo') speedKmh = 15;
        if (widget.transportType == 'Bus') speedKmh = 30;

        double hours = _distance / speedKmh;
        int minutes = (hours * 60).round();
        final now = DateTime.now();
        final arrival = now.add(Duration(minutes: minutes));
        _estimatedTime = "${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}";
      });
      _addMarkers();
    }
  }

  void _onMapCreated(ml.MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    if (!mounted) return;
    setState(() {
      _isStyleLoaded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _addMarkers();
    });
  }

  void _addMarkers() async {
    if (_mapController == null || !_isStyleLoaded) return;
    await _mapController!.clearSymbols();
    await _mapController!.clearLines();

    double? destLat;
    double? destLng;

    if (widget.destination['lat'] != null) {
      destLat = widget.destination['lat'] is String 
          ? CoordinateParser.parse(widget.destination['lat']) 
          : (widget.destination['lat'] as num).toDouble();
    }
    
    if (widget.destination['lng'] != null) {
      destLng = widget.destination['lng'] is String 
          ? CoordinateParser.parse(widget.destination['lng']) 
          : (widget.destination['lng'] as num).toDouble();
    }

    if (destLat == null || destLng == null) return;
    final destLatLng = ml.LatLng(destLat, destLng);

    if (_currentPosition != null) {
      // User Marker - Change color/icon based on transport
      String userIconColor = "#3B82F6"; // Default Blue
      String transportEmoji = "📍";
      if (widget.transportType == 'Voiture') {
        userIconColor = "#EF4444";
        transportEmoji = "🚗";
      }
      if (widget.transportType == 'Vélo') {
        userIconColor = "#10B981";
        transportEmoji = "🚲";
      }
      if (widget.transportType == 'Pied') {
        userIconColor = "#F59E0B";
        transportEmoji = "🚶";
      }
      if (widget.transportType == 'Bus') {
        userIconColor = "#8B5CF6";
        transportEmoji = "🚌";
      }

      await _mapController!.addSymbol(ml.SymbolOptions(
        geometry: _currentPosition!,
        iconSize: 0.1, // Hide icon if it fails
        textField: transportEmoji,
        textSize: 24,
        textOffset: const Offset(0, 0),
        textColor: "#FFFFFF",
      ));

      // Route Line
      if (_routePoints.isNotEmpty) {
        await _mapController!.addLine(ml.LineOptions(
          geometry: _routePoints,
          lineColor: userIconColor,
          lineWidth: 6.0,
          lineOpacity: 0.8,
        ));
      }
    }

    // Destination Marker
    await _mapController!.addSymbol(ml.SymbolOptions(
      geometry: destLatLng,
      textField: "🏁",
      textSize: 24,
      textOffset: const Offset(0, 0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    String styleUrl = 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';
    double pitch = 0.0;
    double bearing = 0.0;

    if (widget.mapStyle == 'Satellite') {
      styleUrl = 'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json'; 
    } else if (widget.mapStyle == '3D') {
      styleUrl = 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
      pitch = 60.0; // 3D Tilt
      bearing = -15.0;
    } else if (widget.mapStyle == 'Terrain') {
      styleUrl = 'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';
    } else if (widget.mapStyle == 'Standard' && !isDarkMode) {
      styleUrl = 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // MapLibre Map Integration
              Positioned.fill(
                child: ml.MapLibreMap(
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  initialCameraPosition: ml.CameraPosition(
                    target: _currentPosition ?? ml.LatLng(7.32, 13.58),
                    zoom: 15.0,
                    tilt: pitch,
                    bearing: bearing,
                  ),
                  styleString: styleUrl,
                  myLocationEnabled: !kIsWeb,
                  trackCameraPosition: true,
                ),
              ),
          
              // Navigation Info Overlay
              Positioned(
                top: 40,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24,
                    opacity: 0.1,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.navigation, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tourner à droite dans 200m',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Vers Avenue de la Gare',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          
              // Bottom Info Bar
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 32,
                  opacity: 0.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Arrivée prévue',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                          Text(
                            _estimatedTime,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Distance',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                          Text(
                            '${_distance.toStringAsFixed(1)} km',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.x, color: AppColors.error),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          
              // Current Position Marker
              Center(
                child: _currentPosition == null ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ) : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}
