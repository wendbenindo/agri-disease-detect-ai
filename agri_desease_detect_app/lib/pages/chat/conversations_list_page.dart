import 'package:flutter/material.dart';
import '../../model/chat/conversation.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'chat_page.dart';

class ConversationsListPage extends StatefulWidget {
  final VoidCallback? onConversationOpened;
  final Function(int)? onNavigateToTab;
  
  const ConversationsListPage({
    super.key,
    this.onConversationOpened,
    this.onNavigateToTab,
  });

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _hasNetworkError = false;
    });

    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        // Utilisateur non connecté - pas d'erreur, juste un état vide
        setState(() {
          _conversations = [];
          _isLoading = false;
          _hasNetworkError = false;
        });
        return;
      }

      final conversations = await _chatService.getUserConversations(userId);
      
      setState(() {
        _conversations = conversations;
        _isLoading = false;
        _hasNetworkError = false;
      });
    } catch (e) {
      print('❌ Erreur chargement conversations: $e');
      
      // Détecter si c'est une erreur réseau
      final isNetworkError = e.toString().contains('SocketException') ||
                            e.toString().contains('Failed host lookup') ||
                            e.toString().contains('ClientException');
      
      setState(() {
        _conversations = [];
        _isLoading = false;
        _hasNetworkError = isNetworkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Mes Conversations'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: Colors.green,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    final isAuthenticated = _authService.isAuthenticated;
    
    // Si erreur réseau et utilisateur connecté
    if (_hasNetworkError && isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off,
                  size: 60,
                  color: Colors.orange.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pas de connexion',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vérifiez votre connexion internet\net réessayez',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadConversations,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Écran normal (utilisateur non connecté ou pas de conversations)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAuthenticated ? Icons.chat_bubble_outline : Icons.login,
                size: 60,
                color: const Color(0xFF1B5E20).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAuthenticated ? 'Aucune conversation' : 'Connectez-vous',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAuthenticated 
                  ? 'Contactez un vendeur depuis\nle marketplace pour commencer'
                  : 'Connectez-vous pour accéder\nà vos conversations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (isAuthenticated)
              ElevatedButton.icon(
                onPressed: () {
                  // Naviguer vers le marketplace (index 2)
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  }
                },
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Voir le Marketplace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Naviguer vers la page de profil (index 4)
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(4);
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Naviguer vers le marketplace (index 2)
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(2);
                      }
                    },
                    child: const Text(
                      'Découvrir le Marketplace',
                      style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final currentUserId = _authService.currentUserId;
    
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }
    
    try {
      final isUserBuyer = conversation.buyerId == currentUserId;
      final otherPersonName = isUserBuyer 
          ? (conversation.vendorName ?? 'Vendeur') 
          : (conversation.buyerName ?? 'Acheteur');
      
      final productName = conversation.productName ?? 'Produit';
      final lastMessage = conversation.lastMessage ?? '';
      final unreadCount = conversation.getUnreadCount(currentUserId);
      
      String timeText = '';
      if (conversation.lastMessageTime != null) {
        final now = DateTime.now();
        final diff = now.difference(conversation.lastMessageTime!);
        
        if (diff.inDays == 0) {
          timeText = '${conversation.lastMessageTime!.hour.toString().padLeft(2, '0')}:${conversation.lastMessageTime!.minute.toString().padLeft(2, '0')}';
        } else if (diff.inDays == 1) {
          timeText = 'Hier';
        } else if (diff.inDays < 7) {
          timeText = '${diff.inDays}j';
        } else {
          timeText = '${conversation.lastMessageTime!.day}/${conversation.lastMessageTime!.month}';
        }
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(conversation: conversation),
                ),
              );
              await Future.delayed(const Duration(milliseconds: 1500));
              await _loadConversations();
              widget.onConversationOpened?.call();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF1B5E20),
                    child: Text(
                      otherPersonName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                productName,
                                style: TextStyle(
                                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 16,
                                  color: const Color(0xFF212121),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timeText.isNotEmpty)
                              Text(
                                timeText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          otherPersonName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage.isEmpty ? 'Commencer la conversation' : lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                  color: lastMessage.isEmpty 
                                      ? Colors.grey.shade400 
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Erreur dans _buildConversationTile: $e');
      print('Stack: $stackTrace');
      return ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.error, color: Colors.white),
        ),
        title: const Text('Erreur d\'affichage'),
        subtitle: Text('$e'),
      );
    }
  }
}
