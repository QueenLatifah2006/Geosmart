import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/services/api_service.dart';
import 'package:geosmart/core/models/structure_model.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';
import 'package:geosmart/shared/widgets/custom_header.dart';
import 'package:geosmart/features/super_admin/presentation/pages/structure_details_page.dart';
import 'package:geosmart/features/user/presentation/pages/rating_page.dart';
import 'package:geosmart/features/user/presentation/pages/navigation_page.dart';
import 'package:geosmart/main.dart';
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

// import 'package:flutter_map/flutter_map.dart'; // Removed
// import 'package:latlong2/latlong.dart'; // Removed to avoid conflict

class UserDashboardPage extends StatefulWidget {
  final bool isMobile;
  final Function(int)? onMenuTap;

  const UserDashboardPage({Key? key, this.isMobile = false, this.onMenuTap}) : super(key: key);

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final _apiService = ApiService();
  String _searchQuery = '';
  bool _isAiSearching = false;
  List<StructureModel> _aiResults = [];
  String? _aiIntent;
  final List<String> _categories = ['Tout', 'Santé', 'Éducation', 'Restauration', 'Hôtels', 'Banques'];
  String _selectedCategory = 'Tout';
  ml.MapLibreMapController? _mapController;
  
  // Navigation State
  bool _isNavigating = false;
  ml.LatLng? _userLocation = ml.LatLng(7.315, 13.575); // Initial simulated location
  List<ml.LatLng> _currentRoute = [];
  int _currentStepIndex = 0;
  String _currentInstruction = '';
  StructureModel? _destination;
  List<StructureModel> _structures = [];
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStream;

