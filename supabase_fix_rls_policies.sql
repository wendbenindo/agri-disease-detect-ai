-- ============================================
-- CORRECTION DES POLITIQUES RLS
-- ============================================
-- Ce script corrige les politiques RLS pour permettre
-- aux utilisateurs de créer des conversations et messages

-- ============================================
-- POLITIQUES POUR LA TABLE CONVERSATIONS
-- ============================================

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Les utilisateurs peuvent créer des conversations" ON public.conversations;
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leurs conversations" ON public.conversations;
DROP POLICY IF EXISTS "Les vendeurs peuvent voir leurs conversations" ON public.conversations;
DROP POLICY IF EXISTS "Tout le monde peut créer des conversations" ON public.conversations;
DROP POLICY IF EXISTS "Tout le monde peut lire les conversations" ON public.conversations;
DROP POLICY IF EXISTS "Tout le monde peut mettre à jour les conversations" ON public.conversations;

-- Seuls les utilisateurs authentifiés (existant dans users) peuvent créer une conversation
CREATE POLICY "Utilisateurs authentifiés peuvent créer des conversations"
  ON public.conversations
  FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = buyer_id)
    AND EXISTS (SELECT 1 FROM public.users WHERE id = vendor_id)
  );

-- Les utilisateurs peuvent voir leurs conversations (acheteur ou vendeur)
CREATE POLICY "Utilisateurs peuvent voir leurs conversations"
  ON public.conversations
  FOR SELECT
  USING (
    buyer_id IN (SELECT id FROM public.users)
    OR vendor_id IN (SELECT id FROM public.users)
  );

-- Les utilisateurs peuvent mettre à jour leurs conversations
CREATE POLICY "Utilisateurs peuvent mettre à jour leurs conversations"
  ON public.conversations
  FOR UPDATE
  USING (
    buyer_id IN (SELECT id FROM public.users)
    OR vendor_id IN (SELECT id FROM public.users)
  )
  WITH CHECK (
    buyer_id IN (SELECT id FROM public.users)
    OR vendor_id IN (SELECT id FROM public.users)
  );

-- ============================================
-- POLITIQUES POUR LA TABLE MESSAGES
-- ============================================

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Les utilisateurs peuvent créer des messages" ON public.messages;
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir les messages de leurs conversations" ON public.messages;
DROP POLICY IF EXISTS "Les utilisateurs peuvent mettre à jour leurs messages" ON public.messages;
DROP POLICY IF EXISTS "Tout le monde peut créer des messages" ON public.messages;
DROP POLICY IF EXISTS "Tout le monde peut lire les messages" ON public.messages;
DROP POLICY IF EXISTS "Tout le monde peut mettre à jour les messages" ON public.messages;

-- Seuls les utilisateurs authentifiés peuvent créer des messages
CREATE POLICY "Utilisateurs authentifiés peuvent créer des messages"
  ON public.messages
  FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = sender_id)
  );

-- Les utilisateurs peuvent lire les messages de leurs conversations
CREATE POLICY "Utilisateurs peuvent lire leurs messages"
  ON public.messages
  FOR SELECT
  USING (
    conversation_id IN (
      SELECT id FROM public.conversations 
      WHERE buyer_id IN (SELECT id FROM public.users)
         OR vendor_id IN (SELECT id FROM public.users)
    )
  );

-- Les utilisateurs peuvent mettre à jour leurs propres messages
CREATE POLICY "Utilisateurs peuvent mettre à jour leurs messages"
  ON public.messages
  FOR UPDATE
  USING (
    sender_id IN (SELECT id FROM public.users)
  )
  WITH CHECK (
    sender_id IN (SELECT id FROM public.users)
  );

-- ============================================
-- VÉRIFICATION
-- ============================================

-- Afficher les politiques actives
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('conversations', 'messages')
ORDER BY tablename, policyname;

COMMENT ON TABLE public.conversations IS 'Table des conversations - RLS: seuls les utilisateurs authentifiés (dans table users)';
COMMENT ON TABLE public.messages IS 'Table des messages - RLS: seuls les utilisateurs authentifiés (dans table users)';
