-- ============================================
-- CORRECTION DES POLITIQUES RLS CHAT-IMAGES
-- ============================================
-- Ce script corrige l'erreur 403 Unauthorized
-- en recréant les bonnes politiques RLS
-- ============================================

-- 1. Supprimer TOUTES les politiques existantes pour chat-images
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
        AND (
            policyname LIKE '%chat%' 
            OR policyname LIKE '%Chat%'
            OR policyname LIKE '%Public Access%'
        )
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
        RAISE NOTICE 'Politique supprimée: %', pol.policyname;
    END LOOP;
END $$;

-- 2. Créer la politique de LECTURE (SELECT) - Public
CREATE POLICY "chat_images_public_read"
ON storage.objects FOR SELECT
USING ( bucket_id = 'chat-images' );

-- 3. Créer la politique d'INSERTION (INSERT) - Authentifiés uniquement
CREATE POLICY "chat_images_authenticated_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat-images' 
  AND auth.role() = 'authenticated'
);

-- 4. Créer la politique de MISE À JOUR (UPDATE) - Authentifiés uniquement
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

-- 5. Créer la politique de SUPPRESSION (DELETE) - Authentifiés uniquement
CREATE POLICY "chat_images_authenticated_delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'chat-images'
  AND auth.role() = 'authenticated'
);

-- ============================================
-- VÉRIFICATION
-- ============================================

-- Afficher toutes les politiques pour chat-images
SELECT 
  policyname,
  cmd as operation,
  CASE 
    WHEN qual IS NOT NULL THEN 'USING: ' || qual
    ELSE ''
  END as using_clause,
  CASE 
    WHEN with_check IS NOT NULL THEN 'WITH CHECK: ' || with_check
    ELSE ''
  END as with_check_clause
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%chat_images%'
ORDER BY cmd;

-- Vérifier le bucket
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'chat-images';

-- ============================================
-- RÉSULTAT ATTENDU
-- ============================================
-- Vous devriez voir 4 politiques :
-- 1. chat_images_public_read (SELECT)
-- 2. chat_images_authenticated_insert (INSERT)
-- 3. chat_images_authenticated_update (UPDATE)
-- 4. chat_images_authenticated_delete (DELETE)
--
-- Le bucket doit être :
-- - public = true
-- - file_size_limit = 5242880 (5 MB)
-- ============================================

-- ============================================
-- TEST MANUEL
-- ============================================
-- Pour tester que ça fonctionne :
-- 1. Ouvrir l'app Flutter
-- 2. Aller dans une conversation
-- 3. Cliquer sur l'icône 📷
-- 4. Sélectionner une image
-- 5. L'upload devrait fonctionner sans erreur 403
-- ============================================
