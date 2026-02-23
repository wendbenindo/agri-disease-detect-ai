-- ============================================================================
-- CORRECTION DU CONFLIT DE FONCTIONS
-- ============================================================================
-- Problème: Il existe 2 versions de approve_vendor_request et reject_vendor_request
-- Solution: Supprimer les anciennes versions et garder les nouvelles

-- Supprimer toutes les versions existantes de approve_vendor_request
DROP FUNCTION IF EXISTS approve_vendor_request(UUID);
DROP FUNCTION IF EXISTS approve_vendor_request(UUID, UUID);

-- Supprimer toutes les versions existantes de reject_vendor_request
DROP FUNCTION IF EXISTS reject_vendor_request(UUID);
DROP FUNCTION IF EXISTS reject_vendor_request(UUID, UUID);

-- Recréer UNIQUEMENT la version avec admin_id
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
$$ LANGUAGE plpgsql;

-- Recréer UNIQUEMENT la version avec admin_id
CREATE OR REPLACE FUNCTION reject_vendor_request(
  request_id UUID,
  admin_id UUID DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  -- Mettre à jour le statut
  UPDATE vendor_requests
  SET 
    status = 'rejected',
    reviewed_by = admin_id,
    reviewed_at = NOW(),
    updated_at = NOW()
  WHERE id = request_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande introuvable ou déjà traitée';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Vérifier les fonctions
SELECT 
  proname AS function_name,
  pg_get_function_arguments(oid) AS arguments
FROM pg_proc
WHERE proname IN ('approve_vendor_request', 'reject_vendor_request')
ORDER BY proname;

-- ✅ Conflit résolu
-- Les fonctions acceptent maintenant admin_id en paramètre optionnel
