import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/verification_service.dart';
import '../../model/pending_verification.dart';

class PendingVerificationsPage extends StatefulWidget {
  const PendingVerificationsPage({super.key});

  @override
  State<PendingVerificationsPage> createState() => _PendingVerificationsPageState();
}

class _PendingVerificationsPageState extends State<PendingVerificationsPage> {
  final VerificationService _verificationService = VerificationService();
  List<PendingVerification> _pendingVerifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingVerifications();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() => _isLoading = true);
    
    try {
      print('📋 Chargement des vérifications en attente...');
      final data = await _verificationService.getPendingVerifications();
      print('✅ Données reçues: ${data.length} vérifications');
      
      setState(() {
        _pendingVerifications = data
            .map((json) {
              try {
                final verification = PendingVerification.fromJson(json);
                print('✅ Vérification créée:');
                print('   - User: ${verification.userName}');
                print('   - Code final affiché: ${verification.code}');
                return verification;
              } catch (e) {
                print('❌ Erreur parsing vérification: $e');
                print('   JSON: $json');
                return null;
              }
            })
            .whereType<PendingVerification>() // Filtrer les null
            .toList();
        _isLoading = false;
      });
      
      print('✅ ${_pendingVerifications.length} vérifications chargées');
    } catch (e) {
      print('❌ Erreur chargement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Code copié dans le presse-papier'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendViaSMS(PendingVerification verification) async {
    final message = Uri.encodeComponent(
      'TipTiga, code d\'activation: ${verification.code}\n'
      'Valide pendant ${verification.hoursRemaining}h'
    );
    
    final phoneNumber = verification.phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    final smsUrl = 'sms:$phoneNumber?body=$message';
    
    try {
      final uri = Uri.parse(smsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        // Marquer comme envoyé après ouverture de l'app SMS
        await _markAsSent(verification.userId);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Impossible d\'ouvrir l\'application SMS'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur envoi SMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendViaWhatsApp(PendingVerification verification) async {
    final message = Uri.encodeComponent(
      'TipTiga, code d\'activation: ${verification.code}\n'
      'Valide pendant ${verification.hoursRemaining}h'
    );
    
    final phoneNumber = verification.phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$message';
    
    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Marquer comme envoyé après ouverture de WhatsApp
        await _markAsSent(verification.userId);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Impossible d\'ouvrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur envoi WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsSent(String userId) async {
    final success = await _verificationService.markCodeAsSent(userId);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Marqué comme envoyé'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _loadPendingVerifications(); // Recharger la liste
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Vérifications en attente'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingVerifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingVerifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune vérification en attente',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tous les utilisateurs sont vérifiés',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingVerifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingVerifications.length,
                    itemBuilder: (context, index) {
                      final verification = _pendingVerifications[index];
                      return _buildVerificationCard(verification);
                    },
                  ),
                ),
    );
  }

  Widget _buildVerificationCard(PendingVerification verification) {
    final isExpired = verification.isExpired;
    final hoursRemaining = verification.hoursRemaining;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpired ? Colors.red.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    verification.userName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Nom et numéro
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        verification.phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge canal
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: verification.verificationMethod == 'whatsapp'
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: verification.verificationMethod == 'whatsapp'
                          ? Colors.green.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        verification.methodIcon,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        verification.methodDisplayText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: verification.verificationMethod == 'whatsapp'
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Divider(color: Colors.grey.shade200),
            
            const SizedBox(height: 16),
            
            // Code de vérification
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code de vérification',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              verification.code,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                fontFamily: 'monospace',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () => _copyCode(verification.code),
                              tooltip: 'Copier le code',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Temps restant
            Row(
              children: [
                Icon(
                  isExpired ? Icons.error_outline : Icons.access_time,
                  size: 16,
                  color: isExpired ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired
                      ? 'Code expiré'
                      : hoursRemaining > 1
                          ? '$hoursRemaining heures restantes'
                          : 'Moins d\'1 heure restante',
                  style: TextStyle(
                    fontSize: 13,
                    color: isExpired ? Colors.red : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'envoi SMS/WhatsApp
            if (!verification.isSent)
              Row(
                children: [
                  // Bouton SMS
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isExpired
                          ? null
                          : () => _sendViaSMS(verification),
                      icon: const Text('📱', style: TextStyle(fontSize: 18)),
                      label: const Text('SMS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bouton WhatsApp
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isExpired
                          ? null
                          : () => _sendViaWhatsApp(verification),
                      icon: const Text('💬', style: TextStyle(fontSize: 18)),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Code envoyé',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
