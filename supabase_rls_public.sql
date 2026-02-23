-- ============================================================================
-- POLITIQUES RLS PUBLIQUES - Accès libre en lecture
-- ============================================================================

-- Supprimer les anciennes politiques authentifiées
DROP POLICY IF EXISTS "Lecture authentifiée des catégories" ON categories;
DROP POLICY IF EXISTS "Lecture authentifiée des vendeurs" ON vendors;
DROP POLICY IF EXISTS "Lecture authentifiée des produits" ON products;
DROP POLICY IF EXISTS "Lecture authentifiée des recommandations" ON disease_products;

-- Recréer les politiques PUBLIQUES (lecture libre)
CREATE POLICY "Lecture publique des catégories"
  ON categories
  FOR SELECT
  USING (true);

CREATE POLICY "Lecture publique des vendeurs actifs"
  ON vendors
  FOR SELECT
  USING (is_active = true);

CREATE POLICY "Lecture publique des produits disponibles"
  ON products
  FOR SELECT
  USING (is_available = true);

CREATE POLICY "Lecture publique des recommandations"
  ON disease_products
  FOR SELECT
  USING (true);

-- ============================================================================
-- NOTE: L'authentification sera requise UNIQUEMENT pour contacter les vendeurs
-- ============================================================================
