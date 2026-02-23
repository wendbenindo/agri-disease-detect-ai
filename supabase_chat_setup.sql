-- ============================================================================
-- SYSTÈME DE CHAT - MARKETPLACE TIPTIGA
-- ============================================================================

-- Table: conversations
-- Stocke les conversations entre acheteurs et vendeurs
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL, -- ID de l'utilisateur (auth.users)
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: messages
-- Stocke les messages d'une conversation
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL, -- ID de l'utilisateur qui envoie
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX IF NOT EXISTS idx_conversations_buyer ON conversations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_vendor ON conversations(vendor_id);
CREATE INDEX IF NOT EXISTS idx_conversations_product ON conversations(product_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- Activer RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLITIQUES RLS - CONVERSATIONS
-- ============================================================================

-- L'acheteur peut voir ses propres conversations
CREATE POLICY "Acheteur peut voir ses conversations"
  ON conversations
  FOR SELECT
  USING (auth.uid() = buyer_id);

-- L'acheteur peut créer une conversation
CREATE POLICY "Acheteur peut créer une conversation"
  ON conversations
  FOR INSERT
  WITH CHECK (auth.uid() = buyer_id);

-- ============================================================================
-- POLITIQUES RLS - MESSAGES
-- ============================================================================

-- L'utilisateur peut voir les messages de ses conversations
CREATE POLICY "Utilisateur peut voir ses messages"
  ON messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND (conversations.buyer_id = auth.uid())
    )
  );

-- L'utilisateur peut envoyer des messages dans ses conversations
CREATE POLICY "Utilisateur peut envoyer des messages"
  ON messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND conversations.buyer_id = auth.uid()
    )
  );

-- L'utilisateur peut marquer ses messages comme lus
CREATE POLICY "Utilisateur peut marquer comme lu"
  ON messages
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND conversations.buyer_id = auth.uid()
    )
  );

-- ============================================================================
-- TRIGGER POUR METTRE À JOUR updated_at
-- ============================================================================

CREATE TRIGGER update_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FONCTION POUR OBTENIR LE DERNIER MESSAGE D'UNE CONVERSATION
-- ============================================================================

CREATE OR REPLACE FUNCTION get_last_message(conversation_uuid UUID)
RETURNS TABLE (
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  sender_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT m.content, m.created_at, m.sender_id
  FROM messages m
  WHERE m.conversation_id = conversation_uuid
  ORDER BY m.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VUE POUR LES CONVERSATIONS AVEC DÉTAILS
-- ============================================================================

CREATE OR REPLACE VIEW conversations_with_details AS
SELECT 
  c.id,
  c.product_id,
  c.buyer_id,
  c.vendor_id,
  c.created_at,
  c.updated_at,
  p.name as product_name,
  p.photo_url as product_photo,
  v.name as vendor_name,
  v.phone as vendor_phone,
  (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id AND m.is_read = false AND m.sender_id != c.buyer_id) as unread_count
FROM conversations c
LEFT JOIN products p ON c.product_id = p.id
LEFT JOIN vendors v ON c.vendor_id = v.id;

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================
