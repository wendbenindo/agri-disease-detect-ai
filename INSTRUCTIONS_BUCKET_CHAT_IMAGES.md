# Instructions : Créer le bucket chat-images

## ⚠️ IMPORTANT

Pour que l'upload de photos dans le chat fonctionne, vous devez créer un bucket `chat-images` dans Supabase.

## 📝 Étapes

### 1. Ouvrir Supabase Dashboard

1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet
3. Cliquez sur "Storage" dans le menu de gauche

### 2. Créer le bucket

1. Cliquez sur "New bucket"
2. Nom du bucket: `chat-images`
3. Public bucket: ✅ **OUI** (cochez la case)
4. Cliquez sur "Create bucket"

### 3. Configurer les politiques (RLS)

Le bucket doit être public pour que les images soient accessibles. Voici les politiques recommandées :

```sql
-- Politique: Tout le monde peut lire les images
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'chat-images' );

-- Politique: Les utilisateurs authentifiés peuvent uploader
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat-images' 
  AND auth.role() = 'authenticated'
);

-- Politique: Les utilisateurs peuvent supprimer leurs propres images
CREATE POLICY "Users can delete own images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'chat-images'
  AND auth.role() = 'authenticated'
);
```

### 4. Vérifier

1. Allez dans Storage > chat-images
2. Vérifiez que le bucket est bien créé
3. Testez l'upload depuis l'application

## ✅ Résultat attendu

Une fois le bucket créé, vous pourrez :
- Cliquer sur l'icône 📷 dans le chat
- Sélectionner une image depuis votre galerie
- L'image sera uploadée et affichée dans la conversation

## 🔧 En cas de problème

Si l'upload ne fonctionne pas :

1. Vérifiez que le bucket `chat-images` existe
2. Vérifiez qu'il est public
3. Vérifiez les politiques RLS
4. Regardez les logs dans la console de l'app

## 📊 Structure des fichiers

Les images sont nommées ainsi :
```
chat_{conversationId}_{timestamp}.jpg
```

Exemple :
```
chat_55f0443f-509a-451b-b8c8-94571ab0dab1_1771947176083.jpg
```

Cela permet de :
- Identifier facilement les images par conversation
- Éviter les conflits de noms
- Faciliter le nettoyage automatique
