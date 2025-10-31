// File: lib/widgets/splash_screen.dart
import 'package:agri_desease_detect_app/main.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/splash_bg.mp4')
      ..setVolume(0.0)
      ..initialize().then((_) {
        if (mounted && !_isDisposed) {
          setState(() {});
          _controller.setLooping(true);
          _controller.play();
        }
      });

    Timer(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NavigationController()),
        );
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vidéo en arrière-plan
          _controller.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : Container(color: Colors.black),

          // Overlay léger
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          // Card blanche en bas avec logo + texte
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo TipTiga
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/tiptiga.png',
                      width: 70,
                      height: 70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nom de l'application
                  const Text(
                    'TipTiga',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  const Text(
                    'Votre assistant agricole intelligent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
