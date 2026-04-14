import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosmart/shared/widgets/premium_sidebar.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/custom_header.dart';
import 'package:geosmart/core/services/api_service.dart';
import 'package:geosmart/core/models/user_model.dart';

class UserManagementPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final bool isMobile;
  final Function(int)? onMenuTap;

  const UserManagementPage({
    Key? key, 
    this.userRole = 'SUPER_ADMIN', 
    this.userName = 'Super Admin',
    this.isMobile = false,
    this.onMenuTap,
  }) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _apiService = ApiService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _apiService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) => 
      u.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      u.email.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _handleBlock(UserModel u) async {
    try {
      final updated = await _apiService.blockUser(u.id, !u.isBlocked);
      setState(() {
        final index = _users.indexWhere((item) => item.id == u.id);
        if (index != -1) _users[index] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${u.name} a été ${updated.isBlocked ? 'bloqué' : 'débloqué'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _handleDelete(UserModel u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: 'Supprimer l\'utilisateur',
        message: 'Êtes-vous sûr de vouloir supprimer ${u.name} ? Cette action est irréversible.',
        confirmText: 'Supprimer',
        isDanger: true,
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteUser(u.id);
        setState(() {
          _users.removeWhere((item) => item.id == u.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${u.name} a été supprimé')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showEditUserDialog(UserModel u) {
    final emailController = TextEditingController(text: u.email);
    final nameController = TextEditingController(text: u.name);
    final phoneController = TextEditingController(text: (u.toJson()['phone'] as String?) ?? '');
    String selectedRole = u.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier l\'utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Utilisateur')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                  decoration: const InputDecoration(labelText: 'Rôle'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updated = await _apiService.updateUser(u.id, {
                    'email': emailController.text,
                    'name': nameController.text,
                    'role': selectedRole,
                    'phone': phoneController.text,
                  });
                  setState(() {
                    final index = _users.indexWhere((item) => item.id == u.id);
                    if (index != -1) _users[index] = updated;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisateur mis à jour avec succès')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Utilisateur')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                  decoration: const InputDecoration(labelText: 'Rôle'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.createUser(
                    emailController.text,
                    passwordController.text,
                    nameController.text,
                    selectedRole,
                    phone: phoneController.text,
                  );
                  Navigator.pop(context);
                  _fetchUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisateur créé avec succès')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
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
                title: 'Utilisateurs',
                isDarkMode: isDarkMode,
                userRole: widget.userRole,
                onNotificationTap: () {},
                onMenuTap: widget.onMenuTap ?? (index) {},
              ),
            const SizedBox(height: 24),
            _buildHeader(isDarkMode),
            const SizedBox(height: 24),
            _buildSearch(isDarkMode),
            const SizedBox(height: 24),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : (widget.isMobile ? _buildMobileList(isDarkMode) : _buildTable(isDarkMode)),
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
            currentRoute: '/super-admin-users',
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
              'Gestion des Utilisateurs',
              style: GoogleFonts.outfit(
                fontSize: widget.isMobile ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            Text(
              'Gérez les comptes et les permissions.',
              style: GoogleFonts.inter(
                fontSize: widget.isMobile ? 12 : 14,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        if (widget.userRole == 'SUPER_ADMIN')
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _showAddUserDialog,
              icon: const Icon(LucideIcons.userPlus, color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildSearch(bool isDarkMode) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      opacity: 0.05,
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Rechercher un utilisateur...',
          hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(LucideIcons.search, size: 20, color: isDarkMode ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMobileList(bool isDarkMode) {
    final users = _filteredUsers;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        final bool isRestricted = (widget.userRole == 'ADMIN' && u.modifiedBySuperAdmin);

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
                      u.name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    _roleBadge(u.role),
                  ],
                ),
                Text(u.email, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionIcon(u.isBlocked ? LucideIcons.unlock : LucideIcons.ban, isRestricted ? null : () => _handleBlock(u), 
                      color: isRestricted ? Colors.grey : (u.isBlocked ? AppColors.success : AppColors.error)),
                    const SizedBox(width: 8),
                    _actionIcon(LucideIcons.edit2, isRestricted ? null : () => _showEditUserDialog(u), color: isRestricted ? Colors.grey : AppColors.warning),
                    const SizedBox(width: 8),
                    _actionIcon(LucideIcons.trash2, isRestricted ? null : () => _handleDelete(u), color: isRestricted ? Colors.grey : AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(bool isDarkMode) {
    final users = _filteredUsers;
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      opacity: 0.04,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DataTable(
          columns: [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Rôle')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: users.map((u) {
            final bool isRestricted = (widget.userRole == 'ADMIN' && u.modifiedBySuperAdmin);
            return DataRow(cells: [
              DataCell(Text(u.name)),
              DataCell(Text(u.email)),
              DataCell(_roleBadge(u.role)),
              DataCell(Text(u.isBlocked ? 'Bloqué' : 'Actif', style: TextStyle(color: u.isBlocked ? Colors.red : Colors.green))),
              DataCell(Row(
                children: [
                  _actionIcon(u.isBlocked ? LucideIcons.unlock : LucideIcons.ban, isRestricted ? null : () => _handleBlock(u), 
                    color: isRestricted ? Colors.grey : (u.isBlocked ? AppColors.success : AppColors.error)),
                  const SizedBox(width: 8),
                  _actionIcon(LucideIcons.edit2, isRestricted ? null : () => _showEditUserDialog(u), color: isRestricted ? Colors.grey : AppColors.warning),
                  const SizedBox(width: 8),
                  _actionIcon(LucideIcons.trash2, isRestricted ? null : () => _handleDelete(u), color: isRestricted ? Colors.grey : AppColors.error),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: role == 'super_admin' ? Colors.purple.withOpacity(0.1) : (role == 'admin' ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'super_admin' ? Colors.purple : (role == 'admin' ? Colors.blue : Colors.grey))),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback? onTap, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color ?? AppColors.primary),
        ),
      ),
    );
  }
}
