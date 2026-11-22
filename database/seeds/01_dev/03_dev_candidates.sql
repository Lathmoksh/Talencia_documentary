-- Development Candidates Seed
-- Candidate Profile
INSERT INTO candidate.candidate_profile (
  id, user_id, first_name, last_name, display_name, date_of_birth, gender,
  headline, summary, current_city_id, total_experience_months,
  current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days,
  profile_completion_percentage, is_profile_searchable, created_at, updated_at
) VALUES (
  '30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003',
  'Arjun', 'Verma', 'Arjun Verma', '1996-05-14', 'MALE',
  'Senior Backend & Distributed Systems Architect',
  'Specialist in PostgreSQL 16 performance engineering, Python FastAPI, and high-concurrency microservices.',
  '00000000-0000-4000-8000-000000000021', 60,
  2400000.00, 3200000.00, 'INR', 30, 95.0, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Skills
INSERT INTO candidate.candidate_skill (
  id, candidate_id, skill_id, proficiency_level, years_of_experience, is_primary, created_at, updated_at
) VALUES
  ('31000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000051', 'EXPERT', 5.0, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('31000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000052', 'EXPERT', 5.0, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('31000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000055', 'ADVANCED', 4.0, false, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;

-- Work Experience
INSERT INTO candidate.candidate_work_experience (
  id, candidate_id, company_name, job_title, start_date, end_date, is_current, description, created_at, updated_at
) VALUES (
  '32000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001',
  'NextGen Distributed Systems', 'Senior Systems Engineer', '2021-08-01', NULL, true,
  'Designed PostgreSQL 16 sharding and event streaming pipelines handling 50k writes/sec.',
  '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Education
INSERT INTO candidate.candidate_education (
  id, candidate_id, institution_name, qualification_id, start_date, end_date, grade_percentage, is_highest, created_at, updated_at
) VALUES (
  '33000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001',
  'National Institute of Technology Karnataka', '00000000-0000-4000-8000-000000000061',
  '2014-08-01', '2018-06-01', 86.50, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
