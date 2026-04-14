import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/theme/app_colors.dart';

import 'package:geosmart/core/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isRobotChecked = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est obligatoire';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'L\'email doit contenir "@" et "."';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < 8) {
      return 'Minimum 8 caractères';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez accepter les termes et conditions')),
        );
        return;
      }
      if (!_isRobotChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez confirmer que vous n\'êtes pas un robot')),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await _apiService.register(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
          _nameController.text.trim(),
          _phoneController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie. Vous pouvez maintenant vous connecter.')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            left: -150,
            child: _buildGlow(AppColors.primary.withOpacity(0.15), 500),
          ),
          Positioned(
            bottom: -200,
            right: -200,
            child: _buildGlow(AppColors.secondary.withOpacity(0.12), 600),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(40.0),
                    borderRadius: 32,
                    opacity: isDarkMode ? 0.05 : 0.08,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Créer un compte',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.textLight,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rejoignez la communauté GeoSmart',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white.withOpacity(0.5) : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nom complet',
                          icon: LucideIcons.user,
                          isDarkMode: isDarkMode,
                          validator: (value) => value == null || value.isEmpty ? 'Le nom est obligatoire' : null,
                        ),
                        const SizedBox(height: 16),
                        // Phone Field
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Téléphone',
                          icon: LucideIcons.phone,
                          isDarkMode: isDarkMode,
                          validator: (value) => value == null || value.isEmpty ? 'Le téléphone est obligatoire' : null,
                        ),
                        const SizedBox(height: 16),
                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: LucideIcons.mail,
                          isDarkMode: isDarkMode,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          icon: LucideIcons.lock,
                          obscureText: _obscurePassword,
                          isDarkMode: isDarkMode,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 20,
                              color: isDarkMode ? Colors.white.withOpacity(0.4) : AppColors.textMutedLight,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Field
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmer le mot de passe',
                          icon: LucideIcons.lock,
                          obscureText: _obscureConfirmPassword,
                          isDarkMode: isDarkMode,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'La confirmation est obligatoire';
                            if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 20,
                              color: isDarkMode ? Colors.white.withOpacity(0.4) : AppColors.textMutedLight,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Terms Checkbox
                        _buildTermsCheckbox(isDarkMode),
                        const SizedBox(height: 32),
                        // Register Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.premiumGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : Text(
                                  "S'inscrire",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // reCAPTCHA Placeholder
                        _buildCaptcha(isDarkMode),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: "Déjà un compte ? ",
                              style: GoogleFonts.inter(color: isDarkMode ? Colors.white.withOpacity(0.5) : AppColors.textMutedLight),
                              children: [
                                TextSpan(
                                  text: "Se connecter",
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 100,
              spreadRadius: 50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: isDarkMode ? Colors.white : AppColors.textLight),
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(color: isDarkMode ? Colors.white.withOpacity(0.5) : AppColors.textMutedLight),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox(bool isDarkMode) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (val) => setState(() => _acceptTerms = val!),
            activeColor: AppColors.primary,
            checkColor: Colors.white,
            side: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 16),
        RichText(
          text: TextSpan(
            text: "J'accepte les ",
            style: GoogleFonts.inter(fontSize: 14, color: isDarkMode ? Colors.white.withOpacity(0.7) : AppColors.textLight),
            children: [
              TextSpan(
                text: 'termes et conditions',
                style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaptcha(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _isRobotChecked,
              onChanged: (val) => setState(() => _isRobotChecked = val ?? false),
              activeColor: AppColors.primary,
              checkColor: Colors.white,
              side: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Text(
            'Je ne suis pas un robot',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode ? Colors.white.withOpacity(0.7) : AppColors.textLight,
            ),
          ),
          Icon(LucideIcons.refreshCw, size: 16, color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
        ],
      ),
    );
  }
  Widget _socialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
