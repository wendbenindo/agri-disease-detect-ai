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

  void _showModelSelector() async {
    final models = await _modelUpdateService.listLocalModels();
    if (!mounted) return;
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
                const Text('Sélectionner un modèle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (models.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Aucun modèle local. Vérifiez les mises à jour.'),
                  )
                else
                  ...models.map((m) => ListTile(
                        leading: const Icon(Icons.memory),
                        title: Text(m.name),
                        subtitle: Text('v${m.version}'),
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _modelUpdateService.setCurrentModel(path: m.path, version: m.version);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Modèle sélectionné: ${m.name}')),
                          );
                        },
                      )),
              ],
            ),
          ),
        );
      },
    );
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
            icon: const Icon(Icons.model_training),
            tooltip: 'Sélectionner modèle',
            onPressed: _showModelSelector,
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
