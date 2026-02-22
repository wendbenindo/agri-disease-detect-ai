-- ============================================================================
-- CONFIGURATION SUPABASE - MARKETPLACE AGRICOLE TIPTIGA
-- ============================================================================
-- Ce script configure la base de données Supabase pour la marketplace
-- avec toutes les mesures de sécurité nécessaires (RLS, policies, indexes)
-- ============================================================================

-- ============================================================================
-- ÉTAPE 1: ACTIVATION DES EXTENSIONS NÉCESSAIRES
-- ============================================================================

-- Extension pour générer des UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ÉTAPE 2: CRÉATION DES TABLES
-- ============================================================================

-- Table: categories
-- Stocke les catégories de produits (Pesticides, Engrais, Semences, Équipements)
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  icon_url TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: vendors
-- Stocke les informations des vendeurs
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  whatsapp TEXT,
  city TEXT NOT NULL,
  region TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: products
-- Stocke les produits agricoles disponibles
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  description TEXT NOT NULL,
  short_description TEXT,
  photo_url TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  dosage TEXT,
  instructions TEXT,
  is_available BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: disease_products
-- Association entre les maladies détectées et les produits recommandés
CREATE TABLE IF NOT EXISTS disease_products (
  disease_id TEXT NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (disease_id, product_id)
);

-- ============================================================================
-- ÉTAPE 3: CRÉATION DES INDEX POUR LES PERFORMANCES
-- ============================================================================

-- Index pour recherche rapide par catégorie
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);

-- Index pour recherche rapide par vendeur
CREATE INDEX IF NOT EXISTS idx_products_vendor_id ON products(vendor_id);

-- Index pour recherche par nom de produit (insensible à la casse)
CREATE INDEX IF NOT EXISTS idx_products_name_lower ON products(LOWER(name));

-- Index pour filtrer les produits disponibles
CREATE INDEX IF NOT EXISTS idx_products_is_available ON products(is_available);

-- Index pour recherche rapide des recommandations par maladie
CREATE INDEX IF NOT EXISTS idx_disease_products_disease_id ON disease_products(disease_id);

-- Index pour tri des catégories
CREATE INDEX IF NOT EXISTS idx_categories_display_order ON categories(display_order);

-- Index pour filtrer les vendeurs actifs
CREATE INDEX IF NOT EXISTS idx_vendors_is_active ON vendors(is_active);

-- ============================================================================
-- ÉTAPE 4: ACTIVATION DE ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Activer RLS sur toutes les tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE disease_products ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- ÉTAPE 5: CRÉATION DES POLITIQUES DE SÉCURITÉ (RLS POLICIES)
-- ============================================================================

-- POLITIQUE: Lecture publique pour les catégories
-- Permet à tous les utilisateurs (même non authentifiés) de lire les catégories
CREATE POLICY "Lecture publique des catégories"
  ON categories
  FOR SELECT
  USING (true);

-- POLITIQUE: Lecture publique pour les vendeurs actifs uniquement
-- Les utilisateurs ne peuvent voir que les vendeurs actifs
CREATE POLICY "Lecture publique des vendeurs actifs"
  ON vendors
  FOR SELECT
  USING (is_active = true);

-- POLITIQUE: Lecture publique pour les produits disponibles uniquement
-- Les utilisateurs ne peuvent voir que les produits disponibles
CREATE POLICY "Lecture publique des produits disponibles"
  ON products
  FOR SELECT
  USING (is_available = true);

-- POLITIQUE: Lecture publique pour les associations maladie-produits
-- Permet de récupérer les recommandations
CREATE POLICY "Lecture publique des recommandations"
  ON disease_products
  FOR SELECT
  USING (true);

-- ============================================================================
-- ÉTAPE 6: CRÉATION DES FONCTIONS UTILITAIRES
-- ============================================================================

-- Fonction pour mettre à jour automatiquement le champ updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers pour mettre à jour updated_at automatiquement
CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vendors_updated_at
  BEFORE UPDATE ON vendors
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ÉTAPE 7: CRÉATION D'UNE VUE POUR LES PRODUITS AVEC DÉTAILS
-- ============================================================================

-- Vue qui joint les produits avec leurs catégories et vendeurs
-- Facilite les requêtes depuis l'application
-- Note: Les vues héritent automatiquement des politiques RLS des tables sous-jacentes
CREATE OR REPLACE VIEW products_with_details AS
SELECT 
  p.id,
  p.name,
  p.price,
  p.description,
  p.short_description,
  p.photo_url,
  p.dosage,
  p.instructions,
  p.is_available,
  p.created_at,
  p.updated_at,
  c.id as category_id,
  c.name as category_name,
  c.icon_url as category_icon,
  v.id as vendor_id,
  v.name as vendor_name,
  v.phone as vendor_phone,
  v.whatsapp as vendor_whatsapp,
  v.city as vendor_city,
  v.region as vendor_region
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN vendors v ON p.vendor_id = v.id
WHERE p.is_available = true AND v.is_active = true;

-- ============================================================================
-- NOTES DE SÉCURITÉ
-- ============================================================================
-- 
-- 1. RLS ACTIVÉ: Toutes les tables ont Row Level Security activé
-- 2. LECTURE SEULE: Les utilisateurs peuvent uniquement LIRE les données (SELECT)
-- 3. FILTRAGE AUTOMATIQUE: Seuls les produits disponibles et vendeurs actifs sont visibles
-- 4. PAS D'ÉCRITURE PUBLIQUE: Aucune politique INSERT/UPDATE/DELETE n'est définie
--    Les modifications doivent se faire via le dashboard Supabase ou une API admin
-- 5. CONTRAINTES: Les prix ne peuvent pas être négatifs (CHECK constraint)
-- 6. CASCADE: Si un vendeur est supprimé, ses produits sont aussi supprimés
-- 7. INDEX: Optimisation des requêtes fréquentes (recherche, filtrage)
--
-- ============================================================================

