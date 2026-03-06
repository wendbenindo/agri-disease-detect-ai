import 'package:flutter/material.dart';
import '../../services/verification_service.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'verify_phone_page.dart';
import 'auth_page.dart';

/// Page qui vérifie si l'utilisateur a une vérification en attente
class PendingVerificationPage extends StatefulWidget {
  const PendingVerificationPage({super.key});

  @override
  State<PendingVerificationPage> createState() => _PendingVerificationPageState();
}

class _PendingVerificationPageState extends State<PendingVerificationPage> {
  final VerificationService _verificationService = VerificationService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _hasPendingVerification = false;
  String? _userId;
  String? _phoneNumber;
  String? _userName;
  String? _verificationMethod;

  @override
  void initState() {
    super.initState();
    _checkPendingVerification();
  }

  Future<void> _checkPendingVerification() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer les infos de l'utilisateur depuis SharedPreferences
      // (même s'il n'est pas connecté, on garde ces infos temporairement)
      final prefs = await SharedPreferences.getInstance();
      final tempUserId = prefs.getString('temp_verification_user_id');
      final tempPhone = prefs.getString('temp_verification_phone');
      final tempName = prefs.getString('temp_verification_name');

      if (tempUserId != null && tempPhone != null && tempName != null) {
        // Vérifier s'il y a un code actif
        final activeCode = await _verificationService.getActiveCode(tempUserId);
        
        if (activeCode != null) {
          setState(() {
            _hasPendingVerification = true;
            _userId = tempUserId;
            _phoneNumber = tempPhone;
            _userName = tempName;
            _verificationMethod = activeCode.verificationMethod;
            _isLoading = false;
          });
          return;
        }
      }

      // Pas de vérification en attente
      setState(() {
        _hasPendingVerification = false;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur vérification en attente: $e');
      setState(() {
        _hasPendingVerification = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _continueVerification() async {
    if (_userId != null && _phoneNumber != null && _userName != null && _verificationMethod != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyPhonePage(
            userId: _userId!,
            phoneNumber: _phoneNumber!,
            userName: _userName!,
            verificationMethod: _verificationMethod!,
          ),
        ),
      );
    }
  }

  Future<void> _cancelVerification() async {
    // Supprimer les infos temporaires
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_verification_user_id');
    await prefs.remove('temp_verification_phone');
    await prefs.remove('temp_verification_name');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasPendingVerification) {
      // Pas de vérification en attente, aller à la page de connexion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pending_actions,
                  size: 64,
                  color: Colors.orange.shade700,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Titre
              const Text(
                'Vérification en attente',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Text(
                'Vous avez une vérification en attente pour le numéro:',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Numéro
              Text(
                _phoneNumber ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Un code de vérification a été généré. Vous pouvez continuer la vérification ou créer un nouveau compte.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Bouton Continuer
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continueVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continuer la vérification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bouton Annuler
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _cancelVerification,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Créer un nouveau compte',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
