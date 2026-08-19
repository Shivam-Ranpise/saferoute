import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { create } from 'https://deno.land/x/djwt@v2.8/mod.ts';

// Supabase and Firebase configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

serve(async (req) => {
  try {
    const { title, body, eventType, childId, token, fcmPayload, orgId } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Retrieve organization API parameters if not directly supplied
    let fcmConfig = fcmPayload;
    if (!fcmConfig && orgId) {
      const { data: org } = await supabase
        .from('organizations')
        .select('api_parameters')
        .eq('id', orgId)
        .single();

      if (org?.api_parameters?.fcm) {
        fcmConfig = org.api_parameters.fcm;
      }
    }

    // Default fallback to project saferoute-80c5b if configured
    const projectId = fcmConfig?.projectId || 'saferoute-80c5b';

    // Build notification data
    const message = {
      message: {
        token: token,
        notification: {
          title: title || 'SafeRoute Alert',
          body: body || '',
        },
        data: {
          event_type: eventType || 'ROUTINE',
          child_id: childId || '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: (eventType === 'EMERGENCY' || eventType === 'BUS_NEARBY') ? 'high' : 'normal',
          notification: {
            channel_id: (eventType === 'EMERGENCY') ? 'saferoute_emergency_alerts' :
                         (eventType === 'BUS_NEARBY') ? 'saferoute_geofence_alerts' : 'saferoute_general_updates',
            icon: 'ic_launcher',
            sound: 'default',
          }
        }
      }
    };

    return new Response(JSON.stringify({ success: true, message: 'Notification queued' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
