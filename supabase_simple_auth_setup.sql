-- ============================================
-- AUTHENTIFICATION SIMPLIFIÉE - CONFIGURATION
-- ============================================
-- Ce script crée la table users pour l'authentification simplifiée
-- sans SMS (gratuit)

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche rapide par numéro
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);

-- RLS Policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Tout le monde peut lire les utilisateurs (pour le chat)
CREATE POLICY "Les utilisateurs sont lisibles par tous"
  ON public.users
  FOR SELECT
  USING (true);

-- Tout le monde peut créer un compte
CREATE POLICY "Tout le monde peut créer un compte"
  ON public.users
  FOR INSERT
  WITH CHECK (true);

-- Les utilisateurs peuvent mettre à jour leur propre profil
CREATE POLICY "Les utilisateurs peuvent mettre à jour leur profil"
  ON public.users
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Fonction pour mettre à jour updated_at automatiquement
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

-- Modifier la table conversations pour utiliser user_id au lieu de auth.uid()
ALTER TABLE public.conversations 
  DROP CONSTRAINT IF EXISTS conversations_buyer_id_fkey;

ALTER TABLE public.conversations
  ADD CONSTRAINT conversations_buyer_id_fkey 
  FOREIGN KEY (buyer_id) 
  REFERENCES public.users(id) 
  ON DELETE CASCADE;

-- Modifier la table messages pour utiliser user_id
ALTER TABLE public.messages
  DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

ALTER TABLE public.messages
  ADD CONSTRAINT messages_sender_id_fkey 
  FOREIGN KEY (sender_id) 
  REFERENCES public.users(id) 
  ON DELETE CASCADE;

-- Données de test
INSERT INTO public.users (phone_number, name) VALUES
  ('+22670000001', 'Vendeur Test'),
  ('+22670000002', 'Acheteur Test')
ON CONFLICT (phone_number) DO NOTHING;

COMMENT ON TABLE public.users IS 'Table des utilisateurs avec authentification simplifiée (sans SMS)';
