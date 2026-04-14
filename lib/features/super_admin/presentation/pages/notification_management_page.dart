import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/app_header.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/core/services/api_service.dart';

class NotificationManagementPage extends StatefulWidget {
  final String userRole;
  const NotificationManagementPage({Key? key, this.userRole = 'SUPER_ADMIN'}) : super(key: key);

  @override
  State<NotificationManagementPage> createState() => _NotificationManagementPageState();
}

class _NotificationManagementPageState extends State<NotificationManagementPage> {
  final _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
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
    final isMobile = MediaQuery.of(context).size.width < 900;
    final userName = widget.userRole == 'SUPER_ADMIN' ? 'Super Admin' : 'Admin';

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: isMobile ? AppHeader(userName: userName) : null,
      body: Row(
        children: [
          if (!isMobile)
            PremiumSidebar(
              currentRoute: widget.userRole == 'SUPER_ADMIN' ? '/super-admin-notifications' : '/admin-notifications',
              userName: userName,
              userRole: widget.userRole,
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDarkMode, isMobile),
                  SizedBox(height: isMobile ? 16 : 32),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _buildNotificationList(isDarkMode, isMobile)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              Text(
                'Restez informé des événements importants.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            isMobile ? 'Tout lire' : 'Tout marquer comme lu',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationList(bool isDarkMode, bool isMobile) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 28,
      opacity: 0.04,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ListView.separated(
          itemCount: _notifications.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.black12),
          itemBuilder: (context, index) {
            final notif = _notifications[index];
            return ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 20,
              ),
              leading: _typeIcon(notif['type']?.toString() ?? 'info'),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      notif['title']?.toString() ?? 'Sans titre',
                      style: GoogleFonts.outfit(
                        fontWeight: (notif['isRead'] == true) ? FontWeight.w500 : FontWeight.bold,
                        color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                  if (notif['isRead'] != true)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, Color(0xFF6366F1)],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    notif['message']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: isMobile ? 12 : 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 12, color: isDarkMode ? Colors.white24 : Colors.black26),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(notif['time'] ?? notif['createdAt']),
                        style: GoogleFonts.inter(fontSize: 11, color: isDarkMode ? Colors.white24 : Colors.black26),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: isMobile 
                ? null 
                : IconButton(
                    icon: Icon(LucideIcons.moreHorizontal, size: 18, color: isDarkMode ? Colors.white38 : Colors.black38),
                    onPressed: () {},
                  ),
            );
          },
        ),
      ),
    );
  }

  Widget _typeIcon(String? type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'error': icon = LucideIcons.alertCircle; color = AppColors.error; break;
      case 'warning': icon = LucideIcons.alertTriangle; color = AppColors.warning; break;
      case 'success': icon = LucideIcons.checkCircle; color = AppColors.success; break;
      default: icon = LucideIcons.info; color = AppColors.info;
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return 'À l\'instant';
    if (time is String) {
      try {
        final date = DateTime.parse(time);
        final now = DateTime.now();
        final diff = now.difference(date);
        if (diff.inMinutes < 1) return 'À l\'instant';
        if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
        if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return time.toString();
      }
    }
    return time.toString();
  }
}
