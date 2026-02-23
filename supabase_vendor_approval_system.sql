-- ============================================================================
-- SYSTÈME D'APPROBATION DES VENDEURS - SÉCURISÉ
-- ============================================================================

-- Table: vendor_requests
-- Stocke les demandes pour devenir vendeur
CREATE TABLE IF NOT EXISTS vendor_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  business_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  city TEXT NOT NULL,
  region TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE
);

-- Table: user_roles
-- Stocke les rôles des utilisateurs
CREATE TABLE IF NOT EXISTS user_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  role TEXT DEFAULT 'buyer' CHECK (role IN ('buyer', 'vendor', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX IF NOT EXISTS idx_vendor_requests_user ON vendor_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_vendor_requests_status ON vendor_requests(status);
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);

-- ============================================================================
-- ACTIVER RLS (Row Level Security)
-- ============================================================================

ALTER TABLE vendor_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLITIQUES RLS - vendor_requests
-- ============================================================================

-- L'utilisateur peut voir sa propre demande
CREATE POLICY "Utilisateur peut voir sa demande"
  ON vendor_requests
  FOR SELECT
  USING (auth.uid() = user_id);

-- L'utilisateur peut créer UNE SEULE demande
CREATE POLICY "Utilisateur peut créer une demande"
  ON vendor_requests
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND NOT EXISTS (
      SELECT 1 FROM vendor_requests 
      WHERE user_id = auth.uid()
    )
  );

-- SEUL L'ADMIN peut voir TOUTES les demandes
CREATE POLICY "Admin peut voir toutes les demandes"
  ON vendor_requests
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- SEUL L'ADMIN peut approuver/rejeter
CREATE POLICY "Admin peut modifier les demandes"
  ON vendor_requests
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- POLITIQUES RLS - user_roles
-- ============================================================================

-- L'utilisateur peut voir son propre rôle
CREATE POLICY "Utilisateur peut voir son rôle"
  ON user_roles
  FOR SELECT
  USING (auth.uid() = user_id);

-- SEUL L'ADMIN peut modifier les rôles
CREATE POLICY "Admin peut modifier les rôles"
  ON user_roles
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- POLITIQUES RLS - products (MISE À JOUR)
-- ============================================================================

-- Réactiver RLS sur products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Tout le monde peut voir les produits" ON products;
DROP POLICY IF EXISTS "Utilisateurs authentifiés peuvent créer des produits" ON products;
DROP POLICY IF EXISTS "Propriétaire peut modifier son produit" ON products;
DROP POLICY IF EXISTS "Propriétaire peut supprimer son produit" ON products;

-- Nouvelle politique : Tout le monde peut VOIR les produits
CREATE POLICY "Lecture publique des produits"
  ON products
  FOR SELECT
  USING (true);

-- SEULS LES VENDEURS APPROUVÉS peuvent créer des produits
CREATE POLICY "Vendeurs approuvés peuvent créer"
  ON products
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() 
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
-- FONCTION : Créer un rôle par défaut pour les nouveaux utilisateurs
-- ============================================================================

CREATE OR REPLACE FUNCTION create_default_user_role()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_roles (user_id, role)
  VALUES (NEW.id, 'buyer');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger : Créer automatiquement un rôle 'buyer' pour chaque nouvel utilisateur
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_default_user_role();

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
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() AND role = 'admin'
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

  -- Changer le rôle de l'utilisateur
  UPDATE user_roles
  SET role = 'vendor', updated_at = NOW()
  WHERE user_id = v_user_id;

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
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() AND role = 'admin'
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
-- CRÉER LE PREMIER ADMIN (À EXÉCUTER UNE SEULE FOIS)
-- Remplace 'TON_USER_ID' par ton vrai user_id de Supabase
-- ============================================================================

-- Pour trouver ton user_id, va dans Authentication > Users dans Supabase
-- Copie ton UUID et remplace ci-dessous

-- INSERT INTO user_roles (user_id, role)
-- VALUES ('TON_USER_ID_ICI', 'admin')
-- ON CONFLICT (user_id) DO UPDATE SET role = 'admin';

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================
