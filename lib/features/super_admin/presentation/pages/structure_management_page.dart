import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/core/utils/snackbar_utils.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'edit_structure_page.dart';
import 'add_structure_page.dart';
import 'structure_details_page.dart';
import 'notification_management_page.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/core/models/structure_model.dart';
import 'package:geosmart/core/services/api_service.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/custom_header.dart';

class StructureManagementPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final bool isMobile;
  final Function(int)? onMenuTap;

  const StructureManagementPage({
    Key? key, 
    this.userRole = 'SUPER_ADMIN', 
    this.userName = 'Super Admin',
    this.isMobile = false,
    this.onMenuTap,
  }) : super(key: key);

  @override
  State<StructureManagementPage> createState() => _StructureManagementPageState();
}

class _StructureManagementPageState extends State<StructureManagementPage> {
  final _apiService = ApiService();
  List<StructureModel> _structures = [];
  bool _isLoading = true;
  String _searchQuery = '';

  Map<String, dynamic> _stats = {
    'total': '0',
    'active': '0',
    'pending': '0',
    'blocked': '0',
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchStructures(),
      _fetchStats(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchStructures() async {
    try {
      final structures = await _apiService.getStructures();
      if (mounted) {
        setState(() {
          _structures = structures;
        });
      }
    } catch (e) {
      print('Error fetching structures: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Erreur lors du chargement des structures: $e');
      }
    }
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _apiService.getStats();
      if (mounted) {
        setState(() {
          _stats = {
            'total': stats['totalStructures'].toString(),
            'active': stats['activeStructures'].toString(),
            'pending': '0',
            'blocked': stats['blockedStructures'].toString(),
          };
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Erreur lors du chargement des statistiques: $e');
      }
    }
  }

  List<StructureModel> get _filteredStructures {
    if (_searchQuery.isEmpty) return _structures;
    return _structures.where((s) => 
      s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      s.type.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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
                title: 'Structures',
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
            _buildHeader(isDarkMode),
            const SizedBox(height: 24),
            _buildSearchAndStats(isDarkMode),
            const SizedBox(height: 24),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : (widget.isMobile ? _buildMobileList(isDarkMode) : _buildTable(isDarkMode)),
            const SizedBox(height: 100), // Space for floating nav
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
            currentRoute: widget.userRole == 'SUPER_ADMIN' ? '/super-admin-structures' : '/admin-structures',
            userName: widget.userName,
            userRole: widget.userRole,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildSearchAndStats(bool isDarkMode) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                opacity: 0.05,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une structure...',
                    hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
                    prefixIcon: Icon(LucideIcons.search, size: 20, color: isDarkMode ? Colors.white38 : Colors.black38),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _filterButton(LucideIcons.filter, 'Filtrer', isDarkMode),
          ],
        ),
        const SizedBox(height: 24),
        _buildStats(isDarkMode),
      ],
    );
  }

  Widget _filterButton(IconData icon, String label, bool isDarkMode) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      opacity: 0.05,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isDarkMode ? AppColors.textDark : AppColors.textLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBlock(StructureModel s) async {
    try {
      final updated = await _apiService.blockStructure(s.id, !s.isBlocked);
      setState(() {
        final index = _structures.indexWhere((item) => item.id == s.id);
        if (index != -1) _structures[index] = updated;
      });
      SnackBarUtils.showSuccess(context, '${s.name} a été ${updated.isBlocked ? 'bloqué' : 'débloqué'}');
    } catch (e) {
      SnackBarUtils.showError(context, 'Erreur: $e');
    }
  }

  Future<void> _handleDelete(StructureModel s) async {
    try {
      await _apiService.deleteStructure(s.id);
      setState(() {
        _structures.removeWhere((item) => item.id == s.id);
      });
      SnackBarUtils.showSuccess(context, '${s.name} a été supprimé');
    } catch (e) {
      SnackBarUtils.showError(context, 'Erreur: $e');
    }
  }

  Widget _buildMobileList(bool isDarkMode) {
    final structures = _filteredStructures;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: structures.length,
      itemBuilder: (context, index) {
        final s = structures[index];
        final bool isRestricted = (widget.userRole == 'ADMIN' && s.modifiedBySuperAdmin);

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
                    Expanded(
                      child: Text(
                        s.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    _statusBadge(s.isBlocked ? 'Bloqué' : (s.isPremium ? 'Premium' : 'Standard')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(LucideIcons.tag, size: 14, color: isDarkMode ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 8),
                    Text(
                      'Type: ${s.type}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionIcon(LucideIcons.eye, () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => StructureDetailsPage(structure: s, userRole: widget.userRole))
                      );
                    }, color: AppColors.primary),
                    const SizedBox(width: 8),
                    if (!(widget.userRole == 'ADMIN' && s.isBlocked)) ...[
                      _actionIcon(LucideIcons.edit2, () async {
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => EditStructurePage(structure: s))
                        );
                        if (result == true) _fetchData();
                      }, color: AppColors.warning),
                      const SizedBox(width: 8),
                    ],
                    if (widget.userRole == 'SUPER_ADMIN') ...[
                      _actionIcon(s.isBlocked ? LucideIcons.unlock : LucideIcons.ban, () {
                        showCustomConfirmDialog(
                          context,
                          title: s.isBlocked ? 'Débloquer la structure' : 'Bloquer la structure',
                          message: 'Voulez-vous vraiment ${s.isBlocked ? 'débloquer' : 'bloquer'} ${s.name} ?',
                          confirmLabel: s.isBlocked ? 'Débloquer' : 'Bloquer',
                          confirmColor: AppColors.warning,
                          icon: s.isBlocked ? LucideIcons.unlock : LucideIcons.ban,
                          onConfirm: () => _handleBlock(s),
                        );
                      }, color: s.isBlocked ? AppColors.success : AppColors.error),
                      const SizedBox(width: 8),
                    ],
                    if (!(widget.userRole == 'ADMIN' && s.isBlocked))
                      _actionIcon(LucideIcons.trash2, () {
                        showCustomConfirmDialog(
                          context,
                          title: 'Supprimer la structure',
                          message: 'Voulez-vous vraiment supprimer ${s.name} ? Cette action est irréversible.',
                          confirmLabel: 'Supprimer',
                          confirmColor: AppColors.error,
                          icon: LucideIcons.trash2,
                          onConfirm: () => _handleDelete(s),
                        );
                      }, color: AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback? onTap, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color ?? AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des Structures',
                style: GoogleFonts.outfit(
                  fontSize: widget.isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              Text(
                'Gérez et modérez les établissements de Ngaoundéré.',
                style: GoogleFonts.inter(
                  fontSize: widget.isMobile ? 12 : 14,
                  color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddStructurePage()),
              );
            },
            icon: const Icon(LucideIcons.plus, color: AppColors.primary),
            tooltip: 'Ajouter une structure',
          ),
        ),
      ],
    );
  }

  Widget _buildStats(bool isDarkMode) {
    if (widget.isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statCard('Total', _stats['total']!, LucideIcons.building, AppColors.primary, isDarkMode),
            const SizedBox(width: 12),
            _statCard('Actifs', _stats['active']!, LucideIcons.checkCircle, AppColors.success, isDarkMode),
            const SizedBox(width: 12),
            _statCard('Attente', _stats['pending']!, LucideIcons.clock, AppColors.warning, isDarkMode),
            const SizedBox(width: 12),
            _statCard('Bloqués', _stats['blocked']!, LucideIcons.ban, AppColors.error, isDarkMode),
          ],
        ),
      );
    }
    return Row(
      children: [
        _statCard('Total', _stats['total']!, LucideIcons.building, AppColors.primary, isDarkMode),
        const SizedBox(width: 24),
        _statCard('Actifs', _stats['active']!, LucideIcons.checkCircle, AppColors.success, isDarkMode),
        const SizedBox(width: 24),
        _statCard('En attente', _stats['pending']!, LucideIcons.clock, AppColors.warning, isDarkMode),
        const SizedBox(width: 24),
        _statCard('Bloqués', _stats['blocked']!, LucideIcons.ban, AppColors.error, isDarkMode),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDarkMode) {
    Widget card = GlassContainer(
      width: widget.isMobile ? 140 : null,
      padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
      borderRadius: 24,
      opacity: 0.04,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon,
              size: widget.isMobile ? 50 : 60,
              color: color.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: widget.isMobile ? 16 : 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: widget.isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return widget.isMobile ? card : Expanded(child: card);
  }

  Widget _buildTable(bool isDarkMode) {
    final structures = _filteredStructures;
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      opacity: 0.04,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02)),
          columns: [
            DataColumn(label: Text('Structure', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87))),
            DataColumn(label: Text('Type', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87))),
            DataColumn(label: Text('Statut', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87))),
            DataColumn(label: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87))),
          ],
          rows: structures.map((s) {
            final bool isRestricted = (widget.userRole == 'ADMIN' && s.modifiedBySuperAdmin);
            
            return DataRow(cells: [
              DataCell(Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87))),
              DataCell(Text(s.type, style: GoogleFonts.inter(color: isDarkMode ? Colors.white70 : Colors.black54))),
              DataCell(_statusBadge(s.isBlocked ? 'Bloqué' : (s.isPremium ? 'Premium' : 'Standard'))),
              DataCell(Row(
                children: [
                  _actionIcon(LucideIcons.eye, () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => StructureDetailsPage(structure: s, userRole: widget.userRole))
                    );
                  }, color: AppColors.primary),
                  const SizedBox(width: 8),
                  if (!(widget.userRole == 'ADMIN' && s.isBlocked)) ...[
                    _actionIcon(LucideIcons.edit2, () async {
                      final result = await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => EditStructurePage(structure: s))
                      );
                      if (result == true) _fetchData();
                    }, color: AppColors.warning),
                    const SizedBox(width: 8),
                  ],
                  if (widget.userRole == 'SUPER_ADMIN') ...[
                    _actionIcon(s.isBlocked ? LucideIcons.unlock : LucideIcons.ban, () {
                      showCustomConfirmDialog(
                        context,
                        title: s.isBlocked ? 'Débloquer la structure' : 'Bloquer la structure',
                        message: 'Voulez-vous vraiment ${s.isBlocked ? 'débloquer' : 'bloquer'} ${s.name} ?',
                        confirmLabel: s.isBlocked ? 'Débloquer' : 'Bloquer',
                        confirmColor: AppColors.warning,
                        icon: s.isBlocked ? LucideIcons.unlock : LucideIcons.ban,
                        onConfirm: () => _handleBlock(s),
                      );
                    }, color: s.isBlocked ? AppColors.success : AppColors.error),
                    const SizedBox(width: 8),
                  ],
                  if (!(widget.userRole == 'ADMIN' && s.isBlocked))
                    _actionIcon(LucideIcons.trash2, () {
                      showCustomConfirmDialog(
                        context,
                        title: 'Supprimer la structure',
                        message: 'Voulez-vous vraiment supprimer ${s.name} ? Cette action est irréversible.',
                        confirmLabel: 'Supprimer',
                        confirmColor: AppColors.error,
                        icon: LucideIcons.trash2,
                        onConfirm: () => _handleDelete(s),
                      );
                    }, color: AppColors.error),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Actif': color = AppColors.success; break;
      case 'En attente': color = AppColors.warning; break;
      case 'Bloqué': color = AppColors.error; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
