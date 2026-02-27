import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OneSignalService {
  static const String _appId = 'e150883a-86b2-4d49-bd52-b4ffbb34b84a';
  // ✅ Plus besoin de la clé REST API ici, elle est sur le serveur
  
  /// Initialise OneSignal
  static Future<void> initialize() async {
    print('🔔 Initialisation de OneSignal...');
    
    // Initialiser OneSignal
    OneSignal.initialize(_appId);
    
    // Demander la permission pour les notifications
    await OneSignal.Notifications.requestPermission(true);
    
    print('✅ OneSignal initialisé avec succès');
  }
  
  /// Configure l'utilisateur et sauvegarde son Player ID
  static Future<void> setUser(String userId) async {
    try {
      print('👤 Configuration de l\'utilisateur OneSignal: $userId');
      
      // Définir l'External User ID
      OneSignal.login(userId);
      
      // Récupérer le Player ID (Subscription ID)
      final playerId = OneSignal.User.pushSubscription.id;
      
      if (playerId != null) {
        print('📱 Player ID: $playerId');
        
        // Sauvegarder le Player ID dans Supabase
        await Supabase.instance.client
            .from('users')
            .update({'onesignal_player_id': playerId})
            .eq('id', userId);
        
        print('✅ Player ID sauvegardé dans Supabase');
      }
    } catch (e) {
      print('❌ Erreur lors de la configuration OneSignal: $e');
    }
  }
  
  /// Déconnecte l'utilisateur
  static Future<void> logout() async {
    try {
      OneSignal.logout();
      print('👋 Utilisateur déconnecté de OneSignal');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion OneSignal: $e');
    }
  }
  
  /// Envoie une notification à un utilisateur spécifique via Edge Function sécurisée
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 Envoi de notification via Edge Function à l\'utilisateur: $userId');
      
      // Récupérer le Player ID de l'utilisateur depuis Supabase
      final response = await Supabase.instance.client
          .from('users')
          .select('onesignal_player_id')
          .eq('id', userId)
          .single();
      
      final playerId = response['onesignal_player_id'] as String?;
      
      if (playerId == null || playerId.isEmpty) {
        print('⚠️ Utilisateur n\'a pas de Player ID');
        return;
      }
      
      print('📱 Player ID trouvé: $playerId');
      
      // ✅ SÉCURISÉ: Envoyer la notification via Edge Function
      // La clé REST API reste cachée sur le serveur
      final functionResponse = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'playerIds': [playerId],
          'title': title,
          'message': message,
          'data': data ?? {},
        },
      );
      
      if (functionResponse.status == 200) {
        print('✅ Notification envoyée avec succès via Edge Function');
        print('   Response: ${functionResponse.data}');
      } else {
        print('❌ Erreur Edge Function: ${functionResponse.status}');
        print('   Response: ${functionResponse.data}');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la notification: $e');
    }
  }
  
  /// Configure les handlers pour les notifications
  static void setupNotificationHandlers({
    Function(OSNotificationClickEvent)? onNotificationOpened,
  }) {
    // Handler quand l'utilisateur clique sur une notification
    OneSignal.Notifications.addClickListener((event) {
      print('🔔 Notification cliquée: ${event.notification.title}');
      
      if (onNotificationOpened != null) {
        onNotificationOpened(event);
      }
    });
    
    // Handler quand une notification est reçue (app au premier plan)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('🔔 Notification reçue en premier plan: ${event.notification.title}');
      
      // Afficher la notification même si l'app est au premier plan
      event.notification.display();
    });
  }
}
