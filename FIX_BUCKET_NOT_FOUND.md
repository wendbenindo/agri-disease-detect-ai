# Fix: Erreur "Bucket not found"

## ❌ Erreur

```
StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)
```

## 🔍 Cause

Le bucket `chat-images` n'existe pas encore dans Supabase Storage.

## ✅ Solution

### Étape 1 : Créer le bucket

1. Ouvrez https://supabase.com/dashboard
2. Sélectionnez votre projet
3. Cliquez sur **Storage** dans le menu de gauche
4. Cliquez sur **New bucket**
5. Remplissez :
   - **Name**: `chat-images`
   - **Public bucket**: ✅ **Cochez cette case** (important !)
6. Cliquez sur **Create bucket**

### Étape 2 : Configurer les politiques (optionnel mais recommandé)

Pour plus de sécurité, ajoutez ces politiques RLS :

1. Allez dans **Storage** > **Policies**
2. Sélectionnez le bucket `chat-images`
3. Cliquez sur **New policy**

**Politique 1 : Lecture publique**
```sql
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'chat-images' );
```

**Politique 2 : Upload pour utilisateurs authentifiés**
```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat-images'
);
```

**Politique 3 : Suppression pour utilisateurs authentifiés**
```sql
CREATE POLICY "Users can delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'chat-images'
);
```

### Étape 3 : Tester

1. Relancez l'application
2. Ouvrez une conversation
3. Cliquez sur l'icône 📷
4. Sélectionnez une image
5. L'image devrait s'uploader et s'afficher dans le chat

## 🔧 Vérification

Pour vérifier que le bucket existe :

1. Allez dans **Storage** dans Supabase
2. Vous devriez voir `chat-images` dans la liste
3. Cliquez dessus pour voir les images uploadées

## 📊 Structure des fichiers

Les images sont nommées :
```
chat_{conversationId}_{timestamp}.jpg
```

Exemple :
```
chat_55f0443f-509a-451b-b8c8-94571ab0dab1_1771947176083.jpg
```

## ⚠️ Important

- Le bucket DOIT être **public** pour que les images soient accessibles
- Sans le bucket, l'upload de photos ne fonctionnera pas
- Les images existantes dans les messages ne seront pas affectées

## 🎯 Résultat attendu

Après avoir créé le bucket :
- ✅ Plus d'erreur "Bucket not found"
- ✅ Upload de photos fonctionne
- ✅ Images affichées dans le chat
- ✅ Badge rouge disparaît quand vous lisez les messages
