import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/app_header.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';
import 'package:geosmart/core/services/api_service.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({Key? key}) : super(key: key);

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'USER';
  final List<String> _roles = ['USER', 'ADMIN', 'SUPER_ADMIN'];
  bool _obscurePassword = true;

  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      showCustomConfirmDialog(
        context,
        title: 'Confirmer l\'ajout',
        message: 'Voulez-vous vraiment ajouter cet utilisateur ?',
        confirmLabel: 'Ajouter',
        confirmColor: AppColors.primary,
        icon: LucideIcons.userPlus,
        onConfirm: () async {
          setState(() => _isLoading = true);
          try {
            await _apiService.createUser(
              _emailController.text.trim(),
              _passwordController.text,
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
              _selectedRole.toLowerCase(),
              phone: _phoneController.text.trim(),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Utilisateur ajouté avec succès')),
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppHeader(userName: 'Super Admin'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvel Utilisateur',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                child: Column(
                  children: [
                    _buildTextField(
                      'Nom *',
                      LucideIcons.user,
                      controller: _lastNameController,
                      validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Prénom *',
                      LucideIcons.user,
                      controller: _firstNameController,
                      validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Téléphone *',
                      LucideIcons.phone,
                      controller: _phoneController,
                      validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Email *',
                      LucideIcons.mail,
                      controller: _emailController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ obligatoire';
                        if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (v) => v == null || v.length < 6 ? 'Mot de passe trop court (min 6)' : null,
                      decoration: InputDecoration(
                        label: RichText(
                          text: TextSpan(
                            text: 'Mot de passe',
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                            children: const [
                              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                        prefixIcon: const Icon(LucideIcons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        label: RichText(
                          text: TextSpan(
                            text: 'Rôle',
                            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                            children: const [
                              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                        prefixIcon: const Icon(LucideIcons.shield),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text('Créer l\'utilisateur', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {TextEditingController? controller, String? Function(String?)? validator}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label.replaceAll(' *', ''),
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
            children: [
              if (label.contains('*'))
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
