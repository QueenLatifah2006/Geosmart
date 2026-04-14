import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

import 'package:geosmart/core/services/api_service.dart';

class SendNotificationPage extends StatefulWidget {
  final String userRole;
  const SendNotificationPage({Key? key, this.userRole = 'SUPER_ADMIN'}) : super(key: key);

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();
  String _targetAudience = 'Tous';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
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
              currentRoute: '/send-notification',
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
                    child: SingleChildScrollView(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(32),
                        borderRadius: 28,
                        opacity: 0.05,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Détails de la Notification',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildTextField('Titre', _titleController, LucideIcons.type, isDarkMode),
                              const SizedBox(height: 20),
                              _buildTextField('Message', _messageController, LucideIcons.messageSquare, isDarkMode, maxLines: 4),
                              const SizedBox(height: 24),
                              Text(
                                'Audience Cible',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAudienceSelector(isDarkMode),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : () => _handleSend(context),
                                  icon: _isLoading 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(LucideIcons.send),
                                  label: Text(_isLoading ? 'Envoi en cours...' : 'Envoyer la Notification'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          'Envoyer une Notification',
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDarkMode, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Ce champ est requis' : null,
    );
  }

  Widget _buildAudienceSelector(bool isDarkMode) {
    final audiences = ['Tous', 'Admins', 'Utilisateurs', 'Structures Premium'];
    return Wrap(
      spacing: 12,
      children: audiences.map((audience) {
        final isSelected = _targetAudience == audience;
        return ChoiceChip(
          label: Text(audience),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _targetAudience = audience);
          },
          backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          selectedColor: AppColors.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : (isDarkMode ? Colors.white70 : Colors.black54),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  void _handleSend(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      showCustomConfirmDialog(
        context,
        title: 'Confirmer l\'envoi',
        message: 'Voulez-vous envoyer cette notification à "$_targetAudience" ?',
        confirmLabel: 'Envoyer',
        confirmColor: AppColors.primary,
        icon: LucideIcons.send,
        onConfirm: () async {
          setState(() => _isLoading = true);
          try {
            String targetRole = 'all';
            if (_targetAudience == 'Admins') targetRole = 'admin';
            if (_targetAudience == 'Utilisateurs') targetRole = 'user';
            if (_targetAudience == 'Structures Premium') targetRole = 'premium';

            await _apiService.createNotification(
              _titleController.text,
              _messageController.text,
              targetRole: targetRole,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification envoyée avec succès')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      );
    }
  }
}
