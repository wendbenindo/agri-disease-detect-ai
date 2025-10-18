import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:agri_desease_detect_app/services/model_update_service.dart';
import 'package:agri_desease_detect_app/utils/app_data.dart';
import 'image_analyse_module.dart';

class DiagnosticPage extends StatefulWidget {
  final File? initialImage;

  const DiagnosticPage({super.key, this.initialImage});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  File? _selectedImage;
  List<File> _history = [];
  final ModelUpdateService _modelUpdateService = ModelUpdateService();

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _selectedImage = widget.initialImage;
      _history.add(widget.initialImage!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _selectedImage = imageFile;
        _history.add(imageFile);
      });
    }
  }

  void _startAnalysis() {
    if (_selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageAnalysisModule(image: _selectedImage!),
        ),
      );
    }
  }

  void _removeFromHistory(int index) {
    setState(() {
      _history.removeAt(index);
    });
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Historique des diagnostics',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14532D))),
              const SizedBox(height: 12),
              _history.isEmpty
                  ? const Text('Aucun diagnostic pour le moment.')
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Image.file(_history[index], width: 50, height: 50, fit: BoxFit.cover),
                            title: Text('Image ${index + 1}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFromHistory(index),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _showCultureSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sélectionner la culture',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...cultures.map((c) => ListTile(
                      leading: Image.asset(c['image']!, width: 40, height: 40, fit: BoxFit.cover),
                      title: Text(c['nom']!),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _onSelectCulture(c);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSelectCulture(Map<String, String> culture) async {
    final name = culture['nom'] ?? '';
    final type = _normalizePlantFromName(name);
    await _modelUpdateService.setCurrentPlantType(type);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Culture active: $name')),
    );
    final results = await Connectivity().checkConnectivity();
    if (!results.contains(ConnectivityResult.none)) {
      await _modelUpdateService.checkForUpdatesUsingCurrentPlant();
      if (_modelUpdateService.isUpdateAvailable.value) {
        await _modelUpdateService.showUpdateDialog(context);
      }
    }
  }

  String _normalizePlantFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('maïs') || lower.contains('mais')) return 'mais';
    if (lower.contains('mil')) return 'mil';
    if (lower.contains('sorgho')) return 'sorgho';
    return lower;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diagnostic',
          style: TextStyle(
            color: Color(0xFF14532D),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF14532D)),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.agriculture),
            tooltip: 'Changer de culture/modèle',
            onPressed: _showCultureSelector,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryModal,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Analyse de votre culture',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14532D),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image_outlined, size: 60, color: Colors.green),
                    ),
            ),
            const SizedBox(height: 24),
            const Text('Options disponibles :',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_back, color: Colors.white),
                  label: const Text('Caméra'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14532D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galerie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF14532D),
                    side: const BorderSide(color: Color(0xFF14532D)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Résultat du diagnostic',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _selectedImage != null
                    ? 'Image prête pour analyse.'
                    : 'Aucune image analysée pour le moment.',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedImage != null)
              ElevatedButton.icon(
                onPressed: _startAnalysis,
                icon: const Icon(Icons.science, color: Colors.white),
                label: const Text("Lancer l'analyse"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
