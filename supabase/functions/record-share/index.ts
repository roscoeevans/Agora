import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST",
};

Deno.serve(async (req: Request) => {
  // Generate correlation ID for request tracking
  const correlationId = crypto.randomUUID();

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // Only allow POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({
        code: "METHOD_NOT_ALLOWED",
        message: "Only POST requests are allowed",
        correlationId,
      }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          code: "UNAUTHORIZED",
          message: "You must be signed in to share posts",
          correlationId,
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with JWT from Authorization header
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    );

    // Get authenticated user from JWT (NEVER trust client-provided user_id)
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({
          code: "UNAUTHORIZED",
          message: "You must be signed in to share posts",
          correlationId,
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse body
    const { postId } = await req.json();

    if (!postId) {
      return new Response(
        JSON.stringify({
          code: "INVALID_REQUEST",
          message: "postId is required",
          correlationId,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Rate limit check (max 1 record per user+post per second)
    const rateLimitKey = `rate_limit:share:${user.id}:${postId}`;
    const { data: rateLimitData } = await supabaseClient
      .from("rate_limits")
      .select("last_action_at")
      .eq("key", rateLimitKey)
      .single();

    if (rateLimitData) {
      const lastAction = new Date(rateLimitData.last_action_at);
      const now = new Date();
      if (now.getTime() - lastAction.getTime() < 1000) {
        return new Response(
          JSON.stringify({
            code: "RATE_LIMITED",
            message: "You're doing that too quickly. Please wait a moment.",
            correlationId,
          }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Call RPC (user_id is derived from JWT, not client body)
    // Note: record_share is idempotent - won't create duplicate shares
    const { data, error } = await supabaseClient
      .rpc("record_share", {
        p_post_id: postId,
        p_user_id: user.id, // From JWT only!
      })
      .single();

    if (error) {
      console.error(`[${correlationId}] RPC error:`, error);

      // Check for specific errors
      if (error.message?.includes("not found")) {
        return new Response(
          JSON.stringify({
            code: "POST_NOT_FOUND",
            message: "Post not found",
            correlationId,
          }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          code: "INTERNAL_ERROR",
          message: "Failed to record share",
          correlationId,
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update rate limit timestamp
    await supabaseClient.from("rate_limits").upsert({
      key: rateLimitKey,
      last_action_at: new Date().toISOString(),
    });

    // Record engagement event for recommendation system (fire and forget)
    supabaseClient
      .from("post_events")
      .insert({
        user_id: user.id,
        post_id: postId,
        type: "share",
        meta: { correlation_id: correlationId },
      })
      .then();

    // Return result
    return new Response(
      JSON.stringify({
        shareCount: data.share_count,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error(`[${correlationId}] Unexpected error:`, err);
    return new Response(
      JSON.stringify({
        code: "INTERNAL_ERROR",
        message: "An unexpected error occurred",
        correlationId,
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});


