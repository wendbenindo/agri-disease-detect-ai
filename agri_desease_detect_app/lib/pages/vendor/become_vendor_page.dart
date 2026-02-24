import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/vendor_service.dart';
import '../../services/auth_service.dart';
import '../auth/auth_page.dart';

class BecomeVendorPage extends StatefulWidget {
  const BecomeVendorPage({super.key});

  @override
  State<BecomeVendorPage> createState() => _BecomeVendorPageState();
}

class _BecomeVendorPageState extends State<BecomeVendorPage> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();
  final _authService = AuthService();

  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _hasExistingRequest = false;
  String? _existingRequestStatus;
  String _completePhoneNumber = ''; // Numéro complet avec indicatif

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    if (!_authService.isAuthenticated) return;

    final request = await _vendorService.getMyVendorRequest();
    if (request != null) {
      setState(() {
        _hasExistingRequest = true;
        _existingRequestStatus = request.status;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier l'authentification
    if (!_authService.isAuthenticated) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      if (result != true) return;
    }

    setState(() => _isLoading = true);

    try {
      await _vendorService.createVendorRequest(
        businessName: _businessNameController.text.trim(),
        phone: _completePhoneNumber, // Utiliser le numéro complet
        city: _cityController.text.trim(),
        region: _regionController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      appBar: AppBar(
        title: const Text('Devenir vendeur'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _hasExistingRequest
          ? _buildExistingRequestView()
          : _buildRequestForm(),
    );
  }

  Widget _buildExistingRequestView() {
    IconData icon;
    Color color;
    String title;
    String message;

    switch (_existingRequestStatus) {
      case 'pending':
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        title = 'Demande en attente';
        message =
            'Votre demande est en cours de traitement. Vous recevrez une notification une fois qu\'elle sera examinée.';
        break;
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'Demande approuvée';
        message =
            'Félicitations ! Votre demande a été approuvée. Vous pouvez maintenant publier des produits.';
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        title = 'Demande refusée';
        message =
            'Votre demande a été refusée. Veuillez contacter l\'administrateur pour plus d\'informations.';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        title = 'Statut inconnu';
        message = 'Statut de la demande inconnu.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade900],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.store, size: 60, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Devenez vendeur',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Remplissez ce formulaire pour demander à devenir vendeur sur notre plateforme',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Nom de l'entreprise
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Nom de l\'entreprise *',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le nom de votre entreprise';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Téléphone avec sélecteur de pays
            IntlPhoneField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone *',
                hintText: '70 00 00 00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              initialCountryCode: 'BF', // Burkina Faso par défaut
              onChanged: (phone) {
                _completePhoneNumber = phone.completeNumber;
              },
              invalidNumberMessage: 'Numéro invalide',
              dropdownIconPosition: IconPosition.trailing,
              flagsButtonPadding: const EdgeInsets.only(left: 12),
              showCountryFlag: true,
              showDropdownIcon: true,
              dropdownTextStyle: const TextStyle(fontSize: 16),
              validator: (phone) {
                if (phone == null || phone.completeNumber.isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Ville
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Ville *',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre ville';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Région
            TextFormField(
              controller: _regionController,
              decoration: InputDecoration(
                labelText: 'Région *',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre région';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description (optionnel)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description de votre activité (optionnel)',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Décrivez brièvement votre activité...',
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Bouton de soumission
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Envoyer la demande',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Votre demande sera examinée par notre équipe. Vous recevrez une notification une fois qu\'elle sera traitée.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                      ),
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
