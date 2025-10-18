import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:agri_desease_detect_app/services/model_update_service.dart';
import 'package:agri_desease_detect_app/widgets/theme.dart';

class ImageAnalysisModule extends StatefulWidget {
  final File image;

  const ImageAnalysisModule({super.key, required this.image});

  @override
  State<ImageAnalysisModule> createState() => _ImageAnalysisModuleState();
}

class _ImageAnalysisModuleState extends State<ImageAnalysisModule> {
  String _predictedClass = '';
  double _confidence = 0.0;
  List<MapEntry<String, double>> _topPredictions = [];
  bool _isLoading = true;
  int _currentStep = 0;
  String _modelVersion = '';
  int _inferenceTimeMs = 0;
  String? _errorMessage;

  List<String> _labels = [];
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _startAnalysisProcess();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<Interpreter> _loadInterpreter() async {
    final modelInfo = await ModelUpdateService().getCurrentModelInfo();
    setState(() => _modelVersion = modelInfo.version);
    try {
      if (modelInfo.path.startsWith('assets/')) {
        return Interpreter.fromAsset(modelInfo.path);
      } else {
        return Interpreter.fromFile(File(modelInfo.path));
      }
    } catch (_) {
      return Interpreter.fromAsset('assets/model/plant_disease_model.tflite');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labels = await ModelUpdateService().getCurrentLabels();
      if (mounted) setState(() => _labels = labels);
    } catch (_) {}
  }

