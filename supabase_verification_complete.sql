-- =====================================================
-- SYSTÈME DE VÉRIFICATION TÉLÉPHONIQUE - SCRIPT COMPLET
-- =====================================================
-- Ce script combine:
-- 1. Création de la table et des fonctions
-- 2. Désactivation du RLS (pour système auth personnalisé)
-- =====================================================

-- =====================================================
-- 1. AJOUTER LA COLONNE is_verified À LA TABLE users
-- =====================================================

-- Vérifier si la colonne existe déjà
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'is_verified'
    ) THEN
        ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Colonne is_verified ajoutée à la table users';
    ELSE
        RAISE NOTICE 'Colonne is_verified existe déjà';
    END IF;
END $$;

-- =====================================================
-- 2. CRÉER LA TABLE verification_codes
-- =====================================================

CREATE TABLE IF NOT EXISTS verification_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    verification_method TEXT NOT NULL CHECK (verification_method IN ('sms', 'whatsapp')),
    phone_number TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Index pour améliorer les performances
    CONSTRAINT unique_active_code UNIQUE (user_id, is_verified)
);

-- Index pour les recherches fréquentes
CREATE INDEX IF NOT EXISTS idx_verification_codes_user_id ON verification_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_codes_expires_at ON verification_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_verification_codes_is_verified ON verification_codes(is_verified);

-- =====================================================
-- 3. DÉSACTIVER LE RLS (Système auth personnalisé)
-- =====================================================

ALTER TABLE verification_codes DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. CRÉER LA VUE pending_verifications (pour admin)
-- =====================================================

CREATE OR REPLACE VIEW pending_verifications AS
SELECT 
    vc.user_id,
    u.name as user_name,
    vc.phone_number,
    vc.code,
    vc.verification_method,
    vc.is_sent,
    vc.expires_at,
    vc.created_at
FROM verification_codes vc
JOIN users u ON vc.user_id = u.id
WHERE vc.is_verified = FALSE 
  AND vc.expires_at > NOW()
ORDER BY vc.created_at DESC;

-- =====================================================
-- 5. FONCTION: Générer un code à 6 chiffres
-- =====================================================

CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    code TEXT;
BEGIN
    -- Générer un code aléatoire à 6 chiffres
    code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    RETURN code;
END;
$$;

-- =====================================================
-- 6. FONCTION: Créer un code de vérification
-- =====================================================

CREATE OR REPLACE FUNCTION create_verification_code(
    p_user_id UUID,
    p_phone_number TEXT,
    p_verification_method TEXT
)
RETURNS TABLE(
    id UUID,
    code TEXT,
    expires_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_code TEXT;
    v_expires_at TIMESTAMP WITH TIME ZONE;
    v_id UUID;
BEGIN
    -- Invalider les anciens codes non vérifiés
    UPDATE verification_codes 
    SET is_verified = TRUE 
    WHERE user_id = p_user_id 
      AND is_verified = FALSE;
    
    -- Générer un nouveau code
    v_code := generate_verification_code();
    v_expires_at := NOW() + INTERVAL '24 hours';
    
    -- Insérer le nouveau code
    INSERT INTO verification_codes (
        user_id,
        code,
        verification_method,
        phone_number,
        expires_at
    ) VALUES (
        p_user_id,
        v_code,
        p_verification_method,
        p_phone_number,
        v_expires_at
    )
    RETURNING verification_codes.id, verification_codes.code, verification_codes.expires_at
    INTO v_id, v_code, v_expires_at;
    
    RETURN QUERY SELECT v_id, v_code, v_expires_at;
END;
$$;

-- =====================================================
-- 7. FONCTION: Vérifier un code
-- =====================================================

CREATE OR REPLACE FUNCTION verify_code(
    p_user_id UUID,
    p_code TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_valid BOOLEAN;
BEGIN
    -- Vérifier si le code existe et est valide
    SELECT EXISTS(
        SELECT 1 
        FROM verification_codes 
        WHERE user_id = p_user_id 
          AND code = p_code 
          AND is_verified = FALSE 
          AND expires_at > NOW()
    ) INTO v_is_valid;
    
    IF v_is_valid THEN
        -- Marquer le code comme vérifié
        UPDATE verification_codes 
        SET is_verified = TRUE,
            verified_at = NOW()
        WHERE user_id = p_user_id 
          AND code = p_code;
        
        -- Marquer l'utilisateur comme vérifié
        UPDATE users 
        SET is_verified = TRUE 
        WHERE id = p_user_id;
        
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;

-- =====================================================
-- 8. FONCTION: Marquer un code comme envoyé (admin)
-- =====================================================

CREATE OR REPLACE FUNCTION mark_code_as_sent(
    p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE verification_codes 
    SET is_sent = TRUE 
    WHERE user_id = p_user_id 
      AND is_verified = FALSE 
      AND expires_at > NOW();
END;
$$;

-- =====================================================
-- 9. FONCTION: Nettoyer les codes expirés (maintenance)
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_expired_codes()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM verification_codes 
    WHERE expires_at < NOW() - INTERVAL '7 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- =====================================================
-- 10. VÉRIFICATIONS FINALES
-- =====================================================

-- Vérifier que tout est en place
DO $$ 
BEGIN
    -- Vérifier la colonne is_verified
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'is_verified'
    ) THEN
        RAISE NOTICE '✅ Colonne is_verified existe';
    ELSE
        RAISE EXCEPTION '❌ Colonne is_verified manquante';
    END IF;
    
    -- Vérifier la table verification_codes
    IF EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_name = 'verification_codes'
    ) THEN
        RAISE NOTICE '✅ Table verification_codes existe';
    ELSE
        RAISE EXCEPTION '❌ Table verification_codes manquante';
    END IF;
    
    -- Vérifier le RLS
    IF EXISTS (
        SELECT 1 
        FROM pg_tables 
        WHERE tablename = 'verification_codes' 
        AND rowsecurity = FALSE
    ) THEN
        RAISE NOTICE '✅ RLS désactivé sur verification_codes';
    ELSE
        RAISE EXCEPTION '❌ RLS encore activé sur verification_codes';
    END IF;
    
    -- Vérifier la vue
    IF EXISTS (
        SELECT 1 
        FROM information_schema.views 
        WHERE table_name = 'pending_verifications'
    ) THEN
        RAISE NOTICE '✅ Vue pending_verifications existe';
    ELSE
        RAISE EXCEPTION '❌ Vue pending_verifications manquante';
    END IF;
    
    RAISE NOTICE '🎉 Installation complète et vérifiée!';
END $$;

-- =====================================================
-- FIN DU SCRIPT
-- =====================================================
-- Le système de vérification téléphonique est maintenant
-- complètement installé et prêt à être utilisé!
-- =====================================================
