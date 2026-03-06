import os
import json
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from sklearn.utils.class_weight import compute_class_weight
import matplotlib.pyplot as plt
from collections import Counter
import logging
from pathlib import Path

# Configuration du logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class PlantDiseasePreprocessor:
    """
    Classe complète pour le préprocessing des données de maladies de plantes
    avec toutes les bonnes pratiques pour un modèle performant.
    """
    
    def __init__(self, 
                 img_size=(224, 224), 
                 batch_size=32, 
                 validation_split=0.2,
                 random_seed=42):
        """
        Initialise le préprocesseur
        
        Args:
            img_size: Taille des images (hauteur, largeur)
            batch_size: Taille des batches
            validation_split: Proportion pour la validation
            random_seed: Graine pour la reproductibilité
        """
        self.img_size = img_size
        self.batch_size = batch_size
        self.validation_split = validation_split
        self.random_seed = random_seed
        
        # Configuration TensorFlow pour la reproductibilité
        tf.random.set_seed(self.random_seed)
        np.random.seed(self.random_seed)
        
        # Répertoires
        self.base_dir = Path(__file__).parent
        self.data_dir = self.base_dir.parent / 'data_split'
        self.output_dir = self.base_dir / 'preprocessing_output'
        self.output_dir.mkdir(exist_ok=True)
        
        # Attributs pour stocker les données
        self.class_indices = {}
        self.class_weights = {}
        self.num_classes = 0
        
    def validate_dataset_structure(self):
        """
        Valide la structure du dataset et affiche des statistiques
        """
        logger.info("Validation de la structure du dataset...")
        
        required_dirs = ['train', 'val', 'test']
        for dir_name in required_dirs:
            dir_path = self.data_dir / dir_name
            if not dir_path.exists():
                raise FileNotFoundError(f"Répertoire manquant: {dir_path}")
            
            # Compter les images par classe
            class_counts = {}
            for class_dir in dir_path.iterdir():
                if class_dir.is_dir():
                    image_count = len([f for f in class_dir.iterdir() 
                                     if f.suffix.lower() in ['.jpg', '.jpeg', '.png', '.bmp']])
                    class_counts[class_dir.name] = image_count
            
            logger.info(f"{dir_name.upper()} - Classes et nombre d'images: {class_counts}")
            
            # Vérifier les déséquilibres
            if class_counts:
                min_count = min(class_counts.values())
                max_count = max(class_counts.values())
                ratio = max_count / min_count if min_count > 0 else float('inf')
                
                if ratio > 10:
                    logger.warning(f"Déséquilibre important détecté dans {dir_name}: "
                                 f"ratio {ratio:.2f} (max: {max_count}, min: {min_count})")
                else:
                    logger.info(f"Équilibre des classes acceptable dans {dir_name}: ratio {ratio:.2f}")
    
    def create_advanced_data_generators(self):
        """
        Crée des générateurs de données avec augmentation avancée
        """
        logger.info("Création des générateurs de données avec augmentation...")
        
        # Générateur d'entraînement avec augmentation forte
        train_datagen = ImageDataGenerator(
            rescale=1./255,
            rotation_range=40,
            width_shift_range=0.2,
            height_shift_range=0.2,
            shear_range=0.2,
            zoom_range=0.2,
            horizontal_flip=True,
            vertical_flip=True,
            fill_mode='nearest',
            brightness_range=[0.8, 1.2],
            channel_shift_range=0.1
        )
        
        # Générateur de validation (seulement normalisation)
        val_datagen = ImageDataGenerator(rescale=1./255)
        
        # Générateur de test (seulement normalisation)
        test_datagen = ImageDataGenerator(rescale=1./255)
        
        # Chargement des données
        train_generator = train_datagen.flow_from_directory(
            self.data_dir / 'train',
            target_size=self.img_size,
            batch_size=self.batch_size,
            class_mode='categorical',
            shuffle=True,
            seed=self.random_seed
        )
        
        val_generator = val_datagen.flow_from_directory(
            self.data_dir / 'val',
            target_size=self.img_size,
            batch_size=self.batch_size,
            class_mode='categorical',
            shuffle=False
        )
        
        test_generator = test_datagen.flow_from_directory(
            self.data_dir / 'test',
            target_size=self.img_size,
            batch_size=self.batch_size,
            class_mode='categorical',
            shuffle=False
        )
        
        # Stocker les informations des classes
        self.class_indices = train_generator.class_indices
        self.num_classes = len(self.class_indices)
        
        logger.info(f"Données chargées - Classes: {self.num_classes}")
        logger.info(f"Mapping des classes: {self.class_indices}")
        
        return train_generator, val_generator, test_generator
    
    def calculate_class_weights(self, train_generator):
        """
        Calcule les poids des classes pour gérer les déséquilibres
        """
        logger.info("Calcul des poids des classes...")
        
        # Obtenir les labels de toutes les images d'entraînement
        labels = []
        for i in range(len(train_generator)):
            _, batch_labels = train_generator[i]
            labels.extend(np.argmax(batch_labels, axis=1))
        
        # Calculer les poids
        class_weights_array = compute_class_weight(
            'balanced',
            classes=np.unique(labels),
            y=labels
        )
        
        # Convertir en dictionnaire
        self.class_weights = dict(enumerate(class_weights_array))
        
        logger.info(f"Poids des classes calculés: {self.class_weights}")
        return self.class_weights
    
    def save_preprocessing_info(self, train_gen, val_gen, test_gen):
        """
        Sauvegarde les informations de préprocessing pour la reproductibilité
        """
        info = {
            'img_size': self.img_size,
            'batch_size': self.batch_size,
            'random_seed': self.random_seed,
            'class_indices': self.class_indices,
            'class_weights': self.class_weights,
            'num_classes': self.num_classes,
            'train_samples': train_gen.samples,
            'val_samples': val_gen.samples,
            'test_samples': test_gen.samples,
            'preprocessing_version': '1.0'
        }
        
        # Sauvegarder en JSON
        with open(self.output_dir / 'preprocessing_info.json', 'w') as f:
            json.dump(info, f, indent=2)
        
        logger.info(f"Informations sauvegardées dans {self.output_dir / 'preprocessing_info.json'}")
    
    def visualize_sample_images(self, train_generator, num_samples=8):
        """
        Visualise quelques images d'exemple avec leurs augmentations
        """
        logger.info("Création de visualisations d'exemple...")
        
        # Obtenir un batch d'images
        batch_images, batch_labels = next(train_generator)
        
        # Créer la figure
        fig, axes = plt.subplots(2, 4, figsize=(15, 8))
        fig.suptitle('Exemples d\'images avec augmentation', fontsize=16)
        
        # Obtenir les noms des classes
        class_names = {v: k for k, v in self.class_indices.items()}
        
        for i in range(min(num_samples, len(batch_images))):
            row = i // 4
            col = i % 4
            
            # Afficher l'image
            axes[row, col].imshow(batch_images[i])
            
            # Obtenir le label
            label_idx = np.argmax(batch_labels[i])
            class_name = class_names[label_idx]
            
            axes[row, col].set_title(f'Classe: {class_name}', fontsize=12)
            axes[row, col].axis('off')
        
        plt.tight_layout()
        plt.savefig(self.output_dir / 'sample_images.png', dpi=150, bbox_inches='tight')
        plt.close()
        
        logger.info(f"Visualisations sauvegardées dans {self.output_dir / 'sample_images.png'}")
    
    def create_data_analysis_report(self, train_gen, val_gen, test_gen):
        """
        Crée un rapport d'analyse des données
        """
        logger.info("Création du rapport d'analyse...")
        
        report = []
        report.append("="*50)
        report.append("RAPPORT D'ANALYSE DU DATASET")
        report.append("="*50)
        
        # Informations générales
        report.append(f"\nNombre total de classes: {self.num_classes}")
        report.append(f"Taille des images: {self.img_size}")
        report.append(f"Taille des batches: {self.batch_size}")
        
        # Distribution des données
        report.append(f"\n--- DISTRIBUTION DES DONNÉES ---")
        report.append(f"Images d'entraînement: {train_gen.samples}")
        report.append(f"Images de validation: {val_gen.samples}")
        report.append(f"Images de test: {test_gen.samples}")
        
        total_images = train_gen.samples + val_gen.samples + test_gen.samples
        report.append(f"Total: {total_images}")
        
        # Pourcentages
        train_pct = (train_gen.samples / total_images) * 100
        val_pct = (val_gen.samples / total_images) * 100
        test_pct = (test_gen.samples / total_images) * 100
        
        report.append(f"\nPourcentages:")
        report.append(f"  Entraînement: {train_pct:.1f}%")
        report.append(f"  Validation: {val_pct:.1f}%")
        report.append(f"  Test: {test_pct:.1f}%")
        
        # Poids des classes
        report.append(f"\n--- POIDS DES CLASSES ---")
        for class_idx, weight in self.class_weights.items():
            class_name = {v: k for k, v in self.class_indices.items()}[class_idx]
            report.append(f"  {class_name}: {weight:.3f}")
        
        # Recommandations
        report.append(f"\n--- RECOMMANDATIONS ---")
        if train_pct < 70:
            report.append("⚠️  Proportion d'entraînement faible (<70%). Considérez augmenter.")
        else:
            report.append("✅ Proportion d'entraînement appropriée.")
        
        if max(self.class_weights.values()) / min(self.class_weights.values()) > 3:
            report.append("⚠️  Déséquilibre important des classes. Poids calculés automatiquement.")
        else:
            report.append("✅ Classes relativement équilibrées.")
        
        # Sauvegarder le rapport
        with open(self.output_dir / 'analysis_report.txt', 'w', encoding='utf-8') as f:
            f.write('\n'.join(report))
        
        # Afficher le rapport
        print('\n'.join(report))
        
        logger.info(f"Rapport sauvegardé dans {self.output_dir / 'analysis_report.txt'}")
    
    def process_all(self):
        """
        Méthode principale qui exécute tout le préprocessing
        """
        logger.info("Début du préprocessing complet...")
        
        try:
            # 1. Valider la structure
            self.validate_dataset_structure()
            
            # 2. Créer les générateurs
            train_gen, val_gen, test_gen = self.create_advanced_data_generators()
            
            # 3. Calculer les poids des classes
            self.calculate_class_weights(train_gen)
            
            # 4. Sauvegarder les informations
            self.save_preprocessing_info(train_gen, val_gen, test_gen)
            
            # 5. Créer des visualisations
            self.visualize_sample_images(train_gen)
            
            # 6. Créer le rapport d'analyse
            self.create_data_analysis_report(train_gen, val_gen, test_gen)
            
            logger.info("Préprocessing terminé avec succès!")
            
            return train_gen, val_gen, test_gen, self.class_weights
            
        except Exception as e:
            logger.error(f"Erreur durant le préprocessing: {str(e)}")
            raise

# Fonctions utilitaires pour l'importation
def load_all_data(data_dir=None, img_size=(224, 224), batch_size=32):
    """
    Fonction simplifiée pour compatibilité avec l'ancien code
    """
    preprocessor = PlantDiseasePreprocessor(img_size=img_size, batch_size=batch_size)
    return preprocessor.process_all()

def get_class_weights(data_dir=None):
    """
    Fonction pour obtenir uniquement les poids des classes
    """
    preprocessor = PlantDiseasePreprocessor()
    train_gen, _, _, class_weights = preprocessor.process_all()
    return class_weights

# Exécution directe
if __name__ == "__main__":
    # Créer le préprocesseur
    preprocessor = PlantDiseasePreprocessor(
        img_size=(224, 224),
        batch_size=32,
        random_seed=42
    )
    
    # Exécuter tout le préprocessing
    train_generator, val_generator, test_generator, class_weights = preprocessor.process_all()
    
    print(f"\n🎉 Préprocessing terminé!")
    print(f"📊 Données prêtes pour l'entraînement du modèle")
    print(f"📁 Résultats sauvegardés dans: {preprocessor.output_dir}")