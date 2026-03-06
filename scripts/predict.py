#!/usr/bin/env python3
"""
"""

import os
import sys
import json
import argparse
import numpy as np
import tensorflow as tf

# Force UTF-8 output for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.imagenet_utils import preprocess_input
import matplotlib.pyplot as plt
import seaborn as sns
from PIL import Image, ImageEnhance, ImageFilter
import cv2
from pathlib import Path
import warnings
import logging
from datetime import datetime
import pandas as pd

# Configuration des warnings
warnings.filterwarnings('ignore')

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('prediction.log'),
        logging.StreamHandler()
    ]
)

class PlantDiseasePredictor:
    """
    Classe complète pour la prédiction optimisée de maladies de plantes
    avec préprocessing avancé et analyse détaillée
    """
    
    def __init__(self, model_path=None, metadata_path=None, confidence_threshold=0.5):
        """
        Initialise le prédicteur avec gestion d'erreurs robuste
        """
        self.model_path = model_path or self._find_model_path()
        self.metadata_path = metadata_path or self._find_metadata_path()
        self.confidence_threshold = confidence_threshold
        
        # Chargement des composants
        self.model = None
        self.class_names = None
        self.class_indices = None
        self.img_size = (224, 224)
        self.model_architecture = None
        
        # Initialisation
        self._load_model_and_metadata()
        self._setup_gpu()
        
        logging.info("🚀 Prédicteur initialisé avec succès")
    
    def _find_model_path(self):
        """Trouve automatiquement le chemin du modèle"""
        possible_paths = [
            '../model/plant_disease_model_optimized.h5',
            './model/plant_disease_model_optimized.h5',
            'model/plant_disease_model_optimized.h5'
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                return path
        
        raise FileNotFoundError("❌ Modèle non trouvé. Vérifiez le chemin.")
    
    def _find_metadata_path(self):
        """Trouve automatiquement le chemin des métadonnées"""
        possible_paths = [
            '../model/model_metadata.json',
            './model/model_metadata.json',
            'model/model_metadata.json'
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                return path
        
        raise FileNotFoundError("❌ Métadonnées non trouvées. Vérifiez le chemin.")
    
    def _setup_gpu(self):
        """Configuration GPU optimisée"""
        gpus = tf.config.experimental.list_physical_devices('GPU')
        if gpus:
            try:
                for gpu in gpus:
                    tf.config.experimental.set_memory_growth(gpu, True)
                logging.info(f"✅ GPU configuré: {len(gpus)} GPU(s)")
            except RuntimeError as e:
                logging.warning(f"⚠️ Erreur GPU: {e}")
        else:
            logging.info("💻 Utilisation du CPU")
    
    def _load_model_and_metadata(self):
        """Charge le modèle et les métadonnées avec gestion d'erreurs"""
        try:
            # Chargement du modèle
            logging.info(f"📥 Chargement du modèle: {self.model_path}")
            self.model = load_model(self.model_path)
            
            # Chargement des métadonnées
            logging.info(f"📥 Chargement des métadonnées: {self.metadata_path}")
            with open(self.metadata_path, 'r', encoding='utf-8') as f:
                metadata = json.load(f)
            
            # Extraction des informations
            self.class_indices = metadata['class_indices']
            self.class_names = [name for name, idx in 
                              sorted(self.class_indices.items(), key=lambda x: x[1])]
            self.img_size = tuple(metadata.get('img_size', (224, 224)))
            self.model_architecture = metadata.get('model_architecture', 'unknown')
            
            logging.info(f"✅ Modèle chargé: {len(self.class_names)} classes")
            logging.info(f"🏗️ Architecture: {self.model_architecture}")
            
        except Exception as e:
            logging.error(f"❌ Erreur lors du chargement: {e}")
            raise
    
    def _validate_image_path(self, img_path):
        """Valide le chemin de l'image"""
        if not os.path.exists(img_path):
            raise FileNotFoundError(f"❌ Image non trouvée: {img_path}")
        
        valid_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']
        if not any(img_path.lower().endswith(ext) for ext in valid_extensions):
            raise ValueError(f"❌ Format d'image non supporté: {img_path}")
        
        return True
    
    def _advanced_preprocessing(self, img_path):
        """
        Préprocessing avancé avec amélioration d'image
        """
        try:
            # Chargement de l'image
            img = Image.open(img_path).convert('RGB')
            
            # Amélioration de l'image
            img = self._enhance_image(img)
            
            # Redimensionnement intelligent
            img = self._smart_resize(img)
            
            # Conversion en array numpy
            img_array = np.array(img, dtype=np.float32)
            
            # Normalisation selon l'architecture du modèle
            if self.model_architecture in ['mobilenetv2', 'efficientnetb0']:
                img_array = (img_array / 127.5) - 1.0  # Normalisation [-1, 1]
            else:
                img_array = img_array / 255.0  # Normalisation [0, 1]
            
            # Ajout de la dimension batch
            img_array = np.expand_dims(img_array, axis=0)
            
            return img_array, img
            
        except Exception as e:
            logging.error(f"❌ Erreur préprocessing: {e}")
            raise
    
    def _enhance_image(self, img):
        """Améliore la qualité de l'image"""
        try:
            # Amélioration du contraste
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(1.2)
            
            # Amélioration de la netteté
            enhancer = ImageEnhance.Sharpness(img)
            img = enhancer.enhance(1.1)
            
            # Filtre de réduction du bruit
            img = img.filter(ImageFilter.SMOOTH_MORE)
            
            return img
            
        except Exception as e:
            logging.warning(f"⚠️ Erreur amélioration image: {e}")
            return img
    
    def _smart_resize(self, img):
        """Redimensionnement intelligent préservant l'aspect ratio"""
        try:
            # Calculer le ratio
            w, h = img.size
            target_w, target_h = self.img_size
            
            # Redimensionner en gardant le ratio
            if w/h > target_w/target_h:
                new_w = target_w
                new_h = int(h * target_w / w)
            else:
                new_h = target_h
                new_w = int(w * target_h / h)
            
            img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Padding pour atteindre la taille cible
            new_img = Image.new('RGB', (target_w, target_h), (0, 0, 0))
            paste_x = (target_w - new_w) // 2
            paste_y = (target_h - new_h) // 2
            new_img.paste(img, (paste_x, paste_y))
            
            return new_img
            
        except Exception as e:
            logging.warning(f"⚠️ Erreur redimensionnement: {e}")
            return img.resize(self.img_size, Image.Resampling.LANCZOS)
    
    def _analyze_predictions(self, predictions, top_k=5):
        """Analyse avancée des prédictions"""
        try:
            # Tri des prédictions
            sorted_indices = predictions.argsort()[::-1]
            
            # Calcul des statistiques
            max_confidence = np.max(predictions)
            entropy = -np.sum(predictions * np.log(predictions + 1e-10))
            
            # Classification de la certitude
            if max_confidence > 0.9:
                certainty = "Très élevée"
            elif max_confidence > 0.7:
                certainty = "Élevée"
            elif max_confidence > 0.5:
                certainty = "Modérée"
            else:
                certainty = "Faible"
            
            # Résultats Top-K
            results = []
            for i in range(min(top_k, len(sorted_indices))):
                idx = sorted_indices[i]
                confidence = predictions[idx]
                
                results.append({
                    'class': self.class_names[idx],
                    'confidence': float(confidence),
                    'percentage': f"{confidence * 100:.2f}%"
                })
            
            analysis = {
                'top_predictions': results,
                'max_confidence': float(max_confidence),
                'entropy': float(entropy),
                'certainty_level': certainty,
                'is_reliable': max_confidence > self.confidence_threshold
            }
            
            return analysis
            
        except Exception as e:
            logging.error(f"❌ Erreur analyse: {e}")
            raise
    
    def predict_single_image(self, img_path, show_details=True, save_results=False):
        """
        Prédiction complète pour une image unique
        """
        try:
            # Validation
            self._validate_image_path(img_path)
            
            logging.info(f"🔍 Analyse de l'image: {os.path.basename(img_path)}")
            
            # Préprocessing
            img_array, original_img = self._advanced_preprocessing(img_path)
            
            # Prédiction
            predictions = self.model.predict(img_array, verbose=0)[0]
            
            # Analyse des résultats
            analysis = self._analyze_predictions(predictions)
            
            # Affichage des résultats
            if show_details:
                self._display_results(img_path, analysis, original_img)
            
            # Sauvegarde des résultats
            if save_results:
                self._save_results(img_path, analysis)
            
            return analysis
            
        except Exception as e:
            logging.error(f"❌ Erreur prédiction: {e}")
            raise
    
    def _display_results(self, img_path, analysis, original_img):
        """Affiche les résultats de manière formatée"""
        print("\n" + "="*60)
        print(f"🖼️  IMAGE ANALYSÉE: {os.path.basename(img_path)}")
        print("="*60)
        
        # Prédiction principale
        top_pred = analysis['top_predictions'][0]
        print(f"🎯 PRÉDICTION PRINCIPALE:")
        print(f"   • Maladie: {top_pred['class']}")
        print(f"   • Confiance: {top_pred['percentage']}")
        print(f"   • Niveau de certitude: {analysis['certainty_level']}")
        
        # Fiabilité
        reliability = "✅ Fiable" if analysis['is_reliable'] else "⚠️ Peu fiable"
        print(f"   • Fiabilité: {reliability}")
        
        # Top 3 prédictions
        print(f"\n🔍 TOP 3 PRÉDICTIONS:")
        for i, pred in enumerate(analysis['top_predictions'][:3], 1):
            print(f"   {i}. {pred['class']} ({pred['percentage']})")
        
        # Statistiques avancées
        print(f"\n📊 STATISTIQUES:")
        print(f"   • Entropie: {analysis['entropy']:.3f}")
        print(f"   • Confiance max: {analysis['max_confidence']:.3f}")
        
        # Recommandations
        self._display_recommendations(analysis)
        
        print("="*60)
    
    def _display_recommendations(self, analysis):
        """Affiche des recommandations basées sur l'analyse"""
        print(f"\n💡 RECOMMANDATIONS:")
        
        if analysis['max_confidence'] > 0.9:
            print("   • Prédiction très fiable, vous pouvez avoir confiance")
        elif analysis['max_confidence'] > 0.7:
            print("   • Prédiction fiable, mais vérifiez avec d'autres sources")
        elif analysis['max_confidence'] > 0.5:
            print("   • Prédiction incertaine, consultez un expert")
        else:
            print("   • Prédiction peu fiable, image de mauvaise qualité ?")
            print("   • Essayez avec une image plus nette ou mieux éclairée")
    
    def _save_results(self, img_path, analysis):
        """Sauvegarde les résultats dans un fichier JSON"""
        try:
            results_dir = Path("results")
            results_dir.mkdir(exist_ok=True)
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"prediction_{timestamp}.json"
            
            result_data = {
                'timestamp': datetime.now().isoformat(),
                'image_path': img_path,
                'image_name': os.path.basename(img_path),
                'model_architecture': self.model_architecture,
                'analysis': analysis
            }
            
            with open(results_dir / filename, 'w', encoding='utf-8') as f:
                json.dump(result_data, f, indent=2, ensure_ascii=False)
            
            logging.info(f"💾 Résultats sauvegardés: {filename}")
            
        except Exception as e:
            logging.error(f"❌ Erreur sauvegarde: {e}")
    
    def predict_batch(self, image_folder, output_csv=None):
        """
        Prédiction par lot pour un dossier d'images
        """
        try:
            image_folder = Path(image_folder)
            if not image_folder.exists():
                raise FileNotFoundError(f"❌ Dossier non trouvé: {image_folder}")
            
            # Extensions supportées
            valid_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']
            image_files = []
            
            for ext in valid_extensions:
                image_files.extend(image_folder.glob(f"*{ext}"))
                image_files.extend(image_folder.glob(f"*{ext.upper()}"))
            
            if not image_files:
                raise ValueError("❌ Aucune image trouvée dans le dossier")
            
            logging.info(f"🔍 Traitement par lot: {len(image_files)} images")
            
            # Traitement des images
            results = []
            for i, img_path in enumerate(image_files, 1):
                try:
                    print(f"📸 Traitement {i}/{len(image_files)}: {img_path.name}")
                    
                    analysis = self.predict_single_image(
                        str(img_path), 
                        show_details=False, 
                        save_results=False
                    )
                    
                    # Préparer les données pour CSV
                    top_pred = analysis['top_predictions'][0]
                    results.append({
                        'image_name': img_path.name,
                        'predicted_class': top_pred['class'],
                        'confidence': top_pred['confidence'],
                        'percentage': top_pred['percentage'],
                        'certainty_level': analysis['certainty_level'],
                        'is_reliable': analysis['is_reliable']
                    })
                    
                except Exception as e:
                    logging.error(f"❌ Erreur image {img_path.name}: {e}")
                    results.append({
                        'image_name': img_path.name,
                        'predicted_class': 'ERROR',
                        'confidence': 0.0,
                        'percentage': '0.00%',
                        'certainty_level': 'Error',
                        'is_reliable': False
                    })
            
            # Sauvegarde CSV
            if output_csv:
                df = pd.DataFrame(results)
                df.to_csv(output_csv, index=False, encoding='utf-8')
                logging.info(f"📊 Résultats sauvegardés: {output_csv}")
            
            return results
            
        except Exception as e:
            logging.error(f"❌ Erreur traitement par lot: {e}")
            raise
    
    def visualize_prediction(self, img_path, save_plot=False):
        """
        Visualise la prédiction avec graphiques
        """
        try:
            # Prédiction
            analysis = self.predict_single_image(img_path, show_details=False)
            
            # Création du graphique
            fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
            
            # Image originale
            img = Image.open(img_path)
            ax1.imshow(img)
            ax1.set_title(f"Image: {os.path.basename(img_path)}")
            ax1.axis('off')
            
            # Graphique des prédictions
            top_5 = analysis['top_predictions'][:5]
            classes = [pred['class'] for pred in top_5]
            confidences = [pred['confidence'] for pred in top_5]
            
            bars = ax2.barh(classes, confidences)
            ax2.set_xlabel('Confiance')
            ax2.set_title('Top 5 Prédictions')
            ax2.set_xlim(0, 1)
            
            # Couleurs des barres
            for i, bar in enumerate(bars):
                if i == 0:
                    bar.set_color('green')
                else:
                    bar.set_color('lightblue')
            
            # Ajout des pourcentages
            for i, (class_name, confidence) in enumerate(zip(classes, confidences)):
                ax2.text(confidence + 0.01, i, f'{confidence*100:.1f}%', 
                        va='center', fontweight='bold')
            
            plt.tight_layout()
            
            if save_plot:
                plot_path = f"prediction_plot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
                plt.savefig(plot_path, dpi=300, bbox_inches='tight')
                logging.info(f"📊 Graphique sauvegardé: {plot_path}")
            
            plt.show()
            
        except Exception as e:
            logging.error(f"❌ Erreur visualisation: {e}")
            raise

def main():
    """Fonction principale avec interface CLI"""
    parser = argparse.ArgumentParser(description="Prédiction de maladies de plantes")
    parser.add_argument("image_path", help="Chemin vers l'image à analyser")
    parser.add_argument("--model", help="Chemin vers le modèle .h5")
    parser.add_argument("--metadata", help="Chemin vers les métadonnées JSON")
    parser.add_argument("--threshold", type=float, default=0.5, 
                       help="Seuil de confiance (défaut: 0.5)")
    parser.add_argument("--save", action="store_true", 
                       help="Sauvegarder les résultats")
    parser.add_argument("--visualize", action="store_true",
                       help="Afficher la visualisation")
    parser.add_argument("--batch", action="store_true",
                       help="Traitement par lot (dossier d'images)")
    parser.add_argument("--output", help="Fichier CSV de sortie pour le batch")
    
    args = parser.parse_args()
    
    try:
        # Initialisation du prédicteur
        predictor = PlantDiseasePredictor(
            model_path=args.model,
            metadata_path=args.metadata,
            confidence_threshold=args.threshold
        )
        
        if args.batch:
            # Traitement par lot
            results = predictor.predict_batch(args.image_path, args.output)
            print(f"\n✅ Traitement terminé: {len(results)} images")
        else:
            # Prédiction simple
            analysis = predictor.predict_single_image(
                args.image_path, 
                show_details=True, 
                save_results=args.save
            )
            
            if args.visualize:
                predictor.visualize_prediction(args.image_path, save_plot=args.save)
    
    except Exception as e:
        logging.error(f"❌ Erreur critique: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()