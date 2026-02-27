import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../model/marketplace/product.dart';
import '../../model/marketplace/category.dart';
import '../../services/marketplace/product_repository.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/marketplace/product_card.dart';
import 'product_detail_page.dart';
import '../auth/auth_page.dart';
import '../chat/chat_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final ProductRepository _repository = ProductRepository();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  
  bool _isLoading = true;
  bool _isOffline = false;
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les produits
      final result = await _repository.getAllProducts();
      final categories = await _repository.getAllCategories();

      setState(() {
        _allProducts = result.products;
        _filteredProducts = result.products;
        _categories = categories;
        _isOffline = result.isOffline;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Si recherche active, ignorer le filtre de catégorie
        if (_searchQuery.isNotEmpty) {
          return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        
        // Sinon, filtre par catégorie uniquement
        final matchesCategory = _selectedCategoryId == null ||
            product.categoryId == _selectedCategoryId;

        return matchesCategory;
      }).toList();
      
      // Trier les produits : nouveaux en premier (< 7 jours), puis par date décroissante
      _filteredProducts.sort((a, b) {
        final now = DateTime.now();
        final aIsNew = now.difference(a.createdAt).inDays < 7;
        final bIsNew = now.difference(b.createdAt).inDays < 7;
        
        // Si l'un est nouveau et pas l'autre, le nouveau vient en premier
        if (aIsNew && !bIsNew) return -1;
        if (!aIsNew && bIsNew) return 1;
        
        // Sinon, trier par date décroissante (plus récent en premier)
        return b.createdAt.compareTo(a.createdAt);
      });
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _filterProducts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20), // Même couleur que le bouton "Analyser une plante"
        foregroundColor: Colors.white,
        title: const Text('TipTiga Market'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Indicateur offline
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade900),
                  const SizedBox(width: 8),
                  Text(
                    'Mode hors ligne',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ],
              ),
            ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Filtres de catégories
          if (_categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('Tous', null),
                  ..._categories.map((category) =>
                      _buildCategoryChip(category.name, category.id)),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Liste des produits
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader()
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailPage(product: product),
                                  ),
                                );
                              },
                              onChatTap: () => _openChat(product),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(Product product) async {
    print('🎯 _openChat appelé pour produit: ${product.name}');
    print('   - productId: ${product.id}');
    print('   - vendorId: ${product.vendorId}');
    
    // Vérifier si le produit a un vendeur
    if (product.vendorId == null) {
      print('❌ Erreur: vendorId est null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce produit n\'a pas de vendeur associé')),
      );
      return;
    }

    print('✅ vendorId OK: ${product.vendorId}');

    // Vérifier si l'utilisateur est connecté
    print('🔍 Vérification authentification...');
    print('   - isAuthenticated: ${_authService.isAuthenticated}');
    print('   - currentUserId: ${_authService.currentUserId}');
    
    if (!_authService.isAuthenticated) {
      print('⚠️ Utilisateur non connecté, affichage AuthPage');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      
      print('📱 Retour de AuthPage: result=$result');
      if (result != true) {
        print('❌ Authentification annulée ou échouée');
        return;
      }
      
      print('✅ Authentification réussie');
      print('   - currentUserId après auth: ${_authService.currentUserId}');
    }

    // Créer ou récupérer la conversation
    try {
      final userId = _authService.currentUserId;
      print('🚀 Tentative création conversation...');
      print('   - userId: $userId');
      print('   - productId: ${product.id}');
      print('   - vendorId: ${product.vendorId}');
      
      if (userId == null) {
        print('❌ ERREUR: userId est null après authentification!');
        throw Exception('Utilisateur non connecté');
      }
      
      final conversation = await _chatService.getOrCreateConversation(
        productId: product.id,
        vendorId: product.vendorId!,
        buyerId: userId,
        productName: product.name,
        productPhotoUrl: product.photoUrl,
      );

      print('✅ Conversation créée/récupérée: ${conversation.id}');

      if (mounted) {
        print('📱 Navigation vers ChatPage');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(conversation: conversation),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ ERREUR dans _openChat: $e');
      print('📍 StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(categoryId),
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.green.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image skeleton
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title skeleton
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Price skeleton
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône avec cercle coloré
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 60,
                color: const Color(0xFF1B5E20).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // Titre
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Aucun résultat' 
                  : 'Aucun produit disponible',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              _searchQuery.isNotEmpty
                  ? 'Essayez avec d\'autres mots-clés'
                  : 'Les produits apparaîtront ici\nune fois ajoutés par les vendeurs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            
            // Bouton d'action (si recherche active)
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                  _filterProducts();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
