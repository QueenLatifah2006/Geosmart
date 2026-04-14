import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/core/services/api_service.dart';

class RecentActivitiesPage extends StatefulWidget {
  final String userRole;
  const RecentActivitiesPage({Key? key, this.userRole = 'SUPER_ADMIN'}) : super(key: key);

  @override
  State<RecentActivitiesPage> createState() => _RecentActivitiesPageState();
}

class _RecentActivitiesPageState extends State<RecentActivitiesPage> {
  final _apiService = ApiService();
  List<dynamic> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final activities = await _apiService.getActivities();
      if (mounted) {
        setState(() {
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

  IconData _getIconForAction(String action) {
    switch (action) {
      case 'CREATED_STRUCTURE': return LucideIcons.plusCircle;
      case 'UPDATED_STRUCTURE': return LucideIcons.edit;
      case 'DELETED_STRUCTURE': return LucideIcons.trash2;
      case 'BLOCKED_STRUCTURE': return LucideIcons.lock;
      case 'UNBLOCKED_STRUCTURE': return LucideIcons.unlock;
      case 'CREATED_USER': return LucideIcons.userPlus;
      case 'UPDATED_USER': return LucideIcons.userCheck;
      case 'BLOCKED_USER': return LucideIcons.ban;
      case 'UNBLOCKED_USER': return LucideIcons.checkCircle;
      default: return LucideIcons.activity;
    }
  }

  Color _getColorForAction(String action) {
    if (action.contains('DELETE') || action.contains('BLOCK')) return AppColors.error;
    if (action.contains('CREATE')) return AppColors.success;
    if (action.contains('UPDATE')) return AppColors.warning;
    return AppColors.primary;
  }

  String _formatAction(String action, String targetType) {
    return '${action.replaceAll('_', ' ')}: $targetType';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final userName = widget.userRole == 'SUPER_ADMIN' ? 'Super Admin' : 'Admin';

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          if (!isMobile)
            PremiumSidebar(
              currentRoute: '/recent-activities',
              userName: userName,
              userRole: widget.userRole,
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDarkMode, isMobile),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 28,
                      opacity: 0.05,
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : _activities.isEmpty
                          ? const Center(child: Text('Aucune activité trouvée'))
                          : ListView.separated(
                              itemCount: _activities.length,
                              separatorBuilder: (context, index) => Divider(height: 32, color: isDarkMode ? Colors.white10 : Colors.black12),
                              itemBuilder: (context, index) {
                                final activity = _activities[index];
                                return _activityItem(activity, isDarkMode);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode, bool isMobile) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.arrowLeft, size: 20, color: isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toutes les Activités',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Historique complet des actions effectuées sur la plateforme.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _activityItem(dynamic activity, bool isDarkMode) {
    final action = activity['action']?.toString() ?? 'UNKNOWN';
    final targetType = activity['targetType']?.toString() ?? '';
    final timestamp = activity['timestamp'] != null ? DateTime.tryParse(activity['timestamp'].toString()) ?? DateTime.now() : DateTime.now();
    final user = (activity['userId'] != null && activity['userId'] is Map) 
        ? activity['userId']['name']?.toString() ?? 'Inconnu' 
        : 'Inconnu';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getColorForAction(action).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(_getIconForAction(action), color: _getColorForAction(action), size: 20),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatAction(action, targetType),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 12, color: isDarkMode ? Colors.white38 : Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontSize: 12, color: isDarkMode ? Colors.white38 : Colors.black38),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white12 : Colors.black12,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.user, size: 12, color: AppColors.primary.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Par $user',
                    style: GoogleFonts.inter(
                      fontSize: 12, 
                      color: AppColors.primary.withOpacity(0.7), 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
