-- Système de rôles pour les utilisateurs

-- 1. Ajouter la colonne role à la table users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'buyer' CHECK (role IN ('buyer', 'vendor', 'admin'));

-- 2. Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- 3. Mettre à jour les vendeurs existants
UPDATE users 
SET role = 'vendor' 
WHERE id IN (
  SELECT DISTINCT vendor_id FROM products WHERE vendor_id IS NOT NULL
);

-- 4. Mettre à jour les politiques RLS pour les produits

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Tout le monde peut voir les produits" ON products;
DROP POLICY IF EXISTS "Seuls les vendeurs peuvent créer des produits" ON products;
DROP POLICY IF EXISTS "Seuls les vendeurs peuvent modifier leurs produits" ON products;
DROP POLICY IF EXISTS "Seuls les vendeurs peuvent supprimer leurs produits" ON products;

-- Nouvelle politique: Tout le monde peut voir les produits
CREATE POLICY "Tout le monde peut voir les produits"
ON products FOR SELECT
TO public
USING (true);

-- Nouvelle politique: Seuls les vendeurs peuvent créer des produits
CREATE POLICY "Seuls les vendeurs peuvent créer des produits"
ON products FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid()::text 
    AND users.role IN ('vendor', 'admin')
  )
);

-- Nouvelle politique: Seuls les vendeurs peuvent modifier leurs propres produits
CREATE POLICY "Seuls les vendeurs peuvent modifier leurs produits"
ON products FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid()::text 
    AND (
      (users.role = 'vendor' AND products.vendor_id = users.id)
      OR users.role = 'admin'
    )
  )
);

-- Nouvelle politique: Seuls les vendeurs peuvent supprimer leurs propres produits
CREATE POLICY "Seuls les vendeurs peuvent supprimer leurs produits"
ON products FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid()::text 
    AND (
      (users.role = 'vendor' AND products.vendor_id = users.id)
      OR users.role = 'admin'
    )
  )
);

-- 5. Créer une fonction pour promouvoir un utilisateur en vendeur
CREATE OR REPLACE FUNCTION promote_to_vendor(user_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE users 
  SET role = 'vendor' 
  WHERE id = user_id;
END;
$$;

-- 6. Créer une fonction pour vérifier si un utilisateur est vendeur
CREATE OR REPLACE FUNCTION is_vendor(user_id TEXT)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role FROM users WHERE id = user_id;
  RETURN user_role IN ('vendor', 'admin');
END;
$$;

-- 7. Commentaires pour documentation
COMMENT ON COLUMN users.role IS 'Rôle de l''utilisateur: buyer (acheteur), vendor (vendeur), admin (administrateur)';
COMMENT ON FUNCTION promote_to_vendor IS 'Promouvoir un utilisateur au rôle de vendeur';
COMMENT ON FUNCTION is_vendor IS 'Vérifier si un utilisateur est vendeur ou admin';
