import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/theme/app_colors.dart';
// import 'package:motion/motion.dart'; // Removed due to missing package

class CustomHeader extends StatefulWidget {
  final String title;
  final bool isDarkMode;
  final String userRole;
  final VoidCallback onNotificationTap;
  final Function(int) onMenuTap;

  final bool hasUnreadNotifications;

  const CustomHeader({
    Key? key,
    required this.title,
    required this.isDarkMode,
    required this.userRole,
    required this.onNotificationTap,
    required this.onMenuTap,
    this.hasUnreadNotifications = true, // Default to true for demo
  }) : super(key: key);

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isMenuOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });
    _controller.forward();
  }

  void _closeMenu() {
    _controller.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() {
          _isMenuOpen = false;
        });
      }
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _closeMenu,
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          Positioned(
            width: 220,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 60),
              child: Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: _animation,
                  alignment: Alignment.topLeft,
                  child: _buildDropdownMenu(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildHomeButton(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildNotificationButton(),
                ],
              ),
            ),
            const SizedBox(width: 48), // Spacer for balance
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return GestureDetector(
      onTap: _toggleMenu,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          _isMenuOpen ? LucideIcons.x : LucideIcons.home,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onNotificationTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.bell,
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              size: 20,
            ),
          ),
        ),
        if (widget.hasUnreadNotifications)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isDarkMode ? AppColors.backgroundDark : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownMenu() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (widget.isDarkMode ? Colors.black : Colors.white).withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _getMenuItems().asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                leading: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                title: Text(
                  item['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  _closeMenu();
                  widget.onMenuTap(item['index'] as int);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMenuItems() {
    if (widget.userRole == 'SUPER_ADMIN') {
      return [
        {'icon': LucideIcons.layoutDashboard, 'label': 'Dashboard', 'index': 0},
        {'icon': LucideIcons.building, 'label': 'Structures', 'index': 1},
        {'icon': LucideIcons.users, 'label': 'Utilisateurs', 'index': 2},
        {'icon': LucideIcons.creditCard, 'label': 'Abonnements', 'index': 3},
        {'icon': LucideIcons.bell, 'label': 'Notifications', 'index': 4},
      ];
    } else if (widget.userRole == 'ADMIN') {
      return [
        {'icon': LucideIcons.layoutDashboard, 'label': 'Dashboard', 'index': 0},
        {'icon': LucideIcons.building, 'label': 'Structures', 'index': 1},
        {'icon': LucideIcons.creditCard, 'label': 'Abonnements', 'index': 2},
        {'icon': LucideIcons.bell, 'label': 'Notifications', 'index': 3},
      ];
    } else {
      return [
        {'icon': LucideIcons.map, 'label': 'Carte', 'index': 0},
        {'icon': LucideIcons.bell, 'label': 'Notifications', 'index': 1},
      ];
    }
  }
}
