class Conversation {
  final String id;
  final String productId;
  final String buyerId;
  final String vendorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Détails supplémentaires (de la vue)
  final String? productName;
  final String? productPhotoUrl;
  final String? vendorName;
  final String? buyerName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCountBuyer;
  final int unreadCountVendor;

  Conversation({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.vendorId,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.productPhotoUrl,
    this.vendorName,
    this.buyerName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCountBuyer = 0,
    this.unreadCountVendor = 0,
  });
  
  // Obtenir le nombre de messages non lus pour un utilisateur spécifique
  int getUnreadCount(String userId) {
    if (userId == buyerId) {
      return unreadCountBuyer;
    } else if (userId == vendorId) {
      return unreadCountVendor;
    }
    return 0;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing conversation: ${json['id']}');
    print('   - Keys disponibles: ${json.keys.toList()}');
    
    try {
      return Conversation(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        buyerId: json['buyer_id'] as String,
        vendorId: json['vendor_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        productName: json['product_name'] as String?,
        productPhotoUrl: json['product_photo_url'] as String?,
        vendorName: json['vendor_name'] as String?,
        buyerName: json['buyer_name'] as String?,
        lastMessage: json['last_message'] as String?,
        lastMessageTime: json['last_message_time'] != null 
            ? DateTime.parse(json['last_message_time'] as String)
            : null,
        unreadCountBuyer: json['unread_count_buyer'] as int? ?? 0,
        unreadCountVendor: json['unread_count_vendor'] as int? ?? 0,
      );
    } catch (e, stackTrace) {
      print('❌ Erreur parsing conversation: $e');
      print('Stack: $stackTrace');
      print('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'buyer_id': buyerId,
      'vendor_id': vendorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
