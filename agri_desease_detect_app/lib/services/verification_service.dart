import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/verification_code.dart';

class VerificationService {
  final _supabase = Supabase.instance.client;

  /// Créer un code de vérification
  Future<VerificationCode?> createVerificationCode({
    required String userId,
    required String phoneNumber,
    required String verificationMethod, // 'sms' ou 'whatsapp'
  }) async {
    try {
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
      return [];
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
