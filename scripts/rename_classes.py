import os
import shutil
from pathlib import Path

def rename_classes_french(data_dir):
    data_path = Path(data_dir)
    if not data_path.exists():
        print(f"❌ Dossier non trouvé: {data_path}")
        return

    # Mapping: "Ancien Nom" -> "Nouveau Nom Français"
    # Préfixes conservés pour la précision du modèle
    mapping = {
        # Maïs (Corn)
        'Blight': 'Mais_Brulure',
        'Common_Rust': 'Mais_Rouille',
        'Gray_Leaf_Spot': 'Mais_Cercosporiose',
        'Healthy': 'Mais_Sain', 
        
        # Sorgho (Sorghum)
        'Anthracnose and Red Rot': 'Sorgho_Anthracnose',
        'Rust': 'Sorgho_Rouille',
        
        # Background
        'Background': 'Hors_Sujet'
    }

    print("🚀 DÉBUT DU RENOMMAGE EN FRANÇAIS")
    print(f"📂 Dossier cible: {data_path}")
    print("=" * 60)

    renamed_count = 0
    
    # On fait deux passes pour éviter les conflits si on échange des noms
    # Passe 1: Renommage direct
    for old_name, new_name in mapping.items():
        if old_name == new_name:
            continue
            
        old_path = data_path / old_name
        new_path = data_path / new_name
        
        if old_path.exists():
            if new_path.exists():
                print(f"⚠️ Le dossier cible existe déjà: {new_name}")
                print(f"   Fusion du contenu de '{old_name}' vers '{new_name}'...")
                # Déplacer le contenu - Gestion des collisions de fichiers
                for item in old_path.iterdir():
                    dest_file = new_path / item.name
                    if dest_file.exists():
                        # Si le fichier existe déjà, on ajoute un suffixe
                        c = 1
                        while dest_file.exists():
                            dest_file = new_path / f"{item.stem}_{c}{item.suffix}"
                            c += 1
                    shutil.move(str(item), str(dest_file))
                
                # Supprimer l'ancien dossier vide
                try:
                    old_path.rmdir()
                    print(f"   ✅ Fusion terminée et dossier ancien supprimé: {old_name} -> {new_name}")
                except OSError:
                    print(f"   ⚠️ Impossible de supprimer {old_name} (peut-être pas vide ?)")
            else:
                try:
                    old_path.rename(new_path)
                    print(f"   ✅ Renommé: '{old_name}'  ➡️  '{new_name}'")
                except OSError as e:
                    print(f"   ❌ Erreur lors du renommage de {old_name}: {e}")
            renamed_count += 1
        else:
            # Vérifier si c'est déjà fait (le nouveau nom existe mais pas l'ancien)
            if new_path.exists():
                print(f"   ℹ️  Déjà fait: '{new_name}' existe déjà (et '{old_name}' n'existe plus).")

    print("=" * 60)
    print(f"🎉 Terminé! {renamed_count} dossiers renommés/fusionnés.")
    
    # Afficher la liste finale
    print("\n📋 LISTE DES CLASSES PRÊTES (FRANÇAIS):")
    if data_path.exists():
        for item in sorted(data_path.iterdir()):
            if item.is_dir():
                print(f"   • {item.name}")

if __name__ == "__main__":
    # Chemin relatif
    base_dir = Path(__file__).resolve().parent.parent
    data_dir = base_dir / "data"
    
    rename_classes_french(data_dir)
