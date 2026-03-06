"""
Script pour augmenter les classes minoritaires du dataset
en utilisant des techniques de data augmentation
"""

import os
import cv2
import numpy as np
from pathlib import Path
import albumentations as A
from tqdm import tqdm
import shutil

# Configuration
DATA_DIR = Path(__file__).parent.parent / 'data'
TARGET_COUNT = 800  # Nombre cible d'images par classe

# Classes à augmenter
MINORITY_CLASSES = {
    'Covered Kernel smut': 279,
    'Head Smut': 499
}

# Pipeline d'augmentation
augmentation_pipeline = A.Compose([
    A.OneOf([
        A.HorizontalFlip(p=1.0),
        A.VerticalFlip(p=1.0),
        A.Rotate(limit=45, p=1.0),
    ], p=0.8),
    
    A.OneOf([
        A.RandomBrightnessContrast(brightness_limit=0.3, contrast_limit=0.3, p=1.0),
        A.HueSaturationValue(hue_shift_limit=20, sat_shift_limit=30, val_shift_limit=20, p=1.0),
        A.RGBShift(r_shift_limit=20, g_shift_limit=20, b_shift_limit=20, p=1.0),
    ], p=0.7),
    
    A.OneOf([
        A.GaussNoise(var_limit=(10.0, 50.0), p=1.0),
        A.GaussianBlur(blur_limit=(3, 7), p=1.0),
        A.MotionBlur(blur_limit=7, p=1.0),
    ], p=0.5),
    
    A.OneOf([
        A.ElasticTransform(alpha=1, sigma=50, p=1.0),
        A.GridDistortion(p=1.0),
        A.OpticalDistortion(distort_limit=0.5, shift_limit=0.5, p=1.0),
    ], p=0.3),
    
    A.RandomScale(scale_limit=0.2, p=0.5),
    A.ShiftScaleRotate(shift_limit=0.1, scale_limit=0.2, rotate_limit=15, p=0.5),
])

def augment_image(image_path, output_dir, num_augmentations=1):
    """
    Applique des augmentations à une image et sauvegarde les résultats
    """
    # Lire l'image
    image = cv2.imread(str(image_path))
    if image is None:
        print(f"⚠️ Impossible de lire: {image_path}")
        return 0
    
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    # Nom de base
    base_name = image_path.stem
    extension = image_path.suffix
    
    augmented_count = 0
    for i in range(num_augmentations):
        try:
            # Appliquer l'augmentation
            augmented = augmentation_pipeline(image=image)['image']
            
            # Sauvegarder
            output_path = output_dir / f"{base_name}_aug_{i+1}{extension}"
            augmented_bgr = cv2.cvtColor(augmented, cv2.COLOR_RGB2BGR)
            cv2.imwrite(str(output_path), augmented_bgr)
            augmented_count += 1
        except Exception as e:
            print(f"⚠️ Erreur augmentation {image_path}: {e}")
    
    return augmented_count

def augment_class(class_name, current_count, target_count):
    """
    Augmente une classe jusqu'au nombre cible
    """
    class_dir = DATA_DIR / class_name
    if not class_dir.exists():
        print(f"❌ Dossier introuvable: {class_dir}")
        return
    
    # Lister toutes les images
    image_files = list(class_dir.glob('*.jpg')) + list(class_dir.glob('*.jpeg')) + list(class_dir.glob('*.png'))
    
    if len(image_files) == 0:
        print(f"❌ Aucune image trouvée dans {class_name}")
        return
    
    print(f"\n📁 Classe: {class_name}")
    print(f"   Images actuelles: {current_count}")
    print(f"   Objectif: {target_count}")
    
    # Calculer combien d'augmentations par image
    images_needed = target_count - current_count
    augmentations_per_image = images_needed // len(image_files) + 1
    
    print(f"   Augmentations par image: {augmentations_per_image}")
    
    # Augmenter chaque image
    total_augmented = 0
    for img_path in tqdm(image_files, desc=f"Augmentation {class_name}"):
        count = augment_image(img_path, class_dir, augmentations_per_image)
        total_augmented += count
        
        # Arrêter si on a atteint l'objectif
        if current_count + total_augmented >= target_count:
            break
    
    final_count = current_count + total_augmented
    print(f"✅ Terminé: {final_count} images (ajouté {total_augmented})")

def main():
    print("🚀 Augmentation des classes minoritaires")
    print("=" * 60)
    
    # Vérifier albumentations
    try:
        import albumentations
        print(f"✅ Albumentations version: {albumentations.__version__}")
    except ImportError:
        print("❌ Albumentations non installé!")
        print("   Installez avec: pip install albumentations")
        return
    
    # Augmenter chaque classe minoritaire
    for class_name, current_count in MINORITY_CLASSES.items():
        augment_class(class_name, current_count, TARGET_COUNT)
    
    print("\n🎉 Augmentation terminée!")
    print("\n📊 Résumé:")
    for class_name in MINORITY_CLASSES.keys():
        class_dir = DATA_DIR / class_name
        if class_dir.exists():
            final_count = len(list(class_dir.glob('*.jpg')) + list(class_dir.glob('*.jpeg')) + list(class_dir.glob('*.png')))
            print(f"   {class_name}: {final_count} images")

if __name__ == "__main__":
    main()
