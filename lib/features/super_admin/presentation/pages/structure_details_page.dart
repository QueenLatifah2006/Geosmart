import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/features/user/presentation/pages/route_planning_page.dart';
import 'package:geosmart/core/services/api_service.dart';

import 'package:geosmart/core/models/structure_model.dart';

class StructureDetailsPage extends StatelessWidget {
  final StructureModel structure;
  final String userRole;

  const StructureDetailsPage({
    Key? key, 
    required this.structure,
    this.userRole = 'USER',
  }) : super(key: key);

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'https://picsum.photos/seed/building/800/400';
    if (path.startsWith('http')) return path;
    return ApiService.fullUrl + path;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(structure.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Header
                Hero(
                  tag: 'structure-${structure.id}',
                  child: Container(
                    height: isMobile ? 200 : 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      image: const DecorationImage(
                        image: NetworkImage('https://picsum.photos/seed/building/800/400'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Info Grid
                GlassContainer(
                  child: Column(
                    children: [
                      _buildDetailRow(LucideIcons.tag, 'Domaine', structure.type, isDarkMode),
                      const Divider(height: 32),
                      _buildDetailRow(LucideIcons.user, 'Propriétaire', structure.ownerId ?? 'Non spécifié', isDarkMode),
                      const Divider(height: 32),
                      _buildDetailRow(LucideIcons.phone, 'Contact', structure.telephone ?? 'Non spécifié', isDarkMode),
                      const Divider(height: 32),
                      _buildDetailRow(
                        LucideIcons.mapPin, 
                        'Localisation', 
                        'Lat: ${structure.lat.toStringAsFixed(4)}, Long: ${structure.lng.toStringAsFixed(4)}', 
                        isDarkMode
                      ),
                      const Divider(height: 32),
                      _buildDetailRow(LucideIcons.info, 'Statut', structure.isBlocked ? 'Bloqué' : (structure.isPremium ? 'Premium' : 'Standard'), isDarkMode, isStatus: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  structure.description.isEmpty ? 'Aucune description disponible pour cette structure.' : structure.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                    height: 1.6,
                  ),
                ),
                
                if (structure.services.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...structure.services.map((s) => _buildItemCard(s['name'] ?? '', '${s['price'] ?? 0} FCFA', 'Service', isDarkMode, s['photo'])),
                ],

                if (structure.products.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Produits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...structure.products.map((p) => _buildItemCard(p['name'] ?? '', '${p['price'] ?? 0} FCFA', 'Produit', isDarkMode, p['photo'])),
                ],

                const SizedBox(height: 48),
                
                // Action Button: Visualize on Map
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoutePlanningPage(
                            destination: structure.toJson(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.map, color: Colors.white),
                    label: const Text(
                      'VOIR SUR LA CARTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDarkMode, {bool isStatus = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(String name, String price, String type, bool isDarkMode, String? photo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(photo != null && photo != 'mock_photo' 
                    ? _getImageUrl(photo) 
                    : 'https://picsum.photos/seed/item/100/100'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  type,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