  Future<void> _startAnalysisProcess() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentStep = 0;
    });
    try {
      await _loadLabels();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _currentStep = 1);
      await Future.delayed(const Duration(milliseconds: 500));
      await _analyzeImage();
      if (mounted) setState(() => _currentStep = 3);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de l\'analyse : $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _analyzeImage() async {
    final startTime = DateTime.now();
    try {
      _interpreter = await _loadInterpreter();

      final imageBytes = await widget.image.readAsBytes();
      img.Image? oriImage = img.decodeImage(imageBytes);
      if (oriImage == null) throw Exception("Image illisible");

      if (mounted) setState(() => _currentStep = 2);

      img.Image resizedImage = img.copyResize(oriImage, width: 224, height: 224);
      Float32List input = Float32List(224 * 224 * 3);
      int index = 0;

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[index++] = img.getRed(pixel) / 255.0;
          input[index++] = img.getGreen(pixel) / 255.0;
          input[index++] = img.getBlue(pixel) / 255.0;
        }
      }

      final inputBuffer = input.buffer.asFloat32List().reshape([1, 224, 224, 3]);
      final outShape = _interpreter!.getOutputTensor(0).shape;
      final int numClasses = outShape.isNotEmpty ? outShape.last : (_labels.isNotEmpty ? _labels.length : 6);
      final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);

      _interpreter!.run(inputBuffer, output);

      final endTime = DateTime.now();
      _inferenceTimeMs = endTime.difference(startTime).inMilliseconds;

      final result = List<double>.from(output[0]);
      final maxProb = result.reduce((a, b) => a > b ? a : b);
      final predictedIndex = result.indexOf(maxProb);

      // Top-3 predictions
      List<MapEntry<int, double>> indexed = [];
      for (int i = 0; i < result.length; i++) {
        indexed.add(MapEntry(i, result[i]));
      }
      indexed.sort((a, b) => b.value.compareTo(a.value));
      final top3 = indexed.take(3).toList();

      _topPredictions = top3.map((e) {
        String label = (_labels.isNotEmpty && e.key < _labels.length) ? _labels[e.key] : 'Classe ${e.key}';
        return MapEntry(label, e.value);
      }).toList();

      String predictedClass = (_labels.isNotEmpty && predictedIndex < _labels.length) ? _labels[predictedIndex] : 'Classe $predictedIndex';

      if (mounted) {
        setState(() {
          _predictedClass = predictedClass;
          _confidence = maxProb;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur pendant l\'analyse : $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStepperHorizontal() {
    final steps = [
      {'icon': Icons.image_rounded, 'label': 'Image'},
      {'icon': Icons.tune_rounded, 'label': 'Préparation'},
      {'icon': Icons.psychology_rounded, 'label': 'Analyse'},
      {'icon': Icons.check_circle_rounded, 'label': 'Résultat'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isCompleted = _currentStep > index;
        final isCurrent = _currentStep == index;
        final step = steps[index];

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? AppColors.successGreen : AppColors.lightGray,
                      ),
                    ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.successGreen
                          : isCurrent
                              ? AppColors.accentGreen
                              : AppColors.lightGray,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted || isCurrent ? Colors.transparent : AppColors.textSecondary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      color: isCompleted || isCurrent ? Colors.white : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? AppColors.successGreen : AppColors.lightGray,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  color: isCompleted || isCurrent ? AppColors.primaryDarkGreen : AppColors.textSecondary,
                  fontFamily: 'SF Pro Text',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildResultCard() {
    final String status = _confidence >= 0.8 ? 'Détection confirmée' : _confidence >= 0.5 ? 'À surveiller' : 'Incertain';
    final Color statusColor = _confidence >= 0.8 ? AppColors.successGreen : _confidence >= 0.5 ? AppColors.warningOrange : AppColors.errorRed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_rounded, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_modelVersion.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v$_modelVersion',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _predictedClass,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDarkGreen,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Confiance : ',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontFamily: 'SF Pro Text',
                ),
              ),
              Text(
                '${(_confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _confidence,
              minHeight: 10,
              backgroundColor: AppColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          if (_topPredictions.length > 1) ...[
            const SizedBox(height: 20),
            Text(
              'Autres prédictions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontFamily: 'SF Pro Text',
              ),
            ),
            const SizedBox(height: 10),
            ..._topPredictions.skip(1).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontFamily: 'SF Pro Text',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: e.value,
                            minHeight: 6,
                            backgroundColor: AppColors.lightGray,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen.withOpacity(0.6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(e.value * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (_inferenceTimeMs > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Temps d\'inférence : ${_inferenceTimeMs}ms',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorRed),
          const SizedBox(height: 12),
          Text(
            'Erreur d\'analyse',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.errorRed,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Une erreur inconnue s\'est produite',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _startAnalysisProcess,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retakePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ImageAnalysisModule(image: File(pickedFile.path)),
        ),
      );
    }
  }

  void _shareResult() {
    final text = 'TipTiga Analyse\n\nMaladie détectée : $_predictedClass\nConfiance : ${(_confidence * 100).toStringAsFixed(1)}%\nModèle : v$_modelVersion';
    Share.share(text, subject: 'Résultat d\'analyse TipTiga');
  }

  void _showAdviceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: AppColors.primaryDarkGreen, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Conseils de traitement',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDarkGreen,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildAdviceSection('🌿 Diagnostic', _predictedClass),
              _buildAdviceSection(
                '💊 Traitement recommandé',
                'Consultez un agronome pour un traitement adapté. En attendant, isolez les plants affectés et évitez l\'arrosage excessif.',
              ),
              _buildAdviceSection(
                '🛡️ Prévention',
                'Rotation des cultures, désinfection des outils, surveillance régulière des plants, aération suffisante.',
              ),
              _buildAdviceSection(
                '📞 Besoin d\'aide ?',
                'Contactez votre service agricole local ou rejoignez la communauté TipTiga pour plus de conseils.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDarkGreen,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse de l\'image'),
        actions: [
          if (!_isLoading && _errorMessage == null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Partager',
              onPressed: _shareResult,
            ),
        ],
      ),
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                widget.image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            // Stepper horizontal
            _buildStepperHorizontal(),
            const SizedBox(height: 28),

            // Result or loading
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryDarkGreen,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analyse en cours...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              )
            else if (_errorMessage != null)
              _buildErrorCard()
            else
              _buildResultCard(),

            // Actions
            if (!_isLoading && _errorMessage == null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retakePhoto,
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      label: const Text('Reprendre'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDarkGreen,
                        side: BorderSide(color: AppColors.primaryDarkGreen, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAdviceSheet,
                      icon: const Icon(Icons.medical_services_rounded, size: 20),
                      label: const Text('Conseils'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDarkGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
