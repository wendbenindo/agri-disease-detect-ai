-- ============================================
-- CRÉATION DU BUCKET CHAT-IMAGES
-- ============================================
-- Ce script crée le bucket pour stocker les images
-- envoyées dans les conversations du chat
-- ============================================

-- 1. Créer le bucket chat-images (public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-images',
  'chat-images',
  true,  -- Public pour que les images soient accessibles
  5242880,  -- 5 MB max par fichier
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Supprimer toutes les anciennes politiques pour chat-images
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND (policyname LIKE '%chat%' OR policyname LIKE '%Chat%')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
    END LOOP;
END $$;

-- 3. Politique : Tout le monde peut lire les images du chat
CREATE POLICY "chat_images_public_read"
ON storage.objects FOR SELECT
USING ( bucket_id = 'chat-images' );

-- 4. Politique : Les utilisateurs authentifiés peuvent uploader dans chat-images
CREATE POLICY "chat_images_authenticated_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat-images' 
  AND auth.role() = 'authenticated'
);

-- 5. Politique : Les utilisateurs authentifiés peuvent mettre à jour dans chat-images
CREATE POLICY "chat_images_authenticated_update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'chat-images'
  AND auth.role() = 'authenticated'
)
WITH CHECK (
  bucket_id = 'chat-images'
  AND auth.role() = 'authenticated'
);

-- 6. Politique : Les utilisateurs authentifiés peuvent supprimer dans chat-images
CREATE POLICY "chat_images_authenticated_delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'chat-images'
  AND auth.role() = 'authenticated'
);

-- ============================================
-- VÉRIFICATION
-- ============================================

-- Vérifier que le bucket existe
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'chat-images';

-- Vérifier les politiques
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%chat%';

-- ============================================
-- RÉSULTAT ATTENDU
-- ============================================
-- Le bucket chat-images doit être créé avec :
-- - public = true
-- - file_size_limit = 5242880 (5 MB)
-- - allowed_mime_types = image/jpeg, image/jpg, image/png, image/webp
--
-- Les politiques doivent permettre :
-- - SELECT : Tout le monde (public)
-- - INSERT : Utilisateurs authentifiés
-- - UPDATE : Utilisateurs authentifiés (leurs propres images)
-- - DELETE : Utilisateurs authentifiés (leurs propres images)
-- ============================================

-- ============================================
-- NOTES
-- ============================================
-- Format des noms de fichiers :
-- chat_{conversationId}_{timestamp}.jpg
--
-- Exemple :
-- chat_55f0443f-509a-451b-b8c8-94571ab0dab1_1771947176083.jpg
--
-- Cela permet de :
-- - Identifier facilement les images par conversation
-- - Éviter les conflits de noms
-- - Faciliter le nettoyage automatique
-- ============================================
