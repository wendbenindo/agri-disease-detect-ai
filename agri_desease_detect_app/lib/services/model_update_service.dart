import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:agri_desease_detect_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart' as crypto;

// Un type de retour simple pour contenir les informations du modèle
class ModelInfo {
  final String version;
  final String path;
  final String labelsPath;

  ModelInfo({required this.version, required this.path, required this.labelsPath});
}

class LocalModel {
  final String name;
  final String path;
  final String version;
  LocalModel({required this.name, required this.path, required this.version});
}

class ModelUpdateService {
  static const String _currentVersionKey = 'current_model_version';
  static const String _currentPathKey = 'current_model_path';
  static const String _currentLabelsPathKey = 'current_model_labels_path';
  static const String _currentPlantTypeKey = 'current_plant_type';

  // Notifier pour l'interface graphique
  final ValueNotifier<bool> isUpdateAvailable = ValueNotifier<bool>(false);
  // Stockage des données du dernier modèle pour la boîte de dialogue
  Map<String, dynamic>? _latestModelData;

  /// Récupère les informations du modèle actuellement utilisé depuis SharedPreferences.
  Future<ModelInfo> getCurrentModelInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_currentVersionKey);
    final path = prefs.getString(_currentPathKey);
    final labelsPath = prefs.getString(_currentLabelsPathKey);

    if (version == null || path == null || labelsPath == null) {
      return ModelInfo(
        version: '1.0',
        path: 'assets/model/plant_disease_model.tflite',
        labelsPath: 'assets/model/labels.json',
      );
    }
    return ModelInfo(version: version, path: path, labelsPath: labelsPath);
  }

  /// Interroge Supabase pour obtenir les informations du dernier modèle actif.
  Future<Map<String, dynamic>?> getLatestModelInfo(String plantType) async {
    try {
      // Robustesse: en cas de plusieurs lignes actives, on prend la plus récente
      final response = await supabase
          .from('active_models')
          .select()
          .eq('plant_type', plantType)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("Erreur lors de la récupération du dernier modèle depuis Supabase: $e");
      return null;
    }
  }

  /// Compare les versions et met à jour le notifier si nécessaire.
  Future<void> checkForUpdates(String plantType) async {
    final ModelInfo currentModel = await getCurrentModelInfo();
    _latestModelData = await getLatestModelInfo(normalizePlantType(plantType));

    if (_latestModelData == null) {
      isUpdateAvailable.value = false;
      return;
    }

    final String latestVersion = (_latestModelData!['version'] as String?) ?? '';
    final String currentVersion = currentModel.version;

    if (_compareSemver(latestVersion, currentVersion) > 0) {
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
                downloadAndApplyUpdate(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Télécharge, vérifie, sauvegarde et active le nouveau modèle (et ses labels) pour usage offline.
  Future<void> downloadAndApplyUpdate(BuildContext context) async {
    if (_latestModelData == null) return;

    Uint8List? modelBytes;
    Uint8List? labelsBytes;
    String? modelPath;
    String? labelsPath;

    try {
      final String modelName = _latestModelData!['model_name'];
      final String labelsName = (_latestModelData!['labels_name'] as String?) ?? _inferLabelsNameFromModel(modelName);
      final String? expectedModelSha = (_latestModelData!['checksum_sha256'] as String?)?.toLowerCase();
      final String? expectedLabelsSha = (_latestModelData!['labels_checksum_sha256'] as String?)?.toLowerCase();

      debugPrint("Début du téléchargement du modèle: $modelName...");

      // Téléchargement du modèle
      modelBytes = await _downloadWithRetries('models', modelName);
      debugPrint("Téléchargement modèle terminé. Taille: ${modelBytes.lengthInBytes} bytes.");

      // Vérification checksum modèle (si fourni)
      if (expectedModelSha != null) {
        final gotSha = _sha256Hex(modelBytes);
        if (gotSha != expectedModelSha) {
          throw Exception('Checksum modèle invalide. Attendu=$expectedModelSha, obtenu=$gotSha');
        }
      }

      // Téléchargement des labels (optionnel mais recommandé)
      try {
        labelsBytes = await _downloadWithRetries('models', labelsName);
        debugPrint("Téléchargement labels terminé (${labelsName}). Taille: ${labelsBytes.lengthInBytes} bytes.");

        if (labelsBytes != null && expectedLabelsSha != null) {
          final gotLabelsSha = _sha256Hex(labelsBytes);
          if (gotLabelsSha != expectedLabelsSha) {
            throw Exception('Checksum labels invalide. Attendu=$expectedLabelsSha, obtenu=$gotLabelsSha');
          }
        }
      } catch (e) {
        debugPrint("Labels introuvables (${labelsName}) ou erreur labels: $e");
      }

      final dir = await getApplicationDocumentsDirectory();
      modelPath = '${dir.path}/$modelName';
      labelsPath = '${dir.path}/$labelsName';

      // Sauvegarde fichiers
      await File(modelPath).writeAsBytes(modelBytes);
      if (labelsBytes != null) {
        await File(labelsPath).writeAsBytes(labelsBytes);
      }
      debugPrint("Fichiers sauvegardés: model=$modelPath labels=${labelsBytes != null ? labelsPath : 'N/A'}");

      // Nettoyage des anciens fichiers si différents
      final prefs = await SharedPreferences.getInstance();
      final oldModelPath = prefs.getString(_currentPathKey);
      final oldLabelsPath = prefs.getString(_currentLabelsPathKey);
      if (oldModelPath != null && oldModelPath != modelPath) {
        try { await File(oldModelPath).delete(); } catch (_) {}
      }
      if (oldLabelsPath != null && labelsBytes != null && oldLabelsPath != labelsPath) {
        try { await File(oldLabelsPath).delete(); } catch (_) {}
      }

      // Mise à jour préférences (après succès complet)
      await prefs.setString(_currentVersionKey, _latestModelData!['version']);
      await prefs.setString(_currentPathKey, modelPath);
      if (labelsBytes != null) {
        await prefs.setString(_currentLabelsPathKey, labelsPath!);
      }

      isUpdateAvailable.value = false; // Cacher la bannière après la mise à jour
      debugPrint("Mise à jour terminée. Le modèle ${_latestModelData!['version']} est maintenant actif.");
      _showSnack(context, 'Modèle mis à jour en version ${_latestModelData!['version']}');
    } catch (e) {
      // Rollback: supprime les fichiers partiellement écrits
      if (modelPath != null) {
        try { await File(modelPath).delete(); } catch (_) {}
      }
      if (labelsPath != null) {
        try { await File(labelsPath).delete(); } catch (_) {}
      }
      debugPrint("Erreur lors du téléchargement ou de l'application du modèle: $e");
      _showSnack(context, 'Échec de la mise à jour du modèle. Veuillez réessayer.');
    }
  }

  /// Variante: utilise un modèle global (pas de culture)
  Future<void> checkForUpdatesGlobal() async {
    await checkForUpdates('global');
  }

  /// Variante: utilise le plantType enregistré (conservée pour compat)
  Future<void> checkForUpdatesUsingCurrentPlant() async {
    final type = await getCurrentPlantType();
    await checkForUpdates(type);
  }

  /// Persist/Read plant type
  Future<void> setCurrentPlantType(String plantType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentPlantTypeKey, normalizePlantType(plantType));
  }

  Future<String> getCurrentPlantType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentPlantTypeKey) ?? 'global';
  }

  String normalizePlantType(String input) {
    // Mode global: on ignore l'input et on renvoie 'global'
    return 'global';
  }

  void _showSnack(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {}
  }

  String _sha256Hex(Uint8List bytes) {
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  /// Compare deux versions sémantiques (ex: 2.1.0 > 2.0.9). Retourne -1, 0, 1.
  int _compareSemver(String a, String b) {
    List<int> parse(String v) {
      final parts = v.split(RegExp(r'[^0-9]+')).where((e) => e.isNotEmpty).toList();
      final nums = parts.map((e) => int.tryParse(e) ?? 0).toList();
      while (nums.length < 3) nums.add(0);
      return nums.take(3).toList();
    }

    final aa = parse(a);
    final bb = parse(b);
    for (int i = 0; i < 3; i++) {
      if (aa[i] != bb[i]) return aa[i] > bb[i] ? 1 : -1;
    }
    return 0;
  }

  /// Télécharge un fichier Supabase avec retries et backoff exponentiel + jitter.
  Future<Uint8List> _downloadWithRetries(
    String bucket,
    String path, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await supabase.storage.from(bucket).download(path);
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) rethrow;
        final backoff = initialDelay * math.pow(2, attempt - 1).toInt();
        // jitter +/- 30%
        final jitterFactor = 0.7 + math.Random().nextDouble() * 0.6;
        final delay = Duration(milliseconds: (backoff.inMilliseconds * jitterFactor).round());
        debugPrint('Téléchargement échoué (tentative $attempt/$maxRetries) pour $path: $e. Nouvelle tentative dans ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      }
    }
  }

  /// Liste les modèles .tflite présents en local (Documents)
  Future<List<LocalModel>> listLocalModels() async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory(dir.path);
    if (!await d.exists()) return [];
    final files = await d.list().toList();
    final models = <LocalModel>[];
    for (final f in files) {
      if (f is File && f.path.endsWith('.tflite')) {
        final name = f.uri.pathSegments.isNotEmpty ? f.uri.pathSegments.last : f.path;
        // tente d'extraire une version simple depuis le nom (ex: _v1_2 -> 1.2)
        final versionMatch = RegExp(r'v(\d+)[._](\d+)').firstMatch(name);
        final version = versionMatch != null ? '${versionMatch.group(1)}.${versionMatch.group(2)}' : 'local';
        models.add(LocalModel(name: name, path: f.path, version: version));
      }
    }
    return models;
  }

  /// Définit un modèle local comme actif
  Future<void> setCurrentModel({required String path, required String version, String? labelsPath}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentPathKey, path);
    await prefs.setString(_currentVersionKey, version);
    if (labelsPath != null) {
      await prefs.setString(_currentLabelsPathKey, labelsPath);
    }
  }

  /// Supprime les anciens fichiers modèles/labels non utilisés (orphelins)
  Future<void> cleanupOrphanModelFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentModel = prefs.getString(_currentPathKey);
      final currentLabels = prefs.getString(_currentLabelsPathKey);
      final dir = await getApplicationDocumentsDirectory();
      final d = Directory(dir.path);
      if (!await d.exists()) return;
      final files = await d.list().toList();
      for (final f in files) {
        if (f is File) {
          final p = f.path;
          final isModel = p.endsWith('.tflite');
          final isLabels = p.endsWith('.labels.json') || p.endsWith('labels.json');
          if ((isModel || isLabels) && p != currentModel && p != currentLabels) {
            try { await f.delete(); } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }
  /// Récupère la liste des labels actuelle (depuis fichier local ou asset)
  Future<List<String>> getCurrentLabels() async {
    try {
      final info = await getCurrentModelInfo();
      if (info.labelsPath.startsWith('assets/')) {
        final content = await rootBundle.loadString(info.labelsPath);
        return _parseLabelsContent(content);
      } else {
        final file = File(info.labelsPath);
        final content = await file.readAsString();
        return _parseLabelsContent(content);
      }
    } catch (e) {
      debugPrint('Erreur de chargement des labels: $e');
      // Fallback minimal
      return const [
        'Healthy',
        'Maize Leaf Spot',
        'Maize Streak',
        'Mil Sorgho',
        'Sorghum Blight',
        'Sorghum Rust',
      ];
    }
  }

  List<String> _parseLabelsContent(String content) {
    // Support JSON array ["a","b"] ou texte avec séparateur par ligne
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // ignore JSON errors, try newline
    }
    return content
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String _inferLabelsNameFromModel(String modelName) {
    if (modelName.endsWith('.tflite')) {
      return modelName.replaceAll(RegExp(r'\.tflite$'), '.labels.json');
    }
    return '$modelName.labels.json';
  }
}
