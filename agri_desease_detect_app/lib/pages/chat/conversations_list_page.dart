import 'package:flutter/material.dart';
import '../../model/chat/conversation.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'chat_page.dart';

class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Conversations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
                ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final currentUserId = _authService.currentUserId;
    
    // Déterminer qui est l'autre personne (vendor ou buyer)
    final isUserBuyer = conversation.buyerId == currentUserId;
    final otherPersonId = isUserBuyer ? conversation.vendorId : conversation.buyerId;
    final otherPersonName = isUserBuyer 
        ? (conversation.vendorName ?? 'Vendeur') 
        : 'Acheteur';
    
    final productName = conversation.productName ?? 'Produit';
    final lastMessage = conversation.lastMessage ?? '';
    final unreadCount = conversation.unreadCount;
    
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
            lastMessage.isEmpty ? 'Aucun message' : lastMessage,
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
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(conversation: conversation),
          ),
        ).then((_) => _loadConversations());
      },
    );
  }
}
