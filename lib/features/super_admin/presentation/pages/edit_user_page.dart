import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';

import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserPage({Key? key, required this.user}) : super(key: key);

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _selectedRole;
  final List<String> _roles = ['USER', 'ADMIN', 'SUPER_ADMIN'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _emailController = TextEditingController(text: widget.user['email']);
    _selectedRole = widget.user['role'];
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      showCustomConfirmDialog(
        context,
        title: 'Confirmer la modification',
        message: 'Voulez-vous enregistrer les modifications de cet utilisateur ?',
        confirmLabel: 'Enregistrer',
        confirmColor: AppColors.primary,
        icon: LucideIcons.userCheck,
        onConfirm: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur mis à jour')),
          );
          Navigator.pop(context);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'Utilisateur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: GlassContainer(
            child: Column(
              children: [
                _buildTextField('Nom complet *', LucideIcons.user, _nameController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                const SizedBox(height: 16),
                _buildTextField('Email *', LucideIcons.mail, _emailController, validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
                  return null;
                }),
                const SizedBox(height: 24),
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
                  items: _roles.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val!),
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
                    child: const Text('Enregistrer les modifications', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {String? Function(String?)? validator}) {
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
