import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface EditPostRequest {
  post_id: string;
  new_text: string;
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
    const body: EditPostRequest = await req.json();

    // Validate new text
    if (!body.new_text || body.new_text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Post text cannot be empty" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (body.new_text.length > 280) {
      return new Response(
        JSON.stringify({ error: "Post text cannot exceed 280 characters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get the existing post
    const { data: existingPost, error: fetchError } = await supabaseClient
      .from("posts")
      .select("*")
      .eq("id", body.post_id)
      .single();

    if (fetchError || !existingPost) {
      return new Response(
        JSON.stringify({ error: "Post not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check if user owns the post
    if (existingPost.author_id !== user.id) {
      return new Response(
        JSON.stringify({ error: "You can only edit your own posts" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check if post is within 15-minute edit window
    const createdAt = new Date(existingPost.created_at);
    const now = new Date();
    const minutesSinceCreation = (now.getTime() - createdAt.getTime()) / (1000 * 60);

    if (minutesSinceCreation > 15) {
      return new Response(
        JSON.stringify({ 
          error: "Edit window expired",
          message: "Posts can only be edited within 15 minutes of creation"
        }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Save current text to edit history
    const { error: historyError } = await supabaseClient
      .from("post_edits")
      .insert({
        post_id: body.post_id,
        previous_text: existingPost.text,
        edited_by: user.id,
      });

    if (historyError) {
      console.error("Error saving edit history:", historyError);
      return new Response(
        JSON.stringify({ error: "Failed to save edit history", details: historyError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update the post
    const { data: updatedPost, error: updateError } = await supabaseClient
      .from("posts")
      .update({
        text: body.new_text.trim(),
        edited_at: new Date().toISOString(),
      })
      .eq("id", body.post_id)
      .select()
      .single();

    if (updateError) {
      console.error("Error updating post:", updateError);
      return new Response(
        JSON.stringify({ error: "Failed to update post", details: updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Return updated post
    return new Response(
      JSON.stringify(updatedPost),
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

