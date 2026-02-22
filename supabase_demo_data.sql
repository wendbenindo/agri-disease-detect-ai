-- ============================================================================
-- DONNÉES DE DÉMONSTRATION - MARKETPLACE AGRICOLE TIPTIGA
-- ============================================================================
-- Ce script insère des données de démonstration réalistes pour tester
-- la marketplace. À exécuter APRÈS supabase_setup.sql
-- ============================================================================

-- ============================================================================
-- INSERTION DES CATÉGORIES
-- ============================================================================

INSERT INTO categories (id, name, icon_url, display_order) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Pesticides', NULL, 1),
  ('22222222-2222-2222-2222-222222222222', 'Engrais', NULL, 2),
  ('33333333-3333-3333-3333-333333333333', 'Semences', NULL, 3),
  ('44444444-4444-4444-4444-444444444444', 'Équipements', NULL, 4)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- INSERTION DES VENDEURS
-- ============================================================================

INSERT INTO vendors (id, name, phone, whatsapp, city, region, is_active) VALUES
  (
    '55555555-5555-5555-5555-555555555551',
    'Agro Services Dakar',
    '+221771234567',
    '+221771234567',
    'Dakar',
    'Dakar',
    true
  ),
  (
    '55555555-5555-5555-5555-555555555552',
    'Ferme Bio Thiès',
    '+221772345678',
    '+221772345678',
    'Thiès',
    'Thiès',
    true
  ),
  (
    '55555555-5555-5555-5555-555555555553',
    'Semences du Sahel',
    '+221773456789',
    '+221773456789',
    'Saint-Louis',
    'Saint-Louis',
    true
  ),
  (
    '55555555-5555-5555-5555-555555555554',
    'Équipements Agricoles Kaolack',
    '+221774567890',
    '+221774567890',
    'Kaolack',
    'Kaolack',
    true
  )
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- INSERTION DES PRODUITS - PESTICIDES
-- ============================================================================

INSERT INTO products (id, name, price, description, short_description, photo_url, category_id, vendor_id, dosage, instructions, is_available) VALUES
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'Fongicide Cuivre Plus',
    15000,
    'Fongicide à base de cuivre efficace contre les maladies fongiques du maïs, sorgho et mil. Protège contre la rouille, la cercosporiose et l''anthracnose. Formulation concentrée pour une protection longue durée.',
    'Fongicide contre rouille et cercosporiose',
    NULL,
    '11111111-1111-1111-1111-111111111111',
    '55555555-5555-5555-5555-555555555551',
    '2-3 kg par hectare, dilué dans 200-300 litres d''eau',
    'Appliquer dès l''apparition des premiers symptômes. Répéter le traitement tous les 10-14 jours si nécessaire. Ne pas traiter en plein soleil.',
    true
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaabbb',
    'Insecticide Bio Neem',
    12000,
    'Insecticide biologique à base d''huile de neem. Efficace contre les insectes ravageurs tout en respectant l''environnement. Convient à l''agriculture biologique.',
    'Insecticide naturel à base de neem',
    NULL,
    '11111111-1111-1111-1111-111111111111',
    '55555555-5555-5555-5555-555555555551',
    '30-50 ml par 10 litres d''eau',
    'Pulvériser le soir ou tôt le matin. Renouveler après la pluie. Période de carence: 3 jours.',
    true
  ),
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaccc',
    'Fongicide Systémique Triazole',
    18500,
    'Fongicide systémique à action préventive et curative. Très efficace contre l''anthracnose du sorgho et les maladies foliaires. Pénètre rapidement dans la plante.',
    'Traitement anthracnose et maladies foliaires',
    NULL,
    '11111111-1111-1111-1111-111111111111',
    '55555555-5555-5555-5555-555555555552',
    '0.5-1 litre par hectare',
    'Appliquer au stade précoce de la maladie. Maximum 2 applications par saison. Respecter un délai de 21 jours avant récolte.',
    true
  ),

