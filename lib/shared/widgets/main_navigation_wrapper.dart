import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/mobile_navigation.dart';
import 'package:geosmart/features/super_admin/presentation/pages/super_admin_dashboard_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/structure_management_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/user_management_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/subscription_management_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/notification_management_page.dart';
import 'package:geosmart/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:geosmart/features/user/presentation/pages/user_dashboard_page.dart';
import 'package:geosmart/shared/pages/profile_page.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

class MainNavigationWrapper extends StatefulWidget {
  final String userRole;
  final String initialRoute;

  const MainNavigationWrapper({
    Key? key,
    required this.userRole,
    this.initialRoute = '',
  }) : super(key: key);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  bool _showProfileMenu = false;

  Widget _getPage(int index) {
    if (widget.userRole == 'SUPER_ADMIN') {
      switch (index) {
        case 0: return SuperAdminDashboardPage(
          isMobile: true, 
          userRole: 'SUPER_ADMIN', 
          userName: 'Super Admin',
          onMenuTap: (idx) => setState(() => _currentIndex = idx),
        );
        case 1: return StructureManagementPage(
          isMobile: true, 
          userRole: 'SUPER_ADMIN',
          onMenuTap: (idx) => setState(() => _currentIndex = idx),
        );
        case 2: return UserManagementPage(
          isMobile: true,
          onMenuTap: (idx) => setState(() => _currentIndex = idx),
        );
        case 3: return SubscriptionManagementPage(
          isMobile: true, 
          userRole: 'SUPER_ADMIN',
          onMenuTap: (idx) => setState(() => _currentIndex = idx),
        );
        case 4: return const NotificationManagementPage(userRole: 'SUPER_ADMIN');
        case 5: return const ProfilePage(userName: 'Super Admin', userRole: 'SUPER_ADMIN', isMobile: true);
        default: return SuperAdminDashboardPage(isMobile: true, onMenuTap: (idx) => setState(() => _currentIndex = idx));
      }
    } else if (widget.userRole == 'ADMIN') {
      switch (index) {
        case 0: return AdminDashboardPage(
          isMobile: true,
          onMenuTap: (idx) => setState(() => _currentIndex = idx),
        );
        case 1: return StructureManagementPage(
          isMobile: true, 
          userRole: 'ADMIN',
          onMenuTap: (idx) => setState(() => _currentIndex = idx),
        );
        case 2: return SubscriptionManagementPage(
          isMobile: true, 
          userRole: 'ADMIN',
          onMenuTap: (idx) => setState(() => _currentIndex = idx),
        );
        case 3: return const NotificationManagementPage(userRole: 'ADMIN');
        case 4: return const ProfilePage(userName: 'Admin', userRole: 'ADMIN', isMobile: true);
        default: return AdminDashboardPage(isMobile: true, onMenuTap: (idx) => setState(() => _currentIndex = idx));
      }
    } else {
      switch (index) {
        case 0: return UserDashboardPage(
          isMobile: true,
          onMenuTap: (idx) => setState(() => _currentIndex = idx),
        );
        case 1: return const NotificationManagementPage(userRole: 'USER');
        case 2: return const ProfilePage(userName: 'Utilisateur', userRole: 'USER', isMobile: true);
        default: return UserDashboardPage(isMobile: true, onMenuTap: (idx) => setState(() => _currentIndex = idx));
      }
    }
  }

  void _handleLogout() {
    showCustomConfirmDialog(
      context,
      title: 'Déconnexion',
      message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
      confirmLabel: 'Se déconnecter',
      confirmColor: AppColors.error,
      icon: LucideIcons.logOut,
      onConfirm: () {
        Navigator.of(context).pushReplacementNamed('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          _getPage(_currentIndex),
          
          // Floating Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MobileNavigation(
              currentIndex: _currentIndex,
              userRole: widget.userRole,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                  _showProfileMenu = false;
                });
              },
            ),
          ),

          // Floating Profile Button
          Positioned(
            right: 24,
            bottom: 100,
            child: _buildFloatingProfileButton(isDarkMode),
          ),

          // Profile Dropdown Menu
          if (_showProfileMenu)
            Positioned(
              right: 24,
              bottom: 160,
              child: _buildProfileDropdown(isDarkMode),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingProfileButton(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showProfileMenu = !_showProfileMenu;
        });
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.premiumGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(LucideIcons.user, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildProfileDropdown(bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dropdownItem(
                LucideIcons.user,
                'Mon Profil',
                () {
                  setState(() {
                    _currentIndex = widget.userRole == 'SUPER_ADMIN' ? 5 : (widget.userRole == 'ADMIN' ? 4 : 2);
                    _showProfileMenu = false;
                  });
                },
                isDarkMode,
              ),
              _dropdownItem(
                isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                isDarkMode ? 'Mode Clair' : 'Mode Sombre',
                () {
                  // Toggle theme logic would go here
                  // For now just close menu
                  setState(() {
                    _showProfileMenu = false;
                  });
                },
                isDarkMode,
              ),
              const Divider(height: 1, color: Colors.white24),
              _dropdownItem(
                LucideIcons.logOut,
                'Déconnexion',
                () {
                  setState(() {
                    _showProfileMenu = false;
                  });
                  _handleLogout();
                },
                isDarkMode,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownItem(IconData icon, String label, VoidCallback onTap, bool isDarkMode, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary, size: 20),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? (isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
