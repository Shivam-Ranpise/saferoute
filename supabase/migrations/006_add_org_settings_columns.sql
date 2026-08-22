-- ============================================================================
-- SafeRoute Migration 006: Add Dynamic Configuration & Multi-Channel API Columns
-- Run this in your Supabase SQL Editor (Dashboard > Project > SQL Editor)
-- ============================================================================

ALTER TABLE organizations
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS geofence_radius_meters INTEGER DEFAULT 200,
    ADD COLUMN IF NOT EXISTS notification_settings JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS api_parameters JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS school_schedule JSONB DEFAULT '{"start_time":"10:00","end_time":"17:00","working_days":["Monday","Tuesday","Wednesday","Thursday","Friday"]}'::jsonb;

-- Ensure Admin RLS update policy permits updating api_parameters
DROP POLICY IF EXISTS "admin_can_update_own_org" ON organizations;
CREATE POLICY "admin_can_update_own_org"
  ON organizations FOR UPDATE
  USING (
    id = get_my_org_id()
    AND get_my_role() = 'ADMIN'
  )
  WITH CHECK (
    id = get_my_org_id()
    AND get_my_role() = 'ADMIN'
  );
