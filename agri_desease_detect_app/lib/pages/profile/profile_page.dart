import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../model/user_role.dart';
import '../auth/auth_page.dart';
import '../vendor/become_vendor_page.dart';
import '../admin/vendor_requests_page.dart';
import '../admin/pending_verifications_page.dart';
import '../marketplace/add_product_page.dart';
import '../marketplace/manage_products_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();
  final VendorService _vendorService = VendorService();
  
  UserRole? _userRole;
  bool _isLoadingRole = true;
  String? _vendorRequestStatus; // 'pending', 'approved', 'rejected', null

  @override
  bool get wantKeepAlive => false; // Ne pas garder l'état, forcer le rebuild

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    
    // Écouter les changements d'état de l'app pour recharger si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserRole();
      }
    });
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger quand le widget est mis à jour
    print('🔄 ProfilePage: didUpdateWidget appelé');
    _loadUserRole();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger aussi quand les dépendances changent
    print('🔄 ProfilePage: didChangeDependencies appelé');
    if (mounted) {
      _loadUserRole();
    }
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Déconnexion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Déconnexion',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        // Réinitialiser l'état complètement
        setState(() {
          _userRole = null;
          _vendorRequestStatus = null;
          _isLoadingRole = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Déconnexion réussie'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important pour AutomaticKeepAliveClientMixin
    
    final isAuthenticated = _authService.isAuthenticated;
    final userName = _authService.currentUserName ?? 'Utilisateur';
    final userPhone = _authService.currentUserPhone ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: isAuthenticated 
          ? null  // Pas d'AppBar si connecté (on utilise extendBodyBehindAppBar)
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Profil',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
      extendBodyBehindAppBar: isAuthenticated,
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
                          Colors.green,
                          Colors.green.shade600,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                        child: Column(
                          children: [
                            // Avatar plus petit
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white,
                                child: Text(
                                  userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Nom
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Téléphone sans icône
                            Text(
                              userPhone,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons d'action selon le rôle
                  if (!_isLoadingRole) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Boutons Admin
                          if (_userRole?.isAdmin == true) ...[
                            _buildActionButton(
                              icon: Icons.admin_panel_settings,
                              label: 'Demandes vendeurs',
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VendorRequestsPage(),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 8),
                            
                            _buildActionButton(
                              icon: Icons.verified_user,
                              label: 'Vérifications en attente',
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PendingVerificationsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                          
                          // Bouton Vendeur - Ajouter un produit
                          if (_userRole?.isVendor == true) ...[
                            if (_userRole?.isAdmin == true) const SizedBox(height: 8),
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
                  
                  // Menu Options - Seulement les fonctionnalités actives
                  _buildMenuSection(
                    title: 'Mon Compte',
                    items: [
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
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton Déconnexion
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleSignOut,
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text(
                            'Déconnexion',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
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
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 80,
                        color: Colors.green.shade300,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Non connecté',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connectez-vous pour accéder à votre profil et profiter de toutes les fonctionnalités',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade300,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                          );
                          // Si connexion réussie, forcer un rebuild complet
                          if (result == true && mounted) {
                            setState(() {
                              _isLoadingRole = true;
                            });
                            await _loadUserRole();
                          }
                        },
                        icon: const Icon(Icons.login, size: 22),
                        label: const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
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
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              items.length,
              (index) => Column(
                children: [
                  items[index],
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                      color: Colors.grey.shade200,
                    ),
                ],
              ),
            ),
          ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.green, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequestButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_empty, size: 22),
          label: const Text(
            'Demande en attente',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade600,
            disabledBackgroundColor: Colors.grey.shade100,
            disabledForegroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
