-- ============================================================
-- Migration 007: Fix notification RLS policies
-- Adds driver INSERT policy on notification_deliveries
-- (Previously only admin could manage, but driver needs to insert deliveries)
-- ============================================================

-- Driver can insert notification deliveries for events they created
CREATE POLICY "driver_can_insert_notification_deliveries"
  ON notification_deliveries FOR INSERT
  WITH CHECK (
    get_my_role() = 'DRIVER'
    AND organization_id = get_my_org_id()
    AND EXISTS (
      SELECT 1 FROM notification_events ne
      WHERE ne.id = notification_deliveries.notification_event_id
        AND ne.sender_profile_id = auth.uid()
    )
  );

-- Also ensure notification_deliveries is in realtime publication
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notification_deliveries'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notification_deliveries;
  END IF;
END $$;
