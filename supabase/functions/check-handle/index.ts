import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
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
    // Get handle from query parameters
    const url = new URL(req.url)
    const handle = url.searchParams.get('handle')

    if (!handle) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing handle parameter',
          message: 'Handle is required' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Validate handle format (3-30 chars, letters, numbers, periods, underscores)
    // Instagram/Threads-style rules: case-insensitive, no consecutive periods
    const handleRegex = /^[a-zA-Z0-9._]{3,30}$/
    if (!handleRegex.test(handle)) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid handle format',
          message: 'Handle must be 3-30 characters, letters, numbers, periods, and underscores only' 
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
    if (!/[a-zA-Z]/.test(handle)) {
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

    // Create Supabase client (no auth required for public availability check)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // Check if handle exists in database (case-insensitive)
    // Since handles are stored as lowercase, convert input to lowercase for comparison
    const handleLowercase = handle.toLowerCase()
    const { data: existingUser, error: queryError } = await supabaseClient
      .from('users')
      .select('handle')
      .eq('handle', handleLowercase)
      .maybeSingle()

    if (queryError) {
      console.error('Error checking handle:', queryError)
      return new Response(
        JSON.stringify({ 
          error: 'Database error',
          message: 'Failed to check handle availability' 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    const available = !existingUser

    // Generate suggestions if handle is taken
    let suggestions: string[] = []
    if (!available) {
      // Generate 5 alternative suggestions
      const baseSuggestions = [
        `${handle}1`,
        `${handle}2`,
        `${handle}_`,
        `${handle}${new Date().getFullYear()}`,
        `${handle}123`,
      ]
      
      // Filter out suggestions that might also be taken
      // (For simplicity, we're just returning them all - could check each one)
      suggestions = baseSuggestions.slice(0, 5)
    }

    // Return availability result
    return new Response(
      JSON.stringify({
        available,
        suggestions: available ? [] : suggestions,
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

