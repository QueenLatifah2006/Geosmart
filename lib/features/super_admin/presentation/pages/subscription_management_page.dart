import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/utils/snackbar_utils.dart';
import 'package:geosmart/main.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/custom_header.dart';
import 'package:geosmart/core/services/api_service.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';

import 'package:geosmart/features/super_admin/presentation/pages/add_subscription_page.dart';
import 'package:geosmart/features/super_admin/presentation/pages/edit_subscription_page.dart';

class SubscriptionManagementPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final bool isMobile;
  final Function(int)? onMenuTap;

  const SubscriptionManagementPage({
    Key? key, 
    this.userRole = 'SUPER_ADMIN', 
    this.userName = 'Super Admin',
    this.isMobile = false,
    this.onMenuTap,
  }) : super(key: key);

  @override
  State<SubscriptionManagementPage> createState() => _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends State<SubscriptionManagementPage> {
  final _apiService = ApiService();
  List<dynamic> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    try {
      final subscriptions = await _apiService.getSubscriptions();
      if (mounted) {
        setState(() {
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erreur lors du chargement des abonnements: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 32),
      color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isMobile)
              CustomHeader(
                title: 'Abonnements',
                isDarkMode: isDarkMode,
                userRole: widget.userRole,
                onNotificationTap: () {},
                onMenuTap: widget.onMenuTap ?? (index) {},
              ),
            const SizedBox(height: 24),
            _buildHeader(isDarkMode),
            const SizedBox(height: 24),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildSubscriptionList(isDarkMode),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );

    if (widget.isMobile) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          PremiumSidebar(
            currentRoute: widget.userRole == 'SUPER_ADMIN' ? '/super-admin-subscriptions' : '/admin-subscriptions',
            userName: widget.userName,
            userRole: widget.userRole,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Abonnements',
              style: GoogleFonts.outfit(
                fontSize: widget.isMobile ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            Text(
              'Gérez les forfaits premium des structures.',
              style: GoogleFonts.inter(
                fontSize: widget.isMobile ? 12 : 14,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        if (widget.userRole == 'SUPER_ADMIN' || widget.userRole == 'ADMIN')
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddSubscriptionPage()),
                ).then((_) => _fetchSubscriptions());
              },
              icon: Icon(LucideIcons.plus, color: AppColors.primary),
              tooltip: 'Ajouter un abonnement',
            ),
          ),
      ],
    );
  }

  Widget _buildSubscriptionList(bool isDarkMode) {
    if (_subscriptions.isEmpty) {
      return const Center(child: Text('Aucun abonnement trouvé'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final sub = _subscriptions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            opacity: 0.04,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Abonnement ${sub['type']}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    _statusBadge(sub['status']),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Structure: ${sub['structureId'] is Map ? sub['structureId']['name'] : 'Inconnue'}',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  'Expire le: ${sub['endDate'] != null ? DateTime.parse(sub['endDate']).toLocal().toString().split(' ')[0] : 'N/A'}',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (widget.userRole == 'SUPER_ADMIN' || widget.userRole == 'ADMIN')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!(widget.userRole == 'ADMIN' && sub['structureId'] != null && sub['structureId']['isBlocked'] == true))
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditSubscriptionPage(subscription: sub),
                              ),
                            );
                            if (result == true) _fetchSubscriptions();
                          },
                          child: const Text('Modifier'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == 'active' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
