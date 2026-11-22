-- Development Requisitions Seed
INSERT INTO recruitment.job_requisition (
  id, organisation_id, posted_by_user_id, job_role_id, job_title, job_category,
  job_type, work_mode, vacancies_count, city_id, min_experience_months, max_experience_months,
  min_salary_amount, max_salary_amount, salary_currency_code, is_salary_negotiable,
  job_description, publish_status, open_to_consultants, application_deadline,
  published_at, created_at, updated_at
) VALUES (
  '40000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000041',
  'Staff Backend Database Architect', 'CORPORATE_PERMANENT', 'FULL_TIME', 'HYBRID', 2,
  '00000000-0000-4000-8000-000000000021', 48, 96,
  2500000.00, 3500000.00, 'INR', true,
  'Lead the high-throughput transactional database core and Kimball analytical reporting marts.',
  'PUBLISHED_ACTIVE', true, '2026-12-31T23:59:59Z', '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Skill requirements
INSERT INTO recruitment.job_requisition_skill (
  id, requisition_id, skill_id, requirement_type, min_experience_months, created_at, created_by, updated_at, updated_by
) VALUES
  ('41000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000051', 'MANDATORY', 48, '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000', '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000'),
  ('41000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000052', 'MANDATORY', 36, '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000', '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000')
ON CONFLICT (id) DO NOTHING;
