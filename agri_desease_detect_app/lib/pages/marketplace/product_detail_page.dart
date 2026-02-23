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
        title: Text(widget.product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey.shade200,
              child: widget.product.photoUrl != null
                  ? Image.network(
                      widget.product.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et prix
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(widget.product.price),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  // Dosage (si disponible)
                  if (widget.product.dosage != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Dosage recommandé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.science, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.product.dosage!,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Instructions (si disponibles)
                  if (widget.product.instructions != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Mode d\'emploi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.product.instructions!,
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Informations du vendeur
                  if (_vendor != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Vendeur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green.shade700,
                                child: const Icon(Icons.store, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _vendor!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_vendor!.city}, ${_vendor!.region}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Bouton de contact (Chat)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openChat,
                              icon: const Icon(Icons.chat),
                              label: const Text('Contacter le vendeur'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_isLoadingVendor)
                    const Center(child: CircularProgressIndicator()),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 80,
        color: Colors.grey.shade400,
      ),
    );
  }
}
