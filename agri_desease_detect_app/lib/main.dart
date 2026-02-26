import 'package:agri_desease_detect_app/services/supabase_service.dart';
import 'package:agri_desease_detect_app/services/auth_service.dart';
import 'package:agri_desease_detect_app/services/chat_service.dart';
import 'package:agri_desease_detect_app/services/onesignal_service.dart';
import 'dart:io' show Platform;
import 'package:agri_desease_detect_app/pages/communitypage.dart';
import 'package:agri_desease_detect_app/pages/profile/profile_page.dart';
import 'package:agri_desease_detect_app/pages/chat/conversations_list_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

import 'package:agri_desease_detect_app/widgets/theme.dart';
import 'package:agri_desease_detect_app/widgets/splashscreen.dart';
import 'package:agri_desease_detect_app/pages/homepage.dart';
import 'package:agri_desease_detect_app/pages/diagnosticpage.dart';
import 'package:agri_desease_detect_app/pages/marketplace/marketplace_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Chargement des variables d'environnement
    await dotenv.load(fileName: ".env");

    // Initialisations critiques
    await initSupabase();
    
    // Initialiser OneSignal
    await OneSignalService.initialize();
    print('✅ OneSignal initialisé');
    
    // Initialiser AuthService
    final authService = AuthService();
    await authService.initialize();
    
    // Lancement de l'application principale
    runApp(const TipTigaApp());
    
    // Permission de localisation en arrière-plan (non bloquant)
    _handleLocationPermission();
  } catch (e) {
    debugPrint("Erreur critique au démarrage : $e");
    // En cas d'erreur, on lance une application d'erreur
    runApp(ErrorApp(error: e.toString()));
  }
}

// Widget simple pour afficher une erreur fatale
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Erreur critique au démarrage de l'application :\n\n$error",
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _handleLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    debugPrint('Les services de localisation sont désactivés.');
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Permission de localisation refusée.');
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    debugPrint('Permission refusée définitivement. Veuillez l’activer dans les paramètres.');
    return;
  }

  debugPrint('Permission de localisation accordée.');
}

class TipTigaApp extends StatelessWidget {
  const TipTigaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TipTiga',
      theme: tipTigaTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // Accès direct sans authentification
    );
  }
}

class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _profileRebuildKey = 0; // Compteur pour forcer le rebuild
  int _unreadMessagesCount = 0; // Compteur de messages non lus
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Écouter les changements d'état d'authentification
    _authService.authStateNotifier.addListener(_onAuthStateChanged);
    
    // Forcer un rebuild initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _profileRebuildKey++;
        });
        _loadUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authService.authStateNotifier.removeListener(_onAuthStateChanged);
    super.dispose();
  }
  
  void _onAuthStateChanged() {
    // Quand l'état d'authentification change, forcer un rebuild
    print('🔔 NavigationController: État d\'authentification changé');
    if (mounted) {
      setState(() {
        _profileRebuildKey++;
      });
      _loadUnreadCount();
    }
  }
  
  Future<void> _loadUnreadCount() async {
    if (!_authService.isAuthenticated) {
      setState(() => _unreadMessagesCount = 0);
      return;
    }
    
    try {
      final chatService = ChatService();
      final count = await chatService.getTotalUnreadCount(_authService.currentUserId!);
      if (mounted) {
        setState(() => _unreadMessagesCount = count);
      }
    } catch (e) {
      print('❌ Erreur chargement messages non lus: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quand l'app revient au premier plan, forcer un rebuild
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _profileRebuildKey++;
      });
      _loadUnreadCount();
    }
  }

  List<Widget> get _pages => [
    const HomePage(),
    const DiagnosticPage(),
    const MarketplacePage(),
    ConversationsListPage(
      key: ValueKey('conversations_$_unreadMessagesCount'),
      onConversationOpened: () {
        // Recharger le compteur après avoir ouvert une conversation
        _loadUnreadCount();
      },
    ),
    ProfilePage(key: ValueKey(_profileRebuildKey)),
  ];

  void _onItemTapped(int index) {
    setState(() {
      // Si on navigue vers le profil, incrémenter la clé pour forcer un rebuild complet
      if (index == 4 && _selectedIndex != 4) {
        _profileRebuildKey++;
      }
      // Si on navigue vers les messages, recharger le compteur
      if (index == 3) {
        _loadUnreadCount();
      }
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier l'état d'authentification pour déterminer les onglets visibles
    final isAuthenticated = _authService.isAuthenticated;
    
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: false, // Masquer les labels non sélectionnés
        selectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Diagnostic',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: _unreadMessagesCount > 0
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              _unreadMessagesCount > 99 ? '99+' : '$_unreadMessagesCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.chat),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
