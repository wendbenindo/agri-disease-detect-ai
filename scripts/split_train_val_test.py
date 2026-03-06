import os
import shutil
import random

def split_dataset(source_dir, output_dir, train_ratio=0.7, val_ratio=0.2, test_ratio=0.1):
    assert abs(train_ratio + val_ratio + test_ratio - 1.0) < 1e-5, "Les ratios doivent faire 100%"

    classes = [d for d in os.listdir(source_dir) if os.path.isdir(os.path.join(source_dir, d))]
    for split in ['train', 'val', 'test']:
        for class_name in classes:
            os.makedirs(os.path.join(output_dir, split, class_name), exist_ok=True)

    for class_name in classes:
        class_path = os.path.join(source_dir, class_name)
        images = os.listdir(class_path)
        random.shuffle(images)

        total = len(images)
        train_end = int(train_ratio * total)
        val_end = train_end + int(val_ratio * total)

        split_sets = {
            'train': images[:train_end],
            'val': images[train_end:val_end],
            'test': images[val_end:]
        }

        for split, image_list in split_sets.items():
            for image_name in image_list:
                src = os.path.join(class_path, image_name)
                dst = os.path.join(output_dir, split, class_name, image_name)
                shutil.copy2(src, dst)

    print("✅ Répartition des données terminée.")

# Exemple d'utilisation
source_dir = r"C:\Personal works\PROGRAMMING\agri-desease-detect-ai\data"
output_dir = r"C:\Personal works\PROGRAMMING\agri-desease-detect-ai\data_split"

split_dataset(source_dir, output_dir)
