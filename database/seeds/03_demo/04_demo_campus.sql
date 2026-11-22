-- Demo Campus Drive Cohort (REQ-22, F-19, WF-09)
INSERT INTO engagement.campus_placement_cohort (
  id, institution_name, degree_program, graduation_year, cohort_status,
  registered_students_count, created_at, updated_at
) VALUES (
  '84000000-0000-4000-8000-000000000001', 'National Institute of Technology Karnataka (NITK)',
  'B.Tech Computer Science & Engineering', 2027, 'DRIVE_ACTIVE', 120,
  '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
