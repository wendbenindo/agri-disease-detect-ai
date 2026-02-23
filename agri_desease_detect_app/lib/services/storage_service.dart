import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _supabase = Supabase.instance.client;
  static const String bucketName = 'product-images';

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
          .from(bucketName)
          .upload(fileName, imageFile);

      print('✅ Image uploadée: $uploadPath');

      // Obtenir l'URL publique
      final publicUrl = _supabase.storage
          .from(bucketName)
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
          .from(bucketName)
          .remove([fileName]);

      print('✅ Image supprimée');
    } catch (e) {
      print('❌ Erreur suppression image: $e');
      rethrow;
    }
  }
}
