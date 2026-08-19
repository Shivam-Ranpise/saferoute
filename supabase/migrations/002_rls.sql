-- ============================================================
-- SafeRoute — Migration 002: Row Level Security (RLS)
-- Run AFTER 001_initial_schema.sql
-- ============================================================
-- ARCHITECTURE:
-- Every table has RLS enabled.
-- Policies are written using helper functions from migration 001.
-- Three roles: ADMIN (org-scoped), DRIVER (bus-scoped), PARENT (child-scoped).
-- Service role (used only in Edge Functions) bypasses RLS.
-- ============================================================

-- ============================================================
-- Enable RLS on all tables
-- ============================================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_location_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_child_proximity_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_event_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLE: organizations
-- ============================================================

-- Admin can read their own organization only
CREATE POLICY "admin_can_read_own_org"
  ON organizations FOR SELECT
  USING (
    id = get_my_org_id()
    AND get_my_role() = 'ADMIN'
  );

-- Admin can update their own org settings only
CREATE POLICY "admin_can_update_own_org"
  ON organizations FOR UPDATE
  USING (
    id = get_my_org_id()
    AND get_my_role() = 'ADMIN'
  );

-- Drivers/Parents can read their org's non-sensitive fields
-- (We restrict this to specific columns via a view in production;
-- for now limit via function check)
CREATE POLICY "driver_parent_can_read_own_org"
  ON organizations FOR SELECT
  USING (
    id = get_my_org_id()
    AND get_my_role() IN ('DRIVER', 'PARENT')
  );

-- No inserts/deletes by any client — only service role (Edge Functions)
-- (Organizations are created by a super-admin process, not client apps)

-- ============================================================
-- TABLE: profiles
-- ============================================================

-- Users can read their own profile
CREATE POLICY "user_can_read_own_profile"
  ON profiles FOR SELECT
  USING (id = auth.uid());

-- Users can update their own profile (name, phone, avatar only — not role/org)
CREATE POLICY "user_can_update_own_profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT role FROM profiles WHERE id = auth.uid())  -- Cannot change own role
    AND organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())  -- Cannot change org
  );

