import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/verification_service.dart';
import '../../services/auth_service.dart';
import '../../main.dart';

class VerifyPhonePage extends StatefulWidget {
  final String userId;
  final String phoneNumber;
  final String userName;
  final String verificationMethod;

  const VerifyPhonePage({
    super.key,
    required this.userId,
    required this.phoneNumber,
    required this.userName,
    required this.verificationMethod,
  });

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final VerificationService _verificationService = VerificationService();
  final AuthService _authService = AuthService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Le code doit contenir 6 chiffres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final isValid = await _verificationService.verifyCode(
        userId: widget.userId,
        code: _codeController.text,
      );

      if (isValid && mounted) {
        // Supprimer les infos temporaires
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('temp_verification_user_id');
        await prefs.remove('temp_verification_phone');
        await prefs.remove('temp_verification_name');
        
        // Connecter l'utilisateur automatiquement après vérification
        await _authService.loginAfterVerification(
          userId: widget.userId,
          phoneNumber: widget.phoneNumber,
          name: widget.userName,
          role: 'buyer', // Par défaut, nouveau compte = buyer
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Compte vérifié avec succès !'),
              backgroundColor: Colors.green,
            ),
          );

          // Attendre un peu pour que l'utilisateur voie le message
          await Future.delayed(const Duration(milliseconds: 500));

          // Rediriger vers la page principale
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const NavigationController()),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Code invalide ou expiré'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Icône
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.verificationMethod == 'whatsapp'
                        ? Icons.chat_bubble
                        : Icons.sms,
                    size: 48,
                    color: Colors.green,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Titre
              const Center(
                child: Text(
                  'Vérification en cours',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Center(
                child: Text(
                  'Un code de vérification a été généré pour',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Numéro
              Center(
                child: Text(
                  widget.phoneNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Info canal
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
                        'Vous recevrez le code par ${widget.verificationMethod == 'whatsapp' ? 'WhatsApp' : 'SMS'} sous peu',
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
              
              // Champ de saisie du code
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    letterSpacing: 8,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 6) {
                    _verifyCode();
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Bouton vérifier
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Vérifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const Spacer(),
              
              // Info expiration
              Center(
                child: Text(
                  'Le code expire dans 24 heures',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
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
