# 🚀 Guide Rapide : Créer le Bucket Chat-Images

## ❌ Erreur Actuelle

```
StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)
```

Cette erreur signifie que le bucket `chat-images` n'existe pas encore dans votre Supabase.

## ✅ Solution en 2 Minutes

### Option 1 : Via l'Interface Supabase (Recommandé)

1. **Ouvrir Supabase Dashboard**
   - Allez sur https://supabase.com/dashboard
   - Sélectionnez votre projet
   - Cliquez sur "Storage" dans le menu de gauche

2. **Créer le bucket**
   - Cliquez sur "New bucket"
   - Nom : `chat-images`
   - Public bucket : ✅ **Cochez la case**
   - File size limit : `5` MB
   - Allowed MIME types : `image/jpeg, image/jpg, image/png, image/webp`
   - Cliquez sur "Create bucket"

3. **Configurer les politiques**
   - Cliquez sur le bucket `chat-images`
   - Allez dans l'onglet "Policies"
   - Cliquez sur "New Policy"
   - Créez ces 4 politiques :

   **a) Lecture publique**
   ```
   Policy name: Public Access
   Allowed operation: SELECT
   Policy definition: true
   ```

   **b) Upload pour utilisateurs authentifiés**
   ```
   Policy name: Authenticated users can upload
   Allowed operation: INSERT
   Policy definition: auth.role() = 'authenticated'
   ```

   **c) Mise à jour**
   ```
   Policy name: Users can update own images
   Allowed operation: UPDATE
   Policy definition: auth.role() = 'authenticated'
   ```

   **d) Suppression**
   ```
   Policy name: Users can delete own images
   Allowed operation: DELETE
   Policy definition: auth.role() = 'authenticated'
   ```

### Option 2 : Via SQL (Plus Rapide)

1. **Ouvrir SQL Editor**
   - Dans Supabase Dashboard
   - Cliquez sur "SQL Editor" dans le menu de gauche

2. **Copier-coller ce script**
   - Ouvrez le fichier `supabase_create_chat_images_bucket.sql`
   - Copiez tout le contenu
   - Collez dans l'éditeur SQL
   - Cliquez sur "Run"

3. **Vérifier**
   - Allez dans Storage
   - Vous devriez voir le bucket `chat-images`

## 🧪 Tester

1. **Ouvrir l'application**
2. **Aller dans une conversation**
3. **Cliquer sur l'icône 📷**
4. **Sélectionner une image**
5. **L'image devrait s'uploader et s'afficher** ✅

## 🔍 Vérification

Pour vérifier que tout fonctionne, exécutez ce SQL :

```sql
-- Vérifier que le bucket existe
SELECT * FROM storage.buckets WHERE id = 'chat-images';

-- Vérifier les politiques
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%chat%';
```

Vous devriez voir :
- 1 bucket `chat-images` avec `public = true`
- 4 politiques (SELECT, INSERT, UPDATE, DELETE)

## ❓ En Cas de Problème

### Erreur : "Bucket already exists"
✅ C'est bon ! Le bucket existe déjà. Vérifiez juste les politiques.

### Erreur : "Permission denied"
❌ Les politiques RLS ne sont pas correctes. Recréez-les avec le script SQL.

### L'image ne s'affiche pas
1. Vérifiez que le bucket est **public** (case cochée)
2. Vérifiez la politique SELECT (lecture publique)
3. Regardez les logs de l'app pour voir l'URL générée

### L'upload échoue
1. Vérifiez la politique INSERT
2. Vérifiez que l'utilisateur est bien authentifié
3. Vérifiez la taille du fichier (max 5 MB)
4. Vérifiez le type MIME (jpeg, jpg, png, webp)

## 📊 Résultat Attendu

Après la création du bucket :

```
✅ Bucket chat-images créé
✅ Public = true
✅ Limite = 5 MB
✅ Types = image/jpeg, image/jpg, image/png, image/webp
✅ 4 politiques RLS configurées
```

Dans l'app :
```
✅ Clic sur 📷 → Sélection d'image
✅ Upload → Barre de progression
✅ Affichage → Image visible dans le chat
✅ Autres utilisateurs → Peuvent voir l'image
```

## 🎯 Prochaine Étape

Une fois le bucket créé, testez l'envoi d'images dans le chat. Tout devrait fonctionner parfaitement !

---

**Temps estimé** : 2-3 minutes  
**Difficulté** : Facile  
**Fichiers nécessaires** : `supabase_create_chat_images_bucket.sql`
