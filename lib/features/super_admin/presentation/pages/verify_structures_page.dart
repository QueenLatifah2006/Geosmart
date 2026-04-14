import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/models/structure_model.dart';
import 'package:geosmart/core/services/api_service.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

class VerifyStructuresPage extends StatefulWidget {
  final String userRole;
  const VerifyStructuresPage({Key? key, this.userRole = 'SUPER_ADMIN'}) : super(key: key);

  @override
  State<VerifyStructuresPage> createState() => _VerifyStructuresPageState();
}

class _VerifyStructuresPageState extends State<VerifyStructuresPage> {
  final _apiService = ApiService();
  List<StructureModel> _pendingStructures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingStructures();
  }

  Future<void> _fetchPendingStructures() async {
    try {
      final structures = await _apiService.getStructures();
      if (mounted) {
        setState(() {
          // Filter for structures that are not yet verified (e.g. status is 'pending')
          // For now, let's assume the API returns all and we filter.
          _pendingStructures = structures.where((s) => s.isBlocked == false && s.isPremium == false).toList(); 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final userName = widget.userRole == 'SUPER_ADMIN' ? 'Super Admin' : 'Admin';

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          if (!isMobile)
            PremiumSidebar(
              currentRoute: '/verify-structures',
              userName: userName,
              userRole: widget.userRole,
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDarkMode, isMobile),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 28,
                      opacity: 0.05,
                      child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : (_pendingStructures.isEmpty 
                            ? const Center(child: Text('Aucune structure en attente de vérification', style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                itemCount: _pendingStructures.length,
                                separatorBuilder: (context, index) => Divider(height: 32, color: isDarkMode ? Colors.white10 : Colors.black12),
                                itemBuilder: (context, index) {
                                  final structure = _pendingStructures[index];
                                  return _structureItem(structure, isDarkMode, isMobile);
                                },
                              )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode, bool isMobile) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        const SizedBox(width: 8),
        Text(
          'Vérification des Structures',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _structureItem(StructureModel structure, bool isDarkMode, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.building, color: AppColors.warning, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                structure.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Type: ${structure.type} • Adresse: ${structure.address}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.checkCircle, color: AppColors.success),
              onPressed: () {
                showCustomConfirmDialog(
                  context,
                  title: 'Valider la structure',
                  message: 'Voulez-vous valider la structure "${structure.name}" ?',
                  confirmLabel: 'Valider',
                  confirmColor: AppColors.success,
                  icon: LucideIcons.checkCircle,
                  onConfirm: () async {
                    try {
                      await _apiService.updateStructure(structure.id, {'isPremium': true});
                      setState(() {
                        _pendingStructures.remove(structure);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Structure "${structure.name}" validée avec succès')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  },
                );
              },
              tooltip: 'Valider',
            ),
            IconButton(
              icon: const Icon(LucideIcons.xCircle, color: AppColors.error),
              onPressed: () {
                showCustomConfirmDialog(
                  context,
                  title: 'Rejeter la structure',
                  message: 'Voulez-vous rejeter la structure "${structure.name}" ?',
                  confirmLabel: 'Rejeter',
                  confirmColor: AppColors.error,
                  icon: LucideIcons.xCircle,
                  onConfirm: () async {
                    try {
                      await _apiService.deleteStructure(structure.id);
                      setState(() {
                        _pendingStructures.remove(structure);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Structure "${structure.name}" rejetée')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  },
                );
              },
              tooltip: 'Rejeter',
            ),
          ],
        ),
      ],
    );
  }
}
