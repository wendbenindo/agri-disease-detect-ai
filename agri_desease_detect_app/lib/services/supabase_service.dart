import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fonction d'initialisation globale pour Supabase.
/// Doit être appelée dans le `main.dart` au démarrage de l'application.
Future<void> initSupabase() async {
  // Récupération des clés depuis le fichier .env
  final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  // Initialisation du client Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

/// Un getter global pour accéder facilement à l'instance du client Supabase
/// n'importe où dans l'application après son initialisation.
/// `Supabase.instance.client` gère le singleton pour nous.
SupabaseClient get supabase => Supabase.instance.client;
