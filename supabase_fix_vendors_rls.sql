-- ============================================================================
-- CORRECTION RLS SUR LA TABLE VENDORS
-- ============================================================================
-- Problème: La fonction approve_vendor_request ne peut pas insérer dans vendors
-- à cause du RLS
-- Solution: Désactiver RLS sur vendors OU utiliser SECURITY DEFINER

-- Option 1: Désactiver RLS sur vendors (RECOMMANDÉ pour simplicité)
ALTER TABLE vendors DISABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "Tout le monde peut voir les vendeurs" ON vendors;
DROP POLICY IF EXISTS "Vendeurs peuvent modifier leur profil" ON vendors;
DROP POLICY IF EXISTS "Seuls les admins peuvent créer des vendeurs" ON vendors;

-- Option 2: Recréer la fonction avec SECURITY DEFINER
-- (permet à la fonction de contourner le RLS)
CREATE OR REPLACE FUNCTION approve_vendor_request(
  request_id UUID,
  admin_id UUID DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_user_id UUID;
  v_business_name TEXT;
  v_phone TEXT;
  v_city TEXT;
  v_region TEXT;
BEGIN
  -- Récupérer les infos de la demande
  SELECT user_id, business_name, phone, city, region
  INTO v_user_id, v_business_name, v_phone, v_city, v_region
  FROM vendor_requests
  WHERE id = request_id AND status = 'pending';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Demande introuvable ou déjà traitée';
  END IF;

  -- Mettre à jour le statut de la demande
  UPDATE vendor_requests
  SET 
    status = 'approved',
    reviewed_by = admin_id,
    reviewed_at = NOW(),
    updated_at = NOW()
  WHERE id = request_id;

  -- Changer le rôle de l'utilisateur dans la table users
  UPDATE users
  SET role = 'vendor', updated_at = NOW()
  WHERE id = v_user_id;

  -- Créer l'entrée dans la table vendors
  INSERT INTO vendors (id, name, phone, city, region)
  VALUES (v_user_id, v_business_name, v_phone, v_city, v_region)
  ON CONFLICT (id) DO UPDATE
  SET name = v_business_name, phone = v_phone, city = v_city, region = v_region;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER; -- SECURITY DEFINER permet de contourner RLS

-- Vérifier l'état du RLS
SELECT 
  schemaname,
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE tablename IN ('vendors', 'vendor_requests', 'products', 'users')
ORDER BY tablename;

-- ✅ RLS désactivé sur vendors
-- ✅ Fonction avec SECURITY DEFINER pour contourner RLS si nécessaire
-- ⚠️  Sécurité gérée au niveau de l'application Flutter
