import 'package:flutter/material.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/core/theme/app_colors.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String userRole;
  final String currentRoute;
  final bool isMobile;

  const PlaceholderPage({
    Key? key,
    required this.title,
    required this.userRole,
    required this.currentRoute,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ),
    );

    if (isMobile) {
      return Scaffold(body: content);
    }

    return Scaffold(
      body: Row(
        children: [
          PremiumSidebar(
            currentRoute: currentRoute,
            userName: 'Utilisateur',
            userRole: userRole,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
