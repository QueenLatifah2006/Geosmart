import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/core/theme/app_colors.dart';

class MobileNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userRole;

  const MobileNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    List<Map<String, dynamic>> navItems = [];

    if (userRole == 'SUPER_ADMIN') {
      navItems = [
        {'icon': LucideIcons.layoutDashboard, 'label': 'Dashboard'},
        {'icon': LucideIcons.building, 'label': 'Structures'},
        {'icon': LucideIcons.users, 'label': 'Utilisateurs'},
        {'icon': LucideIcons.creditCard, 'label': 'Abonnements'},
      ];
    } else if (userRole == 'ADMIN') {
      navItems = [
        {'icon': LucideIcons.layoutDashboard, 'label': 'Dashboard'},
        {'icon': LucideIcons.building, 'label': 'Structures'},
        {'icon': LucideIcons.creditCard, 'label': 'Abonnements'},
      ];
    } else {
      navItems = [
        {'icon': LucideIcons.map, 'label': 'Carte'},
        {'icon': LucideIcons.bell, 'label': 'Notifications'},
        {'icon': LucideIcons.users, 'label': 'utilisateurs'},
      ];
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.1),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: navItems.asMap().entries.map((entry) {
                int idx = entry.key;
                var item = entry.value;
                bool isSelected = currentIndex == idx;

                return GestureDetector(
                  onTap: () => onTap(idx),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'],
                          color: isSelected ? AppColors.primary : (isDarkMode ? Colors.white70 : Colors.black54),
                          size: 24,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
