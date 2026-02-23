import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../model/user_role.dart';
import '../auth/auth_page.dart';
import '../vendor/become_vendor_page.dart';
import '../admin/vendor_requests_page.dart';
import '../marketplace/add_product_page.dart';
import '../marketplace/manage_products_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final VendorService _vendorService = VendorService();
  
  UserRole? _userRole;
  bool _isLoadingRole = true;
  String? _vendorRequestStatus; // 'pending', 'approved', 'rejected', null

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    print('🔍 ProfilePage: _loadUserRole appelé');
    print('   - isAuthenticated: ${_authService.isAuthenticated}');
    
    if (!_authService.isAuthenticated) {
      print('❌ Utilisateur non authentifié');
      setState(() => _isLoadingRole = false);
      return;
    }

    print('✅ Utilisateur authentifié, récupération du rôle...');
    final role = await _vendorService.getCurrentUserRole();
    
    print('📊 Rôle récupéré: $role');
    if (role != null) {
      print('   - role.role: ${role.role}');
      print('   - role.isBuyer: ${role.isBuyer}');
      print('   - role.isVendor: ${role.isVendor}');
      print('   - role.isAdmin: ${role.isAdmin}');
    }
    
    // Vérifier s'il y a une demande de vendeur en attente
    String? requestStatus;
    if (role?.isBuyer == true) {
      final request = await _vendorService.getMyVendorRequest();
      requestStatus = request?.status;
      print('📋 Statut demande vendeur: $requestStatus');
    }
    
    setState(() {
      _userRole = role;
      _vendorRequestStatus = requestStatus;
      _isLoadingRole = false;
    });
    
    print('✅ État mis à jour: _userRole=${_userRole?.role}, _isLoadingRole=$_isLoadingRole, _vendorRequestStatus=$_vendorRequestStatus');
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Text('Déconnexion'),
          ],
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Déconnexion réussie'),
            backgroundColor: Colors.green,
          ),
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
      ),
      body: isAuthenticated
          ? SingleChildScrollView(
              child: Column(
                children: [
                  // Header avec gradient
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade700,
                          Colors.green.shade900,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        
                        // Avatar (taille réduite)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Text(
                              userName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Nom
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Téléphone (sans icône)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            userPhone,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons d'action selon le rôle
                  if (!_isLoadingRole) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Bouton Admin
                          if (_userRole?.isAdmin == true)
                            _buildActionButton(
                              icon: Icons.admin_panel_settings,
                              label: 'Panel Administrateur',
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VendorRequestsPage(),
                                  ),
                                );
                              },
                            ),
                          
                          // Bouton Vendeur - Ajouter un produit
                          if (_userRole?.isVendor == true) ...[
                            if (_userRole?.isAdmin == true) const SizedBox(height: 12),
                            _buildActionButton(
                              icon: Icons.add_business,
                              label: 'Ajouter un produit',
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddProductPage(),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                            ),
                          ],
                          
                          // Bouton Devenir vendeur (pour les buyers uniquement)
                          if (_userRole?.isBuyer == true) ...[
                            // Si demande en attente
                            if (_vendorRequestStatus == 'pending')
                              _buildPendingRequestButton()
                            // Si pas de demande ou demande rejetée
                            else if (_vendorRequestStatus == null || _vendorRequestStatus == 'rejected')
                              _buildActionButton(
                                icon: Icons.store,
                                label: _vendorRequestStatus == 'rejected' 
                                    ? 'Nouvelle demande vendeur' 
                                    : 'Devenir vendeur',
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BecomeVendorPage(),
                                    ),
                                  ).then((_) {
                                    _loadUserRole(); // Recharger le rôle
                                  });
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Statistiques
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.chat_bubble,
                            label: 'Messages',
                            value: '0',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.shopping_bag,
                            label: 'Commandes',
                            value: '0',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.favorite,
                            label: 'Favoris',
                            value: '0',
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Menu Options
                  _buildMenuSection(
                    title: 'Mon Compte',
                    items: [
                      _buildMenuItem(
                        icon: Icons.person,
                        title: 'Informations personnelles',
                        subtitle: 'Modifier vos informations',
                        onTap: () {
                          // TODO: Page édition profil
                        },
                      ),
                      if (_authService.isVendor)
                        _buildMenuItem(
                          icon: Icons.inventory,
                          title: 'Mes produits',
                          subtitle: 'Gérer mes produits',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageProductsPage(),
                              ),
                            );
                          },
                        ),
                      _buildMenuItem(
                        icon: Icons.chat,
                        title: 'Mes conversations',
                        subtitle: 'Voir tous vos messages',
                        onTap: () {
                          Navigator.pushNamed(context, '/conversations');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.shopping_bag,
                        title: 'Mes commandes',
                        subtitle: 'Historique des achats',
                        onTap: () {
                          // TODO: Page commandes
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.favorite,
                        title: 'Mes favoris',
                        subtitle: 'Produits sauvegardés',
                        onTap: () {
                          // TODO: Page favoris
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildMenuSection(
                    title: 'Paramètres',
                    items: [
                      _buildMenuItem(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Gérer les notifications',
                        onTap: () {
                          // TODO: Page notifications
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.language,
                        title: 'Langue',
                        subtitle: 'Français',
                        onTap: () {
                          // TODO: Page langue
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.security,
                        title: 'Sécurité',
                        subtitle: 'Mot de passe et sécurité',
                        onTap: () {
                          // TODO: Page sécurité
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildMenuSection(
                    title: 'Support',
                    items: [
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Aide & Support',
                        subtitle: 'Besoin d\'aide?',
                        onTap: () {
                          // TODO: Page aide
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'À propos',
                        subtitle: 'Version 1.0.0',
                        onTap: () {
                          // TODO: Page à propos
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton Déconnexion
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleSignOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Déconnexion'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Non connecté',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connectez-vous pour accéder à votre profil et profiter de toutes les fonctionnalités',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                        ).then((_) => setState(() {}));
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Se connecter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green.shade700, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildPendingRequestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null, // Désactivé
        icon: const Icon(Icons.hourglass_empty, size: 24),
        label: const Text(
          'Demande en attente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.grey.shade600,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
