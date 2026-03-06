class Category {
  final String id;
  final String name;
  final String? iconUrl;
  final int displayOrder;

  Category({
    required this.id,
    required this.name,
    this.iconUrl,
    this.displayOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'display_order': displayOrder,
    };
  }
}
