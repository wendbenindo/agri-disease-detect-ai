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
    return Conversation.fromJson(response);
  }

  // Récupérer toutes les conversations de l'utilisateur
  Future<List<Conversation>> getUserConversations(String userId) async {
    final response = await _client
        .from('conversations_with_details')
        .select()
        .eq('buyer_id', userId)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Conversation.fromJson(json))
        .toList();
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
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content,
        })
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
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
  }
}

