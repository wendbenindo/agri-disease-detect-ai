import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _supabase = Supabase.instance.client;
  static const String productBucketName = 'product-images';
  static const String chatBucketName = 'chat-images';

  /// Uploader une image et retourner l'URL publique
  Future<String> uploadProductImage(File imageFile) async {
    try {
      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'product_$timestamp$extension';

      print('📤 Upload de l\'image: $fileName');

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
      final imageFile = File(imagePath);
      
      // Note: Pas de vérification auth.currentUser car on utilise un système d'auth custom
      // L'authentification est gérée par la table 'users' et non par 'auth.users'
      
      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imagePath);
      final fileName = 'chat_${conversationId}_$timestamp$extension';

      print('📤 Upload de l\'image chat: $fileName');
      print('📁 Bucket: $chatBucketName');
      print('📄 Fichier: ${imageFile.path}');
      print('📏 Taille: ${await imageFile.length()} bytes');

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
