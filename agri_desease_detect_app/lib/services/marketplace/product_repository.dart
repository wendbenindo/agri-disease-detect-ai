import 'package:connectivity_plus/connectivity_plus.dart';
import '../../model/marketplace/product.dart';
import '../../model/marketplace/category.dart';
import '../../model/marketplace/vendor.dart';
import 'supabase_product_datasource.dart';
import 'local_product_datasource.dart';
import '../auth_service.dart';

class ProductRepository {
  final SupabaseProductDataSource _remoteDataSource = SupabaseProductDataSource();
  final LocalProductDataSource _localDataSource = LocalProductDataSource();
  final AuthService _authService = AuthService();

  // Vérifier la connectivité
  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Récupérer tous les produits (cache-first)
  Future<({List<Product> products, bool isOffline})> getAllProducts() async {
    final isOnline = await _isOnline();
    
    print('🌐 ProductRepository: isOnline = $isOnline');

    if (isOnline) {
      try {
        print('📡 Tentative de récupération depuis Supabase...');
        // Récupérer depuis Supabase
        final products = await _remoteDataSource.fetchAllProducts();
        
        print('✅ Produits récupérés depuis Supabase: ${products.length}');
        
        // Sauvegarder en cache
        await _localDataSource.saveProducts(products);
        await _localDataSource.setLastSyncTime(DateTime.now());
        
        return (products: products, isOffline: false);
      } catch (e, stackTrace) {
        // En cas d'erreur, utiliser le cache
        print('❌ Erreur Supabase: $e');
        print('Stack trace: $stackTrace');
        final cachedProducts = await _localDataSource.getProducts();
        print('📦 Utilisation du cache: ${cachedProducts.length} produits');
        return (products: cachedProducts, isOffline: true);
      }
    } else {
      // Mode offline, utiliser le cache
      print('📴 Mode offline détecté');
      final cachedProducts = await _localDataSource.getProducts();
      return (products: cachedProducts, isOffline: true);
    }
  }

  // Récupérer un produit par ID
  Future<Product?> getProductById(String id) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        return await _remoteDataSource.fetchProductById(id);
      } catch (e) {
        // Fallback sur le cache
        final cachedProducts = await _localDataSource.getProducts();
        try {
          return cachedProducts.firstWhere((p) => p.id == id);
        } catch (e) {
          return null;
        }
      }
    } else {
      // Mode offline
      final cachedProducts = await _localDataSource.getProducts();
      try {
        return cachedProducts.firstWhere((p) => p.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  // Récupérer les produits par catégorie
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final result = await getAllProducts();
    return result.products
        .where((p) => p.categoryId == categoryId)
        .toList();
  }

  // Rechercher des produits par nom
  Future<List<Product>> searchProducts(String query) async {
    final result = await getAllProducts();
    final lowerQuery = query.toLowerCase();
    
    return result.products
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Récupérer les produits recommandés pour une maladie
  Future<List<Product>> getRecommendedProducts(String diseaseId) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        return await _remoteDataSource.fetchRecommendedProducts(diseaseId);
      } catch (e) {
        return [];
      }
    } else {
      // En mode offline, on ne peut pas récupérer les recommandations
      return [];
    }
  }

  // Récupérer toutes les catégories
  Future<List<Category>> getAllCategories() async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        final categories = await _remoteDataSource.fetchAllCategories();
        await _localDataSource.saveCategories(categories);
        return categories;
      } catch (e) {
        return await _localDataSource.getCategories();
      }
    } else {
      return await _localDataSource.getCategories();
    }
  }

  // Récupérer un vendeur par ID
  Future<Vendor?> getVendorById(String id) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        return await _remoteDataSource.fetchVendorById(id);
      } catch (e) {
        return await _localDataSource.getVendorById(id);
      }
    } else {
      return await _localDataSource.getVendorById(id);
    }
  }

  // Synchroniser toutes les données
  Future<void> syncAll() async {
    final isOnline = await _isOnline();
    
    if (!isOnline) return;

    try {
      // Synchroniser les produits
      final products = await _remoteDataSource.fetchAllProducts();
      await _localDataSource.saveProducts(products);

      // Synchroniser les catégories
      final categories = await _remoteDataSource.fetchAllCategories();
      await _localDataSource.saveCategories(categories);

      // Mettre à jour le timestamp
      await _localDataSource.setLastSyncTime(DateTime.now());
    } catch (e) {
      // Ignorer les erreurs de synchronisation
    }
  }

  // Vérifier si le cache est expiré
  Future<bool> isCacheExpired() async {
    return await _localDataSource.isCacheExpired();
  }

  // Ajouter un produit (vendeurs uniquement)
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
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('Vous devez être connecté pour ajouter un produit');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est vendeur ou admin
    if (!_authService.isVendor && !_authService.isAdmin) {
      throw Exception('Seuls les vendeurs peuvent ajouter des produits');
    }

    // ✅ SÉCURITÉ: Vérifier que vendorId correspond à l'utilisateur connecté
    if (vendorId != currentUserId && !_authService.isAdmin) {
      throw Exception('Vous ne pouvez ajouter des produits qu\'en votre nom');
    }

    final isOnline = await _isOnline();
    
    if (!isOnline) {
      throw Exception('Connexion internet requise pour ajouter un produit');
    }

    try {
      final product = await _remoteDataSource.addProduct(
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        vendorId: vendorId,
        photoUrl: photoUrl,
        dosage: dosage,
        instructions: instructions,
      );

      // Rafraîchir le cache
      await syncAll();

      return product;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du produit: $e');
    }
  }

  // Supprimer un produit (vendeurs uniquement)
  Future<void> deleteProduct(String productId) async {
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('Vous devez être connecté pour supprimer un produit');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est vendeur ou admin
    if (!_authService.isVendor && !_authService.isAdmin) {
      throw Exception('Seuls les vendeurs peuvent supprimer des produits');
    }

    final isOnline = await _isOnline();
    
    if (!isOnline) {
      throw Exception('Connexion internet requise pour supprimer un produit');
    }

    try {
      // ✅ SÉCURITÉ: Vérifier que l'utilisateur est propriétaire du produit
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Produit introuvable');
      }

      if (product.vendorId != currentUserId && !_authService.isAdmin) {
        throw Exception('Vous ne pouvez supprimer que vos propres produits');
      }

      await _remoteDataSource.deleteProduct(productId);

      // Rafraîchir le cache
      await syncAll();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du produit: $e');
    }
  }

  // Modifier un produit (vendeurs uniquement)
  Future<void> updateProduct(Product product) async {
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('Vous devez être connecté pour modifier un produit');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est vendeur ou admin
    if (!_authService.isVendor && !_authService.isAdmin) {
      throw Exception('Seuls les vendeurs peuvent modifier des produits');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est propriétaire du produit
    if (product.vendorId != currentUserId && !_authService.isAdmin) {
      throw Exception('Vous ne pouvez modifier que vos propres produits');
    }

    final isOnline = await _isOnline();
    
    if (!isOnline) {
      throw Exception('Connexion internet requise pour modifier un produit');
    }

    try {
      await _remoteDataSource.updateProduct(product);

      // Rafraîchir le cache
      await syncAll();
    } catch (e) {
      throw Exception('Erreur lors de la modification du produit: $e');
    }
  }
}
