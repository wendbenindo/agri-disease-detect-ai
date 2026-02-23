class PendingVerification {
  final String userId;
  final String userName;
  final String phoneNumber;
  final String code;
  final String verificationMethod;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool isSent;

  PendingVerification({
    required this.userId,
    required this.userName,
    required this.phoneNumber,
    required this.code,
    required this.verificationMethod,
    required this.expiresAt,
    required this.createdAt,
    required this.isSent,
  });

  factory PendingVerification.fromJson(Map<String, dynamic> json) {
    return PendingVerification(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      phoneNumber: json['phone_number'] as String,
      code: json['code'] as String,
      verificationMethod: json['verification_method'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isSent: json['is_sent'] as bool? ?? false,
    );
  }

  // Calculer les heures restantes avant expiration
  int get hoursRemaining {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    return difference.inHours;
  }

  // Vérifier si le code est expiré
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  // Obtenir le texte du canal (pour affichage)
  String get methodDisplayText {
    return verificationMethod == 'whatsapp' ? 'WhatsApp' : 'SMS';
  }

  // Obtenir l'icône du canal
  String get methodIcon {
    return verificationMethod == 'whatsapp' ? '💬' : '📱';
  }
}
