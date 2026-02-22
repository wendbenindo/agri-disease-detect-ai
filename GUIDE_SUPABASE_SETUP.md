# Guide de Configuration Supabase - Marketplace TipTiga

## 📋 Vue d'ensemble

Ce guide vous accompagne pas à pas pour configurer votre base de données Supabase de manière sécurisée pour la marketplace agricole.

## 🔐 Principes de Sécurité Appliqués

1. **Row Level Security (RLS)** activé sur toutes les tables
2. **Lecture seule** pour les utilisateurs publics (pas d'écriture)
3. **Filtrage automatique** des données inactives
4. **Contraintes de validation** sur les données (prix positifs, etc.)
5. **Index optimisés** pour les performances
6. **Pas d'exposition des données sensibles** (vendeurs inactifs masqués)

## 🚀 Étapes d'Installation

### Étape 1: Créer un Projet Supabase

1. Allez sur [https://supabase.com](https://supabase.com)
2. Connectez-vous ou créez un compte
3. Cliquez sur "New Project"
4. Remplissez les informations:
   - **Name**: `tiptiga-marketplace` (ou votre choix)
   - **Database Password**: Générez un mot de passe fort (NOTEZ-LE!)
   - **Region**: Choisissez la région la plus proche (ex: Frankfurt pour l'Afrique de l'Ouest)
   - **Pricing Plan**: Free tier suffit pour commencer
5. Cliquez sur "Create new project"
6. Attendez 2-3 minutes que le projet soit créé

### Étape 2: Exécuter le Script de Configuration

1. Dans votre projet Supabase, allez dans **SQL Editor** (icône dans le menu gauche)
2. Cliquez sur "New query"
3. Copiez TOUT le contenu du fichier `supabase_setup.sql`
4. Collez-le dans l'éditeur SQL
5. Cliquez sur "Run" (ou Ctrl+Enter)
6. Vérifiez qu'il n'y a pas d'erreurs (vous devriez voir "Success. No rows returned")

✅ **Vérification**: Allez dans **Table Editor**, vous devriez voir 4 tables:
- `categories`
- `vendors`
- `products`
- `disease_products`

### Étape 3: Insérer les Données de Démonstration

1. Toujours dans **SQL Editor**, créez une nouvelle query
2. Copiez TOUT le contenu du fichier `supabase_demo_data.sql`
3. Collez-le dans l'éditeur SQL
4. Cliquez sur "Run"
5. Vous devriez voir un tableau de résultats montrant:
   ```
   Catégories: 4
   Vendeurs: 4
   Produits: 13
   Associations Maladies-Produits: 12
   ```

✅ **Vérification**: Allez dans **Table Editor** > **products**, vous devriez voir 13 produits

### Étape 4: Vérifier les Politiques de Sécurité (RLS)

1. Allez dans **Authentication** > **Policies**
2. Vérifiez que chaque table a ses politiques:
   - `categories`: "Lecture publique des catégories"
   - `vendors`: "Lecture publique des vendeurs actifs"
   - `products`: "Lecture publique des produits disponibles"
   - `disease_products`: "Lecture publique des recommandations"

3. Testez la sécurité:
   - Allez dans **SQL Editor**
   - Exécutez cette requête:
   ```sql
   -- Cette requête simule un utilisateur non authentifié
   SELECT * FROM products;
   ```
   - Vous devriez voir uniquement les produits avec `is_available = true`

### Étape 5: Récupérer les Clés API

1. Allez dans **Settings** > **API**
2. Notez ces informations (GARDEZ-LES SECRÈTES):
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGc...` (clé publique, peut être dans le code)
   - **service_role key**: `eyJhbGc...` (clé secrète, NE JAMAIS exposer!)

### Étape 6: Configurer l'Application Flutter

1. Ouvrez le fichier `.env` dans votre projet Flutter
2. Ajoutez ou mettez à jour ces lignes:
   ```env
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGc...votre_anon_key...
   ```
3. **IMPORTANT**: Vérifiez que `.env` est dans votre `.gitignore`

### Étape 7: Vérifier la Configuration dans Flutter

1. Ouvrez `agri_desease_detect_app/lib/services/supabase_service.dart`
2. Vérifiez que l'initialisation ressemble à ceci:
   ```dart
   import 'package:supabase_flutter/supabase_flutter.dart';
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   Future<void> initSupabase() async {
     await Supabase.initialize(
       url: dotenv.env['SUPABASE_URL']!,
       anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
     );
   }
   ```

## 🧪 Tests de Sécurité

### Test 1: Vérifier que les utilisateurs ne peuvent pas écrire

Dans SQL Editor, exécutez:
```sql
-- Cette requête devrait ÉCHOUER (c'est normal!)
INSERT INTO products (name, price, description, category_id, vendor_id)
VALUES ('Test Produit', 1000, 'Test', '11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555551');
```

❌ **Résultat attendu**: Erreur "new row violates row-level security policy"
✅ **C'est bon signe!** Les utilisateurs ne peuvent pas insérer de données.

### Test 2: Vérifier le filtrage automatique

Dans SQL Editor, exécutez:
```sql
-- Désactiver un produit
UPDATE products SET is_available = false WHERE name = 'Fongicide Cuivre Plus';

-- Essayer de le lire (en tant qu'utilisateur public)
SELECT * FROM products WHERE name = 'Fongicide Cuivre Plus';
```

❌ **Résultat attendu**: Aucune ligne retournée
✅ **C'est bon signe!** Les produits indisponibles sont masqués.

### Test 3: Tester les recommandations

Dans SQL Editor, exécutez:
```sql
-- Récupérer les produits recommandés pour "Mais_Rouille"
SELECT p.* 
FROM products p
JOIN disease_products dp ON p.id = dp.product_id
WHERE dp.disease_id = 'Mais_Rouille'
ORDER BY dp.priority;
```

✅ **Résultat attendu**: 2 produits (Fongicide Cuivre Plus et Fongicide Systémique)

## 📊 Structure de la Base de Données

```
categories
├── id (UUID, PK)
├── name (TEXT, UNIQUE)
├── icon_url (TEXT, nullable)
├── display_order (INTEGER)
└── timestamps

vendors
├── id (UUID, PK)
├── name (TEXT)
├── phone (TEXT)
├── whatsapp (TEXT, nullable)
├── city (TEXT)
├── region (TEXT)
├── is_active (BOOLEAN)
└── timestamps

products
├── id (UUID, PK)
├── name (TEXT)
├── price (DECIMAL)
├── description (TEXT)
├── short_description (TEXT, nullable)
├── photo_url (TEXT, nullable)
├── category_id (UUID, FK → categories)
├── vendor_id (UUID, FK → vendors)
├── dosage (TEXT, nullable)
├── instructions (TEXT, nullable)
├── is_available (BOOLEAN)
└── timestamps

disease_products
├── disease_id (TEXT, PK)
├── product_id (UUID, PK, FK → products)
├── priority (INTEGER)
└── created_at
```

## 🔧 Maintenance et Administration

### Ajouter un Nouveau Produit

Utilisez le **Table Editor** de Supabase:
1. Allez dans **Table Editor** > **products**
2. Cliquez sur "Insert row"
3. Remplissez les champs (tous sauf `id`, `created_at`, `updated_at`)
4. Cliquez sur "Save"

### Désactiver un Produit (au lieu de le supprimer)

```sql
UPDATE products 
SET is_available = false 
WHERE id = 'uuid-du-produit';
```

### Ajouter une Recommandation pour une Maladie

```sql
INSERT INTO disease_products (disease_id, product_id, priority)
VALUES ('Nom_Maladie', 'uuid-du-produit', 1);
```

## 🚨 Checklist de Sécurité Finale

Avant de passer à l'implémentation Flutter, vérifiez:

- [ ] RLS activé sur toutes les tables
- [ ] Politiques de lecture seule configurées
- [ ] Aucune politique d'écriture publique
- [ ] `.env` dans `.gitignore`
- [ ] Clés API notées en lieu sûr
- [ ] Service_role key JAMAIS dans le code client
- [ ] Tests de sécurité passés
- [ ] Données de démonstration insérées
- [ ] Index créés pour les performances

## 📞 Support

Si vous rencontrez des problèmes:
1. Vérifiez les logs dans **Logs** > **Postgres Logs**
2. Consultez la documentation Supabase: https://supabase.com/docs
3. Vérifiez que votre projet Supabase est bien actif (pas en pause)

## ✅ Prochaines Étapes

Une fois cette configuration terminée, nous pouvons passer à:
1. Création des modèles de données Flutter
2. Implémentation des repositories
3. Configuration du cache local
4. Développement de l'interface utilisateur

---

**🎉 Félicitations!** Votre base de données Supabase est maintenant configurée de manière sécurisée!

