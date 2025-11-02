import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user (optional for For You feed)
    const { data: { user } } = await supabaseClient.auth.getUser()

    // Parse query params
    const url = new URL(req.url)
    const cursor = url.searchParams.get('cursor')
    const limitParam = url.searchParams.get('limit')
    const limit = Math.min(parseInt(limitParam || '20', 10), 50)

    // Build query
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
        share_count,
        visibility,
        created_at,
        edited_at,
        self_destruct_at,
        users!inner (
          handle,
          display_handle,
          display_name,
          avatar_url
        )
      `)
      .eq('visibility', 'public')
      .order('created_at', { ascending: false })
      .limit(limit + 1) // Fetch one extra to determine if there's a next page

    // Apply cursor-based pagination
    if (cursor) {
      const cursorDate = new Date(cursor).toISOString()
      query = query.lt('created_at', cursorDate)
    }

    const { data: posts, error } = await query

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({
          error: 'Failed to fetch posts',
          details: error.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Determine if there's a next page
    let nextCursor
    const resultPosts = posts || []
    if (resultPosts.length > limit) {
      const lastPost = resultPosts[limit - 1]
      nextCursor = lastPost.created_at
      resultPosts.pop() // Remove the extra post
    }

    // Fetch viewer state (likes and reposts) if user is authenticated
    let likedPostIds = new Set()
    let repostedPostIds = new Set()
    
    if (user && resultPosts.length > 0) {
      const postIds = resultPosts.map(p => p.id)
      
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

    // Transform to API format (snake_case -> camelCase)
    const response = {
      posts: resultPosts.map((post: any) => ({
        id: post.id.toString(),
        authorId: post.author_id,
        authorDisplayHandle: post.users.display_handle,
        authorDisplayName: post.users.display_name,
        authorAvatarUrl: post.users.avatar_url,
        text: post.text,
        linkUrl: post.link_url || undefined,
        mediaBundleId: post.media_bundle_id || undefined,
        replyToPostId: post.reply_to_post_id?.toString(),
        quotePostId: post.quote_post_id?.toString(),
        likeCount: post.like_count || 0,
        repostCount: post.repost_count || 0,
        replyCount: post.reply_count || 0,
        shareCount: post.share_count || 0,
        visibility: post.visibility,
        createdAt: new Date(post.created_at).toISOString(),
        editedAt: post.edited_at ? new Date(post.edited_at).toISOString() : null,
        selfDestructAt: post.self_destruct_at ? new Date(post.self_destruct_at).toISOString() : null,
        isLikedByViewer: likedPostIds.has(post.id.toString()),
        isRepostedByViewer: repostedPostIds.has(post.id.toString()),
      })),
      nextCursor,
    }

    return new Response(JSON.stringify(response), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    })
  } catch (err) {
    console.error('Unexpected error:', err)
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: err.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

