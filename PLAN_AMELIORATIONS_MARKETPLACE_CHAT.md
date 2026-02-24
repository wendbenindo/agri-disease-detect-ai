# Plan d'améliorations Marketplace & Chat

## ✅ Tâches complétées

1. ✅ Badge messages plus petit (22x22, style WhatsApp)
2. ✅ Titre "TipTiga Market" au lieu de "Marketplace"
3. ✅ AppBar vert pour MarketplacePage

## 🔄 Tâches en cours

### 1. Upload d'images additionnelles pour les produits

**Objectif** : Permettre d'ajouter plusieurs photos par produit

**Modifications nécessaires** :
- [ ] Modifier le modèle `Product` pour supporter plusieurs photos
- [ ] Modifier `AddProductPage` pour uploader plusieurs images
- [ ] Modifier `ProductDetailPage` pour afficher un carrousel d'images
- [ ] Créer une table `product_images` dans Supabase
- [ ] Mettre à jour les fonctions d'upload

**Fichiers à modifier** :
- `lib/model/marketplace/product.dart`
- `lib/pages/marketplace/add_product_page.dart`
- `lib/pages/marketplace/product_detail_page.dart`
- `lib/services/storage_service.dart`

### 2. Upload de photos dans le chat

**Objectif** : Permettre d'envoyer des images dans les conversations

**Modifications nécessaires** :
- [ ] Ajouter un bouton "📷" dans ChatPage
- [ ] Utiliser `image_picker` pour sélectionner une image
- [ ] Uploader l'image dans le bucket `chat-images`
- [ ] Envoyer le message avec l'URL de l'image
- [ ] Afficher l'image dans la bulle de message

**Fichiers à modifier** :
- `lib/pages/chat/chat_page.dart`
- `lib/services/chat_service.dart`
- `lib/services/storage_service.dart`

### 3. Badge "Nouveau" sur les produits récents

**Objectif** : Afficher un badge sur les produits ajoutés récemment (< 7 jours)

**Modifications nécessaires** :
- [ ] Ajouter une logique pour détecter les produits récents
- [ ] Afficher un badge "NOUVEAU" sur ProductCard
- [ ] Trier les produits pour afficher les nouveaux en premier
- [ ] Ajouter un compteur dans la navigation (optionnel)

**Fichiers à modifier** :
- `lib/widgets/marketplace/product_card.dart`
- `lib/pages/marketplace/marketplace_page.dart`

### 4. Couleur AppBar uniforme pour toute la section Market

**Objectif** : Toutes les pages du marketplace ont le même AppBar vert

**Pages à modifier** :
- [x] MarketplacePage
- [ ] ProductDetailPage
- [ ] AddProductPage
- [ ] EditProductPage
- [ ] ManageProductsPage

### 5. Suppression automatique des conversations après 1 mois

**Objectif** : Nettoyer automatiquement les vieilles conversations

**Modifications nécessaires** :
- [ ] Créer une fonction Supabase (cron job ou trigger)
- [ ] Supprimer les conversations > 30 jours
- [ ] Supprimer les messages associés
- [ ] Supprimer les images du bucket

**Fichiers à créer** :
- `supabase_cleanup_conversations.sql`

### 6. Suppression des images du bucket lors de la suppression

**Objectif** : Nettoyer le storage quand on supprime des conversations

**Modifications nécessaires** :
- [ ] Créer une fonction pour lister les images d'une conversation
- [ ] Supprimer les images du bucket avant de supprimer la conversation
- [ ] Ajouter un trigger SQL pour automatiser

**Fichiers à modifier** :
- `lib/services/storage_service.dart`
- `lib/services/chat_service.dart`

## 📝 Ordre de priorité

1. **Haute priorité** (fonctionnalités visibles)
   - Badge "Nouveau" sur produits récents
   - Couleur AppBar uniforme
   - Upload de photos dans le chat

2. **Moyenne priorité** (améliorations UX)
   - Upload d'images additionnelles pour produits
   - Carrousel d'images dans ProductDetailPage

3. **Basse priorité** (maintenance)
   - Suppression automatique des conversations
   - Nettoyage du storage

## 🚀 Prochaines étapes

Je vais commencer par les tâches de haute priorité dans l'ordre suivant :

1. Couleur AppBar uniforme (rapide)
2. Badge "Nouveau" sur produits (rapide)
3. Upload de photos dans le chat (moyen)
4. Images additionnelles pour produits (complexe)
5. Suppression automatique (complexe)

Voulez-vous que je continue avec ces tâches ?
