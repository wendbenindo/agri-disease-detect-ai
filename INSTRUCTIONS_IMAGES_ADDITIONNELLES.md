# 📸 Instructions - Images Additionnelles pour Produits

## ✅ Implémentation Complétée

### Fichiers Créés/Modifiés:

1. **Service de gestion des images**
   - `lib/services/marketplace/product_images_service.dart` ✅
   - Upload multiple d'images
   - Récupération des images par produit
   - Suppression d'images

2. **Widget Carrousel**
   - `lib/widgets/marketplace/image_carousel.dart` ✅
   - Affichage en carrousel avec indicateurs
   - Vue plein écran avec zoom
   - Compteur d'images

3. **Modèle Product**
   - `lib/model/marketplace/product.dart` ✅
   - Ajout de `List<String> additionalImages`
   - Méthode `allImages` pour obtenir toutes les images
   - Méthode `copyWith()` mise à jour

4. **Page d'ajout de produit**
   - `lib/pages/marketplace/add_product_page.dart` ✅
   - Sélection multiple d'images (jusqu'à 5)
   - Aperçu en grille
   - Upload automatique lors de la sauvegarde

5. **Page de détails du produit**
   - `lib/pages/marketplace/product_detail_page.dart` ✅
   - Carrousel d'images avec navigation
   - Chargement automatique des images additionnelles

---

## 🔧 Configuration Requise

### 1. Exécuter le Script SQL dans Supabase

**IMPORTANT**: Vous devez exécuter le script SQL pour créer la table `product_images`.

#### Étapes:

1. Ouvrez votre projet Supabase
2. Allez dans **SQL Editor**
3. Copiez le contenu du fichier `supabase_product_images.sql`
4. Collez-le dans l'éditeur SQL
5. Cliquez sur **Run** pour exécuter

Le script va créer:
- ✅ Table `product_images` avec colonnes:
  - `id` (UUID, clé primaire)
  - `product_id` (UUID, référence à products)
  - `image_url` (TEXT)
  - `display_order` (INTEGER)
  - `created_at` (TIMESTAMP)
- ✅ Index pour optimiser les requêtes
- ✅ Politiques RLS (Row Level Security)
- ✅ Fonction `get_product_images()` pour récupérer les images

---

## 📱 Utilisation

### Pour les Vendeurs (Ajouter un Produit):

1. Ouvrir **TipTiga Market**
2. Cliquer sur **Ajouter un produit**
3. Remplir les informations du produit
4. **Photo principale**: Cliquer sur "Sélectionner une image"
5. **Images additionnelles**: 
   - Cliquer sur "Ajouter des images"
   - Sélectionner jusqu'à 5 images supplémentaires
   - Les images s'affichent en grille
   - Cliquer sur ❌ pour supprimer une image
6. Cliquer sur **Enregistrer le produit**

### Pour les Acheteurs (Voir un Produit):

1. Ouvrir un produit dans **TipTiga Market**
2. **Carrousel d'images**:
   - Swiper gauche/droite pour naviguer
   - Indicateurs de page en bas
   - Compteur d'images en haut à droite (ex: "2/5")
3. **Vue plein écran**:
   - Cliquer sur une image pour l'agrandir
   - Pincer pour zoomer
   - Swiper pour naviguer entre les images

---

## 🎨 Fonctionnalités

### ✅ Upload Multiple
- Sélection de plusieurs images en une fois
- Limite de 5 images additionnelles par produit
- Aperçu avant upload
- Suppression individuelle

### ✅ Carrousel Interactif
- Navigation fluide entre les images
- Indicateurs de page (points blancs)
- Compteur d'images (ex: "3/5")
- Vue plein écran avec zoom

### ✅ Optimisation
- Images redimensionnées automatiquement (1920x1080)
- Qualité optimisée (85%)
- Chargement progressif
- Gestion des erreurs

### ✅ Sécurité
- Politiques RLS activées
- Seuls les vendeurs peuvent ajouter/supprimer leurs images
- Tout le monde peut voir les images des produits disponibles

---

## 🔍 Vérification

### Vérifier que la table est créée:

```sql
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'product_images'
ORDER BY ordinal_position;
```

### Vérifier les politiques RLS:

```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'product_images';
```

---

## 🐛 Dépannage

### Erreur: "Table 'product_images' does not exist"
➡️ **Solution**: Exécutez le script `supabase_product_images.sql` dans Supabase SQL Editor

### Les images ne s'affichent pas
➡️ **Vérifications**:
1. Le bucket `product-images` existe dans Supabase Storage
2. Le bucket est configuré en **public**
3. Les URLs des images sont valides

### Erreur lors de l'upload
➡️ **Vérifications**:
1. Les politiques RLS sont correctement configurées
2. L'utilisateur est bien authentifié
3. Le produit appartient bien au vendeur

---

## 📊 Structure de la Base de Données

```
products
├── id (UUID)
├── name (TEXT)
├── photo_url (TEXT) ← Image principale
└── ...

product_images
├── id (UUID)
├── product_id (UUID) → products.id
├── image_url (TEXT) ← Images additionnelles
├── display_order (INTEGER)
└── created_at (TIMESTAMP)
```

---

## 🎯 Prochaines Étapes

1. ✅ Exécuter `supabase_product_images.sql`
2. ✅ Tester l'ajout d'un produit avec plusieurs images
3. ✅ Vérifier l'affichage du carrousel
4. ✅ Tester la vue plein écran

---

## 📝 Notes Importantes

- **Limite**: 5 images additionnelles maximum par produit
- **Format**: JPG, PNG supportés
- **Taille**: Redimensionnées automatiquement à 1920x1080
- **Qualité**: 85% pour optimiser la taille
- **Suppression**: Les images sont supprimées automatiquement quand le produit est supprimé (ON DELETE CASCADE)

---

## ✨ Améliorations Futures Possibles

- [ ] Réorganiser l'ordre des images (drag & drop)
- [ ] Ajouter des légendes aux images
- [ ] Compression plus agressive pour mobile
- [ ] Lazy loading des images
- [ ] Cache des images
- [ ] Support de vidéos

---

**Date**: 24 février 2026  
**Status**: ✅ Implémentation complète  
**Testé**: ⏳ En attente de test après exécution du script SQL
