import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:agri_desease_detect_app/services/onesignal_service.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;
  static const String _userIdKey = 'current_user_id';
  static const String _userPhoneKey = 'current_user_phone';
  static const String _userNameKey = 'current_user_name';
  static const String _userRoleKey = 'current_user_role';

  String? _cachedUserId;
  String? _cachedUserPhone;
  String? _cachedUserName;
  String? _cachedUserRole;
  
  // Notifier pour informer les widgets des changements d'état
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  // Vérifier si l'utilisateur est authentifié
  bool get isAuthenticated => _cachedUserId != null;

  // Obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => _cachedUserId;

  // Obtenir le numéro de téléphone de l'utilisateur actuel
  String? get currentUserPhone => _cachedUserPhone;

  // Obtenir le nom de l'utilisateur actuel
  String? get currentUserName => _cachedUserName;

  // Obtenir le rôle de l'utilisateur actuel
  String? get currentUserRole => _cachedUserRole;

  // Vérifier si l'utilisateur est vendeur
  bool get isVendor => _cachedUserRole == 'vendor' || _cachedUserRole == 'admin';

  // Vérifier si l'utilisateur est admin
  bool get isAdmin => _cachedUserRole == 'admin';

  // Initialiser le service (charger depuis le cache)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString(_userIdKey);
    _cachedUserPhone = prefs.getString(_userPhoneKey);
    _cachedUserName = prefs.getString(_userNameKey);
    _cachedUserRole = prefs.getString(_userRoleKey);
    
    // Mettre à jour le notifier
    authStateNotifier.value = _cachedUserId != null;
    
    print('🔧 AuthService initialized:');
    print('   - userId: $_cachedUserId');
    print('   - phone: $_cachedUserPhone');
    print('   - name: $_cachedUserName');
    print('   - role: $_cachedUserRole');
    print('   - authState: ${authStateNotifier.value}');
  }

  // Créer un nouveau compte (sans connexion automatique)
  Future<Map<String, dynamic>> signUp({
    required String phoneNumber,
    required String name,
    required String password,
  }) async {
    try {
      print('📝 Création de compte...');
      // Appeler la fonction Supabase pour créer l'utilisateur
      final result = await _supabase.rpc('create_user_with_password', params: {
        'p_phone_number': phoneNumber,
        'p_name': name,
        'p_password': password,
      });

      final userId = result.toString();

      // Récupérer les infos complètes de l'utilisateur
      final user = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final userRole = user['role'] as String? ?? 'buyer';

      print('✅ Compte créé (non connecté):');
      print('   - userId: $userId');
      print('   - phone: $phoneNumber');
      print('   - name: $name');
      print('   - role: $userRole');
      print('   - is_verified: false (en attente de vérification)');

      // NE PAS sauvegarder dans le cache - l'utilisateur doit d'abord vérifier son numéro
      return {
        'id': userId,
        'phone_number': phoneNumber,
        'name': name,
        'role': userRole,
      };
    } catch (e) {
      print('❌ Erreur signUp: $e');
      if (e.toString().contains('duplicate key')) {
        throw Exception('Ce numéro est déjà utilisé');
      }
      throw Exception('Erreur lors de la création du compte: $e');
    }
  }

  // Connecter l'utilisateur après vérification réussie
  Future<void> loginAfterVerification({
    required String userId,
    required String phoneNumber,
    required String name,
    required String role,
  }) async {
    try {
      print('✅ Connexion après vérification...');
      
      // Sauvegarder dans le cache local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userPhoneKey, phoneNumber);
      await prefs.setString(_userNameKey, name);
      await prefs.setString(_userRoleKey, role);

      _cachedUserId = userId;
      _cachedUserPhone = phoneNumber;
      _cachedUserName = name;
      _cachedUserRole = role;
      
      // Notifier les listeners du changement d'état
      authStateNotifier.value = true;
      
      // Configurer OneSignal pour cet utilisateur
      await OneSignalService.setUser(userId);

      print('✅ Utilisateur connecté:');
      print('   - userId: $userId');
      print('   - phone: $phoneNumber');
      print('   - name: $name');
      print('   - role: $role');
      print('   - authState notifié: true');
    } catch (e) {
      print('❌ Erreur loginAfterVerification: $e');
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Se connecter avec numéro et mot de passe
  Future<Map<String, dynamic>> signIn({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      print('🔐 Tentative de connexion: $phoneNumber');
      
      // Appeler la fonction Supabase pour vérifier le mot de passe
      final result = await _supabase.rpc('verify_user_password', params: {
        'p_phone_number': phoneNumber,
        'p_password': password,
      });

      print('📦 Résultat RPC: $result');

      if (result == null || (result is List && result.isEmpty)) {
        throw Exception('Numéro ou mot de passe incorrect');
      }

      final userData = result is List ? result.first : result;
      final userId = userData['user_id'].toString();
      final userName = userData['user_name'] as String;
      final userPhone = userData['user_phone'] as String;

      // ⚠️ VÉRIFIER QUE L'UTILISATEUR EST VÉRIFIÉ
      final userInfo = await _supabase
          .from('users')
          .select('role, is_verified')
          .eq('id', userId)
          .single();
      
      final isVerified = userInfo['is_verified'] as bool? ?? false;
      
      if (!isVerified) {
        print('❌ Utilisateur non vérifié');
        throw Exception('Votre compte n\'est pas encore vérifié. Veuillez vérifier votre numéro de téléphone.');
      }
      
      final userRole = userInfo['role'] as String? ?? 'buyer';

      // Sauvegarder dans le cache local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userPhoneKey, userPhone);
      await prefs.setString(_userNameKey, userName);
      await prefs.setString(_userRoleKey, userRole);

      _cachedUserId = userId;
      _cachedUserPhone = userPhone;
      _cachedUserName = userName;
      _cachedUserRole = userRole;
      
      // Notifier les listeners du changement d'état
      authStateNotifier.value = true;
      
      // Configurer OneSignal pour cet utilisateur
      await OneSignalService.setUser(userId);

      print('✅ Connexion réussie et sauvegardée:');
      print('   - userId: $userId');
      print('   - phone: $userPhone');
      print('   - name: $userName');
      print('   - role: $userRole');
      print('   - is_verified: $isVerified');
      print('   - authState notifié: true');

      return {
        'id': userId,
        'phone_number': userPhone,
        'name': userName,
        'role': userRole,
      };
    } catch (e) {
      print('❌ Erreur signIn: $e');
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    // Déconnecter de OneSignal
    await OneSignalService.logout();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);

    _cachedUserId = null;
    _cachedUserPhone = null;
    _cachedUserName = null;
    _cachedUserRole = null;
    
    // Notifier les listeners du changement d'état
    authStateNotifier.value = false;
    
    print('👋 Déconnexion effectuée');
    print('   - authState notifié: false');
  }

  // Récupérer les infos d'un utilisateur par numéro de téléphone
  Future<Map<String, dynamic>?> getUserByPhone(String phoneNumber) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, phone_number, name, role, is_verified')
          .eq('phone_number', phoneNumber)
          .single();

      return {
        'id': response['id'],
        'phone_number': response['phone_number'],
        'name': response['name'],
        'role': response['role'],
        'is_verified': response['is_verified'],
      };
    } catch (e) {
      print('❌ Erreur getUserByPhone: $e');
      return null;
    }
  }
}
