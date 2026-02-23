import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/marketplace/product_repository.dart';
import '../../services/auth_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _photoUrlController = TextEditingController();
  
  final ProductRepository _repository = ProductRepository();
  final AuthService _authService = AuthService();
  
  String? _selectedCategoryId;
  List<Map<String, String>> _categories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.getAllCategories();
      setState(() {
        _categories = categories.map((c) => {
          'id': c.id,
          'name': c.name,
        }).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vendorId = _authService.currentUserId!;
      
      await _repository.addProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        vendorId: vendorId,
        photoUrl: _photoUrlController.text.trim().isEmpty 
            ? null 
            : _photoUrlController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty 
            ? null 
            : _dosageController.text.trim(),
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Produit ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un produit'),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du produit *',
                        hintText: 'Ex: Engrais NPK 15-15-15',
                        prefixIcon: const Icon(Icons.shopping_bag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer le nom';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Décrivez votre produit...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Prix
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Prix (FCFA) *',
                        hintText: '5000',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer le prix';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Prix invalide';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Catégorie
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Catégorie *',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat['id'],
                          child: Text(cat['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner une catégorie';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // URL Photo (optionnel)
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL de la photo (optionnel)',
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.image),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dosage (optionnel)
                    TextFormField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        labelText: 'Dosage recommandé (optionnel)',
                        hintText: 'Ex: 50g par litre d\'eau',
                        prefixIcon: const Icon(Icons.science),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Instructions (optionnel)
                    TextFormField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        labelText: 'Mode d\'emploi (optionnel)',
                        hintText: 'Instructions d\'utilisation...',
                        prefixIcon: const Icon(Icons.list_alt),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Bouton Enregistrer
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Enregistrer le produit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }
}
