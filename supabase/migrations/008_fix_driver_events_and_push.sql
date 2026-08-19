-- ============================================================================
-- SafeRoute Migration 008: Fix Driver Notification Events & Deliveries RLS
-- ============================================================================

-- 1. Allow drivers to insert TRIP_STARTED, TRIP_COMPLETED, BUS_DELAY, EMERGENCY, and CUSTOM_ALERT
DROP POLICY IF EXISTS notification_events_insert_rule ON notification_events;
DROP POLICY IF EXISTS driver_can_insert_notification_events ON notification_events;

CREATE POLICY notification_events_insert_rule ON notification_events
    FOR INSERT
    WITH CHECK (
        is_org_admin(organization_id)
        OR (
            event_type IN ('TRIP_STARTED', 'TRIP_COMPLETED', 'BUS_DELAY', 'EMERGENCY', 'CUSTOM_ALERT')
            AND EXISTS (
                SELECT 1 FROM drivers
                WHERE profile_id = auth.uid()
                  AND organization_id = notification_events.organization_id
            )
        )
    );

-- 2. Ensure driver can insert into notification_deliveries for these events
DROP POLICY IF EXISTS driver_can_insert_notification_deliveries ON notification_deliveries;

CREATE POLICY driver_can_insert_notification_deliveries ON notification_deliveries
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM drivers
            WHERE profile_id = auth.uid()
              AND organization_id = notification_deliveries.organization_id
        )
        OR is_org_admin(organization_id)
    );

-- 3. Ensure parents can select their own deliveries
DROP POLICY IF EXISTS parent_can_read_own_deliveries ON notification_deliveries;

CREATE POLICY parent_can_read_own_deliveries ON notification_deliveries
    FOR SELECT
    USING (
        recipient_profile_id = auth.uid()
        OR is_org_admin(organization_id)
    );

-- 4. Enable Supabase Realtime for notification_deliveries & notification_events
DO $BODY$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notification_deliveries'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notification_deliveries;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notification_events'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notification_events;
  END IF;
END $BODY$;
