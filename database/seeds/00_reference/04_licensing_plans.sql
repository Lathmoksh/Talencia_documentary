-- Reference Seed: Subscription Plans & Entitlements
INSERT INTO licensing.subscription_plan (
  id, plan_code, plan_name, tier_level, billing_cycle, base_price_amount, currency_code,
  max_recruiter_seats, max_devices_per_user, monthly_profile_unlock_quota, monthly_outreach_credits, is_active, created_at, updated_at
) VALUES
  ('00000000-0000-4000-8000-000000000071', 'STARTER', 'Talentra Starter', 'TIER_1', 'MONTHLY', 15000.00, 'INR', 2, 2, 50, 100, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000072', 'PROFESSIONAL', 'Talentra Professional', 'TIER_2', 'MONTHLY', 45000.00, 'INR', 10, 3, 500, 1000, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000073', 'ENTERPRISE', 'Talentra Enterprise Scale', 'TIER_3', 'ANNUAL', 350000.00, 'INR', 50, 5, 5000, 10000, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;
