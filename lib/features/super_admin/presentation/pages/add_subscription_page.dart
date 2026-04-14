import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/app_header.dart';
import 'package:geosmart/core/theme/app_colors.dart';

import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

import 'package:geosmart/core/services/api_service.dart';
import 'package:geosmart/core/models/structure_model.dart';

class AddSubscriptionPage extends StatefulWidget {
  const AddSubscriptionPage({Key? key}) : super(key: key);

  @override
  State<AddSubscriptionPage> createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  String? _selectedStructureId;
  String? _selectedPeriod;
  String? _selectedPaymentMode;
  List<StructureModel> _structures = [];
  bool _isLoading = true;

  final List<String> _periods = ['3 mois', '6 mois', '12 mois'];
  final List<String> _paymentModes = ['OM', 'MOMO'];

  @override
  void initState() {
    super.initState();
    _fetchStructures();
  }

  Future<void> _fetchStructures() async {
    try {
      final structures = await _apiService.getStructures();
      if (mounted) {
        setState(() {
          _structures = structures;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleValidate() async {
    if (_formKey.currentState!.validate()) {
      final structure = _structures.firstWhere((s) => s.id == _selectedStructureId);
      
      showCustomConfirmDialog(
        context,
        title: 'Confirmer l\'abonnement',
        message: 'Voulez-vous vraiment créer cet abonnement pour ${structure.name} ?',
        confirmLabel: 'Confirmer',
        confirmColor: AppColors.success,
        icon: LucideIcons.creditCard,
        onConfirm: () async {
          try {
            int duration = int.parse(_selectedPeriod!.split(' ')[0]);
            await _apiService.createSubscription(
              _selectedStructureId!,
              'Premium',
              duration,
            );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abonnement validé avec succès')),
              );
              Navigator.pop(context, true);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                'Nouvel Abonnement',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 28,
                      opacity: 0.04,
                      child: Column(
                        children: [
                          // Select Structure
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildDropdownField(
                                  label: 'Sélectionner la structure',
                                  value: _selectedStructureId,
                                  icon: LucideIcons.building,
                                  items: _structures.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                                  onChanged: (val) => setState(() => _selectedStructureId = val),
                                  validator: (v) => v == null ? 'Veuillez sélectionner une structure' : null,
                                  isDarkMode: isDarkMode,
                                ),
                          const SizedBox(height: 24),
                          // Select Period
                          _buildDropdownField(
                            label: 'Période de l\'abonnement',
                            value: _selectedPeriod,
                            icon: LucideIcons.calendar,
                            items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) => setState(() => _selectedPeriod = val),
                            validator: (v) => v == null ? 'Veuillez sélectionner une période' : null,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 24),
                          // Select Payment Mode
                          _buildDropdownField(
                            label: 'Mode de paiement',
                            value: _selectedPaymentMode,
                            icon: LucideIcons.wallet,
                            items: _paymentModes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) => setState(() => _selectedPaymentMode = val),
                            validator: (v) => v == null ? 'Veuillez sélectionner un mode de paiement' : null,
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
                              onPressed: _handleValidate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                'Valider l\'abonnement',
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
                  ],
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
    required List<DropdownMenuItem<String>> items,
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
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