-- ============================================================================
-- INSERTION DES PRODUITS - ENGRAIS
-- ============================================================================

  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'Engrais NPK 15-15-15',
    25000,
    'Engrais complet équilibré pour toutes les cultures céréalières. Apporte azote, phosphore et potassium en proportions égales. Favorise la croissance et le rendement.',
    'Engrais complet pour céréales',
    NULL,
    '22222222-2222-2222-2222-222222222222',
    '55555555-5555-5555-5555-555555555552',
    '200-300 kg par hectare selon le sol',
    'Appliquer en deux fois: 1/3 au semis, 2/3 au tallage. Enfouir légèrement dans le sol.',
    true
  ),
  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbccc',
    'Urée 46%',
    22000,
    'Engrais azoté concentré à 46% d''azote. Stimule la croissance végétative et améliore le rendement. Idéal pour le maïs et le sorgho.',
    'Engrais azoté haute concentration',
    NULL,
    '22222222-2222-2222-2222-222222222222',
    '55555555-5555-5555-5555-555555555552',
    '100-150 kg par hectare',
    'Fractionner en 2-3 apports. Premier apport 3 semaines après levée. Éviter le contact direct avec les feuilles.',
    true
  ),
  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbddd',
    'Compost Organique Enrichi',
    8000,
    'Compost 100% organique enrichi en micro-organismes bénéfiques. Améliore la structure du sol et la rétention d''eau. Convient à l''agriculture biologique.',
    'Amendement organique pour sol',
    NULL,
    '22222222-2222-2222-2222-222222222222',
    '55555555-5555-5555-5555-555555555552',
    '2-3 tonnes par hectare',
    'Épandre avant le labour. Incorporer dans les 15 premiers cm du sol. Peut être utilisé chaque saison.',
    true
  ),

-- ============================================================================
-- INSERTION DES PRODUITS - SEMENCES
-- ============================================================================

  (
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'Semences Maïs Hybride Précoce',
    35000,
    'Variété hybride de maïs à cycle court (90-100 jours). Résistante à la sécheresse et aux maladies. Rendement potentiel: 4-5 tonnes/ha. Certifiée et traitée.',
    'Maïs hybride résistant cycle court',
    NULL,
    '33333333-3333-3333-3333-333333333333',
    '55555555-5555-5555-5555-555555555553',
    '20-25 kg par hectare',
    'Semer à 75cm entre lignes et 40cm sur la ligne. Profondeur: 5cm. Traiter les semences avant semis si non traitées.',
    true
  ),
  (
    'cccccccc-cccc-cccc-cccc-cccccccccbbb',
    'Semences Sorgho Variété Locale Améliorée',
    28000,
    'Sorgho à grains blancs, variété locale améliorée. Très résistant à la sécheresse. Cycle: 110-120 jours. Bon rendement en zone sahélienne.',
    'Sorgho résistant sécheresse',
    NULL,
    '33333333-3333-3333-3333-333333333333',
    '55555555-5555-5555-5555-555555555553',
    '8-10 kg par hectare',
    'Semer en lignes espacées de 80cm. Éclaircir à 15-20cm sur la ligne après levée. Semer après les premières pluies.',
    true
  ),
  (
    'cccccccc-cccc-cccc-cccc-ccccccccccdd',
    'Semences Mil Sanio Précoce',
    24000,
    'Mil à cycle court (75-85 jours) adapté aux zones à pluviométrie faible. Grains de bonne qualité. Résistant au mildiou.',
    'Mil précoce résistant mildiou',
    NULL,
    '33333333-3333-3333-3333-333333333333',
    '55555555-5555-5555-5555-555555555553',
    '5-7 kg par hectare',
    'Semer en poquets espacés de 1m x 1m. Mettre 10-15 graines par poquet. Éclaircir à 3-4 plants après levée.',
    true
  ),

