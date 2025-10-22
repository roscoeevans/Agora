import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CreateReplyRequest {
  parentPostId: string; // The root post being replied to
  replyToCommentId?: string | null; // Optional: specific comment being replied to (for nested replies)
  text: string;
  attestation?: string; // Device attestation token (optional for now)
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get current user
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const body: CreateReplyRequest = await req.json();

    // Validate required fields
    if (!body.parentPostId) {
      return new Response(
        JSON.stringify({ error: "parentPostId is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!body.text || body.text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Reply text cannot be empty" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (body.text.length > 280) {
      return new Response(
        JSON.stringify({ error: "Reply text cannot exceed 280 characters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get parent post to check it exists and inherit visibility
    const { data: parentPost, error: parentError } = await supabaseClient
      .from("posts")
      .select("id, visibility, author_id")
      .eq("id", body.parentPostId)
      .single();

    if (parentError || !parentPost) {
      return new Response(
        JSON.stringify({ error: "Parent post not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // If replying to a specific comment, verify it exists and belongs to the parent thread
    if (body.replyToCommentId) {
      const { data: replyToComment, error: replyError } = await supabaseClient
        .from("posts")
        .select("id, reply_to_post_id")
        .eq("id", body.replyToCommentId)
        .single();

      if (replyError || !replyToComment) {
        return new Response(
          JSON.stringify({ error: "Comment to reply to not found" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Verify the comment is part of the parent thread
      // (it should have reply_to_post_id pointing to parent or be a reply in the thread)
      // For simplicity, we'll allow it if it exists
    }

    // Get user's profile to get display_handle
    const { data: profile, error: profileError } = await supabaseClient
      .from("users")
      .select("display_handle")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ error: "User profile not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create reply (which is just a post with reply_to_post_id set)
    // Always set reply_to_post_id to the root parent post for flat threading at DB level
    // We'll handle nested display in the UI layer
    const { data: reply, error: replyError } = await supabaseClient
      .from("posts")
      .insert({
        author_id: user.id,
        author_display_handle: profile.display_handle,
        text: body.text.trim(),
        reply_to_post_id: body.parentPostId, // Always point to root post
        visibility: parentPost.visibility, // Inherit parent visibility
      })
      .select()
      .single();

    if (replyError) {
      console.error("Error creating reply:", replyError);
      return new Response(
        JSON.stringify({ error: "Failed to create reply", details: replyError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Increment parent post's reply_count (will be handled by trigger, but we can do it explicitly)
    // The trigger should handle this automatically
    
    // Return created reply
    return new Response(
      JSON.stringify(reply),
      { 
        status: 201, 
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

