/// Traductions françaises des noms de maladies
/// Ne modifie PAS les labels du modèle, juste l'affichage
class DiseaseTranslations {
  static const Map<String, String> frenchNames = {
    // Maladies du Maïs
    'Mais_Brulure': 'Plante atteinte de Brûlure foliaire',
    'Mais_Cercosporiose': 'Plante atteinte de Cercosporiose',
    'Mais_Rouille': 'Plante atteinte de Rouille commune',
    'Mais_Sain': 'Plante saine',
    
    // Maladies du Sorgho
    'Sorgho_Anthracnose': 'Plante atteinte d\'Anthracnose',
    'Sorgho_Rouille': 'Plante atteinte de Rouille',
    'Sorgho_Mildiou': 'Plante atteinte de Mildiou',
    'Sorgho_Sain': 'Plante saine',

    // Hors Sujet / Non reconnu
    'Hors_Sujet': 'Image non reconnue comme une plante.\nVeuillez réessayer.',
    'Background': 'Image non reconnue.\nVeuillez cadrer une plante.',
  };

  /// Traduit un nom de maladie en français
  /// Si pas de traduction trouvée, retourne le nom original
  static String translate(String diseaseName) {
    // Nettoyage préventif des noms (parfois le modèle ajoute des espaces)
    String cleanName = diseaseName.trim();
    
    // Correspondance exacte
    if (frenchNames.containsKey(cleanName)) {
      return frenchNames[cleanName]!;
    }

    // Gestion des "préfixes" si le modèle change
    if (cleanName.contains('Rouille')) return 'Plante atteinte de Rouille';
    if (cleanName.contains('Brulure') || cleanName.contains('Blight')) return 'Plante atteinte de Brûlure';
    if (cleanName.contains('Sain') || cleanName.contains('Healthy')) return 'Plante saine';
    
    return cleanName;
  }

  /// Obtient toutes les traductions disponibles
  static Map<String, String> getAllTranslations() {
    return Map.unmodifiable(frenchNames);
  }

  /// Vérifie si une traduction existe
  static bool hasTranslation(String diseaseName) {
    return frenchNames.containsKey(diseaseName.trim());
  }
}
