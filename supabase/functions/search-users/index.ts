// Agora Search Users Edge Function
// Provides fast, popularity-blended user search with viewer-aware filtering

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
    const q = url.searchParams.get('q')?.trim() ?? ''
    const after = url.searchParams.get('after')?.trim() ?? null
    const limitParam = url.searchParams.get('limit')
    const limit = Math.min(50, Math.max(5, Number(limitParam ?? 20)))

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
          message: 'Authentication required for search' 
        }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Validate query parameter
    if (!q || q.length === 0) {
      return new Response(
        JSON.stringify({ 
          error: 'Bad Request',
          message: 'Query parameter "q" is required' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Call the search_users_v1 database function
    const { data, error: searchError } = await supabaseClient.rpc('search_users_v1', {
      q: q,
      viewer_id: user.id,
      page_limit: limit,
      after_handle: after,
    })

    if (searchError) {
      console.error('Search error:', searchError)
      return new Response(
        JSON.stringify({ 
          error: 'Search failed',
          message: searchError.message 
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
      score: user.score,
    }))

    // Optional: Log search query for analytics (fire-and-forget)
    // Uncomment when you have search_queries table
    /*
    supabaseClient
      .from('search_queries')
      .insert({
        user_id: user.id,
        query: q,
        result_count: results.length,
      })
      .then() // fire and forget
    */

    // Return search results
    return new Response(
      JSON.stringify({ 
        items: results,
        query: q,
        count: results.length,
        hasMore: results.length >= limit,
        nextCursor: results.length >= limit ? results[results.length - 1].handle : null,
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
// curl -i --location 'http://localhost:54321/functions/v1/search-users?q=rocky&limit=10' \
//   --header 'Authorization: Bearer YOUR_JWT_TOKEN'
//
// To invoke in production:
// curl -i --location 'https://PROJECT_ID.supabase.co/functions/v1/search-users?q=rocky&limit=10' \
//   --header 'Authorization: Bearer YOUR_JWT_TOKEN'

