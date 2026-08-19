import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

function haversineDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000;
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

    const { trip_id, action } = await req.json();

    if (action === 'COMPLETE_TRIP') {
      // 1. Fetch all telemetry breadcrumbs for the trip
      const { data: history } = await supabase
        .from('trip_location_history')
        .select('latitude, longitude, speed_kmh, recorded_at')
        .eq('trip_id', trip_id)
        .order('recorded_at', { ascending: true });

      let totalDistanceMeters = 0;
      let totalSpeed = 0;

      if (history && history.length > 1) {
        for (let i = 1; i < history.length; i++) {
          const prev = history[i - 1];
          const curr = history[i];
          totalDistanceMeters += haversineDistanceMeters(
            prev.latitude,
            prev.longitude,
            curr.latitude,
            curr.longitude
          );
          totalSpeed += curr.speed_kmh || 0;
        }
      }

      const totalKm = Math.round((totalDistanceMeters / 1000) * 100) / 100;
      const avgSpeed =
        history && history.length > 0
          ? Math.round((totalSpeed / history.length) * 10) / 10
          : 0;

      // 2. Mark trip completed
      await supabase
        .from('trips')
        .update({
          status: 'COMPLETED',
          ended_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', trip_id);

      // 3. Reset child proximity states
      await supabase
        .from('trip_child_proximity_states')
        .update({
          state: 'OUTSIDE',
          distance_meters: null,
          notified_at: null,
          updated_at: new Date().toISOString(),
        })
        .eq('trip_id', trip_id);

      return new Response(
        JSON.stringify({
          status: 'completed',
          total_distance_km: totalKm,
          average_speed_kmh: avgSpeed,
          data_points: history?.length ?? 0,
        }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    }

    return new Response(JSON.stringify({ status: 'ignored' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
