import 'package:connectivity_plus/connectivity_plus.dart';
import '../../model/marketplace/product.dart';
import '../../model/marketplace/category.dart';
import '../../model/marketplace/vendor.dart';
import 'supabase_product_datasource.dart';
import 'local_product_datasource.dart';

class ProductRepository {
  final SupabaseProductDataSource _remoteDataSource = SupabaseProductDataSource();
  final LocalProductDataSource _localDataSource = LocalProductDataSource();

  // Vérifier la connectivité
  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Récupérer tous les produits (cache-first)
  Future<({List<Product> products, bool isOffline})> getAllProducts() async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        // Récupérer depuis Supabase
        final products = await _remoteDataSource.fetchAllProducts();
        
        // Sauvegarder en cache
        await _localDataSource.saveProducts(products);
        await _localDataSource.setLastSyncTime(DateTime.now());
        
        return (products: products, isOffline: false);
      } catch (e) {
        // En cas d'erreur, utiliser le cache
        final cachedProducts = await _localDataSource.getProducts();
        return (products: cachedProducts, isOffline: true);
      }
    } else {
      // Mode offline, utiliser le cache
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
}
