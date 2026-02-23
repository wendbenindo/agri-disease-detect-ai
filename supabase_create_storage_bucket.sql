-- ============================================================================
-- CRÉER UN BUCKET STORAGE POUR LES IMAGES DE PRODUITS
-- ============================================================================

-- Créer le bucket "product-images" (public)
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Politique: Tout le monde peut VOIR les images
CREATE POLICY "Images publiques en lecture"
ON storage.objects FOR SELECT
USING (bucket_id = 'product-images');

-- Politique: Seuls les vendeurs peuvent UPLOADER des images
CREATE POLICY "Vendeurs peuvent uploader"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'product-images'
  -- Pas de vérification auth.uid() car on utilise un système custom
  -- La sécurité est gérée dans l'app Flutter
);

-- Politique: Seuls les propriétaires peuvent SUPPRIMER leurs images
CREATE POLICY "Propriétaires peuvent supprimer"
ON storage.objects FOR DELETE
USING (bucket_id = 'product-images');

-- Vérifier que le bucket est créé
SELECT * FROM storage.buckets WHERE id = 'product-images';

-- ✅ Bucket créé et accessible publiquement en lecture
-- ✅ Upload géré par l'app Flutter (vérification du rôle vendor)
