import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface UpdateProfileRequest {
  displayName?: string;
  handle?: string;
  displayHandle?: string;
  bio?: string;
  avatarUrl?: string;
}

interface UpdateProfileResponse {
  id: string;
  handle: string;
  displayHandle: string;
  displayName: string;
  bio: string | null;
  avatarUrl: string | null;
  createdAt: string;
}

interface ErrorResponse {
  error: string;
  code?: string;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Get user from JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" } as ErrorResponse),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Get current user
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" } as ErrorResponse),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const body: UpdateProfileRequest = await req.json();

    // Fetch current user data
    const { data: currentUser, error: fetchError } = await supabase
      .from("users")
      .select("handle, handle_last_changed_at")
      .eq("id", user.id)
      .single();

    if (fetchError) {
      console.error("Error fetching user:", fetchError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch user data" } as ErrorResponse),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build update object
    const updates: Record<string, any> = {};

    // Handle change validation
    if (body.handle && body.handle !== currentUser.handle) {
      const newHandle = body.handle.toLowerCase();

      // Check if user can change handle (30-day cooldown)
      if (currentUser.handle_last_changed_at) {
        const lastChanged = new Date(currentUser.handle_last_changed_at);
        const daysSinceChange = (Date.now() - lastChanged.getTime()) / (1000 * 60 * 60 * 24);
        
        if (daysSinceChange < 30) {
          const daysRemaining = Math.ceil(30 - daysSinceChange);
          return new Response(
            JSON.stringify({ 
              error: `You can change your handle again in ${daysRemaining} day${daysRemaining === 1 ? '' : 's'}`,
              code: "HANDLE_CHANGE_COOLDOWN"
            } as ErrorResponse),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      }

      // Validate handle format
      const handleRegex = /^[a-z0-9._]{3,30}$/;
      if (!handleRegex.test(newHandle)) {
        return new Response(
          JSON.stringify({ 
            error: "Invalid handle format. Use 3-30 characters: lowercase letters, numbers, periods, and underscores.",
            code: "INVALID_HANDLE_FORMAT"
          } as ErrorResponse),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Check for consecutive periods
      if (newHandle.includes("..")) {
        return new Response(
          JSON.stringify({ 
            error: "Handle cannot contain consecutive periods",
            code: "INVALID_HANDLE_FORMAT"
          } as ErrorResponse),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Check for all numbers
      if (/^[0-9._]+$/.test(newHandle)) {
        return new Response(
          JSON.stringify({ 
            error: "Handle must contain at least one letter",
            code: "INVALID_HANDLE_FORMAT"
          } as ErrorResponse),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Check if handle is available
      const { data: existingUser } = await supabase
        .from("users")
        .select("id")
        .eq("handle", newHandle)
        .single();

      if (existingUser) {
        return new Response(
          JSON.stringify({ 
            error: "Handle is already taken",
            code: "HANDLE_TAKEN"
          } as ErrorResponse),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      updates.handle = newHandle;
      updates.display_handle = body.displayHandle || newHandle;
      updates.handle_last_changed_at = new Date().toISOString();
    }

    // Update display name
    if (body.displayName !== undefined) {
      if (body.displayName.trim().length === 0) {
        return new Response(
          JSON.stringify({ 
            error: "Display name cannot be empty",
            code: "INVALID_DISPLAY_NAME"
          } as ErrorResponse),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      updates.display_name = body.displayName.trim();
    }

    // Update bio
    if (body.bio !== undefined) {
      updates.bio = body.bio.trim();
    }

    // Update avatar URL
    if (body.avatarUrl !== undefined) {
      updates.avatar_url = body.avatarUrl || null;
    }

    // Update updated_at timestamp
    updates.updated_at = new Date().toISOString();

    // Perform update
    const { data: updatedUser, error: updateError } = await supabase
      .from("users")
      .update(updates)
      .eq("id", user.id)
      .select()
      .single();

    if (updateError) {
      console.error("Error updating profile:", updateError);
      return new Response(
        JSON.stringify({ error: "Failed to update profile" } as ErrorResponse),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Format response
    const response: UpdateProfileResponse = {
      id: updatedUser.id,
      handle: updatedUser.handle,
      displayHandle: updatedUser.display_handle,
      displayName: updatedUser.display_name,
      bio: updatedUser.bio,
      avatarUrl: updatedUser.avatar_url,
      createdAt: updatedUser.created_at,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" } as ErrorResponse),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

