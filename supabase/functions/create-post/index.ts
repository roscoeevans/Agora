import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CreatePostRequest {
  text: string;
  media_bundle_id?: string | null;
  link_url?: string | null;
  quote_post_id?: string | null;
  reply_to_post_id?: string | null;
  self_destruct_at?: string | null; // ISO 8601 datetime
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
    const body: CreatePostRequest = await req.json();

    // Validate text
    if (!body.text || body.text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Post text cannot be empty" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (body.text.length > 280) {
      return new Response(
        JSON.stringify({ error: "Post text cannot exceed 280 characters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validate self_destruct_at (if provided, must be in future)
    if (body.self_destruct_at) {
      const destructTime = new Date(body.self_destruct_at);
      if (isNaN(destructTime.getTime()) || destructTime <= new Date()) {
        return new Response(
          JSON.stringify({ error: "self_destruct_at must be a future datetime" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
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

    // Create post
    const { data: post, error: postError } = await supabaseClient
      .from("posts")
      .insert({
        author_id: user.id,
        author_display_handle: profile.display_handle,
        text: body.text.trim(),
        media_bundle_id: body.media_bundle_id || null,
        link_url: body.link_url || null,
        quote_post_id: body.quote_post_id || null,
        reply_to_post_id: body.reply_to_post_id || null,
        self_destruct_at: body.self_destruct_at || null,
        visibility: "public",
      })
      .select()
      .single();

    if (postError) {
      console.error("Error creating post:", postError);
      return new Response(
        JSON.stringify({ error: "Failed to create post", details: postError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Return created post
    return new Response(
      JSON.stringify(post),
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

