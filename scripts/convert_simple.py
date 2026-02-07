
import os
import tensorflow as tf
import logging

# Configuration du logging pour éviter les erreurs d'encodage sur Windows
import sys
sys.stdout.reconfigure(encoding='utf-8')

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def convert_simple():
    model_path = 'model/plant_disease_model_optimized.h5'
    output_path = 'model/plant_disease_model_compatible.tflite'
    
    if not os.path.exists(model_path):
        logging.error(f"❌ Modèle introuvable : {model_path}")
        return

    logging.info(f"Chargement du modèle : {model_path}")
    model = tf.keras.models.load_model(model_path)
    
    logging.info("Conversion en cours (Sans optimisation)...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    # AUCUNE OPTIMISATION = COMPATIBILITÉ MAXIMALE
    converter.optimizations = [] 
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
        
    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    logging.info(f"✅ Modèle compatible généré : {output_path} ({size_mb:.2f} MB)")

if __name__ == '__main__':
    convert_simple()
