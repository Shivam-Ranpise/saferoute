-- ============================================================
-- SafeRoute — Migration 001: Initial Schema
-- Run this in your Supabase SQL Editor (Project > SQL Editor)
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";  -- Requires Supabase Pro or enabling in dashboard
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE user_role AS ENUM ('ADMIN', 'DRIVER', 'PARENT');

CREATE TYPE trip_status AS ENUM (
  'IDLE', 'STARTING', 'ACTIVE', 'STALE', 'COMPLETED', 'CANCELLED'
);

CREATE TYPE proximity_state AS ENUM (
  'OUTSIDE', 'APPROACHING', 'ENTERED_RADIUS', 'NOTIFIED', 'LOCKED'
);

CREATE TYPE device_platform AS ENUM ('ANDROID', 'IOS', 'WEB');

CREATE TYPE notification_event_type AS ENUM (
  'BUS_NEARBY', 'TRIP_STARTED', 'TRIP_COMPLETED',
  'BUS_DELAY', 'EMERGENCY', 'CUSTOM_ALERT', 'SYSTEM_ANNOUNCEMENT'
);

CREATE TYPE notification_status AS ENUM (
  'CREATED', 'QUEUED', 'PROCESSING', 'COMPLETED',
  'PARTIAL_FAILURE', 'FAILED', 'CANCELLED'
);

CREATE TYPE delivery_status AS ENUM (
  'PENDING', 'PROCESSING', 'SENT', 'DELIVERED', 'FAILED', 'CANCELLED'
);

CREATE TYPE delivery_channel AS ENUM ('PUSH', 'WHATSAPP', 'SMS');

CREATE TYPE notification_priority AS ENUM ('NORMAL', 'HIGH', 'EMERGENCY');

CREATE TYPE provider_type AS ENUM ('FCM', 'FAST2SMS', 'MAYTAPI');

CREATE TYPE audit_action AS ENUM (
  'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT',
  'ASSIGN', 'UNASSIGN', 'SEND_ALERT', 'CHANGE_POLICY',
  'CHANGE_PROVIDER_CONFIG', 'EMERGENCY_ALERT', 'CHANGE_PERMISSION'
);

-- ============================================================
-- TABLE 1: organizations
-- ============================================================

