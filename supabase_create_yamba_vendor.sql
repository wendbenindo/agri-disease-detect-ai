-- ============================================================================
-- CRÉER L'ENTRÉE VENDOR POUR YAMBA
-- ============================================================================

-- Récupérer les infos de la demande de yamba
SELECT 
  user_id,
  business_name,
  phone,
  city,
  region,
  status
FROM vendor_requests
WHERE user_id = 'c23e75df-7f86-426e-95dd-aad7a07a9675';

-- Créer l'entrée vendor pour yamba
INSERT INTO vendors (id, name, phone, city, region)
SELECT 
  user_id,
  business_name,
  phone,
  city,
  region
FROM vendor_requests
WHERE user_id = 'c23e75df-7f86-426e-95dd-aad7a07a9675'
  AND status = 'approved'
ON CONFLICT (id) DO UPDATE
SET 
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  city = EXCLUDED.city,
  region = EXCLUDED.region;

-- Vérifier que yamba existe maintenant dans vendors
SELECT * FROM vendors WHERE id = 'c23e75df-7f86-426e-95dd-aad7a07a9675';

-- ✅ Yamba devrait maintenant pouvoir créer des produits
