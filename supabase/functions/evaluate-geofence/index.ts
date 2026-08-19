import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

interface TelemetryPayload {
  trip_id: string;
  organization_id: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
}

function haversineDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000; // Earth radius in meters
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const payload: TelemetryPayload = await req.json();
    const { trip_id, organization_id, latitude, longitude } = payload;

    // 1. Fetch Organization default proximity radius
    const { data: org } = await supabase
      .from('organizations')
      .select('default_notification_distance_meters')
      .eq('id', organization_id)
      .single();

    const thresholdMeters = org?.default_notification_distance_meters ?? 500;

    // 2. Fetch all children assigned to this trip
    const { data: passengers } = await supabase
      .from('trip_passengers')
      .select('child_id, children:child_id(id, name, pickup_latitude, pickup_longitude, parent_id)')
      .eq('trip_id', trip_id);

    if (!passengers || passengers.length === 0) {
      return new Response(JSON.stringify({ status: 'no_passengers' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const triggeredNotifications: string[] = [];

    // 3. Evaluate Haversine distance for each passenger
    for (const p of passengers) {
      const child: any = p.children;
      if (!child || child.pickup_latitude == null || child.pickup_longitude == null) {
        continue;
      }

      const distance = haversineDistanceMeters(
        latitude,
        longitude,
        child.pickup_latitude,
        child.pickup_longitude
      );

      // Check current proximity state
      const { data: proxState } = await supabase
        .from('trip_child_proximity_states')
        .select('*')
        .eq('trip_id', trip_id)
        .eq('child_id', child.id)
        .maybeSingle();

      const currentState = proxState?.state ?? 'OUTSIDE';

      if (distance <= thresholdMeters && (currentState === 'OUTSIDE' || currentState === 'APPROACHING')) {
        // Update proximity state to NOTIFIED
        await supabase
          .from('trip_child_proximity_states')
          .upsert({
            trip_id,
            child_id: child.id,
            state: 'NOTIFIED',
            distance_meters: Math.round(distance),
            notified_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          });

        // Trigger dispatch-notification
        await supabase.functions.invoke('dispatch-notification', {
          body: {
            organization_id,
            event_type: 'BUS_NEARBY',
            priority: 'HIGH',
            title: 'Bus Arriving Soon! 🚌',
            message: `Bus is approx ${Math.round(distance)}m from ${child.name}'s stop.`,
            recipient_user_ids: [child.parent_id],
          },
        });

        triggeredNotifications.push(child.id);
      }
    }

    return new Response(
      JSON.stringify({
        status: 'success',
        evaluated: passengers.length,
        triggered: triggeredNotifications.length,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
