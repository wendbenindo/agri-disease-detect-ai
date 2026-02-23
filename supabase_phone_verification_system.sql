-- ============================================================================
-- SYSTÈME DE VÉRIFICATION TÉLÉPHONIQUE
-- ============================================================================
-- Ce script crée le système de vérification par code SMS/WhatsApp
-- Les codes sont valides pendant 24 heures

-- ============================================================================
-- 1. CRÉER LA TABLE verification_codes
-- ============================================================================

CREATE TABLE IF NOT EXISTS verification_codes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code VARCHAR(6) NOT NULL,
  verification_method VARCHAR(20) NOT NULL CHECK (verification_method IN ('sms', 'whatsapp')),
  phone_number TEXT NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  is_sent BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  verified_at TIMESTAMP WITH TIME ZONE,
  
  -- Index pour recherche rapide
  CONSTRAINT unique_active_code UNIQUE (user_id, is_verified)
);

-- Index pour améliorer les performances
CREATE INDEX idx_verification_codes_user_id ON verification_codes(user_id);
CREATE INDEX idx_verification_codes_code ON verification_codes(code);
CREATE INDEX idx_verification_codes_expires_at ON verification_codes(expires_at);
CREATE INDEX idx_verification_codes_is_verified ON verification_codes(is_verified);

-- ============================================================================
-- 2. AJOUTER LA COLONNE is_verified DANS users
-- ============================================================================

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;

-- ============================================================================
-- 3. FONCTION POUR GÉNÉRER UN CODE À 6 CHIFFRES
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS VARCHAR(6) AS $$
BEGIN
  RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. FONCTION POUR CRÉER UN CODE DE VÉRIFICATION
-- ============================================================================

CREATE OR REPLACE FUNCTION create_verification_code(
  p_user_id UUID,
  p_phone_number TEXT,
  p_verification_method VARCHAR(20)
)
RETURNS TABLE(
  code VARCHAR(6),
  expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
  v_code VARCHAR(6);
  v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Supprimer les anciens codes non vérifiés de cet utilisateur
  DELETE FROM verification_codes 
  WHERE user_id = p_user_id AND is_verified = FALSE;
  
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
  );
  
  RETURN QUERY SELECT v_code, v_expires_at;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. FONCTION POUR VÉRIFIER UN CODE
-- ============================================================================

CREATE OR REPLACE FUNCTION verify_code(
  p_user_id UUID,
  p_code VARCHAR(6)
)
RETURNS BOOLEAN AS $$
DECLARE
  v_code_record RECORD;
BEGIN
  -- Chercher le code
  SELECT * INTO v_code_record
  FROM verification_codes
  WHERE user_id = p_user_id
    AND code = p_code
    AND is_verified = FALSE
    AND expires_at > NOW();
  
  -- Si le code n'existe pas ou est expiré
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Marquer le code comme vérifié
  UPDATE verification_codes
  SET is_verified = TRUE,
      verified_at = NOW()
  WHERE id = v_code_record.id;
  
  -- Marquer l'utilisateur comme vérifié
  UPDATE users
  SET is_verified = TRUE,
      updated_at = NOW()
  WHERE id = p_user_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 6. FONCTION POUR MARQUER UN CODE COMME ENVOYÉ
-- ============================================================================

CREATE OR REPLACE FUNCTION mark_code_as_sent(
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE verification_codes
  SET is_sent = TRUE
  WHERE user_id = p_user_id
    AND is_verified = FALSE
    AND expires_at > NOW();
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. VUE POUR LE PANEL ADMIN
-- ============================================================================

CREATE OR REPLACE VIEW pending_verifications AS
SELECT 
  vc.id,
  vc.user_id,
  u.name,
  vc.phone_number,
  vc.code,
  vc.verification_method,
  vc.is_sent,
  vc.expires_at,
  vc.created_at,
  EXTRACT(EPOCH FROM (vc.expires_at - NOW())) / 3600 AS hours_remaining
FROM verification_codes vc
JOIN users u ON vc.user_id = u.id
WHERE vc.is_verified = FALSE
  AND vc.expires_at > NOW()
ORDER BY vc.created_at DESC;

-- ============================================================================
-- 8. FONCTION POUR NETTOYER LES CODES EXPIRÉS (à exécuter périodiquement)
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_expired_codes()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM verification_codes
  WHERE expires_at < NOW() - INTERVAL '7 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MESSAGES DE CONFIRMATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Système de vérification téléphonique créé avec succès!';
  RAISE NOTICE '📱 Les codes sont valides pendant 24 heures';
  RAISE NOTICE '💬 Méthodes supportées: SMS et WhatsApp';
  RAISE NOTICE '👨‍💼 Vue admin disponible: pending_verifications';
END $$;