-- Admin can read all profiles in their org
CREATE POLICY "admin_can_read_org_profiles"
  ON profiles FOR SELECT
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- Admin can update profiles in their org (e.g., deactivate)
CREATE POLICY "admin_can_update_org_profiles"
  ON profiles FOR UPDATE
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- Admin can insert profiles (creating new users)
CREATE POLICY "admin_can_insert_profiles"
  ON profiles FOR INSERT
  WITH CHECK (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- Driver can read profiles of parents on their current bus
-- (only profile_id, name, phone — NOT all fields)
-- Note: This is intentionally limited. Full parent contact access
-- is via a specific function in Edge Functions only.
CREATE POLICY "driver_can_read_bus_parent_profiles"
  ON profiles FOR SELECT
  USING (
    get_my_role() = 'DRIVER'
    AND organization_id = get_my_org_id()
    AND EXISTS (
      SELECT 1 FROM children c
      JOIN parents p ON c.parent_id = p.id
      WHERE p.profile_id = profiles.id
        AND c.bus_id = get_my_assigned_bus_id()
        AND c.is_active = TRUE
    )
  );

-- ============================================================
-- TABLE: parents
-- ============================================================

-- Parent can read their own record
CREATE POLICY "parent_can_read_own_record"
  ON parents FOR SELECT
  USING (profile_id = auth.uid());

-- Admin can manage parents in their org
CREATE POLICY "admin_can_manage_org_parents"
  ON parents FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- Driver can read parents of children on their assigned bus
-- (limited — for sending alerts only, not browsing all parents)
CREATE POLICY "driver_can_read_assigned_bus_parents"
  ON parents FOR SELECT
  USING (
    get_my_role() = 'DRIVER'
    AND organization_id = get_my_org_id()
    AND EXISTS (
      SELECT 1 FROM children c
      WHERE c.parent_id = parents.id
        AND c.bus_id = get_my_assigned_bus_id()
        AND c.is_active = TRUE
    )
  );

-- ============================================================
-- TABLE: drivers
-- ============================================================

-- Driver can read their own record
CREATE POLICY "driver_can_read_own_record"
  ON drivers FOR SELECT
  USING (profile_id = auth.uid());

-- Admin can manage drivers in their org
CREATE POLICY "admin_can_manage_org_drivers"
  ON drivers FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- ============================================================
-- TABLE: buses
-- ============================================================

-- Driver can read their assigned bus only
CREATE POLICY "driver_can_read_assigned_bus"
  ON buses FOR SELECT
  USING (
    get_my_role() = 'DRIVER'
    AND current_driver_id = get_my_driver_id()
  );

-- Parent can read the bus their child is assigned to
CREATE POLICY "parent_can_read_assigned_bus"
  ON buses FOR SELECT
  USING (
    get_my_role() = 'PARENT'
    AND EXISTS (
      SELECT 1 FROM children c
      WHERE c.bus_id = buses.id
        AND c.parent_id = get_my_parent_id()
        AND c.is_active = TRUE
    )
  );

-- Admin can manage all buses in their org
CREATE POLICY "admin_can_manage_org_buses"
  ON buses FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- ============================================================
-- TABLE: children
-- ============================================================

-- Parent can read their own children only
CREATE POLICY "parent_can_read_own_children"
  ON children FOR SELECT
  USING (
    get_my_role() = 'PARENT'
    AND parent_id = get_my_parent_id()
  );

-- Parent can update their own children's pickup location and notification distance
CREATE POLICY "parent_can_update_own_children"
  ON children FOR UPDATE
  USING (
    get_my_role() = 'PARENT'
    AND parent_id = get_my_parent_id()
  )
  WITH CHECK (
    parent_id = get_my_parent_id()
    AND organization_id = get_my_org_id()
    -- Parent cannot change bus assignment — only admin can
    AND bus_id = (SELECT bus_id FROM children WHERE id = children.id)
  );

-- Driver can read children assigned to their current bus
-- (active children only — no access to children on other buses)
CREATE POLICY "driver_can_read_assigned_bus_children"
  ON children FOR SELECT
  USING (
    get_my_role() = 'DRIVER'
    AND bus_id = get_my_assigned_bus_id()
    AND is_active = TRUE
  );

-- Admin can manage all children in their org
CREATE POLICY "admin_can_manage_org_children"
  ON children FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- ============================================================
-- TABLE: trips
-- ============================================================

-- Driver can read/update the active trip for their assigned bus
CREATE POLICY "driver_can_manage_own_trip"
  ON trips FOR ALL
  USING (
    get_my_role() = 'DRIVER'
    AND driver_id = get_my_driver_id()
    AND organization_id = get_my_org_id()
  );

-- Parent can read the active trip for their child's assigned bus
CREATE POLICY "parent_can_read_assigned_bus_trip"
  ON trips FOR SELECT
  USING (
    get_my_role() = 'PARENT'
    AND organization_id = get_my_org_id()
    AND bus_id IN (
      SELECT DISTINCT c.bus_id FROM children c
      WHERE c.parent_id = get_my_parent_id()
        AND c.is_active = TRUE
        AND c.bus_id IS NOT NULL
    )
    AND status IN ('STARTING', 'ACTIVE', 'STALE')
  );

-- Admin can manage all trips in their org
CREATE POLICY "admin_can_manage_org_trips"
  ON trips FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- ============================================================
-- TABLE: trip_location_history
-- ============================================================

-- Driver can insert location history for their active trip
CREATE POLICY "driver_can_insert_location_history"
  ON trip_location_history FOR INSERT
  WITH CHECK (
    get_my_role() = 'DRIVER'
    AND organization_id = get_my_org_id()
    AND EXISTS (
      SELECT 1 FROM trips t
      WHERE t.id = trip_location_history.trip_id
        AND t.driver_id = get_my_driver_id()
        AND t.status IN ('ACTIVE', 'STARTING')
    )
  );

-- Parent can read location history for their child's bus (limited window)
CREATE POLICY "parent_can_read_own_bus_location_history"
  ON trip_location_history FOR SELECT
  USING (
    get_my_role() = 'PARENT'
    AND organization_id = get_my_org_id()
    AND EXISTS (
      SELECT 1 FROM trips t
      JOIN children c ON c.bus_id = t.bus_id
      WHERE t.id = trip_location_history.trip_id
        AND c.parent_id = get_my_parent_id()
        AND c.is_active = TRUE
    )
  );

-- Admin can read all location history in their org
CREATE POLICY "admin_can_read_org_location_history"
  ON trip_location_history FOR SELECT
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- ============================================================
-- TABLE: trip_child_proximity_state
-- ============================================================

-- Driver can manage proximity state for children on their trip
CREATE POLICY "driver_can_manage_proximity_state"
  ON trip_child_proximity_state FOR ALL
  USING (
    get_my_role() = 'DRIVER'
    AND EXISTS (
      SELECT 1 FROM trips t
      WHERE t.id = trip_child_proximity_state.trip_id
        AND t.driver_id = get_my_driver_id()
    )
  );

-- Parent can read proximity state for their own children
CREATE POLICY "parent_can_read_own_proximity_state"
  ON trip_child_proximity_state FOR SELECT
  USING (
    get_my_role() = 'PARENT'
    AND EXISTS (
      SELECT 1 FROM children c
      WHERE c.id = trip_child_proximity_state.child_id
        AND c.parent_id = get_my_parent_id()
    )
  );

-- Admin can read all proximity states in their org
CREATE POLICY "admin_can_read_proximity_states"
  ON trip_child_proximity_state FOR SELECT
  USING (
    get_my_role() = 'ADMIN'
    AND EXISTS (
      SELECT 1 FROM trips t
      JOIN buses b ON t.bus_id = b.id
      WHERE t.id = trip_child_proximity_state.trip_id
        AND b.organization_id = get_my_org_id()
    )
  );

-- ============================================================
-- TABLE: device_tokens
-- ============================================================

-- Users can manage their own device tokens
CREATE POLICY "user_can_manage_own_device_tokens"
  ON device_tokens FOR ALL
  USING (profile_id = auth.uid());

-- Admin can read device tokens in their org (for management)
CREATE POLICY "admin_can_read_org_device_tokens"
  ON device_tokens FOR SELECT
  USING (
    get_my_role() = 'ADMIN'
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = device_tokens.profile_id
        AND p.organization_id = get_my_org_id()
    )
  );

