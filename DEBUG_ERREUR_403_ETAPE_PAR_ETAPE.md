# 🔧 Debug Erreur 403 - Étape par Étape

## 🎯 Objectif

Résoudre définitivement l'erreur 403 lors de l'upload d'images dans le chat.

## 📋 Checklist de Vérification

### ✅ Étape 1 : Vérifier que le Bucket Existe

1. Ouvrez https://supabase.com/dashboard
2. Allez dans "Storage"
3. Vérifiez que le bucket `chat-images` existe

**Si le bucket n'existe pas** :
- Créez-le manuellement (New bucket → chat-images → Public ✅)

### ✅ Étape 2 : Exécuter le Script SQL Final

1. Allez dans "SQL Editor"
2. Copiez le contenu de `supabase_fix_chat_images_FINAL.sql`
3. Collez et cliquez "Run"
4. Vérifiez les résultats :
   - ✅ 4 politiques créées
   - ✅ Bucket public = true

### ✅ Étape 3 : Vérifier l'Authentification

Dans l'app Flutter, ajoutez ces logs temporaires :

```dart
// Dans storage_service.dart, méthode uploadChatImage
final user = _supabase.auth.currentUser;
print('🔐 User ID: ${user?.id}');
print('🔐 User role: ${user?.role}');
```

**Résultat attendu** :
```
🔐 User ID: [un UUID]
🔐 User role: authenticated
```

**Si User ID est null** :
- L'utilisateur n'est pas connecté
- Déconnectez-vous et reconnectez-vous

**Si User role est 'anon'** :
- La session a expiré
- Redémarrez l'app

### ✅ Étape 4 : Vérifier les Politiques dans Supabase

Exécutez cette requête SQL :

```sql
SELECT 
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE 'chat_images%';
```

**Résultat attendu** :
```
chat_images_select_all    | SELECT | {public}        | bucket_id = 'chat-images'
chat_images_insert_auth   | INSERT | {authenticated} | bucket_id = 'chat-images'
chat_images_update_auth   | UPDATE | {authenticated} | bucket_id = 'chat-images'
chat_images_delete_auth   | DELETE | {authenticated} | bucket_id = 'chat-images'
```

### ✅ Étape 5 : Tester l'Upload

1. **Redémarrez l'app** (Hot Restart, pas Hot Reload)
2. Ouvrez une conversation
3. Cliquez sur 📷
4. Sélectionnez une image
5. Regardez les logs

**Logs attendus** :
```
🔐 User ID: [UUID]
🔐 User role: authenticated
📤 Upload de l'image chat: chat_[conversation-id]_[timestamp].jpg
📁 Bucket: chat-images
✅ Image chat uploadée: chat_[conversation-id]_[timestamp].jpg
🔗 URL publique chat: https://[project].supabase.co/storage/v1/object/public/chat-images/...
```

## 🐛 Problèmes Courants

### Problème 1 : User role = null

**Cause** : L'utilisateur n'est pas authentifié

**Solution** :
1. Déconnectez-vous de l'app
2. Reconnectez-vous
3. Réessayez

### Problème 2 : Politiques non créées

**Cause** : Le script SQL n'a pas été exécuté correctement

**Solution** :
1. Supprimez manuellement les anciennes politiques :
   - Storage → chat-images → Policies
   - Supprimez toutes les politiques
2. Réexécutez le script `supabase_fix_chat_images_FINAL.sql`

### Problème 3 : Bucket non public

**Cause** : Le bucket est privé

**Solution** :
1. Storage → chat-images → Settings
2. Cochez "Public bucket"
3. Sauvegardez

### Problème 4 : Erreur persiste après tout

**Cause possible** : Cache ou session corrompue

**Solution** :
1. Désinstallez complètement l'app
2. Réinstallez
3. Reconnectez-vous
4. Réessayez

## 🔍 Diagnostic Avancé

### Vérifier le Rôle de l'Utilisateur

Exécutez dans SQL Editor :

```sql
SELECT 
  id,
  email,
  role,
  created_at,
  last_sign_in_at
FROM auth.users
ORDER BY last_sign_in_at DESC
LIMIT 5;
```

Tous les utilisateurs doivent avoir `role = 'authenticated'`.

### Vérifier les Permissions du Bucket

```sql
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types,
  owner
FROM storage.buckets 
WHERE id = 'chat-images';
```

Doit retourner :
- `public = true`
- `file_size_limit = 5242880` (5 MB)
- `allowed_mime_types = {image/jpeg, image/jpg, image/png, image/webp}`

### Tester l'Upload Manuellement

Dans Supabase Dashboard :
1. Storage → chat-images
2. Cliquez "Upload file"
3. Uploadez une image de test
4. Si ça fonctionne ici mais pas dans l'app → Problème d'authentification
5. Si ça ne fonctionne pas ici → Problème de politiques

## 🎯 Solution de Dernier Recours

Si RIEN ne fonctionne :

### Option 1 : Recréer le Bucket

```sql
-- Supprimer le bucket (attention : supprime toutes les images)
DELETE FROM storage.buckets WHERE id = 'chat-images';

-- Recréer
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-images',
  'chat-images',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
);

-- Recréer les politiques
-- (Copiez les 4 politiques du script FINAL)
```

### Option 2 : Désactiver RLS Temporairement (DANGEREUX)

**⚠️ À utiliser UNIQUEMENT pour tester** :

```sql
-- Désactiver RLS sur storage.objects (TEMPORAIRE)
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Tester l'upload dans l'app
-- Si ça fonctionne, le problème vient des politiques

-- RÉACTIVER IMMÉDIATEMENT :
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

## 📞 Besoin d'Aide ?

Si après toutes ces étapes ça ne fonctionne toujours pas :

1. Copiez les logs complets de l'app
2. Copiez le résultat de la requête sur les politiques
3. Copiez le résultat de la requête sur le bucket
4. Partagez ces informations

## ✅ Checklist Finale

Avant de dire que c'est résolu, vérifiez :

- [ ] Le bucket `chat-images` existe
- [ ] Le bucket est public (public = true)
- [ ] 4 politiques sont créées et actives
- [ ] L'utilisateur est authentifié (role = authenticated)
- [ ] L'app a été redémarrée (Hot Restart)
- [ ] L'upload fonctionne sans erreur 403
- [ ] L'image s'affiche dans le chat
- [ ] Les autres utilisateurs peuvent voir l'image

---

**Temps estimé** : 10-15 minutes  
**Difficulté** : Moyenne  
**Fichiers nécessaires** : `supabase_fix_chat_images_FINAL.sql`
