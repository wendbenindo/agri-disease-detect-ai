import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/vendor_request.dart';
import '../model/user_role.dart';
import 'auth_service.dart';

class VendorService {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  // ============================================================================
  // GESTION DES RÔLES
  // ============================================================================

  /// Récupérer le rôle de l'utilisateur connecté
  Future<UserRole?> getCurrentUserRole() async {
    try {
      final userId = _authService.currentUserId;
      print('🔍 getCurrentUserRole - userId: $userId');
      
      if (userId == null) {
        print('❌ userId est null');
        return null;
      }

      final response = await _supabase
          .from('users')
          .select('id, role, created_at, updated_at')
          .eq('id', userId)
          .single();

      print('✅ Réponse Supabase: $response');

      // Adapter au format UserRole
      final userRole = UserRole(
        id: response['id'] as String,
        userId: response['id'] as String,
        role: response['role'] as String,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
      
      print('✅ UserRole créé: role=${userRole.role}, isBuyer=${userRole.isBuyer}');
      
      return userRole;
    } catch (e) {
      print('❌ Erreur getCurrentUserRole: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur est admin
  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role?.isAdmin ?? false;
  }

  /// Vérifier si l'utilisateur est vendeur
  Future<bool> isVendor() async {
    final role = await getCurrentUserRole();
    return role?.isVendor ?? false;
  }

  // ============================================================================
  // DEMANDES DE VENDEUR
  // ============================================================================

  /// Créer une demande pour devenir vendeur
  Future<VendorRequest> createVendorRequest({
    required String businessName,
    required String phone,
    required String city,
    required String region,
    String? description,
  }) async {
    try {
      final userId = _authService.currentUserId;
      print('🔍 createVendorRequest - userId: $userId');
      
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from('vendor_requests')
          .insert({
            'user_id': userId,
            'business_name': businessName,
            'phone': phone,
            'city': city,
            'region': region,
            'description': description,
          })
          .select()
          .single();

      print('✅ Demande créée: ${response['id']}');
      return VendorRequest.fromJson(response);
    } catch (e) {
      print('❌ Erreur createVendorRequest: $e');
      rethrow;
    }
  }

  /// Récupérer la demande de l'utilisateur connecté
  Future<VendorRequest?> getMyVendorRequest() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return null;

      final response = await _supabase
          .from('vendor_requests')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return VendorRequest.fromJson(response);
    } catch (e) {
      print('❌ Erreur getMyVendorRequest: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur a déjà une demande
  Future<bool> hasVendorRequest() async {
    final request = await getMyVendorRequest();
    return request != null;
  }

  // ============================================================================
  // FONCTIONS ADMIN
  // ============================================================================

  /// Récupérer toutes les demandes (ADMIN uniquement)
  Future<List<VendorRequest>> getAllVendorRequests({String? status}) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour voir les demandes');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est admin
      if (!_authService.isAdmin) {
        throw Exception('Seuls les administrateurs peuvent voir toutes les demandes');
      }

      var query = _supabase.from('vendor_requests').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => VendorRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Erreur getAllVendorRequests: $e');
      rethrow;
    }
  }

  /// Approuver une demande (ADMIN uniquement)
  Future<void> approveVendorRequest(String requestId) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final adminId = _authService.currentUserId;
      if (adminId == null) {
        throw Exception('Vous devez être connecté pour approuver une demande');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est admin
      if (!_authService.isAdmin) {
        throw Exception('Seuls les administrateurs peuvent approuver des demandes');
      }

      await _supabase.rpc('approve_vendor_request', params: {
        'request_id': requestId,
        'admin_id': adminId,
      });
      
      print('✅ Demande approuvée: $requestId');
    } catch (e) {
      print('❌ Erreur approveVendorRequest: $e');
      rethrow;
    }
  }

  /// Rejeter une demande (ADMIN uniquement)
  Future<void> rejectVendorRequest(String requestId) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final adminId = _authService.currentUserId;
      if (adminId == null) {
        throw Exception('Vous devez être connecté pour rejeter une demande');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est admin
      if (!_authService.isAdmin) {
        throw Exception('Seuls les administrateurs peuvent rejeter des demandes');
      }

      await _supabase.rpc('reject_vendor_request', params: {
        'request_id': requestId,
        'admin_id': adminId,
      });
      
      print('✅ Demande rejetée: $requestId');
    } catch (e) {
      print('❌ Erreur rejectVendorRequest: $e');
      rethrow;
    }
  }

  /// Compter les demandes en attente (ADMIN uniquement)
  Future<int> getPendingRequestsCount() async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        return 0;
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est admin
      if (!_authService.isAdmin) {
        throw Exception('Seuls les administrateurs peuvent voir le compteur de demandes');
      }

      final response = await _supabase
          .from('vendor_requests')
          .select()
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      print('❌ Erreur getPendingRequestsCount: $e');
      return 0;
    }
  }
}
