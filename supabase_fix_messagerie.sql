-- ============================================
-- CORRECTION DU SYSTÈME DE MESSAGERIE
-- ============================================
-- Ce script corrige la vue conversations_with_details
-- pour ajouter les compteurs de messages non lus
-- ============================================

-- Recréer la vue avec les compteurs de messages non lus
DROP VIEW IF EXISTS conversations_with_details;
CREATE VIEW conversations_with_details AS
SELECT 
  c.id,
  c.product_id,
  c.buyer_id,
  c.vendor_id,
  c.created_at,
  c.updated_at,
  p.name as product_name,
  p.photo_url as product_photo_url,
  p.price as product_price,
  buyer.name as buyer_name,
  vendor.name as vendor_name,
  -- Dernier message
  (SELECT content FROM messages 
   WHERE conversation_id = c.id 
   ORDER BY created_at DESC LIMIT 1) as last_message,
  -- Date du dernier message
  (SELECT created_at FROM messages 
   WHERE conversation_id = c.id 
   ORDER BY created_at DESC LIMIT 1) as last_message_time,
  -- Compter les messages non lus pour le buyer (messages envoyés par le vendor)
  (SELECT COUNT(*) FROM messages 
   WHERE conversation_id = c.id 
   AND sender_id = c.vendor_id 
   AND is_read = false) as unread_count_buyer,
  -- Compter les messages non lus pour le vendor (messages envoyés par le buyer)
  (SELECT COUNT(*) FROM messages 
   WHERE conversation_id = c.id 
   AND sender_id = c.buyer_id 
   AND is_read = false) as unread_count_vendor
FROM conversations c
LEFT JOIN products p ON c.product_id = p.id
LEFT JOIN users buyer ON c.buyer_id = buyer.id
LEFT JOIN users vendor ON c.vendor_id = vendor.id;

-- Vérifier que la vue fonctionne
SELECT * FROM conversations_with_details LIMIT 5;

-- ============================================
-- RÉSULTAT ATTENDU
-- ============================================
-- La vue doit maintenant contenir :
-- - unread_count_buyer : nombre de messages non lus pour l'acheteur
-- - unread_count_vendor : nombre de messages non lus pour le vendeur
-- - last_message : contenu du dernier message
-- - last_message_time : date du dernier message
-- ============================================
