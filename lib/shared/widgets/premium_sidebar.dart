import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/main.dart';

import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:geosmart/core/theme/app_colors.dart';

class PremiumSidebar extends StatelessWidget {
  final String currentRoute;
  final String userName;
  final String userRole;

  const PremiumSidebar({
    Key? key,
    required this.currentRoute,
    required this.userName,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      width: 280,
      borderRadius: 0,
      blur: 25,
      opacity: isDarkMode ? 0.05 : 0.4,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildHeader(isDarkMode),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              children: _buildNavItems(context, isDarkMode),
            ),
          ),
          _buildFooter(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'GeoSmart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, bool isDarkMode) {
    if (userRole == 'SUPER_ADMIN') {
      return [
        _navItem(context, LucideIcons.layoutDashboard, 'Dashboard', '/super-admin-dashboard', isDarkMode),
        _navItem(context, LucideIcons.building, 'Structures', '/super-admin-structures', isDarkMode),
        _navItem(context, LucideIcons.users, 'Utilisateurs', '/super-admin-users', isDarkMode),
        _navItem(context, LucideIcons.creditCard, 'Abonnements', '/super-admin-subscriptions', isDarkMode),
        _navItem(context, LucideIcons.bell, 'Notifications', '/super-admin-notifications', isDarkMode),
        _navItem(context, LucideIcons.user, 'Profil', '/super-admin-profile', isDarkMode),
      ];
    } else if (userRole == 'ADMIN') {
      return [
        _navItem(context, LucideIcons.layoutDashboard, 'Dashboard', '/admin-dashboard', isDarkMode),
        _navItem(context, LucideIcons.building, 'Structures', '/admin-structures', isDarkMode),
        _navItem(context, LucideIcons.creditCard, 'Abonnements', '/admin-subscriptions', isDarkMode),
        _navItem(context, LucideIcons.bell, 'Notifications', '/admin-notifications', isDarkMode),
        _navItem(context, LucideIcons.user, 'Profil', '/admin-profile', isDarkMode),
      ];
    } else {
      return [
        _navItem(context, LucideIcons.map, 'Carte', '/user-dashboard', isDarkMode),
        _navItem(context, LucideIcons.search, 'Recherche', '/user-search', isDarkMode),
        _navItem(context, LucideIcons.heart, 'Favoris', '/user-favorites', isDarkMode),
        _navItem(context, LucideIcons.bell, 'Notifications', '/user-notifications', isDarkMode),
        _navItem(context, LucideIcons.settings, 'Paramètres', '/user-settings', isDarkMode),
        _navItem(context, LucideIcons.user, 'Profil', '/user-profile', isDarkMode),
      ];
    }
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String route, bool isDarkMode) {
    final isSelected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.premiumGradient : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : (isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight),
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDarkMode ? AppColors.textDark : AppColors.textLight),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(userName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      userRole.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(isDarkMode ? LucideIcons.sun : LucideIcons.moon, size: 20),
                onPressed: () => GeoSmartApp.of(context)?.toggleTheme(),
                tooltip: 'Changer le thème',
              ),
              IconButton(
                icon: const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
                onPressed: () {
                  showCustomConfirmDialog(
                    context,
                    title: 'Déconnexion',
                    message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
                    confirmLabel: 'Se déconnecter',
                    confirmColor: Colors.red,
                    icon: LucideIcons.logOut,
                    onConfirm: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  );
                },
                tooltip: 'Déconnexion',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
