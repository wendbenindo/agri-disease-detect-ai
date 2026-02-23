import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;
  static const String _userIdKey = 'current_user_id';
  static const String _userPhoneKey = 'current_user_phone';
  static const String _userNameKey = 'current_user_name';

  String? _cachedUserId;
  String? _cachedUserPhone;
  String? _cachedUserName;

  // Vérifier si l'utilisateur est authentifié
  bool get isAuthenticated => _cachedUserId != null;

  // Obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => _cachedUserId;

  // Obtenir le numéro de téléphone de l'utilisateur actuel
  String? get currentUserPhone => _cachedUserPhone;

  // Obtenir le nom de l'utilisateur actuel
  String? get currentUserName => _cachedUserName;

  // Initialiser le service (charger depuis le cache)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString(_userIdKey);
    _cachedUserPhone = prefs.getString(_userPhoneKey);
    _cachedUserName = prefs.getString(_userNameKey);
    
    print('🔧 AuthService initialized:');
    print('   - userId: $_cachedUserId');
    print('   - phone: $_cachedUserPhone');
    print('   - name: $_cachedUserName');
  }

  // Créer un nouveau compte
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

      // Sauvegarder dans le cache local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userPhoneKey, phoneNumber);
      await prefs.setString(_userNameKey, name);

      _cachedUserId = userId;
      _cachedUserPhone = phoneNumber;
      _cachedUserName = name;

      print('✅ Compte créé et sauvegardé:');
      print('   - userId: $userId');
      print('   - phone: $phoneNumber');
      print('   - name: $name');

      return {
        'id': userId,
        'phone_number': phoneNumber,
        'name': name,
      };
    } catch (e) {
      print('❌ Erreur signUp: $e');
      if (e.toString().contains('duplicate key')) {
        throw Exception('Ce numéro est déjà utilisé');
      }
      throw Exception('Erreur lors de la création du compte: $e');
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

      // Sauvegarder dans le cache local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userPhoneKey, userPhone);
      await prefs.setString(_userNameKey, userName);

      _cachedUserId = userId;
      _cachedUserPhone = userPhone;
      _cachedUserName = userName;

      print('✅ Connexion réussie et sauvegardée:');
      print('   - userId: $userId');
      print('   - phone: $userPhone');
      print('   - name: $userName');

      return {
        'id': userId,
        'phone_number': userPhone,
        'name': userName,
      };
    } catch (e) {
      print('❌ Erreur signIn: $e');
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userNameKey);

    _cachedUserId = null;
    _cachedUserPhone = null;
    _cachedUserName = null;
    
    print('👋 Déconnexion effectuée');
  }
}
