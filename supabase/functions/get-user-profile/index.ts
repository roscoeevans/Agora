// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

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

    // Get authenticated user from JWT (optional for public profiles)
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    // Parse URL to get userId from path
    const url = new URL(req.url)
    const pathParts = url.pathname.split('/').filter(Boolean)
    const userId = pathParts[pathParts.length - 1] // Last segment is userId

    if (!userId || userId === 'get-user-profile') {
      return new Response(
        JSON.stringify({ 
          error: 'Bad Request',
          message: 'userId parameter is required' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRegex.test(userId)) {
      return new Response(
        JSON.stringify({ 
          error: 'Bad Request',
          message: 'Invalid userId format' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Fetch user profile
    const { data: profile, error: fetchError } = await supabaseClient
      .from('users')
      .select('*')
      .eq('id', userId)
      .single()

    if (fetchError) {
      if (fetchError.code === 'PGRST116') {
        // No rows returned - profile not found
        return new Response(
          JSON.stringify({ 
            error: 'Not Found',
            message: 'User profile not found' 
          }),
          {
            status: 404,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        )
      }

      console.error('Error fetching profile:', fetchError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch profile',
          message: fetchError.message 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Get follower count (users who follow this user)
    const { count: followerCount, error: followerError } = await supabaseClient
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('followee_id', userId)

    if (followerError) {
      console.error('Error counting followers:', followerError)
    }

    // Get following count (users this user follows)
    const { count: followingCount, error: followingError } = await supabaseClient
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('follower_id', userId)

    if (followingError) {
      console.error('Error counting following:', followingError)
    }

    // Get post count
    const { count: postCount, error: postCountError } = await supabaseClient
      .from('posts')
      .select('*', { count: 'exact', head: true })
      .eq('author_id', userId)
      .eq('visibility', 'public') // Only count public posts

    if (postCountError) {
      console.error('Error counting posts:', postCountError)
    }

    // Check if current user is following this profile (if authenticated)
    let isFollowing = false
    if (user && user.id !== userId) {
      const { data: followData } = await supabaseClient
        .from('follows')
        .select('*')
        .eq('follower_id', user.id)
        .eq('followee_id', userId)
        .maybeSingle()
      
      isFollowing = followData !== null
    }

    // Transform database row to match OpenAPI schema (camelCase)
    const response = {
      id: profile.id,
      handle: profile.handle,
      displayHandle: profile.display_handle,
      displayName: profile.display_name,
      bio: profile.bio || '',
      avatarUrl: profile.avatar_url,
      createdAt: new Date(profile.created_at).toISOString(),
      followerCount: followerCount || 0,
      followingCount: followingCount || 0,
      postCount: postCount || 0,
      isCurrentUser: user?.id === userId,
      isFollowing: isFollowing,
    }

    // Return user profile
    return new Response(
      JSON.stringify(response),
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

// To invoke:
// curl -i --location --request GET 'http://localhost:54321/functions/v1/get-user-profile/USER_UUID_HERE' \
//   --header 'Authorization: Bearer YOUR_JWT_TOKEN'


