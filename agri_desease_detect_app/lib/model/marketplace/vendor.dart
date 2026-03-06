class Vendor {
  final String id;
  final String name;
  final String phone;
  final String? whatsapp;
  final String city;
  final String region;
  final bool isActive;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.name,
    required this.phone,
    this.whatsapp,
    required this.city,
    required this.region,
    this.isActive = true,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      whatsapp: json['whatsapp'] as String?,
      city: json['city'] as String,
      region: json['region'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'city': city,
      'region': region,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
