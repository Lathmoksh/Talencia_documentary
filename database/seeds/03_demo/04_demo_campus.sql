-- Demo Campus Drive Cohort (REQ-22, F-19, WF-09)
INSERT INTO engagement.campus_placement_cohort (
  id, tpo_user_id, institution_name, degree_program, graduation_year, cohort_status,
  created_at, created_by, updated_at, updated_by
) VALUES (
  '84000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002',
  'National Institute of Technology Karnataka (NITK)',
  'B.Tech Computer Science & Engineering', 2027, 'DRIVE_ACTIVE',
  '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000', '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000'
) ON CONFLICT (id) DO NOTHING;
