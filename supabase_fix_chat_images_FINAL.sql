-- ============================================
-- FIX FINAL - POLITIQUES CHAT-IMAGES
-- ============================================
-- Ce script résout définitivement l'erreur 403
-- en créant des politiques RLS ultra-permissives
-- ============================================

-- ÉTAPE 1 : Supprimer TOUTES les politiques sur storage.objects
-- (Attention : cela affecte tous les buckets temporairement)
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    -- Supprimer toutes les politiques qui mentionnent 'chat'
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
    LOOP
        IF pol.policyname ILIKE '%chat%' THEN
            EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
            RAISE NOTICE 'Supprimé: %', pol.policyname;
        END IF;
    END LOOP;
END $$;

-- ÉTAPE 2 : Créer des politiques ULTRA-PERMISSIVES pour chat-images
-- (On va restreindre après si nécessaire)

-- Politique 1 : Tout le monde peut LIRE (SELECT)
CREATE POLICY "chat_images_select_all"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'chat-images' );

-- Politique 2 : Tout le monde authentifié peut INSÉRER (INSERT)
CREATE POLICY "chat_images_insert_auth"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'chat-images' );

-- Politique 3 : Tout le monde authentifié peut METTRE À JOUR (UPDATE)
CREATE POLICY "chat_images_update_auth"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'chat-images' )
WITH CHECK ( bucket_id = 'chat-images' );

-- Politique 4 : Tout le monde authentifié peut SUPPRIMER (DELETE)
CREATE POLICY "chat_images_delete_auth"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'chat-images' );

-- ÉTAPE 3 : Vérifier que le bucket est bien PUBLIC
UPDATE storage.buckets 
SET public = true 
WHERE id = 'chat-images';

-- ÉTAPE 4 : Vérifier les politiques créées
SELECT 
    '✅ Politique créée: ' || policyname as status,
    cmd as operation,
    roles
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE 'chat_images%'
ORDER BY cmd;

-- ÉTAPE 5 : Vérifier le bucket
SELECT 
    '✅ Bucket configuré' as status,
    id,
    name,
    public,
    file_size_limit / 1024 / 1024 as size_limit_mb
FROM storage.buckets 
WHERE id = 'chat-images';

-- ============================================
-- RÉSULTAT ATTENDU
-- ============================================
-- Vous devriez voir :
-- ✅ 4 politiques créées (SELECT, INSERT, UPDATE, DELETE)
-- ✅ Bucket public = true
-- ✅ Taille limite = 5 MB
-- ============================================

-- ============================================
-- TEST IMMÉDIAT
-- ============================================
-- Après avoir exécuté ce script :
-- 1. Redémarrez l'app Flutter (Hot Restart)
-- 2. Ouvrez une conversation
-- 3. Cliquez sur 📷
-- 4. Sélectionnez une image
-- 5. ✅ Devrait fonctionner !
-- ============================================

-- ============================================
-- SI ÇA NE FONCTIONNE TOUJOURS PAS
-- ============================================
-- Exécutez cette requête pour voir les détails :
-- 
-- SELECT 
--   auth.uid() as current_user_id,
--   auth.role() as current_role;
-- 
-- Si current_role est NULL ou 'anon', l'utilisateur
-- n'est pas authentifié. Déconnectez-vous et 
-- reconnectez-vous dans l'app.
-- ============================================
