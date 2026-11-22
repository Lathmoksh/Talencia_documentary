-- Reference Seed: Subscription Licensing Plans
INSERT INTO licensing.subscription_plan (
    id, plan_code, plan_name, tier_level, billing_cycle, base_price_amount, currency_code,
    max_recruiter_seats, max_devices_per_user, monthly_profile_unlock_quota,
    monthly_outreach_credits, is_active, created_at, created_by, updated_at, updated_by
) VALUES
  ('00000000-0000-4000-8000-000000000031', 'ENTERPRISE_UNLIMITED', 'Enterprise Unlimited Talent', 'TIER_3', 'ANNUAL', 250000.00, 'INR', 50, 3, 5000, 20000, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('00000000-0000-4000-8000-000000000032', 'PROFESSIONAL_STAFFING', 'Professional Staffing Agency', 'TIER_2', 'ANNUAL', 120000.00, 'INR', 20, 2, 2000, 8000, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('00000000-0000-4000-8000-000000000033', 'SMB_GROWTH', 'SMB Growth Starter', 'TIER_1', 'MONTHLY', 15000.00, 'INR', 5, 2, 300, 1000, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000')
ON CONFLICT (id) DO NOTHING;
