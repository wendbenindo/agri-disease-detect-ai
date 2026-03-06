import 'dart:io';
import 'package:agri_desease_detect_app/pages/diagnosticpage.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agri_desease_detect_app/services/weather_service.dart';
import 'package:agri_desease_detect_app/services/model_update_service.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:agri_desease_detect_app/model/weather_model.dart';
import 'package:agri_desease_detect_app/utils/app_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ModelUpdateService _modelUpdateService = ModelUpdateService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  WeatherModel? _weather;
  bool _loading = false;
  bool _weatherError = false;
  String? _modelVersion;

  // Couleurs du thème - dominance blanche avec accent vert foncé
  static const Color primaryDarkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWeather();
    _initModelUpdateListener();
    _initConnectivityListener();
    // Nettoyage opportuniste des anciens fichiers
    _modelUpdateService.cleanupOrphanModelFiles();
    _loadActivePlantType();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) async {
      // Si on détecte une connexion et qu'il y avait une erreur météo, on réessaye.
      if (!result.contains(ConnectivityResult.none) && _weatherError) {
        _loadWeather();
      }
      // Relance un check de MAJ si on vient de se reconnecter
      if (!result.contains(ConnectivityResult.none)) {
        await _modelUpdateService.checkForUpdatesUsingCurrentPlant();
      }
    });
  }

  void _initModelUpdateListener() {
    _modelUpdateService.isUpdateAvailable.addListener(_onModelUpdate);
    // Offline-first: ne vérifie qu'en présence de connexion
    Connectivity().checkConnectivity().then((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        await _modelUpdateService.checkForUpdatesGlobal();
      }
    });
  }

  void _onModelUpdate() {
    // S'assure que le dialogue n'est affiché que si le widget est toujours monté
    if (mounted && _modelUpdateService.isUpdateAvailable.value) {
      _modelUpdateService.showUpdateDialog(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _modelUpdateService.isUpdateAvailable.removeListener(_onModelUpdate);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWeather();
    }
  }

  Future<void> _takePictureAndNavigate() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() => _loading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _loading = false);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiagnosticPage(initialImage: File(pickedFile.path)),
        ),
      );
    }
  }

  Future<void> _loadWeather() async {
    try {
      final weather = await WeatherService().fetchWeather();
      if (mounted) {
        setState(() {
          _weather = weather;
          _weatherError = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur météo : $e');
      if (mounted) {
        setState(() => _weatherError = true);
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo TipTiga
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryDarkGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/images/tiptiga.png',
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TipTiga',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: primaryDarkGreen,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // Groupe d'icônes à droite
          Row(
            children: [
              // Icône météo
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.wb_sunny_rounded, color: Colors.blue.shade700, size: 22),
                  onPressed: _showWeatherModal,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 12),
              // Icône MAJ modèle avec badge + état de téléchargement
              ValueListenableBuilder<bool>(
                valueListenable: _modelUpdateService.isUpdateAvailable,
                builder: (context, hasUpdate, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _modelUpdateService.isDownloading,
                    builder: (context, downloading, __) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.system_update_alt_rounded, size: 22),
                              color: Colors.orange.shade800,
                              tooltip: downloading ? 'Téléchargement en cours…' : 'Vérifier les mises à jour du modèle',
                              onPressed: downloading ? null : _manualCheckForUpdates,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          if (hasUpdate && !downloading)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (downloading)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 12),
              // Icône caméra
              Container(
                decoration: BoxDecoration(
                  color: primaryDarkGreen,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryDarkGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                  onPressed: _takePictureAndNavigate,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCulturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Cultures disponibles',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 130,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20),
            scrollDirection: Axis.horizontal,
            itemCount: cultures.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showCultureDetails(cultures[index]),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            cultures[index]['image']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 85,
                        child: Text(
                          cultures[index]['nom']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textPrimary,
                            fontFamily: 'SF Pro Text',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadActivePlantType() async {
    try {
      final info = await _modelUpdateService.getCurrentModelInfo();
      if (mounted) {
        setState(() {
          _modelVersion = info.version;
        });
      }
    } catch (_) {}
  }

  Widget _buildModelInfoBar() {
    final ver = _modelVersion ?? '—';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.agriculture, color: Color(0xFF1B5E20), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modèle: v$ver',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: _manualCheckForUpdates,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Vérifier'),
          )
        ],
      ),
    );
  }

  Future<void> _manualCheckForUpdates() async {
    if (_modelUpdateService.isDownloading.value) return;
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hors ligne. Reconnectez-vous pour vérifier.')),
        );
      }
      return;
    }
    await _modelUpdateService.checkForUpdatesGlobal();
    if (_modelUpdateService.isUpdateAvailable.value) {
      // Affiche le dialogue si une MAJ est disponible
      if (mounted) await _modelUpdateService.showUpdateDialog(context);
      // Après mise à jour potentielle, recharger meta
      await _loadActivePlantType();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune mise à jour disponible.')),
        );
      }
    }
  }

  Widget _buildCarouselSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Carousel des maladies
            CarouselSlider(
              options: CarouselOptions(
                height: 220,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                viewportFraction: 1.0,
                enlargeCenterPage: false,
              ),
              items: maladies.map((maladie) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      maladie['image']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              }).toList(),
            ),
            // Overlay "Comment ça marche"
            Positioned(
              bottom: 20,
              left: 60,
              right: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Comment ça marche ?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryDarkGreen,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStepIcon(Icons.camera_alt_rounded, 'Photo', primaryDarkGreen),
                        _buildArrow(),
                        _buildStepIcon(Icons.psychology_rounded, 'Analyse', Colors.blue.shade700),
                        _buildArrow(),
                        _buildStepIcon(Icons.medical_services_rounded, 'Soin', Colors.red.shade600),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            fontFamily: 'SF Pro Text',
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: 12,
      color: Colors.grey[400],
    );
  }

  Widget _buildMainActionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _takePictureAndNavigate,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkGreen,
          foregroundColor: Colors.white,
          elevation: 12,
          shadowColor: primaryDarkGreen.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_rounded, size: 26),
            const SizedBox(width: 12),
            Text(
              'Analyser une plante',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modal météo
  void _showWeatherModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(24),
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded, color: primaryDarkGreen, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Météo locale',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: primaryDarkGreen,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _weather != null
                            ? _buildWeatherCard()
                            : _weatherError
                                ? _buildWeatherError()
                                : _buildWeatherLoading(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryDarkGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: primaryDarkGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${_weather!.city}, ${_weather!.country}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: primaryDarkGreen,
                    fontFamily: 'SF Pro Display',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: primaryDarkGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  size: 36,
                  color: primaryDarkGreen,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weather!.temperature.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: primaryDarkGreen,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    Text(
                      'Ressenti ${_weather!.feelsLike.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 15,
                        color: textSecondary,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    Text(
                      _weather!.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'SF Pro Text',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfoTile(
                  Icons.air_rounded,
                  '${_weather!.windSpeed} m/s',
                  'Vent',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _buildWeatherInfoTile(
                  Icons.water_drop_rounded,
                  '${_weather!.humidity}%',
                  'Humidité',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _buildWeatherInfoTile(
                  Icons.visibility_rounded,
                  '${(_weather!.visibility / 1000).toStringAsFixed(1)} km',
                  'Visibilité',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfoTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: primaryDarkGreen),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: textPrimary,
            fontFamily: 'SF Pro Text',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
            fontFamily: 'SF Pro Text',
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherError() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Impossible de charger la météo. Vérifiez votre connexion internet et activez la localisation.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                "Réessayer",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Text',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDarkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherLoading() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: primaryDarkGreen,
          strokeWidth: 3,
        ),
      ),
    );
  }

  void _showCultureDetails(Map<String, dynamic> culture) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(26),
                      children: [
                        Center(
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.asset(
                                culture['image'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          culture['nom'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: primaryDarkGreen,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildSection("🌾 Description générale", culture['description']),
                        _buildSection("🌱 Physionomie", culture['physionomie']),
                        _buildSection("🌤️ Conditions idéales", culture['conditions']),
                        _buildSection("🦠 Maladies fréquentes", culture['maladies']),
                        _buildSection("🔍 Méthodes de détection", culture['tests']),
                        _buildSection("🧠 Conseils pratiques", culture['conseils']),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: primaryDarkGreen,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: textPrimary,
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
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildModelInfoBar()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                // Carrousel en premier
                SliverToBoxAdapter(child: _buildCarouselSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                // Bouton principal juste après le carrousel
                SliverToBoxAdapter(child: _buildMainActionButton()),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                // Cultures disponibles
                SliverToBoxAdapter(child: _buildCulturesList()),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: primaryDarkGreen,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}