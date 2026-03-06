// Edge Function pour envoyer des notifications OneSignal de manière sécurisée
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Gérer les requêtes OPTIONS (CORS preflight)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Récupérer les variables d'environnement
    const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')
    const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
      throw new Error('Variables OneSignal manquantes')
    }

    // Vérifier l'authentification
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Non autorisé')
    }

    // Créer un client Supabase
    const supabase = createClient(
      SUPABASE_URL!,
      SUPABASE_SERVICE_ROLE_KEY!,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // ✅ CORRECTION: Vérifier le token avec la clé anon (pas service role)
    // Car l'app utilise l'authentification custom
    const token = authHeader.replace('Bearer ', '')
    
    // Vérifier que le token est valide en essayant de l'utiliser
    const supabaseClient = createClient(
      SUPABASE_URL!,
      token, // Utiliser le token de l'utilisateur
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Tester si le token fonctionne en faisant une requête simple
    const { error: testError } = await supabaseClient
      .from('users')
      .select('id')
      .limit(1)
    
    if (testError) {
      console.error('❌ Token invalide:', testError)
      throw new Error('Token invalide')
    }

    console.log('✅ Token valide')

    // Récupérer les données de la requête
    const { playerIds, title, message, data } = await req.json()

    if (!playerIds || !Array.isArray(playerIds) || playerIds.length === 0) {
      throw new Error('playerIds requis')
    }

    if (!title || !message) {
      throw new Error('title et message requis')
    }

    console.log('📤 Envoi notification OneSignal:', {
      playerIds,
      title,
      message: message.substring(0, 50) + '...',
    })

    // Envoyer la notification via OneSignal
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_player_ids: playerIds,
        headings: { en: title },
        contents: { en: message },
        data: data || {},
      }),
    })

    const result = await response.json()

    if (!response.ok) {
      console.error('❌ Erreur OneSignal:', result)
      throw new Error(`OneSignal error: ${JSON.stringify(result)}`)
    }

    console.log('✅ Notification envoyée:', result)

    return new Response(
      JSON.stringify({ success: true, result }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

  } catch (error) {
    console.error('❌ Erreur:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})
