import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déconnexion réussie')),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _authService.isAuthenticated;
    final userName = _authService.currentUserName ?? 'Utilisateur';
    final userPhone = _authService.currentUserPhone ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: isAuthenticated
          ? ListView(
              children: [
                const SizedBox(height: 32),
                
                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.shade700,
                    child: Text(
                      userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Nom
                Center(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Téléphone
                Center(
                  child: Text(
                    userPhone,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                const Divider(),
                
                // Options
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Informations du compte'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Page édition profil
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Mes conversations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/conversations');
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text('Mes commandes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Page commandes
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Paramètres'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Page paramètres
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Aide & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Page aide
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('À propos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Page à propos
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Bouton Déconnexion
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Déconnexion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Non connecté',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour accéder à votre profil',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthPage()),
                      ).then((_) => setState(() {}));
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ),
    );
  }
}
