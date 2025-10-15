import 'dart:io';
import 'dart:typed_data';
import 'package:agri_desease_detect_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Un type de retour simple pour contenir les informations du modèle
class ModelInfo {
  final String version;
  final String path;

  ModelInfo({required this.version, required this.path});
}

class ModelUpdateService {
  static const String _currentVersionKey = 'current_model_version';
  static const String _currentPathKey = 'current_model_path';

  // Notifier pour l'interface graphique
  final ValueNotifier<bool> isUpdateAvailable = ValueNotifier<bool>(false);
  // Stockage des données du dernier modèle pour la boîte de dialogue
  Map<String, dynamic>? _latestModelData;

  /// Récupère les informations du modèle actuellement utilisé depuis SharedPreferences.
  Future<ModelInfo> getCurrentModelInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_currentVersionKey);
    final path = prefs.getString(_currentPathKey);

    if (version == null || path == null) {
      return ModelInfo(version: '1.0', path: 'assets/model/plant_disease_model.tflite');
    }
    return ModelInfo(version: version, path: path);
  }

  /// Interroge Supabase pour obtenir les informations du dernier modèle actif.
  Future<Map<String, dynamic>?> getLatestModelInfo(String plantType) async {
    try {
      final response = await supabase
          .from('active_models')
          .select()
          .eq('plant_type', plantType)
          .eq('is_active', true)
          .single();
      return response;
    } catch (e) {
      debugPrint("Erreur lors de la récupération du dernier modèle depuis Supabase: $e");
      return null;
    }
  }

  /// Compare les versions et met à jour le notifier si nécessaire.
  Future<void> checkForUpdates(String plantType) async {
    final ModelInfo currentModel = await getCurrentModelInfo();
    _latestModelData = await getLatestModelInfo(plantType);

    if (_latestModelData == null) return;

    final String latestVersion = _latestModelData!['version'];
    final String currentVersion = currentModel.version;

    if (latestVersion.compareTo(currentVersion) > 0) {
      isUpdateAvailable.value = true;
    } else {
      isUpdateAvailable.value = false;
    }
  }

  /// Affiche la boîte de dialogue de mise à jour.
  Future<void> showUpdateDialog(BuildContext context) async {
    if (_latestModelData == null) {
        debugPrint("Aucune donnée de modèle à afficher dans le dialogue.");
        return;
    }

    final String newVersion = _latestModelData!['version'] ?? 'N/A';
    final String changelog = _latestModelData!['changelog'] ?? 'Aucune description.';
    final num? fileSize = _latestModelData!['file_size_mb'];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mise à jour disponible'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Une nouvelle version ($newVersion) du modèle est disponible.'),
                const SizedBox(height: 10),
                Text('Nouveautés : $changelog'),
                if (fileSize != null) ...[
                  const SizedBox(height: 10),
                  Text('Taille du téléchargement : ${fileSize.toStringAsFixed(1)} Mo'),
                ]
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Plus tard'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Télécharger'),
              onPressed: () {
                Navigator.of(context).pop();
                downloadAndApplyUpdate();
              },
            ),
          ],
        );
      },
    );
  }

  /// Télécharge, sauvegarde et active le nouveau modèle.
  Future<void> downloadAndApplyUpdate() async {
    if (_latestModelData == null) return;

    try {
      final String modelName = _latestModelData!['model_name'];
      debugPrint("Début du téléchargement du modèle: $modelName...");

      final Uint8List fileBytes = await supabase.storage.from('models').download(modelName);
      debugPrint("Téléchargement terminé. Taille: ${fileBytes.lengthInBytes} bytes.");

      final dir = await getApplicationDocumentsDirectory();
      final String filePath = '${dir.path}/$modelName';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      debugPrint("Modèle sauvegardé à l'emplacement: $filePath");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentVersionKey, _latestModelData!['version']);
      await prefs.setString(_currentPathKey, filePath);

      isUpdateAvailable.value = false; // Cacher la bannière après la mise à jour
      debugPrint("Mise à jour terminée. Le modèle ${_latestModelData!['version']} est maintenant actif.");
    } catch (e) {
      debugPrint("Erreur lors du téléchargement ou de l'application du modèle: $e");
    }
  }
}