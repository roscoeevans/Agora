// Agora Suggested Creators Edge Function
// Returns popular users to follow (not already followed by viewer)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse query parameters
    const url = new URL(req.url)
    const limitParam = url.searchParams.get('limit')
    const limit = Math.min(50, Math.max(5, Number(limitParam ?? 10)))

    // Create Supabase client with user's JWT
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user from JWT (required for viewer-aware filtering)
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ 
          error: 'Unauthorized',
          message: 'Authentication required for suggested creators' 
        }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Call the suggested_creators database function
    const { data, error: suggestError } = await supabaseClient.rpc('suggested_creators', {
      viewer_id: user.id,
      page_limit: limit,
    })

    if (suggestError) {
      console.error('Suggested creators error:', suggestError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch suggested creators',
          message: suggestError.message 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Transform database results to camelCase for API consistency
    const results = (data ?? []).map((user: any) => ({
      userId: user.user_id,
      handle: user.handle,
      displayHandle: user.display_handle,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      trustLevel: user.trust_level,
      verified: user.verified,
      followersCount: user.followers_count,
      lastActiveAt: user.last_active_at,
    }))

    // Return suggested creators
    return new Response(
      JSON.stringify({ 
        items: results,
        count: results.length,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

// To invoke locally:
// curl -i --location 'http://localhost:54321/functions/v1/suggested-creators?limit=10' \
//   --header 'Authorization: Bearer YOUR_JWT_TOKEN'



