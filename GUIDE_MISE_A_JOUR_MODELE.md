# 🚀 Guide de Mise à Jour du Modèle IA

Ce guide explique comment déployer une nouvelle version du modèle de détection de maladies (fichier `.tflite`) vers tous les utilisateurs de l'application mobile, sans avoir à republier l'application sur les stores.

## 📋 Prérequis

1.  Avoir généré un nouveau modèle `.tflite` (ex: `plant_disease_model_v4.tflite`).
    *   *Astuce : Utilisez le script `scripts/convert_simple.py` pour une compatibilité maximale.*
2.  (Optionnel) Avoir un fichier de labels `.json` mis à jour si vous avez ajouté de nouvelles maladies.
3.  Avoir accès au projet **Supabase** de l'application.

---

## 1️⃣ Étape 1 : Uploader les fichiers (Stockage)

1.  Connectez-vous à votre projet **Supabase**.
2.  Allez dans le menu de gauche : **Storage** (l'icône de dossier).
3.  Ouvrez le bucket (dossier) nommé **`models`**.
4.  Cliquez sur **Upload File**.
5.  Sélectionnez votre fichier `.tflite` (et votre `.json` si nécessaire).
6.  ⚠️ **Notez bien le nom exact** du fichier uploadé (ex: `modele_v3_1.tflite`).

---

## 2️⃣ Étape 2 : Annoncer la mise à jour (Base de données)

1.  Allez dans le menu de gauche : **Table Editor** (l'icône de tableau).
2.  Ouvrez la table **`active_models`**.
3.  Cliquez sur **Insert row** (Insérer une ligne) > **Insert row**.
4.  Remplissez les champs suivants avec précision :

| Champ | Valeur à mettre | Description |
| :--- | :--- | :--- |
| `plant_type` | `global` | **Toujours** mettre `global`. |
| `version` | `3.0.1` | Doit être supérieure à la version précédente (actuelle: `3.0.0`). |
| `model_name` | `modele_v3_1.tflite` | Le nom **exact** du fichier uploadé à l'étape 1. |
| `labels_name` | `modele_v3_1.labels.json` | (Optionnel) Le nom du fichier labels. Si vide, l'appli cherchera un json du même nom que le modèle. |
| `is_active` | `TRUE` | Cochez la case pour activer la mise à jour. |
| `changelog` | `Amélioration détection Maïs` | Le texte qui s'affichera sur l'écran de l'utilisateur. |
| `file_size_mb` | `3.2` | (Optionnel) La taille du fichier pour info. |
| `checksum_sha256`| (Laisser vide) | (Optionnel) Pour vérification avancée. |

5.  Cliquez sur **Save** (Sauvegarder).

---

## 3️⃣ Étape 3 : Vérification (Application)

1.  Ouvrez l'application mobile **TipTiga**.
2.  Sur l'écran d'accueil, regardez l'icône de mise à jour (flèche vers le bas) en haut à droite.
3.  Une **pastille rouge** 🔴 doit apparaître.
4.  Cliquez dessus : une fenêtre doit s'ouvrir avec votre message (`changelog`).
5.  Cliquez sur **Télécharger**.
6.  Une fois fini, l'appli utilisera le nouveau modèle immédiatement ! 🎉

---

## 💡 Bon à savoir

*   **Retour en arrière** : Si la nouvelle version plante, il suffit de retourner dans Supabase, Table `active_models`, et de décocher `is_active` sur la ligne problématique. L'appli reviendra à la version précédente ou à la version par défaut.
*   **Version minimale** : L'application embarque la version `3.0.0` par défaut. Toute mise à jour doit avoir un numéro de version supérieur (ex: `3.0.1`, `3.1.0`, `4.0.0`).
