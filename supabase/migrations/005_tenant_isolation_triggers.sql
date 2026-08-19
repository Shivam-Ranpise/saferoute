-- ============================================================================
-- SafeRoute Migration 005: Multi-Tenant Enterprise Isolation & Immutability Triggers
-- Ensures organization_id can never be reassigned across existing records.
-- ============================================================================

CREATE OR REPLACE FUNCTION prevent_organization_reassignment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.organization_id <> OLD.organization_id THEN
        RAISE EXCEPTION 'Security Violation: Cannot reassign organization_id from % to % on entity %',
            OLD.organization_id, NEW.organization_id, TG_TABLE_NAME;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply immutability triggers to all tenant-scoped tables
DROP TRIGGER IF EXISTS trg_immutable_org_buses ON buses;
CREATE TRIGGER trg_immutable_org_buses
    BEFORE UPDATE ON buses
    FOR EACH ROW
    EXECUTE FUNCTION prevent_organization_reassignment();

DROP TRIGGER IF EXISTS trg_immutable_org_drivers ON drivers;
CREATE TRIGGER trg_immutable_org_drivers
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE FUNCTION prevent_organization_reassignment();

DROP TRIGGER IF EXISTS trg_immutable_org_children ON children;
CREATE TRIGGER trg_immutable_org_children
    BEFORE UPDATE ON children
    FOR EACH ROW
    EXECUTE FUNCTION prevent_organization_reassignment();

DROP TRIGGER IF EXISTS trg_immutable_org_trips ON trips;
CREATE TRIGGER trg_immutable_org_trips
    BEFORE UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION prevent_organization_reassignment();

DROP TRIGGER IF EXISTS trg_immutable_org_notification_events ON notification_events;
CREATE TRIGGER trg_immutable_org_notification_events
    BEFORE UPDATE ON notification_events
    FOR EACH ROW
    EXECUTE FUNCTION prevent_organization_reassignment();

DROP TRIGGER IF EXISTS trg_immutable_org_notification_deliveries ON notification_deliveries;
CREATE TRIGGER trg_immutable_org_notification_deliveries
    BEFORE UPDATE ON notification_deliveries
    FOR EACH ROW
    EXECUTE FUNCTION prevent_organization_reassignment();

-- Ensure Organization safety parameter columns and constraints
ALTER TABLE organizations
    ADD COLUMN IF NOT EXISTS default_notification_distance_meters INTEGER DEFAULT 500,
    ADD COLUMN IF NOT EXISTS data_retention_days INTEGER DEFAULT 90;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_org_proximity_distance') THEN
        ALTER TABLE organizations ADD CONSTRAINT chk_org_proximity_distance CHECK (default_notification_distance_meters BETWEEN 100 AND 5000);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_org_retention_days') THEN
        ALTER TABLE organizations ADD CONSTRAINT chk_org_retention_days CHECK (data_retention_days BETWEEN 1 AND 3650);
    END IF;
END $$;
