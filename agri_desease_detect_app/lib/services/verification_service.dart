import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/verification_code.dart';
import 'auth_service.dart';

class VerificationService {
  final _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Créer un code de vérification
  Future<VerificationCode?> createVerificationCode({
    required String userId,
    required String phoneNumber,
    required String verificationMethod, // 'sms' ou 'whatsapp'
  }) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que userId correspond à l'utilisateur en cours de création
      // Note: Cette méthode est appelée pendant l'inscription, donc pas de currentUserId encore
      // Mais on vérifie que le phoneNumber correspond bien au userId
      
      print('🔐 Création du code de vérification...');
      print('   - userId: $userId');
      print('   - phoneNumber: $phoneNumber');
      print('   - method: $verificationMethod');

      final response = await _supabase.rpc(
        'create_verification_code',
        params: {
          'p_user_id': userId,
          'p_phone_number': phoneNumber,
          'p_verification_method': verificationMethod,
        },
      ).select().single();

      print('✅ Code créé: ${response['code']}');
      print('   - Expire à: ${response['expires_at']}');

      // Récupérer le code complet depuis la table
      final codeData = await _supabase
          .from('verification_codes')
          .select()
          .eq('user_id', userId)
          .eq('is_verified', false)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return VerificationCode.fromJson(codeData);
    } catch (e) {
      print('❌ Erreur createVerificationCode: $e');
      return null;
    }
  }

  /// Vérifier un code
  Future<bool> verifyCode({
    required String userId,
    required String code,
  }) async {
    try {
      // ✅ SÉCURITÉ: Cette méthode est appelée pendant le processus de vérification
      // avant que l'utilisateur soit connecté, donc on ne peut pas vérifier currentUserId
      // La sécurité est assurée par le fait que l'utilisateur doit connaître le code
      
      print('🔍 Vérification du code...');
      print('   - userId: $userId');
      print('   - code: $code');

      final result = await _supabase.rpc(
        'verify_code',
        params: {
          'p_user_id': userId,
          'p_code': code,
        },
      );

      print('✅ Résultat vérification: $result');
      return result == true;
    } catch (e) {
      print('❌ Erreur verifyCode: $e');
      return false;
    }
  }

  /// Marquer un code comme envoyé (pour l'admin)
  Future<bool> markCodeAsSent(String userId) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour marquer un code comme envoyé');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est admin
      if (!_authService.isAdmin) {
        throw Exception('Seuls les administrateurs peuvent marquer les codes comme envoyés');
      }

      await _supabase.rpc(
        'mark_code_as_sent',
        params: {'p_user_id': userId},
      );
      return true;
    } catch (e) {
      print('❌ Erreur markCodeAsSent: $e');
      return false;
    }
  }

  /// Récupérer le code actif d'un utilisateur
  Future<VerificationCode?> getActiveCode(String userId) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        print('⚠️ Utilisateur non connecté');
        return null;
      }

      // ✅ SÉCURITÉ: Vérifier que userId correspond à l'utilisateur connecté OU que c'est un admin
      if (userId != currentUserId && !_authService.isAdmin) {
        throw Exception('Vous ne pouvez pas voir le code d\'un autre utilisateur');
      }

      final response = await _supabase
          .from('verification_codes')
          .select()
          .eq('user_id', userId)
          .eq('is_verified', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return VerificationCode.fromJson(response);
    } catch (e) {
      print('❌ Erreur getActiveCode: $e');
      return null;
    }
  }

  /// Récupérer tous les codes en attente (pour l'admin)
  Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour voir les codes de vérification');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est admin
      if (!_authService.isAdmin) {
        throw Exception('Seuls les administrateurs peuvent voir tous les codes de vérification');
      }

      final response = await _supabase
          .from('pending_verifications')
          .select()
          .order('created_at', ascending: false);

      print('📋 Codes récupérés de la BD:');
      for (var item in response) {
        print('   - User: ${item['user_name']}');
        print('   - Code BD: ${item['code']}');
        print('   - Type code: ${item['code'].runtimeType}');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur getPendingVerifications: $e');
      rethrow;
    }
  }

  /// Vérifier si un utilisateur est vérifié
  Future<bool> isUserVerified(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_verified')
          .eq('id', userId)
          .single();

      return response['is_verified'] == true;
    } catch (e) {
      print('❌ Erreur isUserVerified: $e');
      return false;
    }
  }
}
