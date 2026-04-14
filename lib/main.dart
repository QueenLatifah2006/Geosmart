import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/features/home/presentation/pages/landing_page.dart';
import 'package:geosmart/features/auth/presentation/pages/login_page.dart';
import 'package:geosmart/features/auth/presentation/pages/register_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/super_admin_dashboard_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/structure_management_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/user_management_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/subscription_management_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/notification_management_page.dart';
import 'package:geosmart/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:geosmart/features/user/presentation/pages/user_dashboard_page.dart';
import 'package:geosmart/shared/pages/profile_page.dart';

import 'package:geosmart/shared/widgets/placeholder_page.dart';
import 'package:geosmart/shared/widgets/main_navigation_wrapper.dart';

void main() {
  runApp(const GeoSmartApp());
}

class GeoSmartApp extends StatefulWidget {
  const GeoSmartApp({Key? key}) : super(key: key);

  static _GeoSmartAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_GeoSmartAppState>();

  @override
  State<GeoSmartApp> createState() => _GeoSmartAppState();
}

class _GeoSmartAppState extends State<GeoSmartApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoSmart Ngaoundéré',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceLight,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceDark,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        
        // Super Admin Routes
        '/super-admin-dashboard': (context) => const MainNavigationWrapper(userRole: 'SUPER_ADMIN'),
        '/super-admin-structures': (context) => const StructureManagementPage(userRole: 'SUPER_ADMIN', userName: 'Super Admin'),
        '/super-admin-users': (context) => const UserManagementPage(),
        '/super-admin-subscriptions': (context) => const SubscriptionManagementPage(userRole: 'SUPER_ADMIN', userName: 'Super Admin'),
        '/super-admin-notifications': (context) => const NotificationManagementPage(userRole: 'SUPER_ADMIN'),
        '/super-admin-profile': (context) => const ProfilePage(userName: 'Super Admin', userRole: 'SUPER_ADMIN'),
        
        // Admin Routes
        '/admin-dashboard': (context) => const MainNavigationWrapper(userRole: 'ADMIN'),
        '/admin-structures': (context) => const StructureManagementPage(userRole: 'ADMIN', userName: 'Admin'),
        '/admin-subscriptions': (context) => const SubscriptionManagementPage(userRole: 'ADMIN', userName: 'Admin'),
        '/admin-notifications': (context) => const NotificationManagementPage(userRole: 'ADMIN'),
        '/admin-profile': (context) => const ProfilePage(userName: 'Admin', userRole: 'ADMIN'),
        
        // User Routes
        '/user-dashboard': (context) => const MainNavigationWrapper(userRole: 'USER'),
        '/user-notifications': (context) => const NotificationManagementPage(userRole: 'USER'),
        '/user-settings': (context) => const ProfilePage(userName: 'Utilisateur', userRole: 'USER'),
        
        // Shared Routes
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ProfilePage(
            userName: args?['userName'] ?? 'Utilisateur',
            userRole: args?['userRole'] ?? 'USER',
          );
        },
      },
    );
  }
}
