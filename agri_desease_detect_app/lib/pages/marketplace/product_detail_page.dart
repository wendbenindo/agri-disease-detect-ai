import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../model/marketplace/product.dart';
import '../../model/marketplace/vendor.dart';
import '../../services/marketplace/product_repository.dart';
import '../../services/marketplace/product_images_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/marketplace/image_carousel.dart';
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
  final ProductImagesService _imagesService = ProductImagesService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  Vendor? _vendor;
  bool _isLoadingVendor = true;
  bool _isFavorite = false;
  List<String> _allImages = [];
  bool _isLoadingImages = true;

  @override
  void initState() {
    super.initState();
    _loadVendor();
    _loadImages();
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

  Future<void> _loadImages() async {
    try {
      // Récupérer les images additionnelles
      final additionalImages = await _imagesService.getProductImages(widget.product.id);
      
      // Combiner image principale + images additionnelles
      final allImages = <String>[];
      if (widget.product.photoUrl != null) {
        allImages.add(widget.product.photoUrl!);
      }
      allImages.addAll(additionalImages);
      
      setState(() {
        _allImages = allImages;
        _isLoadingImages = false;
      });
      
      print('📸 Images chargées: ${_allImages.length}');
    } catch (e) {
      print('❌ Erreur chargement images: $e');
      setState(() {
        _allImages = widget.product.photoUrl != null 
            ? [widget.product.photoUrl!] 
            : [];
        _isLoadingImages = false;
      });
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(price)} FCFA';
  }

  Future<void> _shareProduct() async {
    try {
      final text = '''
🌾 ${widget.product.name}

💰 Prix: ${_formatPrice(widget.product.price)}

📝 ${widget.product.description}

${_vendor != null ? '🏪 Vendeur: ${_vendor!.name}\n📍 ${_vendor!.city}, ${_vendor!.region}' : ''}

Partagé depuis TipTiga - Marketplace Agricole
''';

      await Share.share(
        text,
        subject: widget.product.name,
      );
    } catch (e) {
      print('❌ Erreur partage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openChat() async {
    print('🎯 _openChat appelé pour produit: ${widget.product.name}');
    print('   - productId: ${widget.product.id}');
    print('   - vendorId: ${widget.product.vendorId}');
    
    // Vérifier que le vendorId existe
    if (widget.product.vendorId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vendeur introuvable'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    print('✅ vendorId OK: ${widget.product.vendorId}');
    
    // Vérifier si l'utilisateur est connecté
    print('🔍 Vérification authentification...');
    print('   - isAuthenticated: ${_authService.isAuthenticated}');
    print('   - currentUserId: ${_authService.currentUserId}');
    
    if (!_authService.isAuthenticated) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      
      if (result != true) return;
    }

    final userId = _authService.currentUserId!;
    
    // ❌ BLOQUER si l'utilisateur essaie de se contacter lui-même
    if (userId == widget.product.vendorId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vous ne pouvez pas vous contacter vous-même'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Créer ou récupérer la conversation
    try {
      print('🚀 Tentative création conversation...');
      print('   - userId: $userId');
      print('   - productId: ${widget.product.id}');
      print('   - vendorId: ${widget.product.vendorId}');
      
      final conversation = await _chatService.getOrCreateConversation(
        productId: widget.product.id,
        vendorId: widget.product.vendorId!,
        buyerId: userId,
        productName: widget.product.name,
        productPhotoUrl: widget.product.photoUrl,
      );

      print('✅ Conversation créée/récupérée: ${conversation.id}');
      print('📱 Navigation vers ChatPage');

      if (mounted) {
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // AppBar avec image en arrière-plan
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    setState(() => _isFavorite = !_isFavorite);
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.black),
                  onPressed: _shareProduct,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${widget.product.id}',
                child: _isLoadingImages
                    ? Container(
                        color: Colors.grey.shade50,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : ImageCarousel(
                        imageUrls: _allImages,
                        height: 300,
                      ),
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom et prix en étiquette
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Prix en étiquette
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatPrice(widget.product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                // Dosage (si disponible ET si ce n'est pas vide)
                if (widget.product.dosage != null && 
                    widget.product.dosage!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.science_outlined, 
                              size: 18, 
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Dosage recommandé',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.dosage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Instructions (si disponibles ET si ce n'est pas vide)
                if (widget.product.instructions != null && 
                    widget.product.instructions!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt_outlined, 
                              size: 18, 
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Mode d\'emploi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.instructions!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Informations du vendeur
                if (_vendor != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vendeur',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.store_outlined,
                                color: Colors.green,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _vendor!.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_vendor!.city}, ${_vendor!.region}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else if (_isLoadingVendor)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
      
      // Bouton flottant
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _openChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Contacter le vendeur',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 80,
        color: Colors.grey.shade300,
      ),
    );
  }
}
