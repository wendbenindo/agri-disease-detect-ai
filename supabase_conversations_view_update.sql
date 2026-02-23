-- Mise à jour de la vue conversations_with_details pour inclure le dernier message

DROP VIEW IF EXISTS conversations_with_details;

CREATE VIEW conversations_with_details AS
SELECT 
  c.id,
  c.product_id,
  c.buyer_id,
  c.vendor_id,
  c.created_at,
  c.updated_at,
  p.name AS product_name,
  p.photo_url AS product_photo_url,
  v.name AS vendor_name,
  v.phone_number AS vendor_phone,
  b.name AS buyer_name,
  b.phone_number AS buyer_phone,
  (
    SELECT content 
    FROM messages 
    WHERE conversation_id = c.id 
    ORDER BY created_at DESC 
    LIMIT 1
  ) AS last_message,
  (
    SELECT created_at 
    FROM messages 
    WHERE conversation_id = c.id 
    ORDER BY created_at DESC 
    LIMIT 1
  ) AS last_message_time,
  (
    SELECT COUNT(*) 
    FROM messages 
    WHERE conversation_id = c.id 
    AND sender_id != c.buyer_id 
    AND is_read = false
  )::int AS unread_count
FROM conversations c
LEFT JOIN products p ON c.product_id = p.id
LEFT JOIN users v ON c.vendor_id = v.id
LEFT JOIN users b ON c.buyer_id = b.id;

-- Donner les permissions
GRANT SELECT ON conversations_with_details TO authenticated;
GRANT SELECT ON conversations_with_details TO anon;
