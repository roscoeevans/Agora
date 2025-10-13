// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateProfileRequest {
  handle: string
  displayHandle: string
  displayName: string
  bio?: string
  avatarUrl?: string
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

    // Get authenticated user from JWT
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const body: CreateProfileRequest = await req.json()
    const { handle, displayHandle, displayName, bio, avatarUrl } = body

    // Validate handle format (Instagram/Threads-style rules)
    const handleRegex = /^[a-z0-9._]{3,30}$/
    if (!handleRegex.test(handle)) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid handle format', 
          message: 'Handle must be 3-30 characters, lowercase letters, numbers, periods, and underscores only' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }
    
    // Check for consecutive periods
    if (handle.includes('..')) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid handle format',
          message: 'Handle cannot contain consecutive periods' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }
    
    // Check if all numbers (must have at least one letter)
    if (!/[a-z]/.test(handle)) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid handle format',
          message: 'Handle must contain at least one letter' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Validate display handle and name are not empty
    if (!displayHandle || !displayName) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields',
          message: 'displayHandle and displayName are required' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // TODO: Add additional verification gates
    // - await checkDeviceAttestation(req)
    // - await checkPhoneVerification(user.id)
    // - await checkRateLimits(user.id, req.headers.get('x-forwarded-for'))

    // Check if user already has a profile
    const { data: existingUser } = await supabaseClient
      .from('users')
      .select('id')
      .eq('id', user.id)
      .single()

    if (existingUser) {
      return new Response(
        JSON.stringify({ 
          error: 'Profile already exists',
          message: 'User already has a profile' 
        }),
        {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Check if handle is already taken
    const { data: existingHandle } = await supabaseClient
      .from('users')
      .select('handle')
      .eq('handle', handle)
      .single()

    if (existingHandle) {
      return new Response(
        JSON.stringify({ 
          error: 'Handle already taken',
          message: 'This handle is already in use' 
        }),
        {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Get apple_sub from user metadata if available
    const appleSub = user.user_metadata?.sub || null
    const phoneE164 = user.phone || null

    // Create user profile atomically
    const { data: newUser, error: insertError } = await supabaseClient
      .from('users')
      .insert({
        id: user.id,
        handle: handle,
        display_handle: displayHandle,
        display_name: displayName,
        bio: bio || '',
        avatar_url: avatarUrl || null,
        apple_sub: appleSub,
        phone_e164: phoneE164,
        trust_level: 0,
      })
      .select()
      .single()

    if (insertError) {
      console.error('Error creating profile:', insertError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create profile',
          message: insertError.message 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Transform database row to match OpenAPI schema (camelCase)
    const response = {
      id: newUser.id,
      handle: newUser.handle,
      displayHandle: newUser.display_handle,
      displayName: newUser.display_name,
      bio: newUser.bio,
      avatarUrl: newUser.avatar_url,
      createdAt: new Date(newUser.created_at).toISOString(),
    }

    // Return created user profile
    return new Response(
      JSON.stringify(response),
      {
        status: 201,
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
// curl -i --location --request POST 'http://localhost:54321/functions/v1/create-profile' \
//   --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
//   --header 'Content-Type: application/json' \
//   --data '{"handle":"johndoe","displayHandle":"JohnDoe","displayName":"John Doe"}'

