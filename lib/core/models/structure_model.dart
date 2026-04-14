class StructureModel {
  final String id;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String description;
  final String address;
  final String? telephone;
  final String? ownerId;
  final bool isPremium;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> services;
  final String? mainPhoto;
  final bool isBlocked;
  final String? blockedBy;
  final bool modifiedBySuperAdmin;

  StructureModel({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.description,
    required this.address,
    this.telephone,
    this.ownerId,
    this.mainPhoto,
    required this.isPremium,
    this.products = const [],
    this.services = const [],
    this.isBlocked = false,
    this.blockedBy,
    this.modifiedBySuperAdmin = false,
  });

  factory StructureModel.fromJson(Map<String, dynamic> json) {
    try {
      return StructureModel(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'Autre',
        lat: (json['location']?['lat'] ?? 0.0).toDouble(),
        lng: (json['location']?['lng'] ?? 0.0).toDouble(),
        description: json['description']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        telephone: json['telephone']?.toString(),
        ownerId: json['ownerId'] is Map ? json['ownerId']['_id']?.toString() : json['ownerId']?.toString(),
        mainPhoto: json['mainPhoto']?.toString(),
        isPremium: json['isPremium'] ?? false,
        products: List<Map<String, dynamic>>.from(json['products'] ?? []),
        services: List<Map<String, dynamic>>.from(json['services'] ?? []),
        isBlocked: json['isBlocked'] ?? false,
        blockedBy: json['blockedBy']?.toString(),
        modifiedBySuperAdmin: json['modifiedBySuperAdmin'] ?? false,
      );
    } catch (e) {
      print('Error parsing StructureModel: $e');
      print('Raw JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final data = {
      'name': name,
      'type': type,
      'location': {'lat': lat, 'lng': lng},
      'description': description,
      'address': address,
      'telephone': telephone,
      'mainPhoto': mainPhoto,
      'isPremium': isPremium,
      'products': products,
      'services': services,
      'isBlocked': isBlocked,
      'modifiedBySuperAdmin': modifiedBySuperAdmin,
    };
    if (id.isNotEmpty) {
      data['_id'] = id;
    }
    if (ownerId != null) {
      data['ownerId'] = ownerId!;
    }
    return data;
  }
}
