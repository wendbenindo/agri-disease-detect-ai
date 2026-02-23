import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/marketplace/product.dart';
import '../../model/marketplace/vendor.dart';
import '../../services/marketplace/product_repository.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../auth/auth_page.dart';
import '../chat/chat_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ProductRepository _repository = ProductRepository();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  Vendor? _vendor;
  bool _isLoadingVendor = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  Future<void> _loadVendor() async {
    if (widget.product.vendorId != null) {
      final vendor = await _repository.getVendorById(widget.product.vendorId!);
      setState(() {
        _vendor = vendor;
        _isLoadingVendor = false;
      });
    } else {
      setState(() => _isLoadingVendor = false);
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(price)} FCFA';
  }

  Future<void> _openChat() async {
    // Vérifier si l'utilisateur est connecté
    if (!_authService.isAuthenticated) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      
      // Si l'utilisateur n'a pas réussi à se connecter, arrêter
      if (result != true) return;
    }

    // Créer ou récupérer la conversation
    try {
      final userId = _authService.currentUserId!;
      final conversation = await _chatService.getOrCreateConversation(
        productId: widget.product.id,
        vendorId: widget.product.vendorId!,
        buyerId: userId,
        productName: widget.product.name,
        productPhotoUrl: widget.product.photoUrl,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du produit'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorite 
                        ? '❤️ Ajouté aux favoris' 
                        : 'Retiré des favoris',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Partager le produit
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage en cours...')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du produit avec hero animation
                Hero(
                  tag: 'product-${widget.product.id}',
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: widget.product.photoUrl != null
                        ? Image.network(
                            widget.product.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom et prix
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Prix avec badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade700,
                              Colors.green.shade900,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade700.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_offer,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatPrice(widget.product.price),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Description
                      _buildSection(
                        icon: Icons.description,
                        title: 'Description',
                        child: Text(
                          widget.product.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Dosage (si disponible)
                      if (widget.product.dosage != null) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          icon: Icons.science,
                          title: 'Dosage recommandé',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.water_drop, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.product.dosage!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Instructions (si disponibles)
                      if (widget.product.instructions != null) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          icon: Icons.list_alt,
                          title: 'Mode d\'emploi',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.product.instructions!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.6,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Informations du vendeur
                      if (_vendor != null) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          icon: Icons.store,
                          title: 'Vendeur',
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.shade50,
                                  Colors.grey.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade700,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.shade700.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.store,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _vendor!.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_vendor!.city}, ${_vendor!.region}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (_isLoadingVendor)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      const SizedBox(height: 100), // Espace pour le bouton flottant
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton flottant de contact
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat, size: 24),
                  label: const Text(
                    'Contacter le vendeur',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 100,
        color: Colors.grey.shade400,
      ),
    );
  }
}
