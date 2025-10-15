import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { DOMParser } from "https://deno.land/x/deno_dom@v0.1.45/deno-dom-wasm.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface LinkPreviewRequest {
  url: string;
}

interface LinkPreview {
  url: string;
  title?: string;
  description?: string;
  image_url?: string;
  site_name?: string;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Parse request body
    const body: LinkPreviewRequest = await req.json();

    // Validate URL
    if (!body.url) {
      return new Response(
        JSON.stringify({ error: "URL is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let parsedUrl: URL;
    try {
      parsedUrl = new URL(body.url);
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid URL" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch the page HTML
    let html: string;
    try {
      const response = await fetch(parsedUrl.toString(), {
        headers: {
          "User-Agent": "AgoraBot/1.0 (Link Preview Fetcher)",
        },
        signal: AbortSignal.timeout(5000), // 5 second timeout
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      html = await response.text();
    } catch (error) {
      console.error("Error fetching URL:", error);
      return new Response(
        JSON.stringify({ 
          error: "Failed to fetch URL", 
          details: error.message 
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse HTML and extract Open Graph tags
    const doc = new DOMParser().parseFromString(html, "text/html");
    if (!doc) {
      return new Response(
        JSON.stringify({ error: "Failed to parse HTML" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const preview: LinkPreview = {
      url: body.url,
    };

    // Extract Open Graph tags
    const ogTitle = doc.querySelector('meta[property="og:title"]')?.getAttribute("content");
    const ogDescription = doc.querySelector('meta[property="og:description"]')?.getAttribute("content");
    const ogImage = doc.querySelector('meta[property="og:image"]')?.getAttribute("content");
    const ogSiteName = doc.querySelector('meta[property="og:site_name"]')?.getAttribute("content");

    // Fallback to standard meta tags if OG tags not found
    const title = ogTitle || doc.querySelector("title")?.textContent || undefined;
    const description = ogDescription || 
                       doc.querySelector('meta[name="description"]')?.getAttribute("content") || 
                       undefined;

    preview.title = title?.trim();
    preview.description = description?.trim();
    preview.image_url = ogImage;
    preview.site_name = ogSiteName || parsedUrl.hostname;

    // Return preview
    return new Response(
      JSON.stringify(preview),
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

