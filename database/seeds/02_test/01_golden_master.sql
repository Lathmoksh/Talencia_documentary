-- Golden Master Fixture (Pinned Seed 20261103)
-- Pinned User
INSERT INTO identity.user_account (
  id, email, phone_country_code, phone_number, user_type, account_status,
  is_email_verified, is_phone_verified, two_factor_enabled, failed_login_attempts,
  created_at, updated_at
) VALUES (
  '70000000-0000-4000-8000-000000000001', 'golden.candidate@test.talentra.internal', '+91', '9000000001', 'CANDIDATE', 'ACTIVE_VERIFIED',
  true, true, false, 0, '2026-11-03T00:00:00Z', '2026-11-03T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Pinned Profile
INSERT INTO candidate.candidate_profile (
  id, user_id, first_name, last_name, display_name, date_of_birth, gender,
  headline, summary, current_city_id, total_experience_months,
  current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days,
  profile_completion_percentage, is_profile_searchable, created_at, updated_at
) VALUES (
  '71000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000001',
  'Golden', 'Tester', 'Golden Tester', '1995-01-01', 'OTHER',
  'Standard Golden Master Candidate for Data Tests', 'Deterministic test profile.',
  '00000000-0000-4000-8000-000000000021', 36,
  1500000.00, 2000000.00, 'INR', 15, 100.0, true, '2026-11-03T00:00:00Z', '2026-11-03T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
