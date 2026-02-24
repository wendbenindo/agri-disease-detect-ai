-- ============================================
-- FIX CHAT-IMAGES POUR AUTHENTIFICATION CUSTOM
-- ============================================
-- Ce script crée des politiques RLS qui fonctionnent
-- SANS utiliser auth.users (pour système d'auth custom)
-- ============================================

-- ÉTAPE 1 : Supprimer toutes les anciennes politiques chat
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
        AND policyname ILIKE '%chat%'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
        RAISE NOTICE 'Supprimé: %', pol.policyname;
    END LOOP;
END $$;

-- ÉTAPE 2 : Créer des politiques PUBLIQUES (sans vérification auth)
-- Attention : Cela permet à tout le monde d'uploader
-- Mais c'est nécessaire si vous n'utilisez pas auth.users

-- Politique 1 : Tout le monde peut LIRE
CREATE POLICY "chat_images_public_select"
ON storage.objects FOR SELECT
USING ( bucket_id = 'chat-images' );

-- Politique 2 : Tout le monde peut INSÉRER (upload)
CREATE POLICY "chat_images_public_insert"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'chat-images' );

-- Politique 3 : Tout le monde peut METTRE À JOUR
CREATE POLICY "chat_images_public_update"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'chat-images' )
WITH CHECK ( bucket_id = 'chat-images' );

-- Politique 4 : Tout le monde peut SUPPRIMER
CREATE POLICY "chat_images_public_delete"
ON storage.objects FOR DELETE
USING ( bucket_id = 'chat-images' );

-- ÉTAPE 3 : Vérifier que le bucket est PUBLIC
UPDATE storage.buckets 
SET public = true 
WHERE id = 'chat-images';

-- ÉTAPE 4 : Vérifier les politiques créées
SELECT 
    '✅ Politique créée: ' || policyname as status,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE 'chat_images_public%'
ORDER BY cmd;

-- ÉTAPE 5 : Vérifier le bucket
SELECT 
    '✅ Bucket configuré' as status,
    id,
    name,
    public
FROM storage.buckets 
WHERE id = 'chat-images';

-- ============================================
-- RÉSULTAT ATTENDU
-- ============================================
-- ✅ 4 politiques publiques créées
-- ✅ Bucket public = true
-- ✅ Upload devrait fonctionner maintenant !
-- ============================================

-- ============================================
-- IMPORTANT - SÉCURITÉ
-- ============================================
-- Ces politiques permettent à TOUT LE MONDE d'uploader.
-- C'est nécessaire car vous n'utilisez pas auth.users.
-- 
-- Pour améliorer la sécurité plus tard, vous pouvez :
-- 1. Ajouter une vérification dans votre app Flutter
-- 2. Utiliser des tokens JWT custom
-- 3. Migrer vers auth.users de Supabase
-- ============================================
