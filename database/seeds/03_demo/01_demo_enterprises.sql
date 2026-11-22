-- Demo Enterprises
-- Apex Health Account
INSERT INTO organisation.account (
  id, account_name, account_type, account_status, billing_currency_code, created_at, updated_at
) VALUES (
  '80000000-0000-4000-8000-000000000001', 'Apex Health Systems Group', 'ENTERPRISE', 'ACTIVE', 'INR', '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO organisation.organisation (
  id, account_id, legal_name, trade_name, company_registration_number, website_url,
  industry_id, company_size_tier, verification_status, created_at, updated_at
) VALUES (
  '81000000-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
  'Apex Healthcare Diagnostics India Ltd', 'Apex Health Tech', 'U85110MH2019PLC234567', 'https://apexhealth.org',
  '00000000-0000-4000-8000-000000000033', 'GROWTH_201_TO_1000', 'VERIFIED_ACTIVE', '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
