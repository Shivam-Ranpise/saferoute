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

    const defaultFcmConfig = {
      project_id: "saferoute-80c5b",
      client_email: "firebase-adminsdk-fbsvc@saferoute-80c5b.iam.gserviceaccount.com",
      private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDNzsnsykxiUP96\nX2JlxGG1CwpTxHb5B9DsYvFTFuZM4C7nxlVPrY2xUV2MlD93Y47t6Jga2xT7v+gW\n6Q0ir6TCYlcvDHwJn7/72dxq4AZAlEvYffl+5PEMub7ssbSfz0ByvB7FdwZSoZfI\npeIO7Jca6ge9Wa6TJBIHRdn9HuGZo9y/PX/on/xx0HLoHqv/yeTqS00sPAt9+BZV\np4BDjzv8XjQwn9FqnVKUMvj3gnnvrq+rzjGburUbsB5cd1w7s2WHdwMZO9rtvha3\nDYB5F7B9mxv3xrnhBofg47o4V1gSaS349xqELhA/W5ttr3eQyd9huvnAfqhJAHpq\neJSUh+O7AgMBAAECggEAKdd83hNS7DojdrGlw6LlanVQKC+tMHwSUbzb61Sghcie\nQKjl90kFoaM1LbuGG7O1/1BmfC9GWNhvSxkeforPKGXt67bSEPLViVKFqYTaQI7l\nzKHv84iAKWIqGt0WJ9du9uSgLO1B79LClRyElRwsrGAgKrLs9yVCNRBSfU+l9iIp\nDcQ7JPulhxHUV0wR6OIu7nxcfaMl4vzIJw8VgLa3+r5kK1RHSUJoWuo5Vb3LQb/G\nTy+z2kcbs9cgU2GGKajSqRCjGaENezrm5o4EnvbEbZ6O7SymIELfDL62NXIEAxeX\nXqF4m0zFQhHvXg8k2hR9Alyhhu2VKc+KTCyksbypgQKBgQDlkZAzt1EyjBz953Sf\n5ApZWCoxjnlp6s+rr0DYTWSimWTwqNB+mzC2I7TTu85VEcdYXsTrmLei0a5J0bes\nl4KxiwQmYZj0851A0JFJyuUlVBNNPBpgRCqkzB0IZEKQNYCK6DKbWlfO0LAuUeO2\nFR0iPwUmZ/clPrFy4McDcTJLywKBgQDlgOKKMLdWpCg1k5nO1myfnebLpl/1w/xR\nrPK/8aC1y19YtYd95UuIbplFINJUEFafy0SzLtawUhlr0aY3w9+dvTYk/kMUKSfJ\nzmmN0FUQCPbGIW+Sd5DQab4bbCunt30SOvGzkBpWW9sf8o3VIlhLQqZhTaIZ/ib8\njaIt822p0QKBgQCCgrCiVhN5UyKgTleFFtWzWWYTalYoGvAZQLbywXz225IBJ1fw\nwjV9Nut0fA6fWk4kNSxqbBXqIJ6fJPTwz+njGY8wasfUajL6SBhxBUIkaJnYjNTJ\n6bb8nXXb8XPOHDyJu9wZadEFqKqgirmUKIi5kW5SGUTuDahAEP3TPSVE5QKBgCtW\n43DlMjoSVeWIMgt1Qp4B24upp4VptURXPKAyqP6roR3HagbEPjdNa3Q6dn2ZeEJE\nyHxt4+z4FATgWls9igTnrkneGhy8iN77M8OsC+QzTSatObyXB6nTziqviq7pX50J\ntIsMM20Le53U2CPfkHzl4TWOy4XNEN+wf2feCF+BAoGBAK0t76eCHKHc6/pCs3xe\nMxkvdDa0YuM6qFszJ6xDCYaQKlWBsN20hDu1MieogiLT8RYl9I7b0SbHT6vO3s6t\n90iDlctjhZwqY5PfdEDXmtlimg0VVdV0NqlrmfYhb/E2tOtfJAeKWDds4qL1Sv4l\nTu2l/IUWyIN5GnjdsD6rajiy\n-----END PRIVATE KEY-----\n",
    };

    const fcmConfig = org?.api_parameters?.fcm?.private_key
      ? org.api_parameters.fcm
      : defaultFcmConfig;

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
