"""
Convertisseur TensorFlow Lite optimisé pour modèles de détection de maladies de plantes
Avec quantification, optimisations avancées et tests de performance
"""

import os
import sys
import json
import argparse
import numpy as np
import tensorflow as tf
from pathlib import Path
import logging

# Force UTF-8 output for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')
from datetime import datetime
import matplotlib.pyplot as plt
from PIL import Image
import time
import psutil
import warnings

# Configuration des warnings
warnings.filterwarnings('ignore')

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('tflite_conversion.log'),
        logging.StreamHandler()
    ]
)

class TFLiteConverter:
    """
    Convertisseur TensorFlow Lite avancé avec optimisations complètes
    """
    
    def __init__(self, model_path=None, output_dir=None):
        """
        Initialise le convertisseur
        """
        self.model_path = model_path or self._find_model_path()
        self.output_dir = Path(output_dir) if output_dir else Path('../model')
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Vérifications
        self._validate_inputs()
        
        # Attributs
        self.original_model = None
        self.model_info = {}
        self.conversion_results = {}
        
        logging.info("🚀 Convertisseur TFLite initialisé")
    
    def _find_model_path(self):
        """Trouve automatiquement le modèle"""
        possible_paths = [
            '../model/plant_disease_model_optimized.h5',
            '../model/plant_disease_model.h5',
            './model/plant_disease_model_optimized.h5',
            './model/plant_disease_model.h5',
            'plant_disease_model_optimized.h5',
            'plant_disease_model.h5'
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                logging.info(f"✅ Modèle trouvé: {path}")
                return path
        
        raise FileNotFoundError("❌ Aucun modèle trouvé. Spécifiez le chemin avec --model")
    
    def _validate_inputs(self):
        """Valide les entrées"""
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"❌ Modèle non trouvé: {self.model_path}")
        
        # Vérifier l'extension
        if not self.model_path.endswith('.h5'):
            raise ValueError("❌ Le modèle doit être au format .h5")
        
        logging.info(f"✅ Validation réussie: {self.model_path}")
    
    def _load_model_info(self):
        """Charge les informations du modèle"""
        try:
            # Charger le modèle
            self.original_model = tf.keras.models.load_model(self.model_path)
            
            # Extraire les informations
            self.model_info = {
                'input_shape': self.original_model.input_shape,
                'output_shape': self.original_model.output_shape,
                'num_parameters': self.original_model.count_params(),
                'num_layers': len(self.original_model.layers),
                'model_size_mb': os.path.getsize(self.model_path) / (1024 * 1024)
            }
            
            logging.info("📊 Informations du modèle:")
            logging.info(f"   • Input shape: {self.model_info['input_shape']}")
            logging.info(f"   • Output shape: {self.model_info['output_shape']}")
            logging.info(f"   • Paramètres: {self.model_info['num_parameters']:,}")
            logging.info(f"   • Couches: {self.model_info['num_layers']}")
            logging.info(f"   • Taille: {self.model_info['model_size_mb']:.2f} MB")
            
        except Exception as e:
            logging.error(f"❌ Erreur chargement modèle: {e}")
            raise
    
    def _create_representative_dataset(self, num_samples=100):
        """
        Crée un dataset représentatif pour la quantification
        """
        try:
            input_shape = self.model_info['input_shape']
            
            # Générer des données aléaoires représentatives
            def representative_data_gen():
                for _ in range(num_samples):
                    # Données normalisées entre -1 et 1 (comme MobileNet)
                    data = np.random.uniform(-1.0, 1.0, input_shape).astype(np.float32)
                    yield [data]
            
            logging.info(f"📊 Dataset représentatif créé: {num_samples} échantillons")
            return representative_data_gen
            
        except Exception as e:
            logging.error(f"❌ Erreur création dataset: {e}")
            return None
    
    def _convert_standard(self):
        """Conversion TFLite standard (sans quantification)"""
        try:
            logging.info("🔄 Conversion standard en cours...")
            
            converter = tf.lite.TFLiteConverter.from_keras_model(self.original_model)
            
            # Optimisations de base
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            
            # Conversion
            tflite_model = converter.convert()
            
            # Sauvegarde
            output_path = self.output_dir / "plant_disease_model_standard.tflite"
            with open(output_path, "wb") as f:
                f.write(tflite_model)
            
            # Informations
            size_mb = len(tflite_model) / (1024 * 1024)
            compression_ratio = self.model_info['model_size_mb'] / size_mb
            
            result = {
                'path': str(output_path),
                'size_mb': size_mb,
                'compression_ratio': compression_ratio,
                'quantization': 'None'
            }
            
            logging.info(f"✅ Conversion standard terminée: {size_mb:.2f} MB")
            return result
            
        except Exception as e:
            logging.error(f"❌ Erreur conversion standard: {e}")
            return None
    
    def _convert_dynamic_range_quantized(self):
        """Conversion avec quantification dynamique (poids en int8)"""
        try:
            logging.info("🔄 Conversion avec quantification dynamique...")
            
            converter = tf.lite.TFLiteConverter.from_keras_model(self.original_model)
            
            # Optimisations avec quantification dynamique
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            
            # Conversion
            tflite_model = converter.convert()
            
            # Sauvegarde
            output_path = self.output_dir / "plant_disease_model_dynamic_quant.tflite"
            with open(output_path, "wb") as f:
                f.write(tflite_model)
            
            # Informations
            size_mb = len(tflite_model) / (1024 * 1024)
            compression_ratio = self.model_info['model_size_mb'] / size_mb
            
            result = {
                'path': str(output_path),
                'size_mb': size_mb,
                'compression_ratio': compression_ratio,
                'quantization': 'Dynamic Range (int8 weights)'
            }
            
            logging.info(f"✅ Conversion dynamique terminée: {size_mb:.2f} MB")
            return result
            
        except Exception as e:
            logging.error(f"❌ Erreur conversion dynamique: {e}")
            return None
    
    def _convert_full_integer_quantized(self):
        """Conversion avec quantification complète int8"""
        try:
            logging.info("🔄 Conversion avec quantification complète int8...")
            
            converter = tf.lite.TFLiteConverter.from_keras_model(self.original_model)
            
            # Optimisations
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            
            # Dataset représentatif
            representative_dataset = self._create_representative_dataset()
            if representative_dataset:
                converter.representative_dataset = representative_dataset
            
            # Forcer la quantification int8
            converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
            converter.inference_input_type = tf.int8
            converter.inference_output_type = tf.int8
            
            # Conversion
            tflite_model = converter.convert()
            
            # Sauvegarde
            output_path = self.output_dir / "plant_disease_model_int8_quant.tflite"
            with open(output_path, "wb") as f:
                f.write(tflite_model)
            
            # Informations
            size_mb = len(tflite_model) / (1024 * 1024)
            compression_ratio = self.model_info['model_size_mb'] / size_mb
            
            result = {
                'path': str(output_path),
                'size_mb': size_mb,
                'compression_ratio': compression_ratio,
                'quantization': 'Full Integer (int8)'
            }
            
            logging.info(f"✅ Conversion int8 terminée: {size_mb:.2f} MB")
            return result
            
        except Exception as e:
            logging.error(f"❌ Erreur conversion int8: {e}")
            return None
    
    def _convert_compatible(self):
        """Convertit en format TFLite brut (sans optimisation) pour compatibilité maximale"""
        try:
            logging.info("⏳ Conversion compatible (Raw Float32) en cours...")
            converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
            # PAS d'optimisation ici pour éviter de monter en version d'opérateurs
            # converter.optimizations = [tf.lite.Optimize.DEFAULT] 
            
            tflite_model = converter.convert()

            path = os.path.join(self.output_dir, "plant_disease_model_compatible.tflite")
            with open(path, "wb") as f:
                f.write(tflite_model)

            size_mb = os.path.getsize(path) / (1024 * 1024)
            logging.info(f"✅ Conversion compatible terminée: {size_mb:.2f} MB")
            
            return {
                "path": path,
                "size_mb": size_mb,
                "type": "Compatible (Float32)"
            }
        except Exception as e:
            logging.error(f"❌ Erreur conversion compatible: {e}")
            return None

    def _convert_float16_quantized(self):
        """Conversion avec quantification float16"""
        try:
            logging.info("🔄 Conversion avec quantification float16...")
            
            converter = tf.lite.TFLiteConverter.from_keras_model(self.original_model)
            
            # Optimisations
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            
            # Quantification float16
            converter.target_spec.supported_types = [tf.float16]
            
            # Conversion
            tflite_model = converter.convert()
            
            # Sauvegarde
            output_path = self.output_dir / "plant_disease_model_float16_quant.tflite"
            with open(output_path, "wb") as f:
                f.write(tflite_model)
            
            # Informations
            size_mb = len(tflite_model) / (1024 * 1024)
            compression_ratio = self.model_info['model_size_mb'] / size_mb
            
            result = {
                'path': str(output_path),
                'size_mb': size_mb,
                'compression_ratio': compression_ratio,
                'quantization': 'Float16'
            }
            
            logging.info(f"✅ Conversion float16 terminée: {size_mb:.2f} MB")
            return result
            
        except Exception as e:
            logging.error(f"❌ Erreur conversion float16: {e}")
            return None
    
    def _test_model_performance(self, model_path, num_tests=50):
        """Teste les performances d'un modèle TFLite"""
        try:
            # Charger le modèle TFLite
            interpreter = tf.lite.Interpreter(model_path=model_path)
            interpreter.allocate_tensors()
            
            # Détails du modèle
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            
            input_shape = input_details[0]['shape']
            input_dtype = input_details[0]['dtype']
            
            # Générer des données de test
            if input_dtype == np.int8:
                test_data = np.random.randint(-128, 127, input_shape, dtype=np.int8)
            else:
                test_data = np.random.uniform(-1.0, 1.0, input_shape).astype(input_dtype)
            
            # Tests de performance
            inference_times = []
            memory_usage = []
            
            for _ in range(num_tests):
                # Mesurer l'utilisation mémoire
                process = psutil.Process()
                mem_before = process.memory_info().rss / 1024 / 1024  # MB
                
                # Mesurer le temps d'inférence
                start_time = time.perf_counter()
                
                interpreter.set_tensor(input_details[0]['index'], test_data)
                interpreter.invoke()
                output = interpreter.get_tensor(output_details[0]['index'])
                
                end_time = time.perf_counter()
                inference_time = (end_time - start_time) * 1000  # ms
                
                mem_after = process.memory_info().rss / 1024 / 1024  # MB
                mem_usage = mem_after - mem_before
                
                inference_times.append(inference_time)
                memory_usage.append(max(0, mem_usage))
            
            # Statistiques
            avg_inference_time = np.mean(inference_times)
            std_inference_time = np.std(inference_times)
            avg_memory_usage = np.mean(memory_usage)
            
            performance = {
                'avg_inference_time_ms': avg_inference_time,
                'std_inference_time_ms': std_inference_time,
                'min_inference_time_ms': np.min(inference_times),
                'max_inference_time_ms': np.max(inference_times),
                'avg_memory_usage_mb': avg_memory_usage,
                'fps': 1000 / avg_inference_time if avg_inference_time > 0 else 0
            }
            
            logging.info(f"   📊 Performance: {avg_inference_time:.2f}ms ± {std_inference_time:.2f}ms")
            logging.info(f"   🚀 FPS: {performance['fps']:.1f}")
            logging.info(f"   💾 Mémoire: {avg_memory_usage:.2f} MB")
            
            return performance
            
        except Exception as e:
            logging.error(f"❌ Erreur test performance: {e}")
            return None
    
    def _validate_model_accuracy(self, original_path, tflite_path, num_samples=10):
        """Valide la précision après conversion"""
        try:
            logging.info("🔍 Validation de la précision...")
            
            # Charger les modèles
            original_model = tf.keras.models.load_model(original_path)
            
            interpreter = tf.lite.Interpreter(model_path=tflite_path)
            interpreter.allocate_tensors()
            
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            
            # Générer des données de test
            input_shape = self.model_info['input_shape']
            test_data = np.random.uniform(-1.0, 1.0, (num_samples,) + input_shape[1:]).astype(np.float32)
            
            # Prédictions du modèle original
            original_predictions = original_model.predict(test_data, verbose=0)
            
            # Prédictions du modèle TFLite
            tflite_predictions = []
            
            for i in range(num_samples):
                input_data = test_data[i:i+1]
                
                # Adapter le type de données si nécessaire
                if input_details[0]['dtype'] == np.int8:
                    # Quantifier l'entrée
                    scale, zero_point = input_details[0]['quantization']
                    input_data = (input_data / scale + zero_point).astype(np.int8)
                
                interpreter.set_tensor(input_details[0]['index'], input_data)
                interpreter.invoke()
                output = interpreter.get_tensor(output_details[0]['index'])
                
                # Déquantifier la sortie si nécessaire
                if output_details[0]['dtype'] == np.int8:
                    scale, zero_point = output_details[0]['quantization']
                    output = (output.astype(np.float32) - zero_point) * scale
                
                tflite_predictions.append(output[0])
            
            tflite_predictions = np.array(tflite_predictions)
            
            # Calculer la différence
            max_diff = np.max(np.abs(original_predictions - tflite_predictions))
            mean_diff = np.mean(np.abs(original_predictions - tflite_predictions))
            
            # Précision top-1
            orig_top1 = np.argmax(original_predictions, axis=1)
            tflite_top1 = np.argmax(tflite_predictions, axis=1)
            top1_accuracy = np.mean(orig_top1 == tflite_top1)
            
            accuracy_info = {
                'max_output_diff': float(max_diff),
                'mean_output_diff': float(mean_diff),
                'top1_accuracy_preserved': float(top1_accuracy),
                'samples_tested': num_samples
            }
            
            logging.info(f"   📊 Différence max: {max_diff:.6f}")
            logging.info(f"   📊 Différence moyenne: {mean_diff:.6f}")
            logging.info(f"   🎯 Précision Top-1 préservée: {top1_accuracy:.2%}")
            
            return accuracy_info
            
        except Exception as e:
            logging.error(f"❌ Erreur validation précision: {e}")
            return None
    
    def convert_all_variants(self, test_performance=True, validate_accuracy=True):
        """Convertit toutes les variantes du modèle"""
        try:
            logging.info("\n🚀 DÉBUT DE LA CONVERSION COMPLÈTE")
            logging.info("="*60)
            
            # Charger les informations du modèle
            self._load_model_info()
            
            # Liste des conversions
            conversions = [
                ("Standard", self._convert_standard),
                ("Compatible", self._convert_compatible), # Ajout du mode compatible
                ("Dynamic Range", self._convert_dynamic_range_quantized),
                ("Float16", self._convert_float16_quantized),
                ("Integer Int8", self._convert_full_integer_quantized)
            ]
            
            results = {}
            
            for name, convert_func in conversions:
                try:
                    logging.info(f"\n{'='*20} {name} {'='*20}")
                    
                    # Conversion
                    result = convert_func()
                    if result is None:
                        continue
                    
                    # Tests de performance
                    if test_performance:
                        performance = self._test_model_performance(result['path'])
                        if performance:
                            result['performance'] = performance
                    
                    # Validation de précision
                    if validate_accuracy:
                        accuracy = self._validate_model_accuracy(self.model_path, result['path'])
                        if accuracy:
                            result['accuracy'] = accuracy
                    
                    results[name] = result
                    
                except Exception as e:
                    logging.error(f"❌ Erreur conversion {name}: {e}")
                    continue
            
            # Sauvegarder les résultats
            self._save_conversion_report(results)
            
            # Afficher le résumé
            self._display_summary(results)
            
            return results
            
        except Exception as e:
            logging.error(f"❌ Erreur conversion complète: {e}")
            raise
    
    def _save_conversion_report(self, results):
        """Sauvegarde le rapport de conversion"""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            report_path = self.output_dir / f"conversion_report_{timestamp}.json"
            
            report = {
                'timestamp': datetime.now().isoformat(),
                'original_model': {
                    'path': self.model_path,
                    'info': self.model_info
                },
                'conversions': results
            }
            
            with open(report_path, 'w', encoding='utf-8') as f:
                json.dump(report, f, indent=2, ensure_ascii=False)
            
            logging.info(f"📄 Rapport sauvegardé: {report_path}")
            
        except Exception as e:
            logging.error(f"❌ Erreur sauvegarde rapport: {e}")
    
    def _display_summary(self, results):
        """Affiche le résumé des conversions"""
        print("\n" + "="*80)
        print("📊 RÉSUMÉ DES CONVERSIONS")
        print("="*80)
        
        print(f"🔹 Modèle original: {self.model_info['model_size_mb']:.2f} MB")
        print(f"🔹 Paramètres: {self.model_info['num_parameters']:,}")
        
        print("\n📋 VARIANTES CRÉÉES:")
        print("-" * 80)
        print(f"{'Variante':<20} {'Taille':<12} {'Compression':<12} {'Vitesse':<15} {'Précision':<10}")
        print("-" * 80)
        
        for name, result in results.items():
            size = f"{result['size_mb']:.2f} MB"
            compression = f"{result['compression_ratio']:.1f}x"
            
            # Vitesse
            if 'performance' in result:
                speed = f"{result['performance']['avg_inference_time_ms']:.1f}ms"
            else:
                speed = "N/A"
            
            # Précision
            if 'accuracy' in result:
                precision = f"{result['accuracy']['top1_accuracy_preserved']:.1%}"
            else:
                precision = "N/A"
            
            print(f"{name:<20} {size:<12} {compression:<12} {speed:<15} {precision:<10}")
        
        print("-" * 80)
        
        # Recommandations
        print("\n💡 RECOMMANDATIONS:")
        self._provide_recommendations(results)
        
        print("\n✅ Conversion terminée avec succès!")
        print(f"📁 Fichiers dans: {self.output_dir}")
    
    def _provide_recommendations(self, results):
        """Fournit des recommandations basées sur les résultats"""
        print("\n🎯 Pour différents cas d'usage:")
        
        # Trouver le meilleur modèle pour chaque cas
        fastest = None
        smallest = None
        most_accurate = None
        
        for name, result in results.items():
            # Le plus rapide
            if 'performance' in result:
                if fastest is None or result['performance']['avg_inference_time_ms'] < fastest[1]['performance']['avg_inference_time_ms']:
                    fastest = (name, result)
            
            # Le plus petit
            if smallest is None or result['size_mb'] < smallest[1]['size_mb']:
                smallest = (name, result)
            
            # Le plus précis
            if 'accuracy' in result:
                if most_accurate is None or result['accuracy']['top1_accuracy_preserved'] > most_accurate[1]['accuracy']['top1_accuracy_preserved']:
                    most_accurate = (name, result)
        
        if fastest:
            print(f"   ⚡ Performance max: {fastest[0]} ({fastest[1]['performance']['avg_inference_time_ms']:.1f}ms)")
        
        if smallest:
            print(f"   📱 Taille minimale: {smallest[0]} ({smallest[1]['size_mb']:.2f} MB)")
        
        if most_accurate:
            print(f"   🎯 Précision max: {most_accurate[0]} ({most_accurate[1]['accuracy']['top1_accuracy_preserved']:.1%})")
        
        print("\n📱 Conseils d'utilisation:")
        print("   • Smartphones haut de gamme: Standard ou Dynamic Range")
        print("   • Smartphones bas de gamme: Float16 ou Int8")
        print("   • IoT/Embarqué: Int8 (plus compact)")
        print("   • Temps réel critique: Dynamic Range (bon compromis)")

def main():
    """Fonction principale avec interface CLI"""
    parser = argparse.ArgumentParser(description="Convertisseur TensorFlow Lite optimisé")
    parser.add_argument("--model", help="Chemin vers le modèle .h5")
    parser.add_argument("--output", help="Répertoire de sortie")
    parser.add_argument("--no-performance", action="store_true", 
                       help="Désactiver les tests de performance")
    parser.add_argument("--no-accuracy", action="store_true",
                       help="Désactiver la validation de précision")
    parser.add_argument("--variants", nargs="+", 
                       choices=["standard", "dynamic", "float16", "int8"],
                       help="Variantes spécifiques à convertir")
    
    args = parser.parse_args()
    
    try:
        # Initialisation
        converter = TFLiteConverter(
            model_path=args.model,
            output_dir=args.output
        )
        
        # Conversion
        results = converter.convert_all_variants(
            test_performance=not args.no_performance,
            validate_accuracy=not args.no_accuracy
        )
        
        if not results:
            logging.error("❌ Aucune conversion réussie")
            sys.exit(1)
        
        logging.info("🎉 Toutes les conversions terminées!")
        
    except Exception as e:
        logging.error(f"❌ Erreur critique: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()