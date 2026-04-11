// EA-Moderation Edge Function
// Wird getriggert wenn ea_report_count >= 5

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    )

    const { post_id, reporter_id } = await req.json()

    if (!post_id) {
      return new Response(JSON.stringify({ error: "post_id required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    // Prüfe aktuellen Stand
    const { data: post } = await supabase
      .from("posts")
      .select("ea_report_count, report_status, user_id")
      .eq("id", post_id)
      .single()

    if (!post) {
      return new Response(JSON.stringify({ error: "Post nicht gefunden" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    // Schon in Bearbeitung?
    if (post.report_status !== "none") {
      return new Response(JSON.stringify({ action: "skipped", reason: "already_processing" }))
    }

    // >= 5 Reports → als pending markieren
    if (post.ea_report_count >= 5) {
      await supabase
        .from("posts")
        .update({
          report_status: "pending",
          is_ea_content: true,
        })
        .eq("id", post_id)

      // Admins benachrichtigen
      const { data: admins } = await supabase
        .from("users")
        .select("id")
        .eq("is_admin", true)

      if (admins && admins.length > 0) {
        const notifications = admins.map((admin) => ({
          user_id: admin.id,
          type: "ea_resolved",
          actor_id: reporter_id ?? null,
          post_id,
        }))
        await supabase.from("notifications").insert(notifications)
      }

      console.log(`[EA] Post ${post_id} als pending markiert (${post.ea_report_count} Reports)`)

      return new Response(
        JSON.stringify({ action: "marked_pending", post_id, report_count: post.ea_report_count }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    return new Response(
      JSON.stringify({ action: "queued", report_count: post.ea_report_count }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (error) {
    console.error("[EA Moderation] Error:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
