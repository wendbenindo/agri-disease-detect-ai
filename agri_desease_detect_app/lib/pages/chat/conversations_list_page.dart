import 'package:flutter/material.dart';
import '../../model/chat/conversation.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'chat_page.dart';

class ConversationsListPage extends StatefulWidget {
  final VoidCallback? onConversationOpened;
  
  const ConversationsListPage({
    super.key,
    this.onConversationOpened,
  });

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final conversations = await _chatService.getUserConversations(userId);
      
      setState(() {
        _conversations = conversations;
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

  @override
  Widget build(BuildContext context) {
    print('🎨 ConversationsListPage build: isLoading=$_isLoading, conversations=${_conversations.length}');
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20), // Même couleur que le bouton "Analyser une plante"
        foregroundColor: Colors.white,
        title: const Text('Mes Conversations'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune conversation',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contactez un vendeur pour commencer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: Colors.green,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      print('📝 Building conversation tile $index');
                      final conversation = _conversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
                ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final currentUserId = _authService.currentUserId;
    
    if (currentUserId == null) {
      print('❌ currentUserId est null dans _buildConversationTile');
      return const SizedBox.shrink();
    }
    
    try {
      // Déterminer qui est l'autre personne (vendor ou buyer)
      final isUserBuyer = conversation.buyerId == currentUserId;
      final otherPersonId = isUserBuyer ? conversation.vendorId : conversation.buyerId;
      final otherPersonName = isUserBuyer 
          ? (conversation.vendorName ?? 'Vendeur') 
          : (conversation.buyerName ?? 'Acheteur');
      
      final productName = conversation.productName ?? 'Produit';
      final lastMessage = conversation.lastMessage ?? '';
      final unreadCount = conversation.getUnreadCount(currentUserId);
      
      print('🔍 Conversation tile: product=$productName, otherPerson=$otherPersonName, unread=$unreadCount');
      
      // Formater le temps du dernier message
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

      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade700,
          child: Text(
            otherPersonName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                productName,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
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
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherPersonName,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              lastMessage.isEmpty ? 'Commencer la conversation' : lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                color: lastMessage.isEmpty ? Colors.grey.shade400 : null,
              ),
            ),
          ],
        ),
        trailing: unreadCount > 0
            ? Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        onTap: () async {
          print('🔔 Ouverture conversation: ${conversation.id}');
          print('👤 Current user ID: $currentUserId');
          
          // Ouvrir le chat
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(conversation: conversation),
            ),
          );
          
          // Attendre plus longtemps pour que la BD se mette à jour
          print('⏳ Attente de 1.5 secondes pour la mise à jour de la BD...');
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Recharger les conversations après avoir fermé le chat
          print('🔄 Rechargement des conversations après fermeture du chat...');
          await _loadConversations();
          
          // Notifier le parent pour recharger le compteur global
          widget.onConversationOpened?.call();
        },
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
