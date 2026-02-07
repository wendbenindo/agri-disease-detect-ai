/// Configuration du modèle de détection de maladies
class ModelConfig {
  /// Seuil de confiance minimum pour accepter une prédiction
  /// 
  /// - 0.60 (60%) : Équilibre entre précision et rappel (RECOMMANDÉ)
  /// - 0.70 (70%) : Plus strict, moins de faux positifs
  /// - 0.50 (50%) : Plus permissif, plus de détections
  static const double CONFIDENCE_THRESHOLD = 0.60;
  
  /// Seuil très bas pour détecter les images complètement hors sujet
  /// (ex: table, personne, ciel, etc.)
  static const double VERY_LOW_THRESHOLD = 0.30;
  
  /// Nombre de prédictions alternatives à afficher
  static const int TOP_K_PREDICTIONS = 3;
  
  /// Messages d'erreur personnalisés
  static String getRejectionMessage(double confidence) {
    if (confidence < VERY_LOW_THRESHOLD) {
      return 'Image non reconnue. Merci de prendre une plante en photo.';
    } else if (confidence < CONFIDENCE_THRESHOLD) {
      return 'Image floue ou non reconnue. Veuillez réessayer avec une plante bien visible.';
    }
    return 'Image non reconnue';
  }
  
  /// Conseils pour améliorer la détection
  static const String PHOTO_TIPS = '''
📸 Conseils pour une meilleure détection :

✅ Photographiez une feuille de près
✅ Assurez-vous d'un bon éclairage
✅ Évitez les photos floues
✅ Centrez la zone affectée
✅ Évitez les ombres importantes

❌ Évitez :
- Photos de loin
- Objets autres que des plantes
- Photos très sombres ou surexposées
''';
}
