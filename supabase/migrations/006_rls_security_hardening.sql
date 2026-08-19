-- ============================================================================
-- SafeRoute Migration 006: RLS Security Hardening & Zero-Trust Policies
-- ============================================================================

-- Helper functions for granular permission checks
CREATE OR REPLACE FUNCTION is_org_admin(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
          AND organization_id = org_id
          AND role = 'ADMIN'
          AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_child_parent(target_child_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM children
        WHERE id = target_child_id
          AND parent_id = auth.uid()
          AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_assigned_driver_for_trip(target_trip_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM trips
        WHERE id = target_trip_id
          AND driver_id = auth.uid()
          AND status = 'ACTIVE'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 1. CHILDREN TABLE SECURITY ──────────────────────────────────────────────
ALTER TABLE children ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS children_parent_access ON children;
CREATE POLICY children_parent_access ON children
    FOR SELECT
    USING (
        parent_id = auth.uid()
        OR is_org_admin(organization_id)
        OR EXISTS (
            SELECT 1 FROM trip_child_proximity_state tcps
            JOIN trips t ON t.id = tcps.trip_id
            WHERE tcps.child_id = children.id
              AND t.driver_id = auth.uid()
              AND t.status = 'ACTIVE'
        )
    );

DROP POLICY IF EXISTS children_admin_mutation ON children;
CREATE POLICY children_admin_mutation ON children
    FOR ALL
    USING (is_org_admin(organization_id))
    WITH CHECK (is_org_admin(organization_id));

-- ─── 2. TRIP LOCATION HISTORY SECURITY ──────────────────────────────────────
ALTER TABLE trip_location_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS telemetry_insert_driver_only ON trip_location_history;
CREATE POLICY telemetry_insert_driver_only ON trip_location_history
    FOR INSERT
    WITH CHECK (
        is_assigned_driver_for_trip(trip_id)
        OR is_org_admin(organization_id)
    );

DROP POLICY IF EXISTS telemetry_select_authorized ON trip_location_history;
CREATE POLICY telemetry_select_authorized ON trip_location_history
    FOR SELECT
    USING (
        is_org_admin(organization_id)
        OR is_assigned_driver_for_trip(trip_id)
        OR EXISTS (
            SELECT 1 FROM trip_child_proximity_state tcps
            JOIN children c ON c.id = tcps.child_id
            WHERE tcps.trip_id = trip_location_history.trip_id
              AND c.parent_id = auth.uid()
        )
    );

-- ─── 3. DEVICE TOKENS SECURITY ──────────────────────────────────────────────
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS device_tokens_self_only ON device_tokens;
CREATE POLICY device_tokens_self_only ON device_tokens
    FOR ALL
    USING (profile_id = auth.uid())
    WITH CHECK (profile_id = auth.uid());

-- ─── 4. NOTIFICATION EVENTS SECURITY ────────────────────────────────────────
ALTER TABLE notification_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notification_events_insert_rule ON notification_events;
CREATE POLICY notification_events_insert_rule ON notification_events
    FOR INSERT
    WITH CHECK (
        is_org_admin(organization_id)
        OR (
            event_type = 'EMERGENCY'
            AND EXISTS (
                SELECT 1 FROM drivers
                WHERE profile_id = auth.uid()
                  AND organization_id = notification_events.organization_id
            )
        )
    );
