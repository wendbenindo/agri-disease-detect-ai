-- =====================================================
-- FIX: Désactiver RLS sur verification_codes
-- =====================================================
-- Raison: Système d'authentification personnalisé (pas Supabase Auth)
-- Les fonctions utilisent SECURITY DEFINER pour gérer les permissions

-- Désactiver RLS sur la table verification_codes
ALTER TABLE verification_codes DISABLE ROW LEVEL SECURITY;

-- Vérification
SELECT 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'verification_codes';

-- Le résultat devrait montrer rowsecurity = false

-- =====================================================
-- Note: Les fonctions create_verification_code() et verify_code()
-- utilisent SECURITY DEFINER, donc elles s'exécutent avec les
-- privilèges du propriétaire de la fonction (qui a tous les droits)
-- =====================================================
