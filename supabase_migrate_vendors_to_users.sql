-- ============================================
-- MIGRATION DES VENDEURS VERS TABLE USERS
-- ============================================
-- Ce script migre les vendeurs existants vers la table users
-- et met à jour les produits pour utiliser les nouveaux IDs

-- Créer des utilisateurs pour les vendeurs existants
-- Mot de passe par défaut: "vendor123"
INSERT INTO public.users (id, phone_number, name, password_hash)
SELECT 
  v.id,
  v.phone,
  v.name,
  crypt('vendor123', gen_salt('bf'))
FROM public.vendors v
WHERE NOT EXISTS (
  SELECT 1 FROM public.users u WHERE u.id = v.id
);

-- Vérifier que les produits ont bien des vendor_id
UPDATE public.products
SET vendor_id = '55555555-5555-5555-5555-555555555551'
WHERE vendor_id IS NULL;

-- Afficher les vendeurs migrés
SELECT 
  u.id,
  u.name,
  u.phone_number,
  'Mot de passe: vendor123' as info
FROM public.users u
WHERE u.id IN (
  SELECT id FROM public.vendors
);

COMMENT ON TABLE public.users IS 'Table des utilisateurs (acheteurs et vendeurs) avec authentification par mot de passe';
