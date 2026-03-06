import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/marketplace/product.dart';
import '../../model/marketplace/vendor.dart';
import '../../model/marketplace/category.dart';

class SupabaseProductDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  // Récupérer tous les produits
  Future<List<Product>> fetchAllProducts() async {
    try {
      print('🔍 SupabaseDataSource: Début de la requête products...');
      
      final response = await _client
          .from('products')
          .select()
          .eq('is_available', true)
          .order('created_at', ascending: false);

      print('📦 SupabaseDataSource: Réponse reçue, type: ${response.runtimeType}');
      print('📦 SupabaseDataSource: Nombre d\'items: ${(response as List).length}');

      final products = (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
      
      print('✅ SupabaseDataSource: ${products.length} produits parsés');
      
      return products;
    } catch (e, stackTrace) {
      print('❌ SupabaseDataSource ERROR: $e');
      print('Stack: $stackTrace');
      throw Exception('Erreur lors de la récupération des produits: $e');
    }
  }

  // Récupérer un produit par ID
  Future<Product?> fetchProductById(String id) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', id)
          .eq('is_available', true)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Récupérer les produits par catégorie
  Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('category_id', categoryId)
          .eq('is_available', true)
          .order('name');

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des produits: $e');
    }
  }

  // Récupérer les produits recommandés pour une maladie
  Future<List<Product>> fetchRecommendedProducts(String diseaseId) async {
    try {
      final response = await _client
          .from('disease_products')
          .select('product_id, priority, products(*)')
          .eq('disease_id', diseaseId)
          .order('priority')
          .limit(5);

      return (response as List)
          .map((item) => Product.fromJson(item['products']))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des recommandations: $e');
    }
  }

  // Récupérer toutes les catégories
  Future<List<Category>> fetchAllCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('display_order');

      return (response as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  // Récupérer un vendeur par ID
  Future<Vendor?> fetchVendorById(String id) async {
    try {
      final response = await _client
          .from('vendors')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return Vendor.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Ajouter un produit
  Future<Product> addProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required String vendorId,
    String? photoUrl,
    String? dosage,
    String? instructions,
  }) async {
    try {
      final response = await _client
          .from('products')
          .insert({
            'name': name,
            'description': description,
            'price': price,
            'category_id': categoryId,
            'vendor_id': vendorId,
            'photo_url': photoUrl,
            'dosage': dosage,
            'instructions': instructions,
            'is_available': true,
          })
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du produit: $e');
    }
  }

  // Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      print('🗑️ Suppression du produit: $productId');
      
      final response = await _client
          .from('products')
          .delete()
          .eq('id', productId)
          .select();
      
      print('✅ Produit supprimé: $response');
      
      if (response.isEmpty) {
        print('⚠️ Aucun produit supprimé - ID introuvable ou RLS bloque');
      }
    } catch (e) {
      print('❌ Erreur suppression produit: $e');
      throw Exception('Erreur lors de la suppression du produit: $e');
    }
  }

  // Modifier un produit
  Future<void> updateProduct(Product product) async {
    try {
      await _client
          .from('products')
          .update({
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'photo_url': product.photoUrl,
            'dosage': product.dosage,
            'instructions': product.instructions,
          })
          .eq('id', product.id);
    } catch (e) {
      throw Exception('Erreur lors de la modification du produit: $e');
    }
  }
}
