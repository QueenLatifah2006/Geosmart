import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/core/theme/app_colors.dart';

import 'package:geosmart/main.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? profileImageUrl;
  final bool isMobile;

  const AppHeader({
    Key? key,
    required this.userName,
    this.profileImageUrl,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          const Icon(LucideIcons.mapPin, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'GeoSmart',
            style: TextStyle(
              color: isDarkMode ? AppColors.textDark : AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(isDarkMode ? LucideIcons.sun : LucideIcons.moon, size: 20),
          onPressed: () => GeoSmartApp.of(context)?.toggleTheme(),
          color: isDarkMode ? AppColors.textDark : AppColors.textLight,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              showCustomConfirmDialog(
                context,
                title: 'Déconnexion',
                message: 'Voulez-vous vous déconnecter ?',
                confirmLabel: 'Déconnecter',
                confirmColor: AppColors.error,
                icon: LucideIcons.logOut,
                onConfirm: () => Navigator.pushReplacementNamed(context, '/login'),
              );
            } else if (value == 'profile') {
              // Navigate to profile
            }
          },
          offset: const Offset(0, 50),
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: profileImageUrl != null 
                ? NetworkImage(profileImageUrl!) 
                : null,
              child: profileImageUrl == null 
                ? const Icon(LucideIcons.user, size: 20, color: AppColors.primary) 
                : null,
            ),
          ),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(LucideIcons.user, size: 18),
                title: Text('Profil'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(LucideIcons.logOut, size: 18, color: AppColors.error),
                title: Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
