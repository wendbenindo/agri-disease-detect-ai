class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String? shortDescription;
  final String? photoUrl;
  final String? categoryId;
  final String? vendorId;
  final String? dosage;
  final String? instructions;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.shortDescription,
    this.photoUrl,
    this.categoryId,
    this.vendorId,
    this.dosage,
    this.instructions,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      shortDescription: json['short_description'] as String?,
      photoUrl: json['photo_url'] as String?,
      categoryId: json['category_id'] as String?,
      vendorId: json['vendor_id'] as String?,
      dosage: json['dosage'] as String?,
      instructions: json['instructions'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'short_description': shortDescription,
      'photo_url': photoUrl,
      'category_id': categoryId,
      'vendor_id': vendorId,
      'dosage': dosage,
      'instructions': instructions,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? shortDescription,
    String? photoUrl,
    String? categoryId,
    String? vendorId,
    String? dosage,
    String? instructions,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      photoUrl: photoUrl ?? this.photoUrl,
      categoryId: categoryId ?? this.categoryId,
      vendorId: vendorId ?? this.vendorId,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
