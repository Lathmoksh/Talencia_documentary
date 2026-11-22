-- Boundary Test Cases: Exact Edge Values (DR-023, CTR-06)
-- Zero Salary (Fresher / Intern)
INSERT INTO candidate.candidate_profile (
  id, user_id, first_name, last_name, display_name, date_of_birth, gender,
  headline, summary, current_city_id, total_experience_months,
  current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days,
  profile_completion_percentage, is_profile_searchable, created_at, updated_at
) VALUES (
  '72000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000001',
  'ZeroSalary', 'Boundary', 'ZeroSalary Boundary', '2002-01-01', 'PREFER_NOT_TO_SAY',
  'Zero Salary Entry Level Boundary Profile', 'Testing current_salary = 0.00.',
  '00000000-0000-4000-8000-000000000021', 0,
  0.00, 600000.00, 'INR', 0, 50.0, true, '2026-11-03T00:00:00Z', '2026-11-03T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
