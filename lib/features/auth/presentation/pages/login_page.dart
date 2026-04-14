import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/theme/app_colors.dart';

import 'package:geosmart/core/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isRobotChecked = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      if (!_isRobotChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez confirmer que vous n\'êtes pas un robot')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final data = await _apiService.login(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
        );

        final role = data['user']['role'];
        if (role == 'super_admin') {
          Navigator.pushReplacementNamed(context, '/super-admin-dashboard');
        } else if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
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
            right: -150,
            child: _buildGlow(AppColors.primary.withOpacity(0.15), 500),
          ),
          Positioned(
            bottom: -200,
            left: -200,
            child: _buildGlow(AppColors.secondary.withOpacity(0.12), 600),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(48.0),
                    borderRadius: 32,
                    opacity: isDarkMode ? 0.05 : 0.08,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 40),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'GeoSmart',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.textLight,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous à votre compte',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white.withOpacity(0.5) : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: LucideIcons.mail,
                          isDarkMode: isDarkMode,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 32),
                        // Login Button
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
                            onPressed: _handleLogin,
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
                                  'Se connecter',
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
                        Row(
                          children: [
                            Expanded(child: Divider(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Ou continuer avec',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white.withOpacity(0.3) : AppColors.textMutedLight,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Social Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialIcon(LucideIcons.github, isDarkMode, () {}),
                            const SizedBox(width: 24),
                            _socialIcon(LucideIcons.chrome, isDarkMode, () {}),
                          ],
                        ),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: RichText(
                            text: TextSpan(
                              text: "Pas encore de compte ? ",
                              style: GoogleFonts.inter(color: isDarkMode ? Colors.white.withOpacity(0.5) : AppColors.textMutedLight),
                              children: [
                                TextSpan(
                                  text: "S'inscrire",
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

  Widget _socialIcon(IconData icon, bool isDarkMode, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        opacity: isDarkMode ? 0.05 : 0.08,
        child: Icon(icon, size: 24, color: isDarkMode ? Colors.white.withOpacity(0.8) : AppColors.textLight.withOpacity(0.8)),
      ),
    );
  }
}
