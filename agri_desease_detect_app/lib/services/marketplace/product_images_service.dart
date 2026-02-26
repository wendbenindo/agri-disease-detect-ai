import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../storage_service.dart';
import '../auth_service.dart';

class ProductImagesService {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageService();
  final AuthService _authService = AuthService();

  /// Uploader plusieurs images additionnelles pour un produit
  Future<List<String>> uploadAdditionalImages(
    String productId,
    List<File> imageFiles,
  ) async {
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('Vous devez être connecté pour ajouter des images');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est propriétaire du produit
    final product = await _supabase
        .from('products')
        .select('vendor_id')
        .eq('id', productId)
        .single();

    if (product['vendor_id'] != currentUserId && !_authService.isAdmin) {
      throw Exception('Vous ne pouvez ajouter des images qu\'à vos propres produits');
    }

    final uploadedUrls = <String>[];

    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final imageUrl = await _storageService.uploadProductImage(imageFiles[i]);
        
        // Insérer dans la table product_images
        await _supabase.from('product_images').insert({
          'product_id': productId,
          'image_url': imageUrl,
          'display_order': i,
        });

        uploadedUrls.add(imageUrl);
        print('✅ Image additionnelle ${i + 1}/${imageFiles.length} uploadée');
      }

      return uploadedUrls;
    } catch (e) {
      print('❌ Erreur upload images additionnelles: $e');
      
      // Nettoyer les images déjà uploadées en cas d'erreur
      for (final url in uploadedUrls) {
        try {
          await _storageService.deleteProductImage(url);
        } catch (deleteError) {
          print('⚠️ Erreur nettoyage image: $deleteError');
        }
      }
      
      rethrow;
    }
  }

  /// Récupérer toutes les images additionnelles d'un produit
  Future<List<String>> getProductImages(String productId) async {
    try {
      final response = await _supabase
          .from('product_images')
          .select('image_url')
          .eq('product_id', productId)
          .order('display_order', ascending: true);

      return (response as List)
          .map((item) => item['image_url'] as String)
          .toList();
    } catch (e) {
      print('❌ Erreur récupération images: $e');
      return [];
    }
  }

  /// Supprimer une image additionnelle
  Future<void> deleteProductImage(String productId, String imageUrl) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour supprimer une image');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est propriétaire du produit
      final product = await _supabase
          .from('products')
          .select('vendor_id')
          .eq('id', productId)
          .single();

      if (product['vendor_id'] != currentUserId && !_authService.isAdmin) {
        throw Exception('Vous ne pouvez supprimer que les images de vos propres produits');
      }

      // Supprimer de la base de données
      await _supabase
          .from('product_images')
          .delete()
          .eq('product_id', productId)
          .eq('image_url', imageUrl);

      // Supprimer du storage
      await _storageService.deleteProductImage(imageUrl);

      print('✅ Image additionnelle supprimée');
    } catch (e) {
      print('❌ Erreur suppression image: $e');
      rethrow;
    }
  }

  /// Supprimer toutes les images additionnelles d'un produit
  Future<void> deleteAllProductImages(String productId) async {
    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Vous devez être connecté pour supprimer des images');
      }

      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est propriétaire du produit
      final product = await _supabase
          .from('products')
          .select('vendor_id')
          .eq('id', productId)
          .single();

      if (product['vendor_id'] != currentUserId && !_authService.isAdmin) {
        throw Exception('Vous ne pouvez supprimer que les images de vos propres produits');
      }

      // Récupérer toutes les URLs
      final images = await getProductImages(productId);

      // Supprimer de la base de données
      await _supabase
          .from('product_images')
          .delete()
          .eq('product_id', productId);

      // Supprimer du storage
      for (final imageUrl in images) {
        try {
          await _storageService.deleteProductImage(imageUrl);
        } catch (e) {
          print('⚠️ Erreur suppression image $imageUrl: $e');
        }
      }

      print('✅ Toutes les images additionnelles supprimées');
    } catch (e) {
      print('❌ Erreur suppression images: $e');
      rethrow;
    }
  }
}
