class VerificationCode {
  final String id;
  final String userId;
  final String code;
  final String verificationMethod; // 'sms' ou 'whatsapp'
  final String phoneNumber;
  final bool isVerified;
  final bool isSent;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  VerificationCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.verificationMethod,
    required this.phoneNumber,
    required this.isVerified,
    required this.isSent,
    required this.expiresAt,
    required this.createdAt,
    this.verifiedAt,
  });

  factory VerificationCode.fromJson(Map<String, dynamic> json) {
    return VerificationCode(
      id: json['id'],
      userId: json['user_id'],
      code: json['code'],
      verificationMethod: json['verification_method'],
      phoneNumber: json['phone_number'],
      isVerified: json['is_verified'] ?? false,
      isSent: json['is_sent'] ?? false,
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'code': code,
      'verification_method': verificationMethod,
      'phone_number': phoneNumber,
      'is_verified': isVerified,
      'is_sent': isSent,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  // Vérifier si le code est expiré
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Temps restant avant expiration
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  // Heures restantes
  int get hoursRemaining => timeRemaining.inHours;
}
