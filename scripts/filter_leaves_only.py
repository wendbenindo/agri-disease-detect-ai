"""
Script pour filtrer et garder SEULEMENT les images de FEUILLES
Supprime les images d'épis, grains, tiges, etc.
"""

import os
import shutil
from pathlib import Path
import cv2
import numpy as np
from PIL import Image
import json

# Configuration
BASE_DIR = Path(__file__).parent.parent
DATA_DIR = BASE_DIR / 'data'
EXCLUDED_DIR = BASE_DIR / 'data_excluded'  # Images non-feuilles
REPORT_FILE = BASE_DIR / 'filtering_report.json'

# Créer dossier pour images exclues
EXCLUDED_DIR.mkdir(exist_ok=True)

class LeafFilter:
    """Filtre intelligent pour détecter les feuilles"""
    
    def __init__(self):
        self.stats = {
            'total_images': 0,
            'kept_images': 0,
            'excluded_images': 0,
            'by_class': {},
            'exclusion_reasons': {}
        }
    
    def is_leaf_image(self, image_path):
        """
        Détermine si une image est une feuille
        
        Critères:
        1. Forme allongée (feuille)
        2. Couleur verte dominante
        3. Texture de feuille
        4. Pas de forme ronde (épi/grain)
        """
        try:
            # Lire l'image
            img = cv2.imread(str(image_path))
            if img is None:
                return False, "image_corrupted"
            
            # Convertir en RGB
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            height, width = img.shape[:2]
            
            # Critère 1: Ratio aspect (feuilles sont allongées)
            aspect_ratio = max(width, height) / min(width, height)
            
            # Critère 2: Couleur verte dominante
            hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
            
            # Masque pour vert (feuilles)
            lower_green = np.array([25, 40, 40])
            upper_green = np.array([90, 255, 255])
            green_mask = cv2.inRange(hsv, lower_green, upper_green)
            green_ratio = np.sum(green_mask > 0) / (height * width)
            
            # Masque pour jaune/brun (feuilles malades)
            lower_yellow = np.array([15, 40, 40])
            upper_yellow = np.array([35, 255, 255])
            yellow_mask = cv2.inRange(hsv, lower_yellow, upper_yellow)
            yellow_ratio = np.sum(yellow_mask > 0) / (height * width)
            
            # Masque pour brun (feuilles sèches)
            lower_brown = np.array([10, 40, 20])
            upper_brown = np.array([20, 255, 200])
            brown_mask = cv2.inRange(hsv, lower_brown, upper_brown)
            brown_ratio = np.sum(brown_mask > 0) / (height * width)
            
            # Total végétation
            vegetation_ratio = green_ratio + yellow_ratio + brown_ratio
            
            # Critère 3: Détection de formes rondes (épis/grains)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            blurred = cv2.GaussianBlur(gray, (9, 9), 2)
            circles = cv2.HoughCircles(
                blurred, cv2.HOUGH_GRADIENT, 1, 20,
                param1=50, param2=30, minRadius=10, maxRadius=100
            )
            has_circles = circles is not None and len(circles[0]) > 5
            
            # Critère 4: Texture (feuilles ont des nervures)
            laplacian = cv2.Laplacian(gray, cv2.CV_64F)
            texture_variance = laplacian.var()
            
            # DÉCISION
            reasons = []
            
            # Exclure si beaucoup de cercles (épis/grains)
            if has_circles:
                return False, "circular_shapes_detected"
            
            # Exclure si pas assez de végétation
            if vegetation_ratio < 0.15:
                return False, "insufficient_vegetation"
            
            # Exclure si image trop sombre (mauvaise qualité)
            brightness = np.mean(img_rgb)
            if brightness < 30:
                return False, "too_dark"
            
            # Exclure si image trop claire (surexposée)
            if brightness > 240:
                return False, "overexposed"
            
            # Exclure si texture trop uniforme (pas une feuille)
            if texture_variance < 50:
                return False, "uniform_texture"
            
            # GARDER si:
            # - Végétation présente (vert/jaune/brun)
            # - Pas de formes circulaires
            # - Texture variée
            if vegetation_ratio >= 0.15 and texture_variance >= 50:
                return True, "valid_leaf"
            
            return False, "unknown_reason"
            
        except Exception as e:
            print(f"⚠️ Erreur analyse {image_path.name}: {e}")
            return False, "analysis_error"
    
    def manual_check_mode(self, image_path):
        """
        Mode manuel: affiche l'image et demande confirmation
        """
        try:
            img = Image.open(image_path)
            img.show()
            
            print(f"\n📸 Image: {image_path.name}")
            print("   Est-ce une FEUILLE?")
            print("   o = Oui (garder)")
            print("   n = Non (exclure)")
            print("   s = Skip (garder par défaut)")
            
            choice = input("👉 Choix: ").strip().lower()
            
            if choice == 'o':
                return True, "manual_keep"
            elif choice == 'n':
                return False, "manual_exclude"
            else:
                return True, "manual_skip"
        
        except Exception as e:
            print(f"⚠️ Erreur affichage: {e}")
            return True, "manual_error"
    
    def filter_class(self, class_name, auto_mode=True):
        """Filtre une classe"""
        class_dir = DATA_DIR / class_name
        
        if not class_dir.exists():
            print(f"⚠️ Dossier introuvable: {class_name}")
            return
        
        print(f"\n📁 Traitement: {class_name}")
        print("=" * 60)
        
        # Lister toutes les images
        images = list(class_dir.glob('*.jpg')) + \
                list(class_dir.glob('*.jpeg')) + \
                list(class_dir.glob('*.png')) + \
                list(class_dir.glob('*.JPG')) + \
                list(class_dir.glob('*.JPEG')) + \
                list(class_dir.glob('*.PNG'))
        
        total = len(images)
        kept = 0
        excluded = 0
        
        # Créer dossier d'exclusion pour cette classe
        excluded_class_dir = EXCLUDED_DIR / class_name
        excluded_class_dir.mkdir(exist_ok=True)
        
        print(f"   Total images: {total}")
        
        for i, img_path in enumerate(images, 1):
            self.stats['total_images'] += 1
            
            # Analyser l'image
            if auto_mode:
                is_leaf, reason = self.is_leaf_image(img_path)
            else:
                is_leaf, reason = self.manual_check_mode(img_path)
            
            if is_leaf:
                # Garder
                kept += 1
                self.stats['kept_images'] += 1
            else:
                # Exclure
                excluded += 1
                self.stats['excluded_images'] += 1
                
                # Déplacer vers dossier exclusion
                dest_path = excluded_class_dir / img_path.name
                shutil.move(str(img_path), str(dest_path))
                
                # Compter raisons
                if reason not in self.stats['exclusion_reasons']:
                    self.stats['exclusion_reasons'][reason] = 0
                self.stats['exclusion_reasons'][reason] += 1
            
            # Afficher progression
            if i % 50 == 0 or i == total:
                print(f"   Progression: {i}/{total} ({i*100//total}%) - "
                      f"Gardées: {kept}, Exclues: {excluded}")
        
        # Statistiques de la classe
        self.stats['by_class'][class_name] = {
            'total': total,
            'kept': kept,
            'excluded': excluded,
            'kept_percentage': (kept / total * 100) if total > 0 else 0
        }
        
        print(f"\n   ✅ Terminé: {kept} gardées, {excluded} exclues")
    
    def filter_all_classes(self, auto_mode=True):
        """Filtre toutes les classes"""
        print("🔍 FILTRAGE DES IMAGES - FEUILLES SEULEMENT")
        print("=" * 70)
        
        if not auto_mode:
            print("\n⚠️ MODE MANUEL activé")
            print("   Chaque image sera affichée pour validation")
            confirm = input("\n👉 Continuer? (o/n): ").strip().lower()
            if confirm != 'o':
                print("❌ Annulé")
                return
        
        # Lister toutes les classes
        classes = [d.name for d in DATA_DIR.iterdir() if d.is_dir()]
        
        print(f"\n📦 Classes trouvées: {len(classes)}")
        for class_name in classes:
            print(f"   • {class_name}")
        
        # Filtrer chaque classe
        for class_name in classes:
            self.filter_class(class_name, auto_mode)
        
        # Sauvegarder rapport
        self.save_report()
        
        # Afficher résumé
        self.print_summary()
    
    def save_report(self):
        """Sauvegarde le rapport"""
        with open(REPORT_FILE, 'w', encoding='utf-8') as f:
            json.dump(self.stats, f, indent=2, ensure_ascii=False)
        
        print(f"\n📄 Rapport sauvegardé: {REPORT_FILE}")
    
    def print_summary(self):
        """Affiche le résumé"""
        print("\n" + "=" * 70)
        print("📊 RÉSUMÉ DU FILTRAGE")
        print("=" * 70)
        
        print(f"\n🔢 STATISTIQUES GLOBALES:")
        print(f"   Total images analysées: {self.stats['total_images']}")
        print(f"   Images gardées: {self.stats['kept_images']} "
              f"({self.stats['kept_images']/self.stats['total_images']*100:.1f}%)")
        print(f"   Images exclues: {self.stats['excluded_images']} "
              f"({self.stats['excluded_images']/self.stats['total_images']*100:.1f}%)")
        
        print(f"\n📁 PAR CLASSE:")
        for class_name, stats in self.stats['by_class'].items():
            print(f"   {class_name}:")
            print(f"      Total: {stats['total']}")
            print(f"      Gardées: {stats['kept']} ({stats['kept_percentage']:.1f}%)")
            print(f"      Exclues: {stats['excluded']}")
        
        print(f"\n🚫 RAISONS D'EXCLUSION:")
        for reason, count in sorted(self.stats['exclusion_reasons'].items(), 
                                    key=lambda x: x[1], reverse=True):
            print(f"   {reason}: {count} images")
        
        print(f"\n📁 Images exclues dans: {EXCLUDED_DIR}")
        print(f"   (Tu peux les vérifier manuellement)")

def main():
    filter_obj = LeafFilter()
    
    print("🌿 FILTRE IMAGES - FEUILLES SEULEMENT")
    print("=" * 70)
    
    print("\n📋 MODES DISPONIBLES:")
    print("   1. Automatique (rapide, basé sur IA)")
    print("   2. Manuel (lent, tu valides chaque image)")
    print("   3. Annuler")
    
    choice = input("\n👉 Choix (1-3): ").strip()
    
    if choice == '1':
        print("\n🤖 Mode AUTOMATIQUE sélectionné")
        filter_obj.filter_all_classes(auto_mode=True)
    
    elif choice == '2':
        print("\n👤 Mode MANUEL sélectionné")
        filter_obj.filter_all_classes(auto_mode=False)
    
    else:
        print("❌ Annulé")
        return
    
    print("\n✅ FILTRAGE TERMINÉ!")
    print(f"\n📁 Données nettoyées dans: {DATA_DIR}")
    print(f"📁 Images exclues dans: {EXCLUDED_DIR}")
    print(f"📄 Rapport détaillé: {REPORT_FILE}")

if __name__ == "__main__":
    main()
