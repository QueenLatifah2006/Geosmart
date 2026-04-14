import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/custom_header.dart';

import 'package:geosmart/features/super_admin/presentation/pages/recent_activities_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/verify_structures_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/send_notification_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/notification_management_page.dart';

import 'package:geosmart/core/services/api_service.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  final bool isMobile;
  final String userRole;
  final String userName;
  final Function(int)? onMenuTap;

  const SuperAdminDashboardPage({
    Key? key, 
    this.isMobile = false,
    this.userRole = 'SUPER_ADMIN',
    this.userName = 'Super Admin',
    this.onMenuTap,
  }) : super(key: key);

  @override
  State<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  final _apiService = ApiService();
  Map<String, dynamic>? _stats;
  List<dynamic> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final stats = await _apiService.getStats();
      final activities = await _apiService.getRecentActivities();
      if (mounted) {
        setState(() {
          _stats = stats;
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isMobile)
              CustomHeader(
                title: 'Dashboard',
                isDarkMode: isDarkMode,
                userRole: widget.userRole,
                onNotificationTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationManagementPage()),
                  );
                },
                onMenuTap: widget.onMenuTap ?? (index) {},
              ),
            const SizedBox(height: 24),
            _buildWelcomeSection(isDarkMode),
            const SizedBox(height: 32),
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildStatsGrid(isDarkMode),
            const SizedBox(height: 32),
            if (widget.isMobile) ...[
              _buildRecentActivity(context, isDarkMode),
              const SizedBox(height: 24),
              _buildQuickActions(context, isDarkMode),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildRecentActivity(context, isDarkMode)),
                  const SizedBox(width: 40),
                  Expanded(child: _buildQuickActions(context, isDarkMode)),
                ],
              ),
            const SizedBox(height: 100), // Space for floating nav
          ],
        ),
      ),
    );

    if (widget.isMobile) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Stack(
          children: [
            _buildGlows(),
            SafeArea(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          _buildGlows(),
          Row(
            children: [
              PremiumSidebar(
                currentRoute: widget.userRole == 'SUPER_ADMIN' ? '/super-admin-dashboard' : '/admin-dashboard',
                userName: widget.userName,
                userRole: widget.userRole,
              ),
              Expanded(child: content),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.premiumGradient.createShader(bounds),
            child: Text(
              'Bienvenue, ${widget.userName}',
              style: GoogleFonts.outfit(
                fontSize: widget.isMobile ? 28 : 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Voici un aperçu global de GeoSmart Ngaoundéré.',
            style: GoogleFonts.inter(
              fontSize: widget.isMobile ? 14 : 16,
              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDarkMode) {
    return GridView.count(
      crossAxisCount: widget.isMobile ? 2 : 4,
      shrinkWrap: true,
      crossAxisSpacing: widget.isMobile ? 16 : 24,
      mainAxisSpacing: widget.isMobile ? 16 : 24,
      childAspectRatio: widget.isMobile ? 0.9 : 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard('Total Utilisateurs', '${_stats?['totalUsers'] ?? 0}', LucideIcons.users, AppColors.primary, '+12%', isDarkMode),
        _statCard('Structures Actives', '${_stats?['totalStructures'] ?? 0}', LucideIcons.building, AppColors.success, '+5%', isDarkMode),
        _statCard('Abonnements Premium', '${_stats?['premiumStructures'] ?? 0}', LucideIcons.creditCard, AppColors.info, '+8%', isDarkMode),
        _statCard('Alertes Système', '${_stats?['alerts'] ?? 0}', LucideIcons.alertTriangle, AppColors.error, '-2%', isDarkMode),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, String trend, bool isDarkMode) {
    return GlassContainer(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
      borderRadius: 32,
      opacity: 0.04,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon,
              size: widget.isMobile ? 60 : 80,
              color: color.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: widget.isMobile ? 18 : 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (trend.contains('+') ? AppColors.success : AppColors.error).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trend,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: trend.contains('+') ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: widget.isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: widget.isMobile ? 10 : 12,
                      color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black54,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, bool isDarkMode) {
    return GlassContainer(
      padding: EdgeInsets.all(widget.isMobile ? 24 : 32),
      borderRadius: 32,
      opacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.activity, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Activités Récentes',
                    style: GoogleFonts.outfit(
                      fontSize: widget.isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecentActivitiesPage(userRole: widget.userRole)),
                  );
                },
                child: Text(
                  'Voir tout',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: widget.isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_activities.isEmpty)
            const Center(child: Text('Aucune activité récente'))
          else
            ..._activities.take(5).map((activity) {
              IconData icon;
              Color color;
              final String action = activity['action']?.toString() ?? 'Action';
              final String targetType = activity['targetType']?.toString() ?? 'Système';
              final String timestampStr = activity['timestamp']?.toString() ?? DateTime.now().toIso8601String();
              
              final String userName = (activity['userId'] != null && activity['userId'] is Map)
                  ? activity['userId']['name']?.toString() ?? 'Inconnu'
                  : 'Inconnu';
              
              if (action.contains('BLOCK')) {
                icon = LucideIcons.ban;
                color = AppColors.error;
              } else if (action.contains('CREATE')) {
                icon = LucideIcons.plusCircle;
                color = AppColors.success;
              } else if (action.contains('UPDATE')) {
                icon = LucideIcons.edit2;
                color = AppColors.warning;
              } else {
                icon = LucideIcons.activity;
                color = AppColors.primary;
              }

              String formattedTime;
              try {
                formattedTime = DateTime.parse(timestampStr).toLocal().toString().split('.')[0];
              } catch (e) {
                formattedTime = 'Date inconnue';
              }

              return _activityItem(
                '$action - $targetType',
                formattedTime,
                userName,
                icon,
                color,
                isDarkMode,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String time, String userName, IconData icon, Color color, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: BoxDecoration(color: isDarkMode ? Colors.white24 : Colors.black26, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      'Par $userName',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    return GlassContainer(
      padding: EdgeInsets.all(widget.isMobile ? 24 : 32),
      borderRadius: 32,
      opacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.zap, color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Actions Rapides',
                style: GoogleFonts.outfit(
                  fontSize: widget.isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _quickActionButton(context, 'Envoyer une notification', LucideIcons.send, AppColors.primary, isDarkMode, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SendNotificationPage(userRole: widget.userRole)),
            );
          }),
          const SizedBox(height: 16),
          _quickActionButton(context, 'Vérifier les structures', LucideIcons.shieldCheck, AppColors.warning, isDarkMode, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VerifyStructuresPage(userRole: widget.userRole)),
            );
          }),
        ],
      ),
    );
  }

  Widget _quickActionButton(BuildContext context, String label, IconData icon, Color color, bool isDarkMode, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: isDarkMode ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildGlows() {
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -150,
          child: _buildGlow(AppColors.primary.withOpacity(0.1), 500),
        ),
        Positioned(
          bottom: -100,
          left: 100,
          child: _buildGlow(AppColors.secondary.withOpacity(0.08), 400),
        ),
      ],
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
}
