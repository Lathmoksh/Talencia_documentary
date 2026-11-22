-- Reference Seed: RBAC Roles
INSERT INTO identity.role (id, role_code, role_name, role_scope, description, is_system_role, is_active, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000081', 'SYS_ADMIN', 'System Administrator', 'GLOBAL', 'Full system management and infrastructure control', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000082', 'TENANT_ADMIN', 'Tenant Administrator', 'TENANT', 'Corporate tenant account owner and recruiter administrator', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000083', 'RECRUITER', 'Corporate Recruiter', 'TENANT', 'Creates requisitions, screens candidates, schedules interviews', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000084', 'CANDIDATE', 'Job Seeker Candidate', 'USER', 'Applies for positions, manages resume, sets privacy controls', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000085', 'GIG_WORKER', 'Freelance Gig Specialist', 'USER', 'Lists services, books contracts, submits milestones', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000086', 'TPO_OFFICER', 'University Placement Officer', 'CAMPUS', 'Coordinates campus cohort placement drives and student rosters', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000087', 'AUDITOR', 'Statutory Compliance Auditor', 'GLOBAL', 'Read-only access to audit trails, consent records and DPDP logs', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;
