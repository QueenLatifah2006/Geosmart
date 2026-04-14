import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/services/api_service.dart';
import 'package:geosmart/core/models/structure_model.dart';
import 'package:geosmart/features/super_admin/presentation/pages/structure_management_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/add_structure_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/edit_structure_page.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/custom_header.dart';

class AdminDashboardPage extends StatefulWidget {
  final bool isMobile;
  final Function(int)? onMenuTap;

  const AdminDashboardPage({Key? key, this.isMobile = false, this.onMenuTap}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _apiService = ApiService();
  Map<String, dynamic>? _stats;
  List<dynamic> _activities = [];
  List<StructureModel> _recentStructures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _apiService.getStats(),
        _apiService.getStructures(),
        _apiService.getRecentActivities(),
      ]);
      
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _recentStructures = (results[1] as List<StructureModel>).take(3).toList();
          _activities = results[2] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
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
                title: 'Dashboard Admin',
                isDarkMode: isDarkMode,
                userRole: 'ADMIN',
                onNotificationTap: () {},
                onMenuTap: widget.onMenuTap ?? (index) {},
              ),
            const SizedBox(height: 24),
            _buildWelcomeSection(isDarkMode),
            const SizedBox(height: 32),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildStatsGrid(isDarkMode, context),
            const SizedBox(height: 32),
            if (widget.isMobile) ...[
              _buildRecentActivity(context, isDarkMode),
              const SizedBox(height: 24),
              _buildRecentStructures(isDarkMode, context),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildRecentActivity(context, isDarkMode)),
                  const SizedBox(width: 40),
                  Expanded(child: _buildRecentStructures(isDarkMode, context)),
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
                currentRoute: '/admin-dashboard',
                userName: 'Administrateur',
                userRole: 'ADMIN',
              ),
              Expanded(child: content),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tableau de Bord Admin',
          style: GoogleFonts.outfit(
            fontSize: widget.isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        Text(
          'Gérez vos structures et suivez vos performances.',
          style: GoogleFonts.inter(
            fontSize: widget.isMobile ? 14 : 16,
            color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDarkMode, BuildContext context) {
    return GridView.count(
      crossAxisCount: widget.isMobile ? 2 : 4,
      shrinkWrap: true,
      crossAxisSpacing: widget.isMobile ? 16 : 24,
      mainAxisSpacing: widget.isMobile ? 16 : 24,
      childAspectRatio: widget.isMobile ? 0.9 : 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard('Total Utilisateurs', '${_stats?['totalUsers'] ?? 0}', LucideIcons.users, AppColors.primary, isDarkMode),
        _statCard('Structures Actives', '${_stats?['totalStructures'] ?? 0}', LucideIcons.building, AppColors.success, isDarkMode, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StructureManagementPage(userRole: 'ADMIN')),
          );
        }),
        _statCard('Abonnements Premium', '${_stats?['premiumStructures'] ?? 0}', LucideIcons.creditCard, AppColors.info, isDarkMode),
        _statCard('Vues Totales', '${_stats?['totalViews'] ?? 0}', LucideIcons.eye, AppColors.accent, isDarkMode),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDarkMode, {VoidCallback? onTap}) {
    return GlassContainer(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
      borderRadius: 32,
      opacity: 0.04,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: widget.isMobile ? 18 : 22),
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

  Widget _buildRecentStructures(bool isDarkMode, BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.all(widget.isMobile ? 24 : 40),
      borderRadius: 28,
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mes Structures Récentes',
                style: GoogleFonts.outfit(
                  fontSize: widget.isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddStructurePage()),
                    );
                  },
                  icon: Icon(LucideIcons.plus, size: widget.isMobile ? 20 : 24, color: Colors.white),
                  tooltip: 'Ajouter une structure',
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isMobile ? 24 : 32),
          if (_recentStructures.isEmpty)
            const Center(child: Text('Aucune structure trouvée'))
          else
            ..._recentStructures.map((s) => _structureItem(s, isDarkMode, context)).toList(),
        ],
      ),
    );
  }

  Widget _structureItem(StructureModel structure, bool isDarkMode, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.building, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(structure.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(structure.type, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          _statusBadge(structure.isBlocked ? 'Bloqué' : 'Actif'),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(LucideIcons.edit2, size: 18), 
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditStructurePage(structure: structure)));
              if (result == true) _fetchData();
            }
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == 'Actif' ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGlows() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: _buildGlow(AppColors.primary.withOpacity(0.1), 400),
        ),
        Positioned(
          bottom: 100,
          left: -150,
          child: _buildGlow(AppColors.secondary.withOpacity(0.08), 500),
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
