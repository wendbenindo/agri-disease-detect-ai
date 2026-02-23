-- ============================================================================
-- AJOUTER LA COLONNE image_url À LA TABLE messages
-- ============================================================================

-- Ajouter la colonne image_url (optionnelle)
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Vérifier la structure de la table
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'messages'
ORDER BY ordinal_position;

-- ✅ Colonne image_url ajoutée
-- Les messages peuvent maintenant contenir des images
