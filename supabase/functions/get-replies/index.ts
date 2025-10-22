import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface Reply {
  id: string;
  text: string;
  author_id: string;
  author_display_handle: string;
  author_display_name?: string;
  author_avatar_url?: string;
  created_at: string;
  like_count: number;
  repost_count: number;
  reply_count: number;
  is_liked_by_viewer: boolean;
  is_reposted_by_viewer: boolean;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Get authorization header (optional - public replies visible to all)
    const authHeader = req.headers.get("Authorization");
    
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      authHeader ? { global: { headers: { Authorization: authHeader } } } : {}
    );

    // Get current user (if authenticated)
    let currentUserId: string | null = null;
    if (authHeader) {
      const { data: { user } } = await supabaseClient.auth.getUser();
      currentUserId = user?.id || null;
    }

    // Get post ID from URL params
    const url = new URL(req.url);
    const postId = url.searchParams.get("postId");

    if (!postId) {
      return new Response(
        JSON.stringify({ error: "postId query parameter is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify parent post exists
    const { data: parentPost, error: parentError } = await supabaseClient
      .from("posts")
      .select("id")
      .eq("id", postId)
      .single();

    if (parentError || !parentPost) {
      return new Response(
        JSON.stringify({ error: "Post not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch all replies to this post
    const { data: replies, error: repliesError } = await supabaseClient
      .from("posts")
      .select(`
        id,
        text,
        author_id,
        author_display_handle,
        created_at,
        like_count,
        repost_count,
        reply_count
      `)
      .eq("reply_to_post_id", postId)
      .order("created_at", { ascending: true }); // Oldest first, like Twitter

    if (repliesError) {
      console.error("Error fetching replies:", repliesError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch replies", details: repliesError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!replies || replies.length === 0) {
      return new Response(
        JSON.stringify({ replies: [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get author details for all replies
    const authorIds = [...new Set(replies.map(r => r.author_id))];
    const { data: authors, error: authorsError } = await supabaseClient
      .from("users")
      .select("id, display_name, avatar_url, display_handle")
      .in("id", authorIds);

    if (authorsError) {
      console.error("Error fetching authors:", authorsError);
    }

    const authorsMap = new Map(authors?.map(a => [a.id, a]) || []);

    // Get viewer interaction state (likes/reposts) if user is authenticated
    let likesMap = new Map<string, boolean>();
    let repostsMap = new Map<string, boolean>();

    if (currentUserId) {
      const replyIds = replies.map(r => r.id);

      // Get likes
      const { data: likes } = await supabaseClient
        .from("likes")
        .select("post_id")
        .eq("user_id", currentUserId)
        .in("post_id", replyIds);

      if (likes) {
        likes.forEach(like => likesMap.set(like.post_id, true));
      }

      // Get reposts
      const { data: reposts } = await supabaseClient
        .from("reposts")
        .select("post_id")
        .eq("user_id", currentUserId)
        .in("post_id", replyIds);

      if (reposts) {
        reposts.forEach(repost => repostsMap.set(repost.post_id, true));
      }
    }

    // Build reply objects with author info and viewer state
    const enrichedReplies: Reply[] = replies.map(reply => {
      const author = authorsMap.get(reply.author_id);
      return {
        id: reply.id,
        text: reply.text,
        author_id: reply.author_id,
        author_display_handle: reply.author_display_handle,
        author_display_name: author?.display_name || null,
        author_avatar_url: author?.avatar_url || null,
        created_at: reply.created_at,
        like_count: reply.like_count,
        repost_count: reply.repost_count,
        reply_count: reply.reply_count,
        is_liked_by_viewer: likesMap.get(reply.id) || false,
        is_reposted_by_viewer: repostsMap.get(reply.id) || false,
      };
    });

    return new Response(
      JSON.stringify({ replies: enrichedReplies }),
      { 
        status: 200, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      }
    );

  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

