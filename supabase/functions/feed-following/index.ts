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

    // Parse query parameters
    const url = new URL(req.url)
    const cursor = url.searchParams.get('cursor')
    const limit = parseInt(url.searchParams.get('limit') || '20', 10)
    
    // Validate limit
    if (limit < 1 || limit > 50) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid limit',
          message: 'Limit must be between 1 and 50' 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse cursor (timestamp for chronological pagination)
    let cursorDate: Date | null = null
    if (cursor) {
      cursorDate = new Date(cursor)
      if (isNaN(cursorDate.getTime())) {
        return new Response(
          JSON.stringify({ 
            error: 'Invalid cursor',
            message: 'Cursor must be a valid ISO 8601 date' 
          }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        )
      }
    }

    // First, get list of users the current user follows
    const { data: follows, error: followsError } = await supabaseClient
      .from('follows')
      .select('followee_id')
      .eq('follower_id', user.id)

    if (followsError) {
      console.error('Error fetching follows:', followsError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch follows',
          message: followsError.message 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // If user follows nobody, return empty feed
    if (!follows || follows.length === 0) {
      return new Response(
        JSON.stringify({
          posts: [],
          nextCursor: null,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Extract followee IDs
    const followeeIds = follows.map(f => f.followee_id)

    // Build query for posts from users the current user follows
    // Chronological order (newest first)
    // IMPORTANT: Use explicit foreign key name to disambiguate relationship
    let query = supabaseClient
      .from('posts')
      .select(`
        id,
        author_id,
        text,
        link_url,
        media_bundle_id,
        reply_to_post_id,
        quote_post_id,
        like_count,
        repost_count,
        reply_count,
        visibility,
        created_at,
        edited_at,
        self_destruct_at,
        users!posts_author_id_fkey (
          handle,
          display_handle,
          display_name,
          avatar_url
        )
      `)
      .in('author_id', followeeIds)
      .eq('visibility', 'public')
      .order('created_at', { ascending: false })
      .limit(limit + 1) // Fetch one extra to check if there's a next page

    // Apply cursor for pagination
    if (cursorDate) {
      query = query.lt('created_at', cursorDate.toISOString())
    }

    const { data: posts, error: fetchError } = await query

    if (fetchError) {
      console.error('Error fetching following feed:', fetchError)
      console.error('Full error details:', JSON.stringify(fetchError))
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch following feed',
          message: fetchError.message,
          details: fetchError
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    if (!posts || posts.length === 0) {
      console.log('No posts found for following feed')
      return new Response(
        JSON.stringify({
          posts: [],
          nextCursor: null,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Check if there's a next page
    const hasMore = posts.length > limit
    const postsToReturn = hasMore ? posts.slice(0, limit) : posts
    
    console.log(`Fetched ${postsToReturn.length} posts for following feed`)

    // Determine next cursor (created_at of last post)
    const nextCursor = hasMore && postsToReturn.length > 0
      ? postsToReturn[postsToReturn.length - 1].created_at
      : null

    // Fetch viewer state (likes and reposts) for all posts
    const postIds = postsToReturn.map(p => p.id)
    
    let likedPostIds = new Set()
    let repostedPostIds = new Set()
    
    // Only query likes/reposts if there are posts to check
    if (postIds.length > 0) {
      // Get likes by current user
      const { data: likes } = await supabaseClient
        .from('likes')
        .select('post_id')
        .eq('user_id', user.id)
        .in('post_id', postIds)
      
      likedPostIds = new Set(likes?.map(l => l.post_id) || [])
      
      // Get reposts by current user
      const { data: reposts } = await supabaseClient
        .from('reposts')
        .select('post_id')
        .eq('user_id', user.id)
        .in('post_id', postIds)
      
      repostedPostIds = new Set(reposts?.map(r => r.post_id) || [])
    }
    
    // Transform database rows to match OpenAPI schema (camelCase)
    let transformedPosts
    try {
      transformedPosts = postsToReturn.map((post: any, index: number) => {
        try {
          // Handle users field (can be object or array depending on PostgREST version)
          const userInfo = Array.isArray(post.users) ? post.users[0] : post.users
          
          if (!userInfo) {
            console.error(`Post ${index} missing users field:`, JSON.stringify(post))
            throw new Error(`Post at index ${index} missing user information`)
          }
          
          return {
            id: post.id,
            authorId: post.author_id,
            authorDisplayHandle: userInfo.display_handle,
            authorDisplayName: userInfo.display_name,
            authorAvatarUrl: userInfo.avatar_url,
            text: post.text,
            linkUrl: post.link_url,
            mediaBundleId: post.media_bundle_id,
            replyToPostId: post.reply_to_post_id,
            quotePostId: post.quote_post_id,
            likeCount: post.like_count || 0,
            repostCount: post.repost_count || 0,
            replyCount: post.reply_count || 0,
            visibility: post.visibility,
            createdAt: new Date(post.created_at).toISOString(),
            editedAt: post.edited_at ? new Date(post.edited_at).toISOString() : null,
            selfDestructAt: post.self_destruct_at ? new Date(post.self_destruct_at).toISOString() : null,
            isLikedByViewer: likedPostIds.has(post.id),
            isRepostedByViewer: repostedPostIds.has(post.id),
          }
        } catch (postError) {
          console.error(`Error transforming post at index ${index}:`, postError)
          console.error(`Post data:`, JSON.stringify(post, null, 2))
          throw postError
        }
      })
    } catch (transformError) {
      console.error('Error during post transformation:', transformError)
      return new Response(
        JSON.stringify({
          error: 'Post transformation failed',
          message: transformError.message,
          details: transformError
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Return feed response
    return new Response(
      JSON.stringify({
        posts: transformedPosts,
        nextCursor: nextCursor,
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

// To invoke:
// curl -i --location --request GET 'http://localhost:54321/functions/v1/feed-following?limit=20' \
//   --header 'Authorization: Bearer YOUR_JWT_TOKEN'

