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
