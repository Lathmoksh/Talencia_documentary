-- Development Organisations Seed
-- Account
INSERT INTO organisation.account (
  id, account_name, account_type, account_status, billing_currency_code, created_at, updated_at
) VALUES (
  '20000000-0000-4000-8000-000000000001', 'TechCorp Enterprises Ltd', 'ENTERPRISE', 'ACTIVE', 'INR', '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Organisation
INSERT INTO organisation.organisation (
  id, account_id, legal_name, trade_name, company_registration_number, website_url,
  industry_id, company_size_tier, verification_status, created_at, updated_at
) VALUES (
  '21000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001',
  'TechCorp India Private Limited', 'TechCorp Global', 'U72200KA2020PTC123456', 'https://techcorp.com',
  '00000000-0000-4000-8000-000000000031', 'ENTERPRISE_1000_PLUS', 'VERIFIED_ACTIVE', '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Location
INSERT INTO organisation.organisation_location (
  id, organisation_id, location_type, address_line1, city_id, state_id, country_id, postal_code, is_primary, is_active, created_at, updated_at
) VALUES (
  '22000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000001',
  'HEADQUARTERS', 'Prestige Tech Cloud, Outer Ring Road',
  '00000000-0000-4000-8000-000000000021', '00000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000001',
  '560103', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Recruiter Seat Assignment
INSERT INTO organisation.recruiter_seat_assignment (
  id, organisation_id, user_account_id, seat_type, seat_status, allocated_at, is_active, created_at, updated_at
) VALUES (
  '23000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000002', 'STANDARD_RECRUITER', 'ACTIVE_ALLOCATED',
  '2026-11-01T00:00:00Z', true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
