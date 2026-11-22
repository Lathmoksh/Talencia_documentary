-- 20 Platform State Machine Fixtures
-- Sample Requisition in CLOSED_FILLED state
INSERT INTO recruitment.job_requisition (
  id, organisation_id, posted_by_user_id, job_role_id, job_title, job_category,
  job_type, work_mode, vacancies_count, city_id, min_experience_months, max_experience_months,
  min_salary_amount, max_salary_amount, salary_currency_code, is_salary_negotiable,
  job_description, publish_status, open_to_consultants, application_deadline,
  published_at, created_at, updated_at
) VALUES (
  '73000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000041',
  'Closed Engineering Role', 'CORPORATE_PERMANENT', 'FULL_TIME', 'REMOTE', 1,
  '00000000-0000-4000-8000-000000000021', 24, 48,
  1800000.00, 2400000.00, 'INR', false,
  'FSM verification role.', 'CLOSED_FILLED', false, '2026-10-31T23:59:59Z',
  '2026-10-01T00:00:00Z', '2026-10-01T00:00:00Z', '2026-10-31T23:59:59Z'
) ON CONFLICT (id) DO NOTHING;
