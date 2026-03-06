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
    final codeFromJson = json['code'];
    print('🔍 Parsing PendingVerification:');
    print('   - Code reçu: $codeFromJson');
    print('   - Type: ${codeFromJson.runtimeType}');
    
    return PendingVerification(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Utilisateur',
      phoneNumber: json['phone_number']?.toString() ?? '',
      code: codeFromJson?.toString() ?? '',
      verificationMethod: json['verification_method']?.toString() ?? 'sms',
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