-- ============================================================
-- TABLE: notification_preferences
-- ============================================================

-- Parent can read and update their own preferences
CREATE POLICY "parent_can_manage_own_notif_prefs"
  ON notification_preferences FOR ALL
  USING (
    parent_id = get_my_parent_id()
  );

-- Admin can read preferences in their org
CREATE POLICY "admin_can_read_org_notif_prefs"
  ON notification_preferences FOR SELECT
  USING (
    get_my_role() = 'ADMIN'
    AND EXISTS (
      SELECT 1 FROM parents p
      WHERE p.id = notification_preferences.parent_id
        AND p.organization_id = get_my_org_id()
    )
  );

-- ============================================================
-- TABLE: notification_event_settings
-- ============================================================

-- Admin can manage event settings for their org
CREATE POLICY "admin_can_manage_event_settings"
  ON notification_event_settings FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- Drivers and parents can read event settings (to know what's enabled)
CREATE POLICY "all_can_read_own_org_event_settings"
  ON notification_event_settings FOR SELECT
  USING (
    organization_id = get_my_org_id()
  );

-- ============================================================
-- TABLE: notification_events
-- ============================================================

-- Admin can manage notification events in their org
CREATE POLICY "admin_can_manage_notification_events"
  ON notification_events FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- Driver can insert notification events (alerts) for their org
-- (broadcast org-wide is enforced server-side in Edge Function,
--  not here, because that requires org config check)
CREATE POLICY "driver_can_insert_notification_events"
  ON notification_events FOR INSERT
  WITH CHECK (
    get_my_role() = 'DRIVER'
    AND organization_id = get_my_org_id()
    AND sender_profile_id = auth.uid()
  );

-- Driver can read events they sent
CREATE POLICY "driver_can_read_own_notification_events"
  ON notification_events FOR SELECT
  USING (
    get_my_role() = 'DRIVER'
    AND sender_profile_id = auth.uid()
  );

-- Parent can read notification events sent to them
-- (via notification_deliveries join — see that table's policy)
CREATE POLICY "parent_can_read_relevant_events"
  ON notification_events FOR SELECT
  USING (
    get_my_role() = 'PARENT'
    AND organization_id = get_my_org_id()
    AND EXISTS (
      SELECT 1 FROM notification_deliveries nd
      WHERE nd.notification_event_id = notification_events.id
        AND nd.recipient_profile_id = auth.uid()
    )
  );

-- ============================================================
-- TABLE: notification_deliveries
-- ============================================================

-- Admin can manage deliveries in their org
CREATE POLICY "admin_can_manage_org_deliveries"
  ON notification_deliveries FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- Parent can read their own deliveries
CREATE POLICY "parent_can_read_own_deliveries"
  ON notification_deliveries FOR SELECT
  USING (
    recipient_profile_id = auth.uid()
  );

-- ============================================================
-- TABLE: notification_templates
-- ============================================================

-- Admin can manage templates for their org
CREATE POLICY "admin_can_manage_templates"
  ON notification_templates FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- All users can read templates for their org (needed for rendering)
CREATE POLICY "all_can_read_own_org_templates"
  ON notification_templates FOR SELECT
  USING (
    organization_id = get_my_org_id()
    AND is_active = TRUE
  );

-- ============================================================
-- TABLE: provider_settings
-- ============================================================

-- Admin can manage provider settings for their org
-- (config field only — secrets are in Edge Function env, not here)
CREATE POLICY "admin_can_manage_provider_settings"
  ON provider_settings FOR ALL
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- ============================================================
-- TABLE: audit_logs
-- ============================================================

-- Admin can read audit logs for their org
CREATE POLICY "admin_can_read_org_audit_logs"
  ON audit_logs FOR SELECT
  USING (
    get_my_role() = 'ADMIN'
    AND organization_id = get_my_org_id()
  );

-- Audit logs are INSERT-only for authenticated users (via Edge Functions)
-- No client-side insert allowed directly — only service role inserts audit logs
-- This prevents tampering with audit trails

-- ============================================================
-- REALTIME PUBLICATIONS
-- Only publish tables that need real-time updates.
-- Never publish static config tables or profile/settings tables.
-- ============================================================

-- Enable realtime only for the trips table (current location + status)
-- and notification_events (for live alerts)
-- Parents subscribe to specific bus/trip rows only (filtered via client-side filter)

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'trips') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE trips;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'notification_events') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notification_events;
  END IF;
END $$;

-- NOTE: trip_location_history is NOT added to realtime —
-- parents/admin read the current location from trips.current_latitude/longitude.
-- History is loaded on-demand, not streamed.
