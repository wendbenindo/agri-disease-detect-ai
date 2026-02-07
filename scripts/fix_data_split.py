import sys
import os
import shutil
import random
from pathlib import Path

# Force UTF-8 output for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Configuration pour la reproductibilité (même mélange à chaque fois)
random.seed(42)

def split_dataset(source_dir, output_dir, train_ratio=0.7, val_ratio=0.2, test_ratio=0.1):
    """
    Divise les données en ensembles d'entraînement (Train), validation (Val) et test (Test).
    
    Args:
        source_dir (str): Chemin vers le dossier 'data' contenant les classes.
        output_dir (str): Chemin vers le dossier 'data_split' où les données seront organisées.
        train_ratio (float): Proportion pour l'entraînement (défaut: 0.7 = 70%)
        val_ratio (float): Proportion pour la validation (défaut: 0.2 = 20%)
        test_ratio (float): Proportion pour le test (défaut: 0.1 = 10%)
    """
    source_path = Path(source_dir)
    output_path = Path(output_dir)
    
    print("\n🔍 VÉRIFICATION DES DOSSIERS")
    print(f"   📂 Source (vos images): {source_path}")
    print(f"   📂 Destination (organisé): {output_path}")

    # Vérification que le dossier source existe
    if not source_path.exists():
        print(f"❌ ERREUR: Le dossier source n'existe pas: {source_path}")
        print("   Assurez-vous d'avoir un dossier 'data' avec vos classes d'images à l'intérieur.")
        return

    # Vérification que les ratios font bien 100%
    if abs(train_ratio + val_ratio + test_ratio - 1.0) > 1e-5:
        print("❌ ERREUR: La somme des ratios doit être égale à 1.0 (100%)")
        return

    # Nettoyer le dossier de destination pour repartir de zéro
    if output_path.exists():
        print("🧹 Nettoyage de l'ancien dossier 'data_split'...")
        try:
            shutil.rmtree(output_path)
        except Exception as e:
            print(f"⚠️ Impossible de supprimer l'ancien dossier complètement: {e}")
    
    # Créer le dossier principal
    output_path.mkdir(parents=True, exist_ok=True)

    # Récupérer les classes (les sous-dossiers dans 'data')
    classes = [d.name for d in source_path.iterdir() if d.is_dir()]
    
    if not classes:
        print("❌ AUCUNE CLASSE TROUVÉE dans le dossier source.")
        return
        
    print(f"📋 Classes trouvées: {', '.join(classes)}")

    # Créer l'arborescence complète (train/val/test pour chaque classe)
    for split in ['train', 'val', 'test']:
        for class_name in classes:
            (output_path / split / class_name).mkdir(parents=True, exist_ok=True)

    print("\n🚀 DÉBUT DE LA RÉPARTITION")
    print("=" * 60)
    
    total_images_copied = 0
    stats = {}
    
    # Traitement de chaque classe
    for class_name in classes:
        class_dir = source_path / class_name
        
        # Trouver toutes les images
        valid_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp'}
        images = [f.name for f in class_dir.iterdir() if f.suffix.lower() in valid_extensions]
        
        # Mélanger aléatoirement les images
        random.shuffle(images)

        total = len(images)
        
        # Calculer les points de coupure
        train_end = int(train_ratio * total)
        val_end = train_end + int(val_ratio * total)

        # Diviser la liste des images
        split_sets = {
            'train': images[:train_end],
            'val': images[train_end:val_end],
            'test': images[val_end:]
        }
        
        # Statistiques pour cette classe
        stats[class_name] = {
            'total': total,
            'train': len(split_sets['train']),
            'val': len(split_sets['val']),
            'test': len(split_sets['test'])
        }

        print(f"   📦 Classe '{class_name}': {total} images")
        print(f"      ↳ Train: {len(split_sets['train'])} | Val: {len(split_sets['val'])} | Test: {len(split_sets['test'])}")

        # Copier physiquement les fichiers
        for split, image_list in split_sets.items():
            for image_name in image_list:
                src = class_dir / image_name
                dst = output_path / split / class_name / image_name
                shutil.copy2(src, dst)
                total_images_copied += 1

    print("\n" + "=" * 60)
    print("✅ RÉPARTITION TERMINÉE AVEC SUCCÈS!")
    print(f"📦 Total images traitées: {total_images_copied}")
    print(f"📁 Dossier prêt pour l'entraînement: {output_path}")

    # Vérification d'alerte pour les petits datasets
    print("\n⚠️ VÉRIFICATION FINALE:")
    dataset_ok = True
    for class_name, data in stats.items():
        if data['train'] < 10:
            print(f"   ⚠️ ATTENTION: La classe '{class_name}' a très peu d'images d'entraînement ({data['train']}).")
            dataset_ok = False
            
    if dataset_ok:
        print("   ✅ Tout semble correct. Vous pouvez lancer l'entraînement !")
    else:
        print("   💡 Conseil: Ajoutez plus d'images pour les classes signalées ci-dessus.")

if __name__ == "__main__":
    # Chemins relatifs basés sur l'emplacement du script
    # Le script est dans /scripts/, donc on remonte d'un cran pour trouver /data/
    base_dir = Path(__file__).resolve().parent.parent
    data_dir = base_dir / "data"
    split_dir = base_dir / "data_split"
    
    split_dataset(data_dir, split_dir)
