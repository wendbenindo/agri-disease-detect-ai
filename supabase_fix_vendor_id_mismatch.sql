-- ============================================================================
-- CORRIGER LE PROBLÈME D'ID VENDOR
-- ============================================================================
-- Problème: L'app utilise un ID différent de celui dans la base de données
-- Solution: Créer l'entrée vendor avec l'ID que l'app utilise

-- Vérifier quel ID l'app utilise
-- L'erreur montre: c6b16317-9419-455e-9e2e-aa515c2bbab3

-- Option 1: Créer une entrée vendor avec cet ID
INSERT INTO vendors (id, name, phone, city, region)
VALUES (
  'c6b16317-9419-455e-9e2e-aa515c2bbab3',
  'wewe',
  '+226123456',
  'ouagadougou',
  'kadiogo'
)
ON CONFLICT (id) DO NOTHING;

-- Vérifier les deux entrées
SELECT * FROM vendors WHERE id IN (
  'c23e75df-7f86-426e-95dd-aad7a07a9675',  -- ID correct de yamba
  'c6b16317-9419-455e-9e2e-aa515c2bbab3'   -- ID utilisé par l'app
);

-- ⚠️  MEILLEURE SOLUTION: Déconnecte-toi et reconnecte-toi dans l'app
-- Cela va rafraîchir le cache et utiliser le bon ID
