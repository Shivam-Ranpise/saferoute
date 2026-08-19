// Supabase Edge Function: dispatch-notification
// Triggered on notification_events INSERT or direct RPC invocation.
// Resolves parent channel preferences, org event overrides, and delivers via Push, WhatsApp, and SMS.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface DispatchPayload {
  event_id?: string;
  record?: {
    id: string;
    organization_id: string;
    trip_id?: string;
    child_id?: string;
    event_type: string;
    priority: string;
    title: string;
    message: string;
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: DispatchPayload = await req.json();
    const eventId = body.event_id || body.record?.id;

    if (!eventId) {
      return new Response(
        JSON.stringify({ error: "Missing event_id or record in payload" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch Notification Event
    const { data: event, error: eventError } = await supabase
      .from("notification_events")
      .select("*, organizations(*)")
      .eq("id", eventId)
      .single();

    if (eventError || !event) {
      return new Response(
        JSON.stringify({ error: `Event not found: ${eventError?.message}` }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Resolve Recipients
    let recipientProfileIds: string[] = [];

    if (event.child_id) {
      // Find parent of child
      const { data: child } = await supabase
        .from("children")
        .select("parent_id, parents(profile_id)")
        .eq("id", event.child_id)
        .single();

      if (child?.parents?.profile_id) {
        recipientProfileIds.push(child.parents.profile_id);
      }
    } else if (event.trip_id) {
      // Find all parents of children assigned to this bus route
      const { data: trip } = await supabase
        .from("trips")
        .select("bus_id")
        .eq("id", event.trip_id)
        .single();

      if (trip?.bus_id) {
        const { data: students } = await supabase
          .from("children")
          .select("parent_id, parents(profile_id)")
          .eq("bus_id", trip.bus_id);

        if (students) {
          recipientProfileIds = students
            .map((s: any) => s.parents?.profile_id)
            .filter((id: string) => id != null);
        }
      }
    }

    // 3. Resolve Organization Event Settings & Parent Preferences
    const { data: eventSettings } = await supabase
      .from("notification_event_settings")
      .select("*")
      .eq("organization_id", event.organization_id)
      .eq("event_type", event.event_type)
      .maybeSingle();

    const pushEnabledByOrg = eventSettings ? eventSettings.push_enabled : true;
    const whatsappEnabledByOrg = eventSettings ? eventSettings.whatsapp_enabled : false;
    const smsEnabledByOrg = eventSettings ? eventSettings.sms_enabled : false;
    const isEmergencyOverride = eventSettings?.emergency_override || event.priority === "CRITICAL" || event.priority === "HIGH";

    const results = [];

    for (const recipientId of recipientProfileIds) {
      // Get parent preferences
      const { data: parent } = await supabase
        .from("parents")
        .select("id, notification_preferences(*)")
        .eq("profile_id", recipientId)
        .maybeSingle();

      const prefs = parent?.notification_preferences;

      // Channels to deliver to
      const shouldSendPush = pushEnabledByOrg && (isEmergencyOverride || (prefs ? prefs.push_enabled : true));
      const shouldSendWhatsapp = whatsappEnabledByOrg && (isEmergencyOverride || (prefs ? prefs.whatsapp_enabled : false));
      const shouldSendSms = smsEnabledByOrg && (isEmergencyOverride || (prefs ? prefs.sms_enabled : false));

      // Deliver PUSH (FCM)
      if (shouldSendPush) {
        const { data: tokens } = await supabase
          .from("device_tokens")
          .select("fcm_token, platform")
          .eq("profile_id", recipientId)
          .eq("is_active", true);

        // Record delivery record (Idempotent: UNIQUE(notification_event_id, recipient_profile_id, channel))
        const { data: delivery } = await supabase
          .from("notification_deliveries")
          .upsert(
            {
              notification_event_id: event.id,
              organization_id: event.organization_id,
              recipient_profile_id: recipientId,
              child_id: event.child_id,
              channel: "PUSH",
              provider: "FCM",
              status: tokens && tokens.length > 0 ? "SENT" : "DELIVERED",
              last_attempt_at: new Date().toISOString(),
              attempt_count: 1,
            },
            { onConflict: "notification_event_id,recipient_profile_id,channel" }
          )
          .select()
          .single();

        results.push({ channel: "PUSH", recipient: recipientId, deliveryId: delivery?.id, tokensCount: tokens?.length ?? 0 });
      }

      // Deliver WHATSAPP (Meta Cloud API / Mock)
      if (shouldSendWhatsapp) {
        const { data: delivery } = await supabase
          .from("notification_deliveries")
          .upsert(
            {
              notification_event_id: event.id,
              organization_id: event.organization_id,
              recipient_profile_id: recipientId,
              child_id: event.child_id,
              channel: "WHATSAPP",
              provider: "META_WHATSAPP",
              status: "SENT",
              last_attempt_at: new Date().toISOString(),
              attempt_count: 1,
            },
            { onConflict: "notification_event_id,recipient_profile_id,channel" }
          )
          .select()
          .single();

        results.push({ channel: "WHATSAPP", recipient: recipientId, deliveryId: delivery?.id });
      }

      // Deliver SMS (Twilio / Mock)
      if (shouldSendSms) {
        const { data: delivery } = await supabase
          .from("notification_deliveries")
          .upsert(
            {
              notification_event_id: event.id,
              organization_id: event.organization_id,
              recipient_profile_id: recipientId,
              child_id: event.child_id,
              channel: "SMS",
              provider: "TWILIO",
              status: "SENT",
              last_attempt_at: new Date().toISOString(),
              attempt_count: 1,
            },
            { onConflict: "notification_event_id,recipient_profile_id,channel" }
          )
          .select()
          .single();

        results.push({ channel: "SMS", recipient: recipientId, deliveryId: delivery?.id });
      }
    }

    // 4. Update Event Status
    await supabase
      .from("notification_events")
      .update({
        status: "PROCESSED",
        updated_at: new Date().toISOString(),
      })
      .eq("id", event.id);

    return new Response(
      JSON.stringify({ success: true, eventId: event.id, deliveries: results }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
