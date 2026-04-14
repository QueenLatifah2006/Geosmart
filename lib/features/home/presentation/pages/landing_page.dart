import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/theme/app_colors.dart';

import 'package:geosmart/core/services/api_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await _apiService.getCurrentUser();
    if (user != null && mounted) {
      if (user.role == 'super_admin') {
        Navigator.pushReplacementNamed(context, '/super-admin-dashboard');
      } else if (user.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-dashboard');
      }
    }
  }

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'GEOSMART',
      'description': 'La plateforme intelligente de géolocalisation pour explorer et gérer les structures de la ville avec une expérience premium.',
      'icon': LucideIcons.mapPin,
    },
    {
      'title': 'EXPLORER',
      'description': 'Découvrez tous les points d\'intérêt de Ngaoundéré avec une précision inégalée et des filtres intelligents.',
      'icon': LucideIcons.map,
    },
    {
      'title': 'GÉRER',
      'description': 'Outils avancés pour les administrateurs pour gérer leurs établissements et notifications en temps réel.',
      'icon': LucideIcons.building,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Dark Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Deep Slate
                  Color(0xFF020617), // Deep Black
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Decorative background shapes (Darker Purple for depth)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                color: const Color(0xFF4C1D95).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content with PageView
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildPage(
                      context, 
                      _onboardingData[index]['title'], 
                      _onboardingData[index]['description'], 
                      _onboardingData[index]['icon'], 
                      isMobile,
                      size,
                    );
                  },
                ),
              ),
              
              // Bottom Section: Dots, Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
                child: Column(
                  children: [
                    // START / NEXT Button
                    SizedBox(
                      width: isMobile ? double.infinity : 300,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _onboardingData.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400), 
                              curve: Curves.easeInOut
                            );
                          } else {
                            Navigator.pushNamed(context, '/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 10,
                          shadowColor: Colors.black.withOpacity(0.5),
                        ),
                        child: Text(
                          _currentPage == _onboardingData.length - 1 ? 'START' : 'SUIVANT',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Page Indicators (Dots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length, 
                        (index) => _buildDot(index == _currentPage)
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, String title, String description, IconData icon, bool isMobile, Size size) {
    return Center(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32.0 : 64.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Title
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 42 : 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Central Icon with Glassmorphism
              GlassContainer(
                width: isMobile ? 220 : 300,
                height: isMobile ? 220 : 300,
                borderRadius: 60,
                blur: 20,
                opacity: 0.1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: isMobile ? 100 : 140,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Description Text
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 20,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: isActive ? 24 : 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: isActive ? null : Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
    );
  }
}
