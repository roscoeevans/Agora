import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '', 
      Deno.env.get('SUPABASE_ANON_KEY') ?? '', 
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! }
        }
      }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();

    const url = new URL(req.url);
    const pathParts = url.pathname.split('/').filter(Boolean);
    const userId = pathParts[pathParts.length - 1];

    if (!userId || userId === 'get-user-posts') {
      return new Response(JSON.stringify({
        error: 'Bad Request',
        message: 'userId parameter is required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(userId)) {
      return new Response(JSON.stringify({
        error: 'Bad Request',
        message: 'Invalid userId format'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const cursor = url.searchParams.get('cursor');
    const limit = parseInt(url.searchParams.get('limit') || '20', 10);
    
    if (limit < 1 || limit > 50) {
      return new Response(JSON.stringify({
        error: 'Invalid limit',
        message: 'Limit must be between 1 and 50'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    let cursorDate = null;
    if (cursor) {
      cursorDate = new Date(cursor);
      if (isNaN(cursorDate.getTime())) {
        return new Response(JSON.stringify({
          error: 'Invalid cursor',
          message: 'Cursor must be a valid ISO 8601 date'
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
    }

    let query = supabaseClient
      .from('posts')
      .select('id, author_id, text, link_url, media_bundle_id, reply_to_post_id, quote_post_id, like_count, repost_count, reply_count, visibility, created_at, edited_at, self_destruct_at')
      .eq('author_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit + 1);

    if (user?.id !== userId) {
      query = query.eq('visibility', 'public');
    }

    if (cursorDate) {
      query = query.lt('created_at', cursorDate.toISOString());
    }

    const { data: posts, error: fetchError } = await query;

    if (fetchError) {
      console.error('Error fetching user posts:', fetchError);
      return new Response(JSON.stringify({
        error: 'Failed to fetch user posts',
        message: fetchError.message
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const { data: userProfile, error: profileError } = await supabaseClient
      .from('users')
      .select('handle, display_handle, display_name, avatar_url')
      .eq('id', userId)
      .single();

    if (profileError) {
      console.error('Error fetching user profile:', profileError);
      return new Response(JSON.stringify({
        error: 'Failed to fetch user profile',
        message: profileError.message
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const hasMore = posts.length > limit;
    const postsToReturn = hasMore ? posts.slice(0, limit) : posts;
    const nextCursor = hasMore && postsToReturn.length > 0 ? postsToReturn[postsToReturn.length - 1].created_at : null;

    // Fetch viewer state (likes and reposts) for all posts (only if user is authenticated)
    let likedPostIds = new Set();
    let repostedPostIds = new Set();
    
    if (user) {
      const postIds = postsToReturn.map(p => p.id);
      
      // Get likes by current user
      const { data: likes } = await supabaseClient
        .from('likes')
        .select('post_id')
        .eq('user_id', user.id)
        .in('post_id', postIds);
      
      likedPostIds = new Set(likes?.map(l => l.post_id) || []);
      
      // Get reposts by current user
      const { data: reposts } = await supabaseClient
        .from('reposts')
        .select('post_id')
        .eq('user_id', user.id)
        .in('post_id', postIds);
      
      repostedPostIds = new Set(reposts?.map(r => r.post_id) || []);
    }

    const transformedPosts = postsToReturn.map((post) => ({
      id: post.id.toString(),
      authorId: post.author_id,
      authorDisplayHandle: userProfile.display_handle,
      authorDisplayName: userProfile.display_name,
      authorAvatarUrl: userProfile.avatar_url,
      text: post.text,
      linkUrl: post.link_url,
      mediaBundleId: post.media_bundle_id,
      replyToPostId: post.reply_to_post_id?.toString(),
      quotePostId: post.quote_post_id?.toString(),
      likeCount: post.like_count || 0,
      repostCount: post.repost_count || 0,
      replyCount: post.reply_count || 0,
      visibility: post.visibility,
      createdAt: new Date(post.created_at).toISOString(),
      editedAt: post.edited_at ? new Date(post.edited_at).toISOString() : null,
      selfDestructAt: post.self_destruct_at ? new Date(post.self_destruct_at).toISOString() : null,
      isLikedByViewer: likedPostIds.has(post.id),
      isRepostedByViewer: repostedPostIds.has(post.id),
    }));

    return new Response(JSON.stringify({
      posts: transformedPosts,
      nextCursor: nextCursor,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Unexpected error:', error);
    return new Response(JSON.stringify({
      error: 'Internal server error',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});