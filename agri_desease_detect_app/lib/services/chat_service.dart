import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/chat/conversation.dart';
import '../model/chat/message.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  // Créer ou récupérer une conversation
  Future<Conversation> getOrCreateConversation({
    required String productId,
    required String vendorId,
    required String buyerId,
    String? productName,
    String? productPhotoUrl,
  }) async {
    print('📞 Création/récupération conversation: productId=$productId, buyerId=$buyerId, vendorId=$vendorId');

    // Vérifier si une conversation existe déjà
    final existing = await _client
        .from('conversations')
        .select()
        .eq('product_id', productId)
        .eq('buyer_id', buyerId)
        .maybeSingle();

    if (existing != null) {
      print('✅ Conversation existante trouvée');
      return Conversation.fromJson(existing);
    }

    // Créer une nouvelle conversation
    print('📝 Création nouvelle conversation...');
    final response = await _client
        .from('conversations')
        .insert({
          'product_id': productId,
          'buyer_id': buyerId,
          'vendor_id': vendorId,
        })
        .select()
        .single();

    print('✅ Conversation créée: ${response['id']}');
    
    // Envoyer un message de bienvenue avec l'image du produit
    if (productPhotoUrl != null && productName != null) {
      print('📸 Envoi du message de bienvenue avec image...');
      await sendMessage(
        conversationId: response['id'],
        senderId: buyerId,
        content: '👋 Bonjour, je suis intéressé par ce produit : $productName',
        imageUrl: productPhotoUrl,
      );
    }
    
    return Conversation.fromJson(response);
  }

  // Récupérer toutes les conversations de l'utilisateur
  Future<List<Conversation>> getUserConversations(String userId) async {
    print('📞 Récupération des conversations pour userId: $userId');
    
    try {
      final response = await _client
          .from('conversations_with_details')
          .select()
          .or('buyer_id.eq.$userId,vendor_id.eq.$userId')
          .order('updated_at', ascending: false);

      print('📦 Conversations récupérées: ${(response as List).length}');
      
      return (response as List)
          .map((json) {
            print('📄 Conversation JSON: $json');
            return Conversation.fromJson(json);
          })
          .toList();
    } catch (e, stackTrace) {
      print('❌ Erreur getUserConversations: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }
  
  // Compter le nombre total de messages non lus pour un utilisateur
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final conversations = await getUserConversations(userId);
      int total = 0;
      for (var conv in conversations) {
        total += conv.getUnreadCount(userId);
      }
      print('📊 Total messages non lus pour $userId: $total');
      return total;
    } catch (e) {
      print('❌ Erreur getTotalUnreadCount: $e');
      return 0;
    }
  }

  // Récupérer les messages d'une conversation
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => Message.fromJson(json))
        .toList();
  }

  // Envoyer un message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? imageUrl,
  }) async {
    final messageData = {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    };
    
    if (imageUrl != null) {
      messageData['image_url'] = imageUrl;
    }

    final response = await _client
        .from('messages')
        .insert(messageData)
        .select()
        .single();

    // Mettre à jour le timestamp de la conversation
    await _client
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    return Message.fromJson(response);
  }

  // Écouter les nouveaux messages en temps réel
  Stream<Message> subscribeToMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.map((json) => Message.fromJson(json)).toList())
        .expand((messages) => messages);
  }

  // Marquer les messages comme lus
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      print('📖 Marquage des messages comme lus...');
      print('   - conversationId: $conversationId');
      print('   - userId: $userId');
      
      final result = await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .select();
      
      print('✅ Messages marqués comme lus: ${result.length} messages');
    } catch (e, stackTrace) {
      print('❌ Erreur markAsRead: $e');
      print('Stack: $stackTrace');
      // Ne pas rethrow pour ne pas bloquer l'ouverture du chat
    }
  }
}

