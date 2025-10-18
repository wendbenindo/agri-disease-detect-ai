/// Traductions françaises des noms de maladies
/// Ne modifie PAS les labels du modèle, juste l'affichage
class DiseaseTranslations {
  static const Map<String, String> frenchNames = {
    // Maladies
    'Healthy': 'Sain',
    'Maize Leaf Spot': 'Tache foliaire du maïs',
    'Maize Streak': 'Striure du maïs',
    'Mil Sorgho': 'Mil Sorgho',
    'Sorghum Blight': 'Brûlure du sorgho',
    'Sorghum Rust': 'Rouille du sorgho',
    
    // Vous pouvez ajouter d'autres maladies ici
    'Bacterial Blight': 'Brûlure bactérienne',
    'Gray Leaf Spot': 'Tache grise des feuilles',
    'Northern Corn Leaf Blight': 'Helminthosporiose',
    'Common Rust': 'Rouille commune',
  };

  /// Traduit un nom de maladie en français
  /// Si pas de traduction trouvée, retourne le nom original
  static String translate(String diseaseName) {
    return frenchNames[diseaseName] ?? diseaseName;
  }

  /// Obtient toutes les traductions disponibles
  static Map<String, String> getAllTranslations() {
    return Map.unmodifiable(frenchNames);
  }

  /// Vérifie si une traduction existe
  static bool hasTranslation(String diseaseName) {
    return frenchNames.containsKey(diseaseName);
  }
}
