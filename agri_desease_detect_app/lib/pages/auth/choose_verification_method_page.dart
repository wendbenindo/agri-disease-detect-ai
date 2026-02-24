import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/verification_service.dart';
import 'verify_phone_page.dart';

class ChooseVerificationMethodPage extends StatefulWidget {
  final String userId;
  final String phoneNumber;
  final String userName;

  const ChooseVerificationMethodPage({
    super.key,
    required this.userId,
    required this.phoneNumber,
    required this.userName,
  });

  @override
  State<ChooseVerificationMethodPage> createState() =>
      _ChooseVerificationMethodPageState();
}

class _ChooseVerificationMethodPageState
    extends State<ChooseVerificationMethodPage> {
  final VerificationService _verificationService = VerificationService();
  bool _isLoading = false;

  Future<void> _selectMethod(String method) async {
    setState(() => _isLoading = true);

    try {
      // Sauvegarder les infos temporairement (pour pouvoir revenir)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_verification_user_id', widget.userId);
      await prefs.setString('temp_verification_phone', widget.phoneNumber);
      await prefs.setString('temp_verification_name', widget.userName);
      
      // Créer le code de vérification
      final code = await _verificationService.createVerificationCode(
        userId: widget.userId,
        phoneNumber: widget.phoneNumber,
        verificationMethod: method,
      );

      if (code != null && mounted) {
        // Naviguer vers la page de vérification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPhonePage(
              userId: widget.userId,
              phoneNumber: widget.phoneNumber,
              userName: widget.userName,
              verificationMethod: method,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de la génération du code'),
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
        setState(() => _isLoading = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Titre
                    const Text(
                      'Vérification du numéro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Sous-titre
                    Text(
                      'Comment souhaitez-vous recevoir votre code de vérification ?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Numéro
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Text(
                            widget.phoneNumber,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Bouton WhatsApp
                    _buildMethodButton(
                      icon: Icons.chat_bubble,
                      title: 'WhatsApp',
                      subtitle: 'Recevoir le code via WhatsApp',
                      color: Colors.green,
                      onTap: () => _selectMethod('whatsapp'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bouton SMS
                    _buildMethodButton(
                      icon: Icons.sms,
                      title: 'SMS',
                      subtitle: 'Recevoir le code par message simple',
                      color: Colors.blue,
                      onTap: () => _selectMethod('sms'),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Le code sera valide pendant 24 heures',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
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
    );
  }

  Widget _buildMethodButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
