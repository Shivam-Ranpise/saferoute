import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleanPem = pem
    .replace(/-----BEGIN [A-Z ]+-----/g, "")
    .replace(/-----END [A-Z ]+-----/g, "")
    .replace(/\s+/g, "");
  const binaryString = atob(cleanPem);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

function base64UrlEncode(str: string): string {
  return btoa(str)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function createJwt(clientEmail: string, privateKeyPem: string, scope: string): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const claimSet = {
    iss: clientEmail,
    scope: scope,
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaimSet = base64UrlEncode(JSON.stringify(claimSet));
  const unsignedToken = `${encodedHeader}.${encodedClaimSet}`;

  const keyBuffer = pemToArrayBuffer(privateKeyPem);
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBuffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const encoder = new TextEncoder();
  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(unsignedToken)
  );

  const signatureBytes = new Uint8Array(signatureBuffer);
  let signatureString = "";
  for (let i = 0; i < signatureBytes.length; i++) {
    signatureString += String.fromCharCode(signatureBytes[i]);
  }
  const encodedSignature = base64UrlEncode(signatureString);

  return `${unsignedToken}.${encodedSignature}`;
}

async function getGoogleAccessToken(clientEmail: string, privateKeyPem: string): Promise<string> {
  const jwt = await createJwt(clientEmail, privateKeyPem, "https://www.googleapis.com/auth/firebase.messaging");
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenJson = await tokenRes.json();
  if (!tokenRes.ok) {
    throw new Error(`Google Auth error: ${JSON.stringify(tokenJson)}`);
  }
  return tokenJson.access_token;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body = await req.json();
    const eventId = body.event_id || body.record?.id;
    let orgId = body.organization_id || body.record?.organization_id;
    let title = body.title || body.record?.title;
    let message = body.message || body.record?.message;
    let eventType = body.event_type || body.record?.event_type || "ROUTINE";
    let senderProfileId = body.sender_profile_id || body.record?.sender_profile_id;
    let busId = body.bus_id || body.record?.bus_id;

    if (eventId) {
      const { data: eventData } = await supabase
        .from("notification_events")
        .select("*, trips(bus_id)")
        .eq("id", eventId)
        .maybeSingle();

      if (eventData) {
        orgId = eventData.organization_id;
        title = eventData.title;
        message = eventData.message;
        eventType = eventData.event_type;
        senderProfileId = eventData.sender_profile_id;
        busId = eventData.trips?.bus_id;
      }
    }

    if (!orgId) {
      return new Response(JSON.stringify({ error: "Missing organization_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: org } = await supabase
      .from("organizations")
      .select("api_parameters")
      .eq("id", orgId)
      .single();

    const fcmConfig = org?.api_parameters?.fcm;
    if (!fcmConfig || !fcmConfig.private_key || !fcmConfig.client_email) {
      return new Response(JSON.stringify({ error: "FCM service account not configured for this organization" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const projectId = fcmConfig.project_id || "saferoute-80c5b";
    const googleToken = await getGoogleAccessToken(fcmConfig.client_email, fcmConfig.private_key);

    // Resolve ONLY parent recipient profile IDs (explicitly excluding driver / sender)
    const recipientProfileIds = new Set<string>();

    // 1. Check existing deliveries for this event
    if (eventId) {
      const { data: deliveries } = await supabase
        .from("notification_deliveries")
        .select("recipient_profile_id")
        .eq("notification_event_id", eventId);

      if (deliveries && deliveries.length > 0) {
        for (const d of deliveries) {
          if (d.recipient_profile_id && d.recipient_profile_id !== senderProfileId) {
            recipientProfileIds.add(d.recipient_profile_id);
          }
        }
      }
    }

    // 2. If no deliveries found yet, find parents of children on the bus
    if (recipientProfileIds.size === 0 && busId) {
      const { data: children } = await supabase
        .from("children")
        .select("parents(profile_id)")
        .eq("bus_id", busId)
        .eq("is_active", true);

      if (children) {
        for (const c of children as any[]) {
          const pid = c.parents?.profile_id;
          if (pid && pid !== senderProfileId) {
            recipientProfileIds.add(pid);
          }
        }
      }
    }

    // 3. Fallback: all parent profiles in the organization (excluding sender)
    if (recipientProfileIds.size === 0) {
      const { data: orgParents } = await supabase
        .from("profiles")
        .select("id")
        .eq("organization_id", orgId)
        .eq("role", "PARENT");

      if (orgParents) {
        for (const p of orgParents) {
          if (p.id && p.id !== senderProfileId) {
            recipientProfileIds.add(p.id);
          }
        }
      }
    }

    // Query active device tokens ONLY for target parents
    let targetTokens: { token: string; profileId: string }[] = [];
    if (recipientProfileIds.size > 0) {
      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("fcm_token, profile_id")
        .in("profile_id", Array.from(recipientProfileIds))
        .eq("is_active", true);

      if (tokens) {
        targetTokens = tokens
          .filter((t: any) => t.profile_id !== senderProfileId)
          .map((t: any) => ({ token: t.fcm_token, profileId: t.profile_id }));
      }
    }

    console.log(`[push-dispatch] Dispatching event: "${title}" to ${targetTokens.length} parent devices (sender excluded: ${senderProfileId})`);

    const results = [];
    for (const target of targetTokens) {
      const fcmPayload = {
        message: {
          token: target.token,
          notification: {
            title: title || "SafeRoute Notification",
            body: message || "",
          },
          data: {
            title: title || "SafeRoute Notification",
            message: message || "",
            event_type: eventType,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channel_id: "saferoute_emergency_alerts_v2",
              icon: "ic_launcher",
              sound: "default",
              visibility: "public",
              default_sound: true,
              default_vibrate_timings: true,
            },
          },
        },
      };

      const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${googleToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      });

      const fcmJson = await fcmRes.json();
      if (!fcmRes.ok && fcmJson.error?.details?.[0]?.errorCode === "UNREGISTERED") {
        await supabase
          .from("device_tokens")
          .update({ is_active: false })
          .eq("fcm_token", target.token);
      }
      results.push({ token: target.token, profileId: target.profileId, status: fcmRes.status, response: fcmJson });
    }

    return new Response(JSON.stringify({ success: true, delivered: results.length, results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
