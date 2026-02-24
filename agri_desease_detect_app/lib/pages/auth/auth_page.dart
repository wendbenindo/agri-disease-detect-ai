import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/auth_service.dart';
import 'choose_verification_method_page.dart';
import 'pending_verification_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isSignUp = true; // true = Créer compte, false = Se connecter
  bool _obscurePassword = true;
  String _completePhoneNumber = ''; // Numéro complet avec indicatif

  @override
  void initState() {
    super.initState();
    _checkPendingVerification();
  }

  Future<void> _checkPendingVerification() async {
    // Vérifier s'il y a une vérification en attente
    final prefs = await SharedPreferences.getInstance();
    final tempUserId = prefs.getString('temp_verification_user_id');
    
    if (tempUserId != null && mounted) {
      // Il y a une vérification en attente, rediriger
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingVerificationPage()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // Créer un nouveau compte
        print('📝 Création de compte...');
        final result = await _authService.signUp(
          phoneNumber: _completePhoneNumber, // Utiliser le numéro complet
          name: _nameController.text.trim(),
          password: _passwordController.text,
        );
        print('✅ Compte créé: $result');

        final userId = result['id'] as String;
        final phoneNumber = result['phone_number'] as String;
        final userName = result['name'] as String;

        if (mounted) {
          // Rediriger vers le choix du canal de vérification
          print('📱 Redirection vers choix du canal...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChooseVerificationMethodPage(
                userId: userId,
                phoneNumber: phoneNumber,
                userName: userName,
              ),
            ),
          );
        }
      } else {
        // Se connecter
        print('🔐 Connexion...');
        final result = await _authService.signIn(
          phoneNumber: _completePhoneNumber, // Utiliser le numéro complet
          password: _passwordController.text,
        );
        print('✅ Connecté: $result');

        if (mounted) {
          print('✅ Navigation retour avec succès');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('❌ Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isSignUp ? 'Créer un compte' : 'Connexion'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Icône
                Icon(
                  _isSignUp ? Icons.person_add : Icons.login,
                  size: 80,
                  color: Colors.green.shade700,
                ),
                
                const SizedBox(height: 24),
                
                // Titre
                Text(
                  _isSignUp 
                      ? 'Créez votre compte pour contacter les vendeurs'
                      : 'Connectez-vous pour continuer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Champ Nom (seulement pour inscription)
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Votre nom',
                      hintText: 'Ex: Abdoul Karim',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      if (value.trim().length < 2) {
                        return 'Le nom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Champ Téléphone avec sélecteur de pays
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: '70 00 00 00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  initialCountryCode: 'BF', // Burkina Faso par défaut
                  onChanged: (phone) {
                    _completePhoneNumber = phone.completeNumber;
                    print('📱 Numéro complet: $_completePhoneNumber');
                  },
                  invalidNumberMessage: 'Numéro invalide',
                  dropdownIconPosition: IconPosition.trailing,
                  flagsButtonPadding: const EdgeInsets.only(left: 12),
                  showCountryFlag: true,
                  showDropdownIcon: true,
                  dropdownTextStyle: const TextStyle(fontSize: 16),
                ),
                
                const SizedBox(height: 20),
                
                // Champ Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: _isSignUp ? 'Minimum 6 caractères' : 'Votre mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (_isSignUp && value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Bouton Principal
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isSignUp ? 'Créer mon compte' : 'Se connecter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Bouton Basculer
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _formKey.currentState?.reset();
                    });
                  },
                  child: Text(
                    _isSignUp 
                        ? 'Déjà un compte ? Se connecter'
                        : 'Pas de compte ? Créer un compte',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Note de sécurité
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre mot de passe est sécurisé et chiffré. Vous restez connecté jusqu\'à déconnexion.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
