import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/features/user/presentation/pages/navigation_page.dart';

class RoutePlanningPage extends StatefulWidget {
  final Map<String, dynamic> destination;

  const RoutePlanningPage({Key? key, required this.destination}) : super(key: key);

  @override
  State<RoutePlanningPage> createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends State<RoutePlanningPage> {
  String _transportType = 'Voiture';
  String _mapStyle = 'Standard';

  final List<Map<String, dynamic>> _transportModes = [
    {'label': 'Pied', 'icon': LucideIcons.footprints, 'time': '15 min'},
    {'label': 'Vélo', 'icon': LucideIcons.bike, 'time': '8 min'},
    {'label': 'Voiture', 'icon': LucideIcons.car, 'time': '3 min'},
    {'label': 'Bus', 'icon': LucideIcons.bus, 'time': '10 min'},
  ];

  final List<Map<String, dynamic>> _mapStyles = [
    {'label': 'Standard', 'icon': LucideIcons.map},
    {'label': 'Satellite', 'icon': LucideIcons.layers},
    {'label': 'Terrain', 'icon': LucideIcons.mountain},
    {'label': '3D', 'icon': LucideIcons.box},
    {'label': 'Sombre', 'icon': LucideIcons.moon},
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Planifier l\'itinéraire', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination Info
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              opacity: 0.05,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.mapPin, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Destination', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          widget.destination['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Transport Selection
            Text(
              'Mode de transport',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _transportModes.length,
              itemBuilder: (context, index) {
                final mode = _transportModes[index];
                final isSelected = _transportType == mode['label'];
                
                return InkWell(
                  onTap: () => setState(() => _transportType = mode['label']),
                  borderRadius: BorderRadius.circular(20),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    opacity: isSelected ? 0.2 : 0.05,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode['icon'],
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mode['label'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                        ),
                        Text(
                          mode['time'],
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Map Style Selection
            Text(
              'Style de la carte',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mapStyles.length,
                itemBuilder: (context, index) {
                  final style = _mapStyles[index];
                  final isSelected = _mapStyle == style['label'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () => setState(() => _mapStyle = style['label']),
                      borderRadius: BorderRadius.circular(20),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        borderRadius: 20,
                        opacity: isSelected ? 0.2 : 0.05,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              style['icon'],
                              color: isSelected ? AppColors.primary : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              style['label'],
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Start Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationPage(
                        destination: widget.destination,
                        transportType: _transportType,
                        mapStyle: _mapStyle,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Commencer',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
