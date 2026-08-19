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
