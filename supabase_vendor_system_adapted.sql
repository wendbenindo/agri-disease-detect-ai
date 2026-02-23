-- ============================================================================
-- SYSTÈME D'APPROBATION DES VENDEURS - ADAPTÉ À TA STRUCTURE
-- ============================================================================
-- Tu as déjà la table 'users' avec la colonne 'role'
-- On crée juste la table vendor_requests et les fonctions

-- Table: vendor_requests
CREATE TABLE IF NOT EXISTS vendor_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  business_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  city TEXT NOT NULL,
  region TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE
);

-- Index
CREATE INDEX IF NOT EXISTS idx_vendor_requests_user ON vendor_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_vendor_requests_status ON vendor_requests(status);

-- Activer RLS
ALTER TABLE vendor_requests ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLITIQUES RLS - vendor_requests
-- ============================================================================

-- L'utilisateur peut voir sa propre demande
DROP POLICY IF EXISTS "Utilisateur peut voir sa demande" ON vendor_requests;
CREATE POLICY "Utilisateur peut voir sa demande"
  ON vendor_requests
  FOR SELECT
  USING (
    user_id IN (
      SELECT id FROM users WHERE id = auth.uid()
    )
  );

-- L'utilisateur peut créer UNE SEULE demande
DROP POLICY IF EXISTS "Utilisateur peut créer une demande" ON vendor_requests;
CREATE POLICY "Utilisateur peut créer une demande"
  ON vendor_requests
  FOR INSERT
  WITH CHECK (
    user_id IN (SELECT id FROM users WHERE id = auth.uid())
    AND NOT EXISTS (
      SELECT 1 FROM vendor_requests 
      WHERE user_id = auth.uid()
    )
  );

-- SEUL L'ADMIN peut voir TOUTES les demandes
DROP POLICY IF EXISTS "Admin peut voir toutes les demandes" ON vendor_requests;
CREATE POLICY "Admin peut voir toutes les demandes"
  ON vendor_requests
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- SEUL L'ADMIN peut modifier les demandes
DROP POLICY IF EXISTS "Admin peut modifier les demandes" ON vendor_requests;
CREATE POLICY "Admin peut modifier les demandes"
  ON vendor_requests
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- FONCTION : Approuver une demande de vendeur
-- ============================================================================

CREATE OR REPLACE FUNCTION approve_vendor_request(request_id UUID)
RETURNS void AS $$
DECLARE
  v_user_id UUID;
  v_business_name TEXT;
  v_phone TEXT;
  v_city TEXT;
  v_region TEXT;
BEGIN
  -- Vérifier que l'utilisateur est admin
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Seuls les admins peuvent approuver des demandes';
  END IF;

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
    reviewed_by = auth.uid(),
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FONCTION : Rejeter une demande de vendeur
-- ============================================================================

CREATE OR REPLACE FUNCTION reject_vendor_request(request_id UUID)
RETURNS void AS $$
BEGIN
  -- Vérifier que l'utilisateur est admin
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Seuls les admins peuvent rejeter des demandes';
  END IF;

  -- Mettre à jour le statut
  UPDATE vendor_requests
  SET 
    status = 'rejected',
    reviewed_by = auth.uid(),
    reviewed_at = NOW(),
    updated_at = NOW()
  WHERE id = request_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande introuvable ou déjà traitée';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- METTRE À JOUR LES POLITIQUES RLS SUR PRODUCTS
-- ============================================================================

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Lecture publique des produits" ON products;
DROP POLICY IF EXISTS "Vendeurs approuvés peuvent créer" ON products;
DROP POLICY IF EXISTS "Propriétaire peut modifier" ON products;
DROP POLICY IF EXISTS "Propriétaire peut supprimer" ON products;

-- Tout le monde peut VOIR les produits
CREATE POLICY "Lecture publique des produits"
  ON products
  FOR SELECT
  USING (true);

-- SEULS LES VENDEURS peuvent créer des produits
CREATE POLICY "Vendeurs peuvent créer"
  ON products
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() 
      AND role = 'vendor'
    )
    AND auth.uid() = vendor_id
  );

-- SEUL LE PROPRIÉTAIRE peut modifier son produit
CREATE POLICY "Propriétaire peut modifier"
  ON products
  FOR UPDATE
  USING (auth.uid() = vendor_id);

-- SEUL LE PROPRIÉTAIRE peut supprimer son produit
CREATE POLICY "Propriétaire peut supprimer"
  ON products
  FOR DELETE
  USING (auth.uid() = vendor_id);

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================
