-- ============================================
-- CRÉATION DE LA TABLE product_images
-- ============================================
-- Cette table permet de stocker plusieurs images par produit
-- ============================================

-- Créer la table product_images
CREATE TABLE IF NOT EXISTS product_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Contrainte pour éviter les doublons
  UNIQUE(product_id, image_url)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_product_images_product_id ON product_images(product_id);
CREATE INDEX IF NOT EXISTS idx_product_images_display_order ON product_images(product_id, display_order);

-- Activer RLS (Row Level Security)
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

-- Politique: Tout le monde peut lire les images des produits disponibles
CREATE POLICY "Public can view product images"
ON product_images FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM products 
    WHERE products.id = product_images.product_id 
    AND products.is_available = true
  )
);

-- Politique: Les vendeurs peuvent ajouter des images à leurs produits
CREATE POLICY "Vendors can insert images for their products"
ON product_images FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM products 
    WHERE products.id = product_images.product_id 
    AND products.vendor_id IN (SELECT id FROM users WHERE id = products.vendor_id)
  )
);

-- Politique: Les vendeurs peuvent supprimer les images de leurs produits
CREATE POLICY "Vendors can delete images from their products"
ON product_images FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM products 
    WHERE products.id = product_images.product_id 
    AND products.vendor_id IN (SELECT id FROM users WHERE id = products.vendor_id)
  )
);

-- Politique: Les vendeurs peuvent modifier l'ordre des images de leurs produits
CREATE POLICY "Vendors can update images for their products"
ON product_images FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM products 
    WHERE products.id = product_images.product_id 
    AND products.vendor_id IN (SELECT id FROM users WHERE id = products.vendor_id)
  )
);

-- Fonction pour obtenir toutes les images d'un produit
CREATE OR REPLACE FUNCTION get_product_images(p_product_id UUID)
RETURNS TABLE (
  id UUID,
  image_url TEXT,
  display_order INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pi.id,
    pi.image_url,
    pi.display_order
  FROM product_images pi
  WHERE pi.product_id = p_product_id
  ORDER BY pi.display_order ASC;
END;
$$ LANGUAGE plpgsql;

-- Vérifier que la table est créée
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'product_images'
ORDER BY ordinal_position;

-- ============================================
-- NOTES IMPORTANTES
-- ============================================
-- 
-- 1. Cette table stocke les images additionnelles
-- 2. L'image principale reste dans products.photo_url
-- 3. display_order permet de trier les images
-- 4. ON DELETE CASCADE supprime automatiquement les images
--    quand un produit est supprimé
-- 
-- UTILISATION:
-- - Insérer une image: INSERT INTO product_images (product_id, image_url, display_order) VALUES (...)
-- - Récupérer les images: SELECT * FROM get_product_images('product_id')
-- - Supprimer une image: DELETE FROM product_images WHERE id = '...'
-- 
-- ============================================
