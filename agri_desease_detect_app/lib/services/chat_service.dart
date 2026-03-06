import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/chat/conversation.dart';
import '../model/chat/message.dart';
import 'onesignal_service.dart';
import 'auth_service.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Créer ou récupérer une conversation
  Future<Conversation> getOrCreateConversation({
    required String productId,
    required String vendorId,
    required String buyerId,
    String? productName,
    String? productPhotoUrl,
  }) async {
    print('📞 Création/récupération conversation: productId=$productId, buyerId=$buyerId, vendorId=$vendorId');

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('Vous devez être connecté pour démarrer une conversation');
    }

    // ✅ SÉCURITÉ: Vérifier que buyerId correspond à l'utilisateur connecté
    if (buyerId != currentUserId) {
      throw Exception('Vous ne pouvez pas créer une conversation pour un autre utilisateur');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur ne se contacte pas lui-même
    if (buyerId == vendorId) {
      throw Exception('Vous ne pouvez pas vous contacter vous-même');
    }

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
    
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('Vous devez être connecté pour voir vos conversations');
    }

    // ✅ SÉCURITÉ: Vérifier que userId correspond à l'utilisateur connecté
    if (userId != currentUserId) {
      throw Exception('Vous ne pouvez pas voir les conversations d\'un autre utilisateur');
    }
    
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
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      return 0;
    }

    // ✅ SÉCURITÉ: Vérifier que userId correspond à l'utilisateur connecté
    if (userId != currentUserId) {
      throw Exception('Vous ne pouvez pas voir le compteur d\'un autre utilisateur');
    }

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
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('Vous devez être connecté pour voir les messages');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est participant de la conversation
    final conversation = await _client
        .from('conversations')
        .select('buyer_id, vendor_id')
        .eq('id', conversationId)
        .single();

    if (conversation['buyer_id'] != currentUserId && 
        conversation['vendor_id'] != currentUserId) {
      throw Exception('Vous n\'êtes pas participant de cette conversation');
    }

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
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('Vous devez être connecté pour envoyer un message');
    }

    // ✅ SÉCURITÉ: Vérifier que senderId correspond à l'utilisateur connecté
    if (senderId != currentUserId) {
      throw Exception('Vous ne pouvez pas envoyer un message pour un autre utilisateur');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est participant de la conversation
    final conversation = await _client
        .from('conversations')
        .select('buyer_id, vendor_id')
        .eq('id', conversationId)
        .single();

    if (conversation['buyer_id'] != currentUserId && 
        conversation['vendor_id'] != currentUserId) {
      throw Exception('Vous n\'êtes pas participant de cette conversation');
    }

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

    // Envoyer une notification au destinataire
    try {
      // Déterminer qui est le destinataire (celui qui n'est pas l'expéditeur)
      final receiverId = conversation['buyer_id'] == senderId 
          ? conversation['vendor_id'] 
          : conversation['buyer_id'];
      
      // Récupérer le nom de l'expéditeur
      final senderInfo = await _client
          .from('users')
          .select('name')
          .eq('id', senderId)
          .single();
      
      final senderName = senderInfo['name'] as String;
      
      // Préparer le message de notification
      String notificationMessage = content;
      if (imageUrl != null) {
        notificationMessage = '📷 Photo';
      }
      
      // Envoyer la notification
      print('📤 Envoi notification à $receiverId de la part de $senderName');
      await OneSignalService.sendNotificationToUser(
        userId: receiverId,
        title: 'Nouveau message de $senderName',
        message: notificationMessage,
        data: {
          'type': 'chat',
          'conversation_id': conversationId,
          'sender_id': senderId,
        },
      );
      print('✅ Notification envoyée avec succès');
    } catch (e) {
      print('❌ Erreur envoi notification: $e');
      // Ne pas bloquer l'envoi du message si la notification échoue
    }

    return Message.fromJson(response);
  }

  // Écouter les nouveaux messages en temps réel
  Stream<Message> subscribeToMessages(String conversationId) {
    // Note: La vérification de sécurité est faite lors de l'appel à getMessages()
    // qui est appelé avant de s'abonner au stream
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
    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est connecté
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      print('⚠️ Utilisateur non connecté, impossible de marquer comme lu');
      return;
    }

    // ✅ SÉCURITÉ: Vérifier que userId correspond à l'utilisateur connecté
    if (userId != currentUserId) {
      throw Exception('Vous ne pouvez pas marquer les messages d\'un autre utilisateur comme lus');
    }

    // ✅ SÉCURITÉ: Vérifier que l'utilisateur est participant de la conversation
    try {
      final conversation = await _client
          .from('conversations')
          .select('buyer_id, vendor_id')
          .eq('id', conversationId)
          .single();

      if (conversation['buyer_id'] != currentUserId && 
          conversation['vendor_id'] != currentUserId) {
        throw Exception('Vous n\'êtes pas participant de cette conversation');
      }

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

