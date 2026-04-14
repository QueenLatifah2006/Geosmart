import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/utils/snackbar_utils.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';

import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

import 'package:geosmart/core/services/api_service.dart';

class EditSubscriptionPage extends StatefulWidget {
  final Map<String, dynamic> subscription;

  const EditSubscriptionPage({Key? key, required this.subscription}) : super(key: key);

  @override
  State<EditSubscriptionPage> createState() => _EditSubscriptionPageState();
}

class _EditSubscriptionPageState extends State<EditSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late String? _selectedPeriod;
  final List<String> _periods = ['3 mois', '6 mois', '1 an'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final endDate = DateTime.parse(widget.subscription['endDate']);
    final startDate = DateTime.parse(widget.subscription['startDate']);
    final diffDays = endDate.difference(startDate).inDays;
    
    if (diffDays >= 360) {
      _selectedPeriod = '1 an';
    } else if (diffDays >= 180) {
      _selectedPeriod = '6 mois';
    } else {
      _selectedPeriod = '3 mois';
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      showCustomConfirmDialog(
        context,
        title: 'Confirmer la modification',
        message: 'Voulez-vous enregistrer les modifications de cet abonnement ?',
        confirmLabel: 'Enregistrer',
        confirmColor: AppColors.primary,
        icon: LucideIcons.save,
        onConfirm: () async {
          setState(() => _isLoading = true);
          try {
            int days = 90;
            if (_selectedPeriod == '6 mois') days = 180;
            if (_selectedPeriod == '1 an') days = 365;

            final startDate = DateTime.parse(widget.subscription['startDate']);
            final endDate = startDate.add(Duration(days: days));

            await _apiService.updateSubscription(widget.subscription['_id'], {
              'endDate': endDate.toIso8601String(),
            });

            if (mounted) {
              SnackBarUtils.showSuccess(context, 'Abonnement mis à jour');
              Navigator.pop(context, true);
            }
          } catch (e) {
            if (mounted) {
              SnackBarUtils.showError(context, 'Erreur: $e');
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sub = widget.subscription;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: isDarkMode ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Modifier l\'Abonnement',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 28,
                  opacity: 0.04,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.building, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Structure',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                  Text(
                                    sub['structureId'] is Map ? sub['structureId']['name'] : 'Inconnue',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildDropdownField(
                        label: 'Période de validation',
                        value: _selectedPeriod,
                        icon: LucideIcons.calendar,
                        items: _periods,
                        onChanged: (val) => setState(() => _selectedPeriod = val),
                        validator: (v) => v == null ? 'Veuillez sélectionner une période' : null,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'Enregistrer les modifications',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?)? validator,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          dropdownColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          style: GoogleFonts.inter(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