CREATE TABLE organizations (
  id                              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                            TEXT NOT NULL,
  logo_url                        TEXT,
  timezone                        TEXT NOT NULL DEFAULT 'UTC',
  is_active                       BOOLEAN NOT NULL DEFAULT TRUE,

  -- Driver permission flags
  driver_can_broadcast_org_wide   BOOLEAN NOT NULL DEFAULT FALSE,
  driver_can_send_emergency_alerts BOOLEAN NOT NULL DEFAULT FALSE,
  driver_can_send_custom_alerts   BOOLEAN NOT NULL DEFAULT TRUE,
  emergency_override_enabled      BOOLEAN NOT NULL DEFAULT FALSE,

  -- Data retention (days) — all values must be within safe min/max bounds
  -- Min 1 day, max 3650 days (10 years) for each
  gps_history_retention_days      INTEGER NOT NULL DEFAULT 30
    CHECK (gps_history_retention_days >= 1 AND gps_history_retention_days <= 3650),
  notification_log_retention_days INTEGER NOT NULL DEFAULT 90
    CHECK (notification_log_retention_days >= 1 AND notification_log_retention_days <= 3650),
  emergency_alert_retention_days  INTEGER NOT NULL DEFAULT 180
    CHECK (emergency_alert_retention_days >= 1 AND emergency_alert_retention_days <= 3650),
  trip_history_retention_days     INTEGER NOT NULL DEFAULT 365
    CHECK (trip_history_retention_days >= 1 AND trip_history_retention_days <= 3650),
  device_token_retention_days     INTEGER NOT NULL DEFAULT 60
    CHECK (device_token_retention_days >= 1 AND device_token_retention_days <= 3650),
  audit_log_retention_days        INTEGER NOT NULL DEFAULT 365
    CHECK (audit_log_retention_days >= 1 AND audit_log_retention_days <= 3650),

  created_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 2: profiles
-- Links to Supabase Auth users (auth.users)
-- ============================================================

CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  phone           TEXT,
  email           TEXT NOT NULL,
  role            user_role NOT NULL,
  avatar_url      TEXT,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 3: parents
-- ============================================================

CREATE TABLE parents (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id      UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 4: drivers
-- ============================================================

CREATE TABLE drivers (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id      UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  license_number  TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 5: buses
-- current_driver_id is the persistent assignment (not per-trip)
-- ============================================================

CREATE TABLE buses (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  bus_number          TEXT NOT NULL,
  registration_number TEXT,
  capacity            INTEGER CHECK (capacity > 0),
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  current_driver_id   UUID REFERENCES drivers(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, bus_number)
);

-- ============================================================
-- TABLE 6: children
-- ============================================================

CREATE TABLE children (
  id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id             UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  parent_id                   UUID NOT NULL REFERENCES parents(id) ON DELETE RESTRICT,
  name                        TEXT NOT NULL,
  photo_url                   TEXT,
  bus_id                      UUID REFERENCES buses(id) ON DELETE SET NULL,
  pickup_latitude             DOUBLE PRECISION,
  pickup_longitude            DOUBLE PRECISION,
  pickup_name                 TEXT,
  pickup_address              TEXT,
  notification_distance_meters INTEGER NOT NULL DEFAULT 500
    CHECK (notification_distance_meters >= 100 AND notification_distance_meters <= 10000),
  is_active                   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 7: trips
-- Holds ONLY the current/latest location — never insert per GPS update.
-- Use UPDATE to refresh current_latitude/longitude etc.
-- ============================================================

CREATE TABLE trips (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  bus_id            UUID NOT NULL REFERENCES buses(id) ON DELETE RESTRICT,
  driver_id         UUID NOT NULL REFERENCES drivers(id) ON DELETE RESTRICT,
  status            trip_status NOT NULL DEFAULT 'IDLE',
  started_at        TIMESTAMPTZ,
  ended_at          TIMESTAMPTZ,
  -- Current location (single row, updated in-place per GPS fix)
  current_latitude  DOUBLE PRECISION,
  current_longitude DOUBLE PRECISION,
  current_speed     DOUBLE PRECISION,   -- km/h
  current_heading   DOUBLE PRECISION,   -- degrees 0-360
  current_accuracy  DOUBLE PRECISION,   -- meters
  last_location_at  TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 8: trip_location_history
-- Sampled history only (every 30-60s or significant movement).
-- NEVER every raw GPS reading.
-- organization_id is denormalized for efficient cleanup queries.
-- ============================================================

CREATE TABLE trip_location_history (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  latitude        DOUBLE PRECISION NOT NULL,
  longitude       DOUBLE PRECISION NOT NULL,
  speed           DOUBLE PRECISION,
  heading         DOUBLE PRECISION,
  accuracy        DOUBLE PRECISION,
  recorded_at     TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 9: trip_child_proximity_state
-- Per-child, per-trip state machine.
-- Unique constraint prevents duplicate state rows.
-- Reset to OUTSIDE on new trip start.
-- ============================================================

CREATE TABLE trip_child_proximity_state (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id             UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  child_id            UUID NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  state               proximity_state NOT NULL DEFAULT 'OUTSIDE',
  last_distance_meters DOUBLE PRECISION,
  last_evaluated_at   TIMESTAMPTZ,
  notified_at         TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (trip_id, child_id)
);

-- ============================================================
-- TABLE 10: device_tokens
-- A profile may have multiple active devices.
-- ============================================================

CREATE TABLE device_tokens (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  fcm_token   TEXT NOT NULL,
  platform    device_platform NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- One token string per profile (upsert by token value)
  UNIQUE (fcm_token)
);

-- ============================================================
-- TABLE 11: notification_preferences
-- Parent channel preferences — one of three layers in channel resolution.
-- emergency_override is NOT here — it's org-level only.
-- ============================================================

CREATE TABLE notification_preferences (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id       UUID NOT NULL UNIQUE REFERENCES parents(id) ON DELETE CASCADE,
  push_enabled    BOOLEAN NOT NULL DEFAULT TRUE,
  whatsapp_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  sms_enabled     BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 12: notification_event_settings
-- Per-org, per-event-type channel configuration.
-- Admin controls any combination — no fixed priority.
-- ============================================================

CREATE TABLE notification_event_settings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  event_type      notification_event_type NOT NULL,
  push_enabled    BOOLEAN NOT NULL DEFAULT TRUE,
  whatsapp_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  sms_enabled     BOOLEAN NOT NULL DEFAULT FALSE,
  -- emergency_override: if true + org.emergency_override_enabled,
  -- this event bypasses parent notification_preferences
  emergency_override BOOLEAN NOT NULL DEFAULT FALSE,
  enabled         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, event_type)
);

-- ============================================================
-- TABLE 13: notification_events
-- One row per notification event (delivery is tracked separately).
-- ============================================================

CREATE TABLE notification_events (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  trip_id           UUID REFERENCES trips(id) ON DELETE SET NULL,
  sender_profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  event_type        notification_event_type NOT NULL,
  priority          notification_priority NOT NULL DEFAULT 'NORMAL',
  title             TEXT NOT NULL,
  message           TEXT NOT NULL,
  status            notification_status NOT NULL DEFAULT 'CREATED',
  scheduled_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE 14: notification_deliveries
-- Per-recipient, per-channel delivery tracking.
-- UNIQUE(event_id, recipient_id, channel) prevents duplicate sends.
-- DELIVERED only set by webhook — SENT is practical terminal for FCM.
-- ============================================================

CREATE TABLE notification_deliveries (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_event_id   UUID NOT NULL REFERENCES notification_events(id) ON DELETE CASCADE,
  organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  recipient_profile_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  child_id                UUID REFERENCES children(id) ON DELETE SET NULL,
  channel                 delivery_channel NOT NULL,
  provider                provider_type,
  provider_message_id     TEXT,  -- Used to match delivery webhooks
  status                  delivery_status NOT NULL DEFAULT 'PENDING',
  attempt_count           INTEGER NOT NULL DEFAULT 0,
  last_attempt_at         TIMESTAMPTZ,
  next_retry_at           TIMESTAMPTZ,
  error_code              TEXT,
  error_message           TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- THE KEY IDEMPOTENCY CONSTRAINT:
  -- Prevents duplicate sends even if the queue processor runs twice.
  UNIQUE (notification_event_id, recipient_profile_id, channel)
);

-- ============================================================
-- TABLE 15: notification_templates
-- Channel-specific templates per org + event type.
-- Variables: {{child_name}} {{bus_number}} {{distance}} {{driver_name}}
--            {{message}} {{estimated_time}}
-- ============================================================

CREATE TABLE notification_templates (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id  UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  event_type       notification_event_type NOT NULL,
  channel          delivery_channel NOT NULL,
  title            TEXT,  -- For push notifications
  message_template TEXT NOT NULL,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, event_type, channel)
);

-- ============================================================
-- TABLE 16: provider_settings
-- Configuration metadata only — NO secrets stored here.
-- Actual secrets (API keys) live in Supabase Edge Function secrets.
-- This table stores non-secret config (enabled status, sender IDs, etc.)
-- ============================================================

CREATE TABLE provider_settings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  provider        provider_type NOT NULL,
  is_enabled      BOOLEAN NOT NULL DEFAULT FALSE,
  -- Non-secret config stored as JSONB (e.g., sender_id, phone_id, etc.)
  -- NEVER store API keys, tokens, or secrets here
  config          JSONB NOT NULL DEFAULT '{}',
  -- config_secret_key_names: list of which keys live in Edge Function secrets
  -- (for admin UI display purposes only — values are never returned)
  config_secret_key_names TEXT[] NOT NULL DEFAULT '{}',
  last_tested_at  TIMESTAMPTZ,
  test_status     TEXT,  -- 'SUCCESS', 'FAILED', or null
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, provider)
);

-- ============================================================
-- TABLE 17: audit_logs
-- Immutable audit trail. Never store secrets in metadata.
-- ============================================================

CREATE TABLE audit_logs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  actor_profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action          audit_action NOT NULL,
  entity_type     TEXT NOT NULL,
  entity_id       UUID,
  metadata        JSONB NOT NULL DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
  -- No updated_at — audit logs are immutable
);

-- ============================================================
-- INDEXES
-- Based on Phase 13 performance requirements
-- ============================================================

-- profiles
CREATE INDEX idx_profiles_organization_id ON profiles(organization_id);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_is_active ON profiles(is_active);

-- parents
CREATE INDEX idx_parents_organization_id ON parents(organization_id);
CREATE INDEX idx_parents_profile_id ON parents(profile_id);

-- drivers
CREATE INDEX idx_drivers_organization_id ON drivers(organization_id);
CREATE INDEX idx_drivers_profile_id ON drivers(profile_id);
CREATE INDEX idx_drivers_is_active ON drivers(is_active);

-- buses
CREATE INDEX idx_buses_organization_id ON buses(organization_id);
CREATE INDEX idx_buses_current_driver_id ON buses(current_driver_id);
CREATE INDEX idx_buses_is_active ON buses(is_active);

-- children
CREATE INDEX idx_children_organization_id ON children(organization_id);
CREATE INDEX idx_children_parent_id ON children(parent_id);
CREATE INDEX idx_children_bus_id ON children(bus_id);
CREATE INDEX idx_children_is_active ON children(is_active);

-- trips
CREATE INDEX idx_trips_organization_id ON trips(organization_id);
CREATE INDEX idx_trips_bus_id ON trips(bus_id);
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_last_location_at ON trips(last_location_at);
-- Active trips query (most common)
CREATE INDEX idx_trips_active ON trips(organization_id, status)
  WHERE status IN ('ACTIVE', 'STALE', 'STARTING');

-- trip_location_history (largest table — batched cleanup needs these)
CREATE INDEX idx_tlh_organization_id ON trip_location_history(organization_id);
CREATE INDEX idx_tlh_trip_id ON trip_location_history(trip_id);
CREATE INDEX idx_tlh_recorded_at ON trip_location_history(recorded_at);
CREATE INDEX idx_tlh_org_recorded ON trip_location_history(organization_id, recorded_at);

-- trip_child_proximity_state
CREATE INDEX idx_tcps_trip_id ON trip_child_proximity_state(trip_id);
CREATE INDEX idx_tcps_child_id ON trip_child_proximity_state(child_id);

-- device_tokens
CREATE INDEX idx_device_tokens_profile_id ON device_tokens(profile_id);
CREATE INDEX idx_device_tokens_is_active ON device_tokens(is_active);
CREATE INDEX idx_device_tokens_last_seen ON device_tokens(last_seen_at);

-- notification_preferences
CREATE INDEX idx_notif_pref_parent_id ON notification_preferences(parent_id);

-- notification_event_settings
CREATE INDEX idx_nes_organization_id ON notification_event_settings(organization_id);
CREATE INDEX idx_nes_event_type ON notification_event_settings(event_type);

-- notification_events
CREATE INDEX idx_ne_organization_id ON notification_events(organization_id);
CREATE INDEX idx_ne_trip_id ON notification_events(trip_id);
CREATE INDEX idx_ne_event_type ON notification_events(event_type);
CREATE INDEX idx_ne_status ON notification_events(status);
CREATE INDEX idx_ne_created_at ON notification_events(created_at);

-- notification_deliveries
CREATE INDEX idx_nd_notification_event_id ON notification_deliveries(notification_event_id);
CREATE INDEX idx_nd_organization_id ON notification_deliveries(organization_id);
CREATE INDEX idx_nd_recipient_profile_id ON notification_deliveries(recipient_profile_id);
CREATE INDEX idx_nd_status ON notification_deliveries(status);
CREATE INDEX idx_nd_next_retry_at ON notification_deliveries(next_retry_at)
  WHERE status IN ('PENDING', 'FAILED') AND next_retry_at IS NOT NULL;
CREATE INDEX idx_nd_provider_message_id ON notification_deliveries(provider_message_id)
  WHERE provider_message_id IS NOT NULL;
CREATE INDEX idx_nd_created_at ON notification_deliveries(created_at);

-- notification_templates
CREATE INDEX idx_nt_organization_id ON notification_templates(organization_id);

-- provider_settings
CREATE INDEX idx_ps_organization_id ON provider_settings(organization_id);

-- audit_logs
CREATE INDEX idx_al_organization_id ON audit_logs(organization_id);
CREATE INDEX idx_al_actor_profile_id ON audit_logs(actor_profile_id);
CREATE INDEX idx_al_created_at ON audit_logs(created_at);
CREATE INDEX idx_al_entity ON audit_logs(entity_type, entity_id);

-- ============================================================
-- TRIGGERS: auto-update updated_at columns
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_parents_updated_at
  BEFORE UPDATE ON parents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_drivers_updated_at
  BEFORE UPDATE ON drivers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_buses_updated_at
  BEFORE UPDATE ON buses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_children_updated_at
  BEFORE UPDATE ON children
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_trips_updated_at
  BEFORE UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_notification_preferences_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_notification_event_settings_updated_at
  BEFORE UPDATE ON notification_event_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_notification_events_updated_at
  BEFORE UPDATE ON notification_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_notification_deliveries_updated_at
  BEFORE UPDATE ON notification_deliveries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_notification_templates_updated_at
  BEFORE UPDATE ON notification_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_provider_settings_updated_at
  BEFORE UPDATE ON provider_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_trip_child_proximity_state_updated_at
  BEFORE UPDATE ON trip_child_proximity_state
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_device_tokens_updated_at2
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- DATABASE HELPER FUNCTIONS
-- ============================================================

-- Get the current user's profile (used in RLS policies)
CREATE OR REPLACE FUNCTION get_my_profile()
RETURNS profiles AS $$
  SELECT * FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Get the current user's role (used in RLS policies)
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Get the current user's organization_id (used in RLS policies)
CREATE OR REPLACE FUNCTION get_my_org_id()
RETURNS UUID AS $$
  SELECT organization_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Get the driver record for the current user
CREATE OR REPLACE FUNCTION get_my_driver_id()
RETURNS UUID AS $$
  SELECT d.id FROM drivers d WHERE d.profile_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Get the parent record for the current user
CREATE OR REPLACE FUNCTION get_my_parent_id()
RETURNS UUID AS $$
  SELECT p.id FROM parents p WHERE p.profile_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Get the bus assigned to the current driver
CREATE OR REPLACE FUNCTION get_my_assigned_bus_id()
RETURNS UUID AS $$
  SELECT b.id FROM buses b
  JOIN drivers d ON b.current_driver_id = d.id
  WHERE d.profile_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Upsert notification_preferences when a parent is created
CREATE OR REPLACE FUNCTION create_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notification_preferences (parent_id)
  VALUES (NEW.id)
  ON CONFLICT (parent_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_default_notif_prefs
  AFTER INSERT ON parents
  FOR EACH ROW EXECUTE FUNCTION create_default_notification_preferences();
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

ALTER PUBLICATION supabase_realtime ADD TABLE trips;
ALTER PUBLICATION supabase_realtime ADD TABLE notification_events;

-- NOTE: trip_location_history is NOT added to realtime —
-- parents/admin read the current location from trips.current_latitude/longitude.
-- History is loaded on-demand, not streamed.
-- ============================================================
-- SafeRoute — Migration 003: Helper DB Functions & Default Data
-- Run AFTER 002_rls.sql
-- ============================================================

-- ============================================================
-- Function: Initialize notification_event_settings for a new org
-- Call this after creating a new organization.
-- ============================================================
CREATE OR REPLACE FUNCTION initialize_org_notification_settings(p_org_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO notification_event_settings
    (organization_id, event_type, push_enabled, whatsapp_enabled, sms_enabled, emergency_override, enabled)
  VALUES
    (p_org_id, 'BUS_NEARBY',          TRUE, FALSE, FALSE, FALSE, TRUE),
    (p_org_id, 'TRIP_STARTED',        TRUE, FALSE, FALSE, FALSE, TRUE),
    (p_org_id, 'TRIP_COMPLETED',      TRUE, FALSE, FALSE, FALSE, TRUE),
    (p_org_id, 'BUS_DELAY',           TRUE, FALSE, TRUE,  FALSE, TRUE),
    (p_org_id, 'EMERGENCY',           TRUE, TRUE,  TRUE,  TRUE,  TRUE),
    (p_org_id, 'CUSTOM_ALERT',        TRUE, FALSE, FALSE, FALSE, TRUE),
    (p_org_id, 'SYSTEM_ANNOUNCEMENT', TRUE, FALSE, FALSE, FALSE, TRUE)
  ON CONFLICT (organization_id, event_type) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Function: Initialize default notification templates for a new org
-- ============================================================
CREATE OR REPLACE FUNCTION initialize_org_notification_templates(p_org_id UUID)
RETURNS VOID AS $$
BEGIN
  -- BUS_NEARBY templates
  INSERT INTO notification_templates (organization_id, event_type, channel, title, message_template)
  VALUES
    (p_org_id, 'BUS_NEARBY', 'PUSH',
     '🚌 Bus {{bus_number}} is nearby!',
     'The school bus is {{distance}} away from {{child_name}}''s pickup point. Get ready!'),
    (p_org_id, 'BUS_NEARBY', 'SMS',
     NULL,
     'SafeRoute: Bus {{bus_number}} is {{distance}} from {{child_name}}''s stop. Get ready!'),
    (p_org_id, 'BUS_NEARBY', 'WHATSAPP',
     NULL,
     '🚌 *SafeRoute Alert*\nBus *{{bus_number}}* is *{{distance}}* away from {{child_name}}''s pickup point.\nGet ready! 👟'),

  -- TRIP_STARTED templates
    (p_org_id, 'TRIP_STARTED', 'PUSH',
     '🚌 Bus {{bus_number}} has started',
     'Driver {{driver_name}} has started the bus route. Track live in SafeRoute.'),
    (p_org_id, 'TRIP_STARTED', 'SMS',
     NULL,
     'SafeRoute: Bus {{bus_number}} trip started by {{driver_name}}. Open app to track live.'),
    (p_org_id, 'TRIP_STARTED', 'WHATSAPP',
     NULL,
     '🚌 *SafeRoute*: Bus *{{bus_number}}* trip started.\nDriver: {{driver_name}}\nOpen the app to track live. 🗺️'),

  -- TRIP_COMPLETED templates
    (p_org_id, 'TRIP_COMPLETED', 'PUSH',
     '✅ Bus {{bus_number}} trip completed',
     'The bus route has been completed. Children have been dropped off.'),
    (p_org_id, 'TRIP_COMPLETED', 'SMS',
     NULL,
     'SafeRoute: Bus {{bus_number}} trip completed. All children dropped off.'),
    (p_org_id, 'TRIP_COMPLETED', 'WHATSAPP',
     NULL,
     '✅ *SafeRoute*: Bus *{{bus_number}}* trip completed.\nAll children have been dropped off safely.'),

  -- BUS_DELAY templates
    (p_org_id, 'BUS_DELAY', 'PUSH',
     '⏱️ Bus {{bus_number}} is delayed',
     '{{message}}'),
    (p_org_id, 'BUS_DELAY', 'SMS',
     NULL,
     'SafeRoute: Bus {{bus_number}} delay - {{message}}'),
    (p_org_id, 'BUS_DELAY', 'WHATSAPP',
     NULL,
     '⏱️ *SafeRoute Delay Alert*\nBus *{{bus_number}}*: {{message}}'),

  -- EMERGENCY templates
    (p_org_id, 'EMERGENCY', 'PUSH',
     '🚨 EMERGENCY — Bus {{bus_number}}',
     '{{message}}'),
    (p_org_id, 'EMERGENCY', 'SMS',
     NULL,
     'EMERGENCY SafeRoute: Bus {{bus_number}} - {{message}} - Contact school immediately.'),
    (p_org_id, 'EMERGENCY', 'WHATSAPP',
     NULL,
     '🚨 *EMERGENCY — SafeRoute*\nBus *{{bus_number}}*\n{{message}}\n\nPlease contact the school immediately.'),

  -- CUSTOM_ALERT templates
    (p_org_id, 'CUSTOM_ALERT', 'PUSH',
     '📢 Alert from Bus {{bus_number}}',
     '{{message}}'),
    (p_org_id, 'CUSTOM_ALERT', 'SMS',
     NULL,
     'SafeRoute Bus {{bus_number}}: {{message}}'),
    (p_org_id, 'CUSTOM_ALERT', 'WHATSAPP',
     NULL,
     '📢 *SafeRoute*\nBus *{{bus_number}}*: {{message}}'),

  -- SYSTEM_ANNOUNCEMENT templates
    (p_org_id, 'SYSTEM_ANNOUNCEMENT', 'PUSH',
     '📣 SafeRoute Announcement',
     '{{message}}'),
    (p_org_id, 'SYSTEM_ANNOUNCEMENT', 'SMS',
     NULL,
     'SafeRoute: {{message}}'),
    (p_org_id, 'SYSTEM_ANNOUNCEMENT', 'WHATSAPP',
     NULL,
     '📣 *SafeRoute Announcement*\n{{message}}')

  ON CONFLICT (organization_id, event_type, channel) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Function: Initialize provider_settings placeholders for a new org
-- ============================================================
CREATE OR REPLACE FUNCTION initialize_org_provider_settings(p_org_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO provider_settings (organization_id, provider, is_enabled, config, config_secret_key_names)
  VALUES
    (p_org_id, 'FCM',      FALSE, '{"project_id": ""}',
     ARRAY['fcm_server_key']),
    (p_org_id, 'FAST2SMS', FALSE, '{"sender_id": "SRTE", "route": "q"}',
     ARRAY['fast2sms_api_key']),
    (p_org_id, 'MAYTAPI',  FALSE, '{"product_id": "", "phone_id": ""}',
     ARRAY['maytapi_api_token'])
  ON CONFLICT (organization_id, provider) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Function: Full org initialization (call after creating an org)
-- ============================================================
CREATE OR REPLACE FUNCTION initialize_organization(p_org_id UUID)
RETURNS VOID AS $$
BEGIN
  PERFORM initialize_org_notification_settings(p_org_id);
  PERFORM initialize_org_notification_templates(p_org_id);
  PERFORM initialize_org_provider_settings(p_org_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Function: resolve_notification_channels
-- Returns which channels are allowed for a given event + parent
-- Implements Phase 9.1 three-layer channel resolution logic
-- ============================================================
CREATE OR REPLACE FUNCTION resolve_notification_channels(
  p_org_id          UUID,
  p_event_type      notification_event_type,
  p_parent_id       UUID
)
RETURNS TABLE(channel delivery_channel, allowed BOOLEAN) AS $$
DECLARE
  v_nes                notification_event_settings%ROWTYPE;
  v_np                 notification_preferences%ROWTYPE;
  v_org                organizations%ROWTYPE;
  v_emergency_override BOOLEAN;
BEGIN
  -- Load org settings
  SELECT * INTO v_org FROM organizations WHERE id = p_org_id;

  -- Load event settings for this org + event type
  SELECT * INTO v_nes
  FROM notification_event_settings
  WHERE organization_id = p_org_id AND event_type = p_event_type;

  -- Load parent preferences
  SELECT * INTO v_np
  FROM notification_preferences
  WHERE parent_id = p_parent_id;

  -- Emergency override applies when:
  -- org.emergency_override_enabled = true AND event_settings.emergency_override = true
  v_emergency_override := (v_org.emergency_override_enabled AND v_nes.emergency_override);

  -- PUSH: allowed if org+event enables it, AND (parent allows it OR emergency override)
  RETURN QUERY SELECT
    'PUSH'::delivery_channel,
    (v_nes.push_enabled AND v_nes.enabled AND (v_np.push_enabled OR v_emergency_override));

  -- SMS: allowed if org+event enables it, AND (parent allows it OR emergency override)
  RETURN QUERY SELECT
    'SMS'::delivery_channel,
    (v_nes.sms_enabled AND v_nes.enabled AND (v_np.sms_enabled OR v_emergency_override));

  -- WHATSAPP: allowed if org+event enables it, AND (parent allows it OR emergency override)
  RETURN QUERY SELECT
    'WHATSAPP'::delivery_channel,
    (v_nes.whatsapp_enabled AND v_nes.enabled AND (v_np.whatsapp_enabled OR v_emergency_override));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================
-- Function: render_notification_template
-- Replaces template variables with actual values
-- ============================================================
CREATE OR REPLACE FUNCTION render_notification_template(
  p_template TEXT,
  p_vars     JSONB
)
RETURNS TEXT AS $$
DECLARE
  v_result TEXT := p_template;
  v_key    TEXT;
  v_value  TEXT;
BEGIN
  FOR v_key, v_value IN SELECT key, value #>> '{}' FROM jsonb_each(p_vars)
  LOOP
    v_result := REPLACE(v_result, '{{' || v_key || '}}', COALESCE(v_value, ''));
  END LOOP;
  RETURN v_result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- Function: insert_audit_log (used by Edge Functions)
-- ============================================================
CREATE OR REPLACE FUNCTION insert_audit_log(
  p_org_id          UUID,
  p_actor_id        UUID,
  p_action          audit_action,
  p_entity_type     TEXT,
  p_entity_id       UUID DEFAULT NULL,
  p_metadata        JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO audit_logs (organization_id, actor_profile_id, action, entity_type, entity_id, metadata)
  VALUES (p_org_id, p_actor_id, p_action, p_entity_type, p_entity_id, p_metadata)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ============================================================
-- SafeRoute — Migration 004: Test Seed Data
-- For manual verification of Phase 1 exit criteria ONLY.
-- Run AFTER 003_functions.sql
-- DELETE this data from production before going live.
-- ============================================================

-- IMPORTANT: Replace these UUIDs with actual Supabase Auth user IDs
-- after creating test users in Supabase Auth dashboard:
-- 1. Go to Authentication > Users > Add user
-- 2. Create: admin@test.saferoute, driver@test.saferoute, parent@test.saferoute
-- 3. Create: admin2@testorg2.saferoute (for cross-org RLS testing)
-- Then replace the placeholder UUIDs below.

-- ─────────────────────────────────────────────
-- Organizations
-- ─────────────────────────────────────────────
INSERT INTO organizations (id, name, timezone, is_active)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Springfield Elementary', 'Asia/Kolkata', TRUE),
  ('22222222-2222-2222-2222-222222222222', 'Shelbyville Middle School', 'Asia/Kolkata', TRUE)
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────
-- Profiles (replace UUIDs with real Auth user IDs after creating users)
-- ─────────────────────────────────────────────
-- Org 1 profiles
-- INSERT INTO profiles (id, name, phone, email, role, organization_id)
-- VALUES
--   ('YOUR_ADMIN_AUTH_UUID', 'Principal Skinner', '+919999000001', 'admin@test.saferoute', 'ADMIN', '11111111-1111-1111-1111-111111111111'),
--   ('YOUR_DRIVER_AUTH_UUID', 'Otto Mann', '+919999000002', 'driver@test.saferoute', 'DRIVER', '11111111-1111-1111-1111-111111111111'),
--   ('YOUR_PARENT_AUTH_UUID', 'Marge Simpson', '+919999000003', 'parent@test.saferoute', 'PARENT', '11111111-1111-1111-1111-111111111111');

-- Org 2 profile (for cross-org RLS testing)
-- INSERT INTO profiles (id, name, phone, email, role, organization_id)
-- VALUES
--   ('YOUR_ADMIN2_AUTH_UUID', 'Principal Valiant', '+919999000004', 'admin2@testorg2.saferoute', 'ADMIN', '22222222-2222-2222-2222-222222222222');

-- ─────────────────────────────────────────────
-- Role-specific records
-- ─────────────────────────────────────────────
-- INSERT INTO drivers (profile_id, organization_id, license_number) VALUES
--   ('YOUR_DRIVER_AUTH_UUID', '11111111-1111-1111-1111-111111111111', 'DL-0420110149646');

-- INSERT INTO parents (profile_id, organization_id) VALUES
--   ('YOUR_PARENT_AUTH_UUID', '11111111-1111-1111-1111-111111111111');

-- ─────────────────────────────────────────────
-- Buses
-- ─────────────────────────────────────────────
-- INSERT INTO buses (id, organization_id, bus_number, registration_number, capacity) VALUES
--   ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'BUS-01', 'KA-01-AB-1234', 40);

-- ─────────────────────────────────────────────
-- Children
-- ─────────────────────────────────────────────
-- INSERT INTO children (organization_id, parent_id, name, bus_id, pickup_latitude, pickup_longitude, pickup_name, notification_distance_meters)
-- SELECT
--   '11111111-1111-1111-1111-111111111111',
--   p.id,
--   'Bart Simpson',
--   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
--   12.9716, -- Bangalore lat (example)
--   77.5946, -- Bangalore lon (example)
--   '742 Evergreen Terrace',
--   750
-- FROM parents p
-- WHERE p.profile_id = 'YOUR_PARENT_AUTH_UUID';

-- ─────────────────────────────────────────────
-- Initialize org settings
-- ─────────────────────────────────────────────
-- SELECT initialize_organization('11111111-1111-1111-1111-111111111111');
-- SELECT initialize_organization('22222222-2222-2222-2222-222222222222');

-- ─────────────────────────────────────────────
-- RLS VERIFICATION QUERIES (run as each test user via anon key)
-- ─────────────────────────────────────────────

-- Test 1: As parent — should return OWN children only
-- SELECT * FROM children;  -- Should only see Bart, not children from other parents

-- Test 2: As parent — try to access driver route data
-- SELECT * FROM trips;  -- Should return only trips for assigned bus

-- Test 3: As driver — try to access all parents
-- SELECT * FROM parents;  -- Should only see parents on assigned bus

-- Test 4: As admin of org1 — try to access org2 data
-- SELECT * FROM profiles WHERE organization_id = '22222222-2222-2222-2222-222222222222';
-- Should return empty set (RLS blocks cross-org access)

-- Test 5: Cross-org trip access
-- SELECT * FROM trips;  -- Admin of org1 should never see org2 trips

-- ─────────────────────────────────────────────
-- CLEANUP (run before going to production)
-- ─────────────────────────────────────────────
-- DELETE FROM children WHERE name = 'Bart Simpson';
-- DELETE FROM buses WHERE bus_number = 'BUS-01';
-- DELETE FROM parents WHERE profile_id = 'YOUR_PARENT_AUTH_UUID';
-- DELETE FROM drivers WHERE profile_id = 'YOUR_DRIVER_AUTH_UUID';
-- DELETE FROM profiles WHERE email IN ('admin@test.saferoute', 'driver@test.saferoute', 'parent@test.saferoute', 'admin2@testorg2.saferoute');
-- DELETE FROM organizations WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
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

-- Ensure Organization safety parameter constraints
ALTER TABLE organizations
    ADD CONSTRAINT chk_org_proximity_distance CHECK (default_notification_distance_meters BETWEEN 300 AND 2000),
    ADD CONSTRAINT chk_org_retention_days CHECK (data_retention_days BETWEEN 30 AND 365);
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
          AND status = 'IN_PROGRESS'
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
            SELECT 1 FROM trip_passengers tp
            JOIN trips t ON t.id = tp.trip_id
            WHERE tp.child_id = children.id
              AND t.driver_id = auth.uid()
              AND t.status = 'IN_PROGRESS'
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
            SELECT 1 FROM trip_passengers tp
            JOIN children c ON c.id = tp.child_id
            WHERE tp.trip_id = trip_location_history.trip_id
              AND c.parent_id = auth.uid()
        )
    );

-- ─── 3. DEVICE TOKENS SECURITY ──────────────────────────────────────────────
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS device_tokens_self_only ON device_tokens;
CREATE POLICY device_tokens_self_only ON device_tokens
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

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
                WHERE user_id = auth.uid()
                  AND organization_id = notification_events.organization_id
                  AND is_active = true
            )
        )
    );
