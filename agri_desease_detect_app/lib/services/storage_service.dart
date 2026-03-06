import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'auth_service.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  static const String productBucketName = 'product-images';
  static const String chatBucketName = 'chat-images';
  
  // Limite de taille: 5 MB
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Uploader une image et retourner l'URL publique
  Future<String> uploadProductImage(File imageFile) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour uploader une image');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est vendeur ou admin
      if (!_authService.isVendor && !_authService.isAdmin) {
        throw Exception('Seuls les vendeurs peuvent uploader des images de produits');
      }

      // ✅ SÉCURITÉ: Vérifier la taille du fichier
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        throw Exception('L\'image est trop volumineuse (max 5 MB)');
      }

      // ✅ SÉCURITÉ: Vérifier le type de fichier
      final extension = path.extension(imageFile.path).toLowerCase();
      if (!['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
        throw Exception('Format d\'image non supporté. Utilisez JPG, PNG ou WEBP');
      }

      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_$timestamp$extension';

      print('📤 Upload de l\'image: $fileName');
      print('📏 Taille: $fileSize bytes');

      // Uploader l'image dans le bucket
      final uploadPath = await _supabase.storage
          .from(productBucketName)
          .upload(fileName, imageFile);

      print('✅ Image uploadée: $uploadPath');

      // Obtenir l'URL publique
      final publicUrl = _supabase.storage
          .from(productBucketName)
          .getPublicUrl(fileName);

      print('🔗 URL publique: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ Erreur upload image: $e');
      rethrow;
    }
  }

  /// Supprimer une image du bucket
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour supprimer une image');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est vendeur ou admin
      if (!_authService.isVendor && !_authService.isAdmin) {
        throw Exception('Seuls les vendeurs peuvent supprimer des images de produits');
      }

      // Note: La vérification que l'utilisateur est propriétaire du produit
      // devrait être faite au niveau du ProductRepository avant d'appeler cette méthode

      // Extraire le nom du fichier de l'URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      print('🗑️ Suppression de l\'image: $fileName');

      await _supabase.storage
          .from(productBucketName)
          .remove([fileName]);

      print('✅ Image supprimée');
    } catch (e) {
      print('❌ Erreur suppression image: $e');
      rethrow;
    }
  }
  
  /// Uploader une image de chat et retourner l'URL publique
  Future<String> uploadChatImage(String imagePath, String conversationId) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour envoyer une image');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est participant de la conversation
      final conversation = await _supabase
          .from('conversations')
          .select('buyer_id, vendor_id')
          .eq('id', conversationId)
          .single();

      if (conversation['buyer_id'] != currentUserId && 
          conversation['vendor_id'] != currentUserId) {
        throw Exception('Vous n\'êtes pas participant de cette conversation');
      }

      final imageFile = File(imagePath);
      
      // ✅ SÉCURITÉ: Vérifier la taille du fichier
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        throw Exception('L\'image est trop volumineuse (max 5 MB)');
      }

      // ✅ SÉCURITÉ: Vérifier le type de fichier
      final extension = path.extension(imagePath).toLowerCase();
      if (!['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
        throw Exception('Format d\'image non supporté. Utilisez JPG, PNG ou WEBP');
      }
      
      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_${conversationId}_$timestamp$extension';

      print('📤 Upload de l\'image chat: $fileName');
      print('📁 Bucket: $chatBucketName');
      print('📄 Fichier: ${imageFile.path}');
      print('📏 Taille: $fileSize bytes');

      // Uploader l'image dans le bucket chat-images
      final uploadPath = await _supabase.storage
          .from(chatBucketName)
          .upload(fileName, imageFile);

      print('✅ Image chat uploadée: $uploadPath');

      // Obtenir l'URL publique
      final publicUrl = _supabase.storage
          .from(chatBucketName)
          .getPublicUrl(fileName);

      print('🔗 URL publique chat: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      print('❌ Erreur upload image chat: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Supprimer une image de chat du bucket
  Future<void> deleteChatImage(String imageUrl) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour supprimer une image');
      }

      // Note: La vérification que l'utilisateur est participant de la conversation
      // devrait être faite au niveau du ChatService avant d'appeler cette méthode

      // Extraire le nom du fichier de l'URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      print('🗑️ Suppression de l\'image chat: $fileName');

      await _supabase.storage
          .from(chatBucketName)
          .remove([fileName]);

      print('✅ Image chat supprimée');
    } catch (e) {
      print('❌ Erreur suppression image chat: $e');
      rethrow;
    }
  }
}
