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
