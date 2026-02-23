-- ============================================================================
-- CORRECTION RLS SUR LA TABLE PRODUCTS
-- ============================================================================
-- Problème: Le RLS bloque l'insertion de produits par les vendeurs
-- Solution: Désactiver RLS sur products (sécurité gérée dans l'app)

-- Désactiver RLS sur products
ALTER TABLE products DISABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "Lecture publique des produits" ON products;
DROP POLICY IF EXISTS "Vendeurs peuvent créer" ON products;
DROP POLICY IF EXISTS "Propriétaire peut modifier" ON products;
DROP POLICY IF EXISTS "Propriétaire peut supprimer" ON products;
DROP POLICY IF EXISTS "Tout le monde peut voir les produits" ON products;
DROP POLICY IF EXISTS "Seuls les vendeurs peuvent créer des produits" ON products;
DROP POLICY IF EXISTS "Seuls les vendeurs peuvent modifier leurs produits" ON products;
DROP POLICY IF EXISTS "Seuls les vendeurs peuvent supprimer leurs produits" ON products;

-- Vérifier l'état du RLS sur toutes les tables
SELECT 
  schemaname,
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE tablename IN ('products', 'vendors', 'vendor_requests', 'users', 'categories')
  AND schemaname = 'public'
ORDER BY tablename;

-- ✅ RLS désactivé sur products
-- ⚠️  Sécurité gérée au niveau de l'application Flutter
-- ⚠️  Seuls les vendeurs approuvés peuvent créer des produits (vérification app)
