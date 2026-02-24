# 🔧 Fix Erreur 403 - Chat Images

## ❌ Erreur Actuelle

```
StorageException(message: new row violates row-level security policy, 
statusCode: 403, error: Unauthorized)
```

## 🔍 Diagnostic

Cette erreur signifie que :
- ✅ Le bucket `chat-images` existe
- ❌ Les politiques RLS (Row Level Security) bloquent l'upload
- ❌ L'utilisateur authentifié n'a pas la permission d'insérer

## ✅ Solution Rapide (1 minute)

### Étape 1 : Ouvrir SQL Editor

1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet
3. Cliquez sur "SQL Editor" dans le menu de gauche

### Étape 2 : Exécuter le Script de Correction

1. Ouvrez le fichier `supabase_fix_chat_images_policies.sql`
2. Copiez TOUT le contenu
3. Collez dans l'éditeur SQL
4. Cliquez sur "Run" (ou F5)

### Étape 3 : Vérifier

Vous devriez voir dans les résultats :
```
✅ 4 politiques créées :
   - chat_images_public_read (SELECT)
   - chat_images_authenticated_insert (INSERT)
   - chat_images_authenticated_update (UPDATE)
   - chat_images_authenticated_delete (DELETE)
```

### Étape 4 : Tester

1. Retournez dans l'app Flutter
2. Ouvrez une conversation
3. Cliquez sur 📷
4. Sélectionnez une image
5. ✅ L'upload devrait fonctionner !

## 🔍 Vérification Manuelle (Optionnel)

Si vous voulez vérifier manuellement les politiques :

1. Dans Supabase Dashboard, allez dans "Storage"
2. Cliquez sur le bucket `chat-images`
3. Allez dans l'onglet "Policies"
4. Vous devriez voir 4 politiques actives

## 🐛 Problèmes Possibles

### Erreur : "policy already exists"

C'est normal si vous avez déjà des politiques. Le script les supprime d'abord.

**Solution** : Exécutez quand même le script complet, il va :
1. Supprimer les anciennes politiques
2. Créer les nouvelles

### L'erreur 403 persiste

**Causes possibles** :
1. L'utilisateur n'est pas authentifié
2. Le token de session a expiré
3. Les politiques n'ont pas été appliquées

**Solutions** :
1. Déconnectez-vous et reconnectez-vous dans l'app
2. Vérifiez que `auth.role() = 'authenticated'` dans les politiques
3. Attendez 10 secondes et réessayez

### Le bucket n'est pas public

Si les images ne s'affichent pas après l'upload :

1. Allez dans Storage > chat-images
2. Cliquez sur "Settings"
3. Cochez "Public bucket"
4. Sauvegardez

## 📊 Explication Technique

### Pourquoi l'erreur 403 ?

Les politiques RLS de Supabase contrôlent qui peut faire quoi sur les fichiers. Par défaut, PERSONNE ne peut rien faire. Il faut explicitement autoriser :

```sql
-- ❌ AVANT : Pas de politique = Accès refusé
-- Résultat : 403 Unauthorized

-- ✅ APRÈS : Politique INSERT pour authentifiés
CREATE POLICY "chat_images_authenticated_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat-images' 
  AND auth.role() = 'authenticated'
);
-- Résultat : Upload autorisé pour utilisateurs connectés
```

### Les 4 Politiques Nécessaires

1. **SELECT (Lecture)** : Public
   - Tout le monde peut voir les images
   - Nécessaire pour afficher les images dans le chat

2. **INSERT (Création)** : Authentifiés
   - Seuls les utilisateurs connectés peuvent uploader
   - Sécurise contre les uploads anonymes

3. **UPDATE (Modification)** : Authentifiés
   - Permet de remplacer une image
   - Rarement utilisé mais utile

4. **DELETE (Suppression)** : Authentifiés
   - Permet de supprimer une image
   - Utile pour le nettoyage

## 🎯 Résultat Attendu

Après avoir exécuté le script :

```
✅ Upload d'images : Fonctionne
✅ Affichage d'images : Fonctionne
✅ Sécurité : Seuls les authentifiés peuvent uploader
✅ Lecture : Tout le monde peut voir les images
```

## 📝 Logs de Débogage

Si ça ne fonctionne toujours pas, vérifiez les logs :

```dart
// Dans storage_service.dart
print('🔐 User ID: ${_client.auth.currentUser?.id}');
print('🔐 User role: ${_client.auth.currentUser?.role}');
print('📁 Bucket: chat-images');
print('📄 File path: $filePath');
```

Vous devriez voir :
```
🔐 User ID: [un UUID]
🔐 User role: authenticated
📁 Bucket: chat-images
📄 File path: chat_[conversation-id]_[timestamp].jpg
```

Si `User role` est `null` ou `anon`, l'utilisateur n'est pas authentifié.

## 🚀 Prochaine Étape

Une fois le script exécuté, l'envoi d'images dans le chat fonctionnera parfaitement !

---

**Temps estimé** : 1 minute  
**Difficulté** : Facile  
**Fichier nécessaire** : `supabase_fix_chat_images_policies.sql`
