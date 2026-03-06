import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

// Handler pour les messages en arrière-plan (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Message reçu en arrière-plan: ${message.messageId}');
  print('Titre: ${message.notification?.title}');
  print('Corps: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;

  /// Initialiser le service de notifications
  Future<void> initialize(String userId) async {
    if (_initialized) {
      print('⚠️ NotificationService déjà initialisé');
      return;
    }

    try {
      print('🔔 Initialisation du service de notifications...');

      // 1. Demander la permission (iOS/Android 13+)
      await _requestPermission();

      // 2. Configurer les notifications locales
      await _setupLocalNotifications();

      // 3. Obtenir le token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      print('✅ Token FCM obtenu: ${_fcmToken?.substring(0, 20)}...');

      // 4. Sauvegarder le token dans Supabase
      if (_fcmToken != null) {
        await _saveFcmTokenToSupabase(userId, _fcmToken!);
      }

      // 5. Écouter les messages
      _setupMessageHandlers();

      // 6. Écouter le rafraîchissement du token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 Token FCM rafraîchi');
        _fcmToken = newToken;
        _saveFcmTokenToSupabase(userId, newToken);
      });

      _initialized = true;
      print('✅ Service de notifications initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Demander la permission pour les notifications
  Future<void> _requestPermission() async {
    if (kIsWeb) return;

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permission accordée pour les notifications');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Permission provisoire accordée');
    } else {
      print('❌ Permission refusée pour les notifications');
    }
  }

  /// Configurer les notifications locales (pour afficher quand l'app est ouverte)
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Canal Android pour les notifications de messages
    const androidChannel = AndroidNotificationChannel(
      'chat_messages',
      'Messages de chat',
      description: 'Notifications pour les nouveaux messages',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Configurer les handlers de messages
  void _setupMessageHandlers() {
    // Message reçu quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Message reçu (app au premier plan)');
      print('Titre: ${message.notification?.title}');
      print('Corps: ${message.notification?.body}');
      
      // Afficher une notification locale
      _showLocalNotification(message);
    });

    // Message cliqué quand l'app est en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Notification cliquée (app en arrière-plan)');
      _handleNotificationTap(message);
    });

    // Vérifier si l'app a été ouverte via une notification
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📩 App ouverte via notification');
        _handleNotificationTap(message);
      }
    });
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Messages de chat',
      channelDescription: 'Notifications pour les nouveaux messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Gérer le clic sur une notification
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapée: ${message.data}');
    // TODO: Naviguer vers la conversation appropriée
    // Vous pouvez utiliser un NavigatorKey global ou un event bus
  }

  /// Callback quand une notification locale est tapée
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification locale tapée: ${response.payload}');
    // TODO: Naviguer vers la conversation appropriée
  }

  /// Sauvegarder le token FCM dans Supabase
  Future<void> _saveFcmTokenToSupabase(String userId, String token) async {
    try {
      print('💾 Sauvegarde du token FCM dans Supabase...');
      
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);
      
      print('✅ Token FCM sauvegardé dans Supabase');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde du token FCM: $e');
    }
  }

  /// Obtenir le token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Supprimer le token FCM (lors de la déconnexion)
  Future<void> clearFcmToken(String userId) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': null})
          .eq('id', userId);
      
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      print('✅ Token FCM supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression du token FCM: $e');
    }
  }
}
