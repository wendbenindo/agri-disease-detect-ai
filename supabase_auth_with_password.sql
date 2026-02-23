-- ============================================
-- AUTHENTIFICATION AVEC MOT DE PASSE
-- ============================================
-- Ce script crée la table users avec mot de passe sécurisé

-- Extension pour le hachage de mot de passe
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table des utilisateurs avec mot de passe
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);

-- RLS Policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Lecture publique (pour le chat)
DROP POLICY IF EXISTS "Les utilisateurs sont lisibles par tous" ON public.users;
CREATE POLICY "Les utilisateurs sont lisibles par tous"
  ON public.users
  FOR SELECT
  USING (true);

-- Création de compte (sans authentification)
DROP POLICY IF EXISTS "Tout le monde peut créer un compte" ON public.users;
CREATE POLICY "Tout le monde peut créer un compte"
  ON public.users
  FOR INSERT
  WITH CHECK (true);

-- Mise à jour (tout le monde peut mettre à jour)
DROP POLICY IF EXISTS "Les utilisateurs peuvent mettre à jour leur profil" ON public.users;
CREATE POLICY "Les utilisateurs peuvent mettre à jour leur profil"
  ON public.users
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour créer un utilisateur avec mot de passe haché
CREATE OR REPLACE FUNCTION create_user_with_password(
  p_phone_number TEXT,
  p_name TEXT,
  p_password TEXT
)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  INSERT INTO public.users (phone_number, name, password_hash)
  VALUES (p_phone_number, p_name, crypt(p_password, gen_salt('bf')))
  RETURNING id INTO v_user_id;
  
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier le mot de passe
CREATE OR REPLACE FUNCTION verify_user_password(
  p_phone_number TEXT,
  p_password TEXT
)
RETURNS TABLE(
  user_id UUID,
  user_name TEXT,
  user_phone TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, name, phone_number
  FROM public.users
  WHERE phone_number = p_phone_number
    AND password_hash = crypt(p_password, password_hash);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mettre à jour les contraintes de conversations
ALTER TABLE public.conversations 
  DROP CONSTRAINT IF EXISTS conversations_buyer_id_fkey;

ALTER TABLE public.conversations
  ADD CONSTRAINT conversations_buyer_id_fkey 
  FOREIGN KEY (buyer_id) 
  REFERENCES public.users(id) 
  ON DELETE CASCADE;

-- Mettre à jour les contraintes de messages
ALTER TABLE public.messages
  DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

ALTER TABLE public.messages
  ADD CONSTRAINT messages_sender_id_fkey 
  FOREIGN KEY (sender_id) 
  REFERENCES public.users(id) 
  ON DELETE CASCADE;

-- Données de test (mot de passe: "test123")
INSERT INTO public.users (phone_number, name, password_hash) VALUES
  ('+22670000001', 'Vendeur Test', crypt('test123', gen_salt('bf'))),
  ('+22670000002', 'Acheteur Test', crypt('test123', gen_salt('bf')))
ON CONFLICT (phone_number) DO NOTHING;

COMMENT ON TABLE public.users IS 'Table des utilisateurs avec authentification par mot de passe';
COMMENT ON COLUMN public.users.password_hash IS 'Mot de passe haché avec bcrypt';
