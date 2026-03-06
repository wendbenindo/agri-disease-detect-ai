import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/marketplace/product.dart';
import '../../model/marketplace/category.dart';
import '../../model/marketplace/vendor.dart';

class LocalProductDataSource {
  static const String _productsKey = 'cached_products';
  static const String _categoriesKey = 'cached_categories';
  static const String _vendorsKey = 'cached_vendors';
  static const String _lastSyncKey = 'last_sync_time';

  // Sauvegarder les produits en cache
  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = products.map((p) => p.toJson()).toList();
    await prefs.setString(_productsKey, jsonEncode(jsonList));
  }

  // Récupérer les produits du cache
  Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_productsKey);
    
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Product.fromJson(json)).toList();
  }

  // Sauvegarder les catégories en cache
  Future<void> saveCategories(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = categories.map((c) => c.toJson()).toList();
    await prefs.setString(_categoriesKey, jsonEncode(jsonList));
  }

  // Récupérer les catégories du cache
  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);
    
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Category.fromJson(json)).toList();
  }

  // Sauvegarder les vendeurs en cache
  Future<void> saveVendors(List<Vendor> vendors) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = vendors.map((v) => v.toJson()).toList();
    await prefs.setString(_vendorsKey, jsonEncode(jsonList));
  }

  // Récupérer les vendeurs du cache
  Future<List<Vendor>> getVendors() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_vendorsKey);
    
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Vendor.fromJson(json)).toList();
  }

  // Récupérer un vendeur par ID du cache
  Future<Vendor?> getVendorById(String id) async {
    final vendors = await getVendors();
    try {
      return vendors.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  // Sauvegarder le timestamp de la dernière synchronisation
  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  // Récupérer le timestamp de la dernière synchronisation
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastSyncKey);
    
    if (timeString == null) return null;
    
    return DateTime.parse(timeString);
  }

  // Vérifier si le cache est expiré (plus de 7 jours)
  Future<bool> isCacheExpired() async {
    final lastSync = await getLastSyncTime();
    
    if (lastSync == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    return difference.inDays > 7;
  }

  // Effacer tout le cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_productsKey);
    await prefs.remove(_categoriesKey);
    await prefs.remove(_vendorsKey);
    await prefs.remove(_lastSyncKey);
  }
}
