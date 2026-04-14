import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/core/utils/snackbar_utils.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';
import 'package:geosmart/shared/widgets/app_header.dart';
import 'package:geosmart/core/theme/app_colors.dart';

import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

import 'package:geosmart/core/services/api_service.dart';
import 'package:geosmart/core/models/structure_model.dart';

import 'package:geosmart/core/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class AddStructurePage extends StatefulWidget {
  const AddStructurePage({Key? key}) : super(key: key);

  @override
  State<AddStructurePage> createState() => _AddStructurePageState();
}

class _AddStructurePageState extends State<AddStructurePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _ownerIdController = TextEditingController();
  final _otherTypeController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _selectedType;
  String? _mainPhoto;
  final List<Map<String, dynamic>> _services = [];
  final List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
  }

  double? _parseCoordinate(String input) {
    // Try DD
    final dd = double.tryParse(input);
    if (dd != null) return dd;

    // Try DMS: 13° 34' 56" E
    final dmsRegex = RegExp(r'''(\d+)°\s*(\d+)'\s*(\d+(?:\.\d+)?)"\s*([NSEW])''', caseSensitive: false);
    final match = dmsRegex.firstMatch(input);
    if (match != null) {
      double degrees = double.parse(match.group(1)!);
      double minutes = double.parse(match.group(2)!);
      double seconds = double.parse(match.group(3)!);
      String direction = match.group(4)!.toUpperCase();

      double decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);
      if (direction == 'S' || direction == 'W') {
        decimal = -decimal;
      }
      return decimal;
    }

    // Try GeoJSON: [13.58, 7.32]
    if (input.startsWith('[') && input.endsWith(']')) {
      final parts = input.substring(1, input.length - 1).split(',');
      if (parts.length == 2) {
        return double.tryParse(parts[0].trim());
      }
    }
    return null;
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return ApiService.fullUrl + path;
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        SnackBarUtils.showError(context, 'Veuillez sélectionner un type');
        return;
      }

      final lat = _parseCoordinate(_latitudeController.text);
      final lng = _parseCoordinate(_longitudeController.text);

      if (lat == null || lng == null) {
        SnackBarUtils.showError(context, 'Format de coordonnées invalide');
        return;
      }

      showCustomConfirmDialog(
        context,
        title: 'Confirmer l\'ajout',
        message: 'Voulez-vous vraiment ajouter cette nouvelle structure ?',
        confirmLabel: 'Enregistrer',
        confirmColor: AppColors.primary,
        icon: LucideIcons.building,
        onConfirm: () async {
          setState(() => _isLoading = true);
          try {
            final structure = StructureModel(
              id: '',
              name: _nameController.text,
              type: _selectedType == 'Autre' ? _otherTypeController.text : _selectedType!,
              lat: lat,
              lng: lng,
              description: _descriptionController.text,
              address: _addressController.text,
              telephone: _telephoneController.text,
              ownerId: _ownerIdController.text.isNotEmpty ? _ownerIdController.text : null,
              mainPhoto: _mainPhoto,
              isPremium: false,
              products: _products.map((p) => {
                'name': (p['name'] as TextEditingController).text,
                'price': double.tryParse((p['price'] as TextEditingController).text) ?? 0.0,
                'photo': p['photo'],
              }).toList(),
              services: _services.map((s) => {
                'name': (s['name'] as TextEditingController).text,
                'price': double.tryParse((s['price'] as TextEditingController).text) ?? 0.0,
                'photo': s['photo'],
              }).toList(),
            );
            await _apiService.createStructure(structure);
            SnackBarUtils.showSuccess(context, 'Structure enregistrée avec succès');
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to list
          } catch (e) {
            SnackBarUtils.showError(context, 'Erreur: $e');
          } finally {
            setState(() => _isLoading = false);
          }
        },
      );
    }
  }

  void _addService() {
    setState(() {
      _services.add({'name': TextEditingController(), 'price': TextEditingController(), 'photo': null});
    });
  }

  void _addProduct() {
    setState(() {
      _products.add({'name': TextEditingController(), 'price': TextEditingController(), 'photo': null});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppHeader(userName: 'Super Admin'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle Structure',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                child: Column(
                  children: [
                    _buildMainPhotoUpload(isDarkMode),
                    const SizedBox(height: 24),
                    _buildTextField('Nom de la structure *', LucideIcons.building, controller: _nameController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Longitude *', LucideIcons.mapPin, controller: _longitudeController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Latitude *', LucideIcons.mapPin, controller: _latitudeController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type *',
                        prefixIcon: const Icon(LucideIcons.briefcase),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Education', 'Santé', 'Commerce', 'Transport', 'Autre']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v),
                      validator: (v) => v == null ? 'Champ obligatoire' : null,
                    ),
                    if (_selectedType == 'Autre') ...[
                      const SizedBox(height: 16),
                      _buildTextField('Spécifier le type *', LucideIcons.edit3, controller: _otherTypeController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                    ],
                    const SizedBox(height: 16),
                    _buildTextField('Propriétaire (ID ou Nom)', LucideIcons.user, controller: _ownerIdController),
                    const SizedBox(height: 16),
                    _buildTextField('Téléphone *', LucideIcons.phone, controller: _telephoneController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                    const SizedBox(height: 16),
                    _buildTextField('Adresse *', LucideIcons.map, controller: _addressController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                    const SizedBox(height: 16),
                    _buildTextField('Description *', LucideIcons.alignLeft, maxLines: 3, controller: _descriptionController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('Services', _addService),
                    ...List.generate(_services.length, (index) => _buildItemField('service', index, _services)),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader('Produits', _addProduct),
                    ...List.generate(_products.length, (index) => _buildItemField('produit', index, _products)),

                    const SizedBox(height: 32),
                    
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Enregistrer la structure', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainPhotoUpload(bool isDarkMode) {
    final picker = ImagePicker();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo principale de la structure', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              try {
                setState(() => _isLoading = true);
                final bytes = await image.readAsBytes();
                final url = await _apiService.uploadImage(bytes, image.name);
                setState(() => _mainPhoto = url);
              } catch (e) {
                SnackBarUtils.showError(context, 'Erreur lors de l\'upload: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            }
          },
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
            ),
            child: _mainPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(_getImageUrl(_mainPhoto), fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.image, size: 40, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text('Cliquez pour ajouter une photo', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, {int maxLines = 1, TextEditingController? controller, String? Function(String?)? validator}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label.replaceAll(' *', ''),
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
            children: [
              if (label.contains('*'))
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildItemField(String type, int index, List<Map<String, dynamic>> list) {
    final item = list[index];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final picker = ImagePicker();
    
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField('Nom du $type *', LucideIcons.tag, controller: item['name'], validator: (v) => v == null || v.isEmpty ? 'Requis' : null)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Prix (FCFA) *', LucideIcons.dollarSign, controller: item['price'], validator: (v) => v == null || v.isEmpty ? 'Requis' : null)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      try {
                        final bytes = await image.readAsBytes();
                        final url = await _apiService.uploadImage(bytes, image.name);
                        setState(() => item['photo'] = url);
                      } catch (e) {
                        SnackBarUtils.showError(context, 'Erreur lors de l\'upload: $e');
                      }
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item['photo'] != null ? LucideIcons.checkCircle : LucideIcons.image, 
                             color: item['photo'] != null ? AppColors.success : null, size: 18),
                        const SizedBox(width: 8),
                        Text(item['photo'] != null ? 'Photo ajoutée' : 'Ajouter une photo', 
                             style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => setState(() => list.removeAt(index)), 
                icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20)
              ),
            ],
          ),
          if (item['photo'] != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_getImageUrl(item['photo']), height: 80, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}
