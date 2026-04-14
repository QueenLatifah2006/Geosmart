import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/main.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/core/theme/app_colors.dart';

import 'package:geosmart/core/services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final String userRole;
  final String userName;
  final bool isMobile;

  const ProfilePage({
    Key? key,
    required this.userRole,
    required this.userName,
    this.isMobile = false,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _apiService = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isSaving = false;
  late String _displayName;
  late String _displayRole;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _displayRole = widget.userRole;
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: ''); // Should fetch from API
    _phoneController = TextEditingController(text: '');
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await _apiService.getProfile();
      setState(() {
        _displayName = user.name;
        _displayRole = user.role;
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';
      });
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _handleUpdateProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = await _apiService.updateProfile(
        _nameController.text, 
        _emailController.text,
        phone: _phoneController.text,
      );
      setState(() {
        _displayName = user.name;
        _displayRole = user.role;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleChangePassword(String oldPass, String newPass) async {
    try {
      await _apiService.changePassword(oldPass, newPass);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      padding: EdgeInsets.all(widget.isMobile ? 20 : 32),
      color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDarkMode),
            const SizedBox(height: 32),
            _buildProfileCard(isDarkMode),
            const SizedBox(height: 32),
            _buildSettingsSection(isDarkMode),
          ],
        ),
      ),
    );

    if (widget.isMobile) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          PremiumSidebar(
            currentRoute: '/profile',
            userName: widget.userName,
            userRole: widget.userRole,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mon Profil',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              Text(
                'Gérez vos informations personnelles et vos préférences.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(isDarkMode ? LucideIcons.sun : LucideIcons.moon),
              onPressed: () => GeoSmartApp.of(context)?.toggleTheme(),
              tooltip: 'Changer le thème',
            ),
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: AppColors.error),
              onPressed: () {
                showCustomConfirmDialog(
                  context,
                  title: 'Déconnexion',
                  message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
                  confirmLabel: 'Se déconnecter',
                  confirmColor: Colors.red,
                  icon: LucideIcons.logOut,
                  onConfirm: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                );
              },
              tooltip: 'Déconnexion',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          if (widget.isMobile) ...[
            _buildMobileProfileHeader(isDarkMode),
          ] else ...[
            _buildDesktopProfileHeader(isDarkMode),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          if (widget.isMobile) ...[
            _buildTextField('Nom complet', _nameController, LucideIcons.user, isDarkMode),
            const SizedBox(height: 24),
            _buildTextField('Email', _emailController, LucideIcons.mail, isDarkMode),
            const SizedBox(height: 24),
            _buildTextField('Téléphone', _phoneController, LucideIcons.phone, isDarkMode),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildTextField('Nom complet', _nameController, LucideIcons.user, isDarkMode)),
                const SizedBox(width: 24),
                Expanded(child: _buildTextField('Email', _emailController, LucideIcons.mail, isDarkMode)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildTextField('Téléphone', _phoneController, LucideIcons.phone, isDarkMode)),
                const SizedBox(width: 24),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
          if (widget.isMobile) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleUpdateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer les modifications'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileProfileHeader(bool isDarkMode) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          _displayRole.replaceAll('_', ' '),
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDesktopProfileHeader(bool isDarkMode) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                _displayRole.replaceAll('_', ' '),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Membre depuis Janvier 2026', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleUpdateProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(bool isDarkMode) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Changer le mot de passe',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField('Ancien mot de passe', oldPasswordController, LucideIcons.lock, isDarkMode, isPassword: true),
              const SizedBox(height: 16),
              _buildDialogTextField('Nouveau mot de passe', newPasswordController, LucideIcons.shield, isDarkMode, isPassword: true),
              const SizedBox(height: 16),
              _buildDialogTextField('Confirmer le mot de passe', confirmPasswordController, LucideIcons.checkCircle, isDarkMode, isPassword: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text == confirmPasswordController.text && newPasswordController.text.isNotEmpty) {
                await _handleChangePassword(oldPasswordController.text, newPasswordController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Les mots de passe ne correspondent pas.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(String label, TextEditingController controller, IconData icon, bool isDarkMode, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _handleShareLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les services de localisation sont désactivés.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de localisation refusée.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les permissions de localisation sont définitivement refusées.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Position actuelle: ${position.latitude}, ${position.longitude}')),
      );
      
      // Optionally send to backend or just show success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de localisation: $e')),
      );
    }
  }

  Widget _buildSettingsSection(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres de Sécurité',
            style: GoogleFonts.outfit(
              fontSize: widget.isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          SizedBox(height: widget.isMobile ? 20 : 24),
          _settingsTile(LucideIcons.lock, 'Changer le mot de passe', 'Dernière modification il y a 3 mois', isDarkMode),
          const SizedBox(height: 12),
          _settingsTile(LucideIcons.shield, 'Authentification à deux facteurs', 'Désactivé', isDarkMode),
          const SizedBox(height: 12),
          _settingsTile(LucideIcons.eye, 'Confidentialité des données', 'Gérez vos préférences de partage', isDarkMode),
          const SizedBox(height: 12),
          _settingsTile(LucideIcons.share2, 'Partager ma localisation', 'Partagez votre position actuelle', isDarkMode),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, bool isDarkMode) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: () {
        if (title == 'Changer le mot de passe') {
          _showChangePasswordDialog(isDarkMode);
        } else if (title == 'Partager ma localisation') {
          _handleShareLocation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action: $title')),
          );
        }
      },
    );
  }
}
