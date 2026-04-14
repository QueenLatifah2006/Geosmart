import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/core/utils/snackbar_utils.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';

import 'package:geosmart/shared/widgets/custom_confirm_dialog.dart';

import 'package:geosmart/core/models/structure_model.dart';
import 'package:geosmart/core/services/api_service.dart';

class EditStructurePage extends StatefulWidget {
  final dynamic structure;

  const EditStructurePage({Key? key, required this.structure}) : super(key: key);

  @override
  State<EditStructurePage> createState() => _EditStructurePageState();
}

class _EditStructurePageState extends State<EditStructurePage> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _longitudeController;
  late TextEditingController _latitudeController;
  late TextEditingController _descriptionController;
  late TextEditingController _telephoneController;
  late TextEditingController _ownerIdController;
  late TextEditingController _otherTypeController;
  String? _selectedType;
  String? _mainPhoto;
  bool _isSaving = false;
  late StructureModel _structure;
  final List<Map<String, dynamic>> _services = [];
  final List<Map<String, dynamic>> _products = [];

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return ApiService.fullUrl + path;
  }

  @override
  void initState() {
    super.initState();
    if (widget.structure is StructureModel) {
      _structure = widget.structure;
    } else {
      _structure = StructureModel.fromJson(widget.structure as Map<String, dynamic>);
    }
    _nameController = TextEditingController(text: _structure.name);
    
    final types = ['Education', 'Santé', 'Commerce', 'Transport'];
    if (types.contains(_structure.type)) {
      _selectedType = _structure.type;
      _otherTypeController = TextEditingController();
    } else {
      _selectedType = 'Autre';
      _otherTypeController = TextEditingController(text: _structure.type);
    }

    _longitudeController = TextEditingController(text: _structure.lng.toString());
    _latitudeController = TextEditingController(text: _structure.lat.toString());
    _descriptionController = TextEditingController(text: _structure.description);
    _telephoneController = TextEditingController(text: _structure.telephone ?? '');
    _ownerIdController = TextEditingController(text: _structure.ownerId ?? '');
    _mainPhoto = _structure.mainPhoto;

    // Initialize products and services
    for (var s in _structure.services) {
      _services.add({
        'name': TextEditingController(text: s['name']),
        'price': TextEditingController(text: s['price']?.toString() ?? ''),
        'photo': s['photo'],
      });
    }
    for (var p in _structure.products) {
      _products.add({
        'name': TextEditingController(text: p['name']),
        'price': TextEditingController(text: p['price']?.toString() ?? ''),
        'photo': p['photo'],
      });
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

  double? _parseCoordinate(String input) {
    final dd = double.tryParse(input);
    if (dd != null) return dd;

    final dmsRegex = RegExp(r'''(\d+)°\s*(\d+)'\s*(\d+(?:\.\d+)?)"\s*([NSEW])''', caseSensitive: false);
    final match = dmsRegex.firstMatch(input);
    if (match != null) {
      double degrees = double.parse(match.group(1)!);
      double minutes = double.parse(match.group(2)!);
      double seconds = double.parse(match.group(3)!);
      String direction = match.group(4)!.toUpperCase();
      double decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);
      if (direction == 'S' || direction == 'W') decimal = -decimal;
      return decimal;
    }
    return null;
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
        title: 'Confirmer les modifications',
        message: 'Voulez-vous vraiment enregistrer les modifications pour cette structure ?',
        confirmLabel: 'Enregistrer',
        confirmColor: AppColors.primary,
        icon: LucideIcons.save,
        onConfirm: () async {
          setState(() => _isSaving = true);
          try {
            await _apiService.updateStructure(_structure.id, {
              'name': _nameController.text,
              'type': _selectedType == 'Autre' ? _otherTypeController.text : _selectedType,
              'location': {
                'lng': lng,
                'lat': lat,
              },
              'description': _descriptionController.text,
              'telephone': _telephoneController.text,
              'ownerId': _ownerIdController.text.isNotEmpty ? _ownerIdController.text : null,
              'mainPhoto': _mainPhoto,
              'products': _products.map((p) {
                final priceText = (p['price'] as TextEditingController).text;
                return {
                  'name': (p['name'] as TextEditingController).text,
                  'price': priceText.isNotEmpty ? priceText : '0',
                  'photo': p['photo'],
                };
              }).toList(),
              'services': _services.map((s) {
                final priceText = (s['price'] as TextEditingController).text;
                return {
                  'name': (s['name'] as TextEditingController).text,
                  'price': priceText.isNotEmpty ? priceText : '0',
                  'photo': s['photo'],
                };
              }).toList(),
            });
            if (mounted) {
              SnackBarUtils.showSuccess(context, 'Modifications enregistrées');
              Navigator.pop(context, true);
            }
          } catch (e) {
            if (mounted) {
              SnackBarUtils.showError(context, 'Erreur: $e');
            }
          } finally {
            if (mounted) setState(() => _isSaving = false);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la Structure'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: GlassContainer(
            child: Column(
              children: [
                _buildMainPhotoUpload(isDarkMode),
                const SizedBox(height: 24),
                _buildTextField('Nom de la structure *', LucideIcons.building, _nameController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Longitude *', LucideIcons.mapPin, _longitudeController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Latitude *', LucideIcons.mapPin, _latitudeController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Domaine *',
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
                  _buildTextField('Spécifier le type *', LucideIcons.edit3, _otherTypeController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                ],
                const SizedBox(height: 16),
                _buildTextField('Propriétaire (ID ou Nom)', LucideIcons.user, _ownerIdController),
                const SizedBox(height: 16),
                _buildTextField('Téléphone *', LucideIcons.phone, _telephoneController, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                const SizedBox(height: 16),
                _buildTextField('Description *', LucideIcons.alignLeft, _descriptionController, maxLines: 3, validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Services', _addService),
                ...List.generate(_services.length, (index) => _buildItemField('service', index, _services)),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Produits', _addProduct),
                ...List.generate(_products.length, (index) => _buildItemField('produit', index, _products)),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Enregistrer les modifications', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
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
                setState(() => _isSaving = true);
                final bytes = await image.readAsBytes();
                final url = await _apiService.uploadImage(bytes, image.name);
                setState(() => _mainPhoto = url);
              } catch (e) {
                SnackBarUtils.showError(context, 'Erreur lors de l\'upload: $e');
              } finally {
                setState(() => _isSaving = false);
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
              Expanded(child: _buildTextField('Nom du $type *', LucideIcons.tag, item['name'], validator: (v) => v == null || v.isEmpty ? 'Requis' : null)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Prix (FCFA) *', LucideIcons.dollarSign, item['price'], validator: (v) => v == null || v.isEmpty ? 'Requis' : null)),
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

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {int maxLines = 1, String? Function(String?)? validator}) {
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
}