  @override
  void dispose() {
    _positionStream?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchStructures();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = ml.LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(ml.CameraUpdate.newLatLngZoom(_userLocation!, 14.0));
        _addMarkers();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _fetchStructures() async {
    try {
      final structures = await _apiService.getStructures();
      debugPrint('Fetched ${structures.length} structures');
      if (mounted) {
        setState(() {
          _structures = structures;
          _isLoading = false;
        });
        _addMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAiSearch() async {
    if (_searchQuery.isEmpty) return;

    setState(() {
      _isAiSearching = true;
      _aiIntent = null;
    });

    try {
      final response = await _apiService.aiSearch(_searchQuery);
      if (mounted) {
        setState(() {
          _aiIntent = response['intent'];
          _aiResults = (response['results'] as List)
              .map((json) => StructureModel.fromJson(json))
              .toList();
          _isAiSearching = false;
        });
        _addMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAiSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur IA: $e')),
        );
      }
    }
  }

  Future<void> _handleScan(String type) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _apiService.analyzeImage(base64Image, type);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        final analysis = response['analysis'];
        final structure = response['structure'] != null 
            ? StructureModel.fromJson(response['structure']) 
            : null;

        _showScanResult(analysis, structure);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Scan: $e')),
        );
      }
    }
  }

  void _showScanResult(Map<String, dynamic> analysis, StructureModel? structure) {
    showDialog(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: 'Résultat de l\'analyse IA',
        message: '${analysis['identifiedName']}\n\n${analysis['description']}',
        confirmText: structure != null ? 'Voir la structure' : 'OK',
        onConfirm: () {
          if (structure != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StructureDetailsPage(structure: structure, userRole: 'USER'),
              ),
            );
          }
        },
      ),
    );
  }

  List<StructureModel> get _filteredStructures {
    List<StructureModel> baseList = _structures;
    if (_searchQuery.isNotEmpty && _aiResults.isNotEmpty) {
      baseList = _aiResults;
    }
    
    return baseList.where((s) {
      // Filter by blocked status
      if (s.isBlocked) return false;
      
      // Filter by category (Robust matching)
      if (_selectedCategory != 'Tout') {
        final normalizedSelected = _selectedCategory.toLowerCase().trim();
        final normalizedType = s.type.toLowerCase().trim();
        
        // Handle common accent differences (Education vs Éducation)
        bool matches = normalizedType == normalizedSelected;
        if (!matches) {
          final noAccentSelected = normalizedSelected.replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e');
          final noAccentType = normalizedType.replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e');
          matches = noAccentType == noAccentSelected;
        }
        
        if (!matches) return false;
      }

      // Filter by search query (name, product, or service)
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      final nameMatch = s.name.toLowerCase().contains(query);
      final productMatch = s.products.any((p) => (p['name'] as String? ?? '').toLowerCase().contains(query));
      final serviceMatch = s.services.any((serv) => (serv['name'] as String? ?? '').toLowerCase().contains(query));
      
      return nameMatch || productMatch || serviceMatch;
    }).toList();
  }

  Timer? _navigationTimer;

  void _showStructureQuickActions(StructureModel s, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 28,
        opacity: 0.15,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.building, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(s.type, style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startNavigation(s);
                    },
                    icon: const Icon(LucideIcons.navigation),
                    label: const Text('Naviguer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _actionButton(LucideIcons.info, () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StructureDetailsPage(structure: s, userRole: 'USER')),
                  );
                }, isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNavigation(StructureModel dest) async {
    if (_userLocation == null) {
      await _getCurrentLocation();
    }
    
    if (_userLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez activer votre GPS pour la navigation')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _destination = dest;
      _isNavigating = true; // Show panel early for feedback
    });

    try {
      final routePoints = await _apiService.getRoute(
        _userLocation!.latitude, 
        _userLocation!.longitude, 
        dest.lat, 
        dest.lng
      );

      if (mounted) {
        setState(() {
          _isNavigating = true;
          _currentStepIndex = 0;
          _currentInstruction = 'En route vers ${dest.name}';
          _currentRoute = routePoints.map((p) => ml.LatLng(p['lat']!, p['lng']!)).toList();
          _isLoading = false;
        });

        _mapController?.animateCamera(ml.CameraUpdate.newLatLngZoom(_userLocation!, 16.0));
        _addMarkers();

        // Start real-time location tracking for navigation
        _positionStream?.cancel();
        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          if (_isNavigating) {
            setState(() {
              _userLocation = ml.LatLng(position.latitude, position.longitude);
              _updateNavigationProgress();
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting navigation: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de calculer l\'itinéraire')),
        );
      }
    }
  }

  void _updateNavigationProgress() {
    if (!_isNavigating || _currentRoute.isEmpty || _userLocation == null) return;

    // Find the closest point on the route to the user's current location
    // For simplicity, we just check if we've reached the destination
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude, 
      _userLocation!.longitude, 
      _destination!.lat, 
      _destination!.lng
    );

    if (distance < 20) { // Within 20 meters
      setState(() {
        _isNavigating = false;
        _currentInstruction = 'Vous êtes arrivé à destination';
      });
      _positionStream?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation terminée')),
      );
    } else {
      // Update instruction based on progress (simplified)
      setState(() {
        _currentInstruction = 'Continuez vers ${_destination!.name} (${distance.toInt()}m)';
      });
    }
    
    _mapController?.animateCamera(ml.CameraUpdate.newLatLng(_userLocation!));
    _addMarkers();
  }

  Widget _buildNavigationPanel(bool isDarkMode) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      opacity: 0.2,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _currentStepIndex == 1 ? LucideIcons.arrowLeft : 
              _currentStepIndex == 2 ? LucideIcons.arrowRight : 
              LucideIcons.navigation, 
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentInstruction,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Distance restante: ${((_currentRoute.length - 1 - _currentStepIndex) * 0.5).toStringAsFixed(1)} km',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isNavigating = false;
                _navigationTimer?.cancel();
                _currentRoute = [];
              });
              _addMarkers();
            },
            icon: const Icon(LucideIcons.x, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  bool _isStyleLoaded = false;

  void _onMapCreated(ml.MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    setState(() {
      _isStyleLoaded = true;
    });
    _addMarkers();
  }

  void _addMarkers() async {
    if (_mapController == null || !_isStyleLoaded) return;
    
    // Clear existing symbols
    await _mapController!.clearSymbols();
    await _mapController!.clearLines();

    // Add user location symbol
    if (_userLocation != null) {
      try {
        await _mapController!.addSymbol(ml.SymbolOptions(
          geometry: ml.LatLng(_userLocation!.latitude, _userLocation!.longitude),
          textField: "🔵",
          textSize: 16,
        ));
      } catch (e) {
        debugPrint('Error adding user location symbol: $e');
      }
    }

    // Add structure symbols
    for (var s in _filteredStructures) {
      try {
        debugPrint('Adding marker for structure: ${s.name} at ${s.lat}, ${s.lng}');
        await _mapController!.addSymbol(ml.SymbolOptions(
          geometry: ml.LatLng(s.lat, s.lng),
          textField: "📍\n${s.name}",
          textSize: 12,
          textOffset: const Offset(0, 0.5),
          textColor: "#FFFFFF",
        ));
      } catch (e) {
        debugPrint('Error adding structure symbol for ${s.name}: $e');
      }
    }

    // Add route line if exists
    if (_currentRoute.isNotEmpty) {
      await _mapController!.addLine(ml.LineOptions(
        geometry: _currentRoute.map((p) => ml.LatLng(p.latitude, p.longitude)).toList(),
        lineColor: "#6366F1",
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget content = Stack(
      children: [
        // MapLibre Map Integration
        ml.MapLibreMap(
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          initialCameraPosition: ml.CameraPosition(
            target: ml.LatLng(7.32, 13.58),
            zoom: 14.0,
          ),
          styleString: isDarkMode 
            ? 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json'
            : 'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json',
          myLocationEnabled: true,
          trackCameraPosition: true,
        ),
        
        // Navigation Instructions Panel
        if (_isNavigating)
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: _buildNavigationPanel(isDarkMode),
          ),
        
        // Top Header & Search Bar & Categories
        Positioned(
          top: widget.isMobile ? 12 : 40,
          left: widget.isMobile ? 16 : 40,
          right: widget.isMobile ? 16 : 40,
          child: SafeArea(
            child: Column(
              children: [
                if (widget.isMobile)
                  CustomHeader(
                    title: 'Exploration',
                    isDarkMode: isDarkMode,
                    userRole: 'USER',
                    onNotificationTap: () {},
                    onMenuTap: widget.onMenuTap ?? (index) {},
                  ),
                const SizedBox(height: 12),
                _buildSearchBar(isDarkMode),
                if (_aiIntent != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _aiIntent!,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildCategoryList(isDarkMode),
              ],
            ),
          ),
        ),

        // Results List (if searching)
        if (_searchQuery.isNotEmpty || _selectedCategory != 'Tout')
          Positioned(
            top: widget.isMobile ? 220 : 180,
            left: widget.isMobile ? 16 : 40,
            right: widget.isMobile ? 16 : 40,
            bottom: widget.isMobile ? 100 : 120,
            child: _buildResultsList(isDarkMode),
          ),
        
        // Map Controls
        Positioned(
          bottom: widget.isMobile ? 120 : 140,
          right: widget.isMobile ? 16 : 40,
          child: _buildMapControls(isDarkMode),
        ),
        
        // Bottom Navigation / Transport Modes
        Positioned(
          bottom: widget.isMobile ? 20 : 40,
          left: widget.isMobile ? 16 : 40,
          right: widget.isMobile ? 16 : 40,
          child: _buildTransportModes(isDarkMode),
        ),
      ],
    );

    if (widget.isMobile) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          PremiumSidebar(
            currentRoute: '/user-dashboard',
            userName: 'Utilisateur',
            userRole: 'USER',
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            borderRadius: 20,
            opacity: 0.1,
            child: TextField(
              onChanged: (v) {
                setState(() {
                  _searchQuery = v;
                  if (v.isEmpty) _aiResults = [];
                });
              },
              onSubmitted: (_) => _handleAiSearch(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit, service...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _aiResults = [];
                        _aiIntent = null;
                      }),
                    )
                  : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _actionButton(
          _isAiSearching ? LucideIcons.loader : LucideIcons.sparkles, 
          _handleAiSearch, 
          isDarkMode,
          color: AppColors.primary
        ),
      ],
    );
  }

  void _showAiAssistant() {
    final TextEditingController chatController = TextEditingController();
    bool isTyping = false;
    List<Map<String, String>> messages = [
      {'role': 'ai', 'content': 'Bonjour ! Je suis l\'assistant GeoSmart. Comment puis-je vous aider à Ngaoundéré aujourd\'hui ?'}
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => GlassContainer(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          borderRadius: 28,
          opacity: 0.15,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Assistant GeoSmart', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: Colors.white54)),
                ],
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isAi = msg['role'] == 'ai';
                    return Align(
                      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAi ? Colors.white.withOpacity(0.1) : AppColors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg['content']!, style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
              if (isTyping)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('L\'IA réfléchit...', style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 12,
                      opacity: 0.1,
                      child: TextField(
                        controller: chatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(hintText: 'Posez votre question...', hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: isTyping ? null : () async {
                      final text = chatController.text;
                      if (text.isEmpty) return;
                      
                      setModalState(() {
                        messages.add({'role': 'user', 'content': text});
                        chatController.clear();
                        isTyping = true;
                      });

                      try {
                        final reply = await _apiService.aiChat(text);
                        setModalState(() {
                          messages.add({'role': 'ai', 'content': reply});
                          isTyping = false;
                        });

                        // Check for navigation command: [[NAV:StructureName]]
                        final navRegex = RegExp(r'\[\[NAV:(.*?)\]\]');
                        final match = navRegex.firstMatch(reply);
                        if (match != null) {
                          final structureName = match.group(1)!.trim();
                          final structure = _structures.firstWhere(
                            (s) => s.name.toLowerCase() == structureName.toLowerCase(),
                            orElse: () => _structures.firstWhere(
                              (s) => s.name.toLowerCase().contains(structureName.toLowerCase()),
                              orElse: () => _structures[0], // Fallback
                            ),
                          );
                          
                          if (mounted) {
                            Navigator.pop(context); // Close chat
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NavigationPage(
                                  destination: {
                                    'name': structure.name,
                                    'lat': structure.lat,
                                    'lng': structure.lng,
                                  },
                                  transportType: 'Voiture',
                                  mapStyle: 'Standard',
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        String errorMessage = 'Désolé, une erreur est survenue.';
                        if (e is Map && e['message'] != null) {
                          errorMessage = e['message'];
                        } else if (e.toString().contains('MISSING_API_KEY')) {
                          errorMessage = 'Le service IA n\'est pas configuré. Veuillez vérifier votre clé API Gemini dans les paramètres.';
                        }
                        
                        setModalState(() {
                          messages.add({'role': 'ai', 'content': errorMessage});
                          isTyping = false;
                        });
                      }
                    },
                    icon: const Icon(LucideIcons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanOptions(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 28,
        opacity: 0.15,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan Intelligent IA', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _scanOptionButton(LucideIcons.qrCode, 'Code QR / Produit', () {
                    Navigator.pop(context);
                    _handleScan('qr');
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _scanOptionButton(LucideIcons.building, 'Analyse Façade', () {
                    Navigator.pop(context);
                    _handleScan('facade');
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _scanOptionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        opacity: 0.1,
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onPressed, bool isDarkMode, {Color? color}) {
    return GlassContainer(
      width: 48,
      height: 48,
      borderRadius: 14,
      padding: EdgeInsets.zero,
      opacity: 0.1,
      child: IconButton(
        icon: Icon(icon, size: 20, color: color ?? (isDarkMode ? Colors.white : Colors.black)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCategoryList(bool isDarkMode) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  if (cat == 'Tout') {
                    _searchQuery = '';
                    _aiResults = [];
                    _aiIntent = null;
                  }
                });
                _addMarkers();
              },
              borderRadius: BorderRadius.circular(24),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                borderRadius: 24,
                opacity: isSelected ? 0.2 : 0.05,
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(bool isDarkMode) {
    final results = _filteredStructures;
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      opacity: 0.1,
      child: results.isEmpty 
        ? Center(
            child: Text(
              'Aucun résultat trouvé',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          )
        : ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final s = results[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StructureDetailsPage(structure: s, userRole: 'USER'),
                    ),
                  );
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.building, color: AppColors.primary, size: 20),
                ),
                title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(s.type, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                trailing: const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 18),
              );
            },
          ),
    );
  }

  Widget _buildMapControls(bool isDarkMode) {
    return Column(
      children: [
        _mapControlButton(LucideIcons.plus, () {
          _mapController?.animateCamera(ml.CameraUpdate.zoomIn());
        }),
        const SizedBox(height: 12),
        _mapControlButton(LucideIcons.minus, () {
          _mapController?.animateCamera(ml.CameraUpdate.zoomOut());
        }),
        const SizedBox(height: 24),
        _mapControlButton(LucideIcons.camera, () {
          _showScanOptions(isDarkMode);
        }, color: AppColors.accent, tooltip: 'Scan IA (QR/Façade)'),
        const SizedBox(height: 12),
        _mapControlButton(LucideIcons.navigation, () {
          if (_userLocation != null) {
            _mapController?.animateCamera(ml.CameraUpdate.newLatLngZoom(_userLocation!, 16.0));
          } else {
            _getCurrentLocation();
          }
        }, color: AppColors.primary, tooltip: 'Ma position'),
        if (_isNavigating) ...[
          const SizedBox(height: 12),
          _mapControlButton(LucideIcons.xCircle, () {
            setState(() {
              _isNavigating = false;
              _currentRoute = [];
              _positionStream?.cancel();
            });
            _addMarkers();
          }, color: Colors.red, tooltip: 'Arrêter la navigation'),
        ],
        const SizedBox(height: 12),
        _mapControlButton(LucideIcons.bot, () {
          _showAiAssistant();
        }, color: AppColors.primary, tooltip: 'Assistant IA (RAG)'),
        const SizedBox(height: 12),
        _mapControlButton(LucideIcons.messageSquare, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RatingPage()));
        }),
        const SizedBox(height: 12),
        _mapControlButton(LucideIcons.heart, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajouté aux favoris')),
          );
        }),
        const SizedBox(height: 12),
        _mapControlButton(LucideIcons.share2, () {
          if (_userLocation != null) {
            final text = 'Ma position GeoSmart: https://www.google.com/maps/search/?api=1&query=${_userLocation!.latitude},${_userLocation!.longitude}';
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lien de localisation copié dans le presse-papier')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Localisation non disponible')),
            );
          }
        }, tooltip: 'Partager ma localisation'),
        const SizedBox(height: 12),
        _mapControlButton(LucideIcons.settings, () {
          // Map settings
        }),
      ],
    );
  }

  Widget _mapControlButton(IconData icon, VoidCallback onTap, {Color? color, String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Tooltip(
        message: tooltip ?? '',
        child: GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          opacity: color != null ? 1.0 : 0.1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: color != null ? AppColors.premiumGradient : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransportModes(bool isDarkMode) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      opacity: 0.08,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _transportItem(LucideIcons.footprints, 'Pied', '12 min'),
          _transportItem(LucideIcons.bike, 'Vélo', '5 min'),
          _transportItem(LucideIcons.car, 'Voiture', '2 min'),
          _transportItem(LucideIcons.bus, 'Bus', '8 min'),
        ],
      ),
    );
  }

  Widget _transportItem(IconData icon, String label, String time) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
