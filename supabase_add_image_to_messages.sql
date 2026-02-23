-- Ajouter la colonne image_url à la table messages

ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_messages_image_url ON messages(image_url) WHERE image_url IS NOT NULL;