-- ============================================================================
-- INSERTION DES PRODUITS - ÉQUIPEMENTS
-- ============================================================================

  (
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'Pulvérisateur à Dos 16L',
    45000,
    'Pulvérisateur manuel à dos de 16 litres. Lance télescopique réglable. Buse à jet réglable. Idéal pour traitement phytosanitaire sur petites surfaces.',
    'Pulvérisateur manuel 16L',
    NULL,
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555554',
    NULL,
    'Rincer après chaque utilisation. Vérifier les joints régulièrement. Stocker à l''abri du soleil.',
    true
  ),
  (
    'dddddddd-dddd-dddd-dddd-dddddddddccc',
    'Semoir Manuel de Précision',
    65000,
    'Semoir manuel pour semis en ligne. Réglage de l''écartement et de la profondeur. Convient pour maïs, sorgho, mil. Construction robuste.',
    'Semoir manuel réglable',
    NULL,
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555554',
    NULL,
    'Régler selon la taille des graines. Nettoyer après usage. Graisser les parties mobiles régulièrement.',
    true
  ),
  (
    'dddddddd-dddd-dddd-dddd-dddddddddeee',
    'Houe Rotative Manuelle',
    32000,
    'Houe rotative pour désherbage mécanique. Largeur de travail: 30cm. Manche ergonomique. Réduit la pénibilité du sarclage.',
    'Outil de désherbage mécanique',
    NULL,
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555554',
    NULL,
    'Utiliser sur sol légèrement humide. Affûter les lames régulièrement. Nettoyer après usage.',
    true
  )
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- ASSOCIATIONS MALADIES-PRODUITS (RECOMMANDATIONS)
-- ============================================================================
-- Note: Les disease_id correspondent aux labels du modèle de détection
-- Ajuster selon les noms exacts utilisés dans votre modèle ML

INSERT INTO disease_products (disease_id, product_id, priority) VALUES
  -- Maïs Rouille -> Fongicide Cuivre Plus (priorité 1)
  ('Mais_Rouille', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1),
  -- Maïs Rouille -> Fongicide Systémique (priorité 2)
  ('Mais_Rouille', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaccc', 2),
  
  -- Maïs Cercosporiose -> Fongicide Cuivre Plus (priorité 1)
  ('Mais_Cercosporiose', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1),
  -- Maïs Cercosporiose -> Fongicide Systémique (priorité 2)
  ('Mais_Cercosporiose', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaccc', 2),
  
  -- Maïs Brûlure -> Fongicide Systémique (priorité 1)
  ('Mais_Brulure', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaccc', 1),
  -- Maïs Brûlure -> Fongicide Cuivre Plus (priorité 2)
  ('Mais_Brulure', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2),
  
  -- Sorgho Anthracnose -> Fongicide Systémique (priorité 1)
  ('Sorgho_Anthracnose', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaccc', 1),
  -- Sorgho Anthracnose -> Fongicide Cuivre Plus (priorité 2)
  ('Sorgho_Anthracnose', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2),
  
  -- Sorgho Rouille -> Fongicide Cuivre Plus (priorité 1)
  ('Sorgho_Rouille', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1),
  -- Sorgho Rouille -> Fongicide Systémique (priorité 2)
  ('Sorgho_Rouille', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaccc', 2),
  
  -- Recommandations générales pour plantes saines (engrais)
  ('Mais_Sain', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1),
  ('Mais_Sain', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbccc', 2)
ON CONFLICT (disease_id, product_id) DO NOTHING;

-- ============================================================================
-- VÉRIFICATION DES DONNÉES INSÉRÉES
-- ============================================================================

-- Compter les enregistrements
SELECT 'Catégories' as table_name, COUNT(*) as count FROM categories
UNION ALL
SELECT 'Vendeurs', COUNT(*) FROM vendors
UNION ALL
SELECT 'Produits', COUNT(*) FROM products
UNION ALL
SELECT 'Associations Maladies-Produits', COUNT(*) FROM disease_products;

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================

