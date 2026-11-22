-- Development Identities Seed
-- 1. System Admin
INSERT INTO identity.user_account (
  id, email, phone_country_code, phone_number, user_type, account_status,
  is_email_verified, is_phone_verified, two_factor_enabled, failed_login_attempts,
  created_at, updated_at
) VALUES (
  '10000000-0000-4000-8000-000000000001', 'admin@talentra.internal', '+91', '9876543210', 'SYSTEM_ADMIN', 'ACTIVE_VERIFIED',
  true, true, true, 0, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- 2. Corporate Recruiter User
INSERT INTO identity.user_account (
  id, email, phone_country_code, phone_number, user_type, account_status,
  is_email_verified, is_phone_verified, two_factor_enabled, failed_login_attempts,
  created_at, updated_at
) VALUES (
  '10000000-0000-4000-8000-000000000002', 'priya.sharma@techcorp.com', '+91', '9876543211', 'EMPLOYER_RECRUITER', 'ACTIVE_VERIFIED',
  true, true, false, 0, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- 3. Candidate User
INSERT INTO identity.user_account (
  id, email, phone_country_code, phone_number, user_type, account_status,
  is_email_verified, is_phone_verified, two_factor_enabled, failed_login_attempts,
  created_at, updated_at
) VALUES (
  '10000000-0000-4000-8000-000000000003', 'arjun.verma@talent.dev', '+91', '9876543212', 'CANDIDATE', 'ACTIVE_VERIFIED',
  true, true, false, 0, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- 4. Gig Worker User
INSERT INTO identity.user_account (
  id, email, phone_country_code, phone_number, user_type, account_status,
  is_email_verified, is_phone_verified, two_factor_enabled, failed_login_attempts,
  created_at, updated_at
) VALUES (
  '10000000-0000-4000-8000-000000000004', 'rohan.designer@gigpro.io', '+91', '9876543213', 'GIG_WORKER', 'ACTIVE_VERIFIED',
  true, true, false, 0, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Passwords (argon2id hashes)
INSERT INTO identity.user_credential (
  id, user_id, password_hash, password_salt, hash_algorithm, password_changed_at, must_change_password, created_at, updated_at
) VALUES 
  ('11000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '$argon2id$v=19$m=65536,t=3,p=4$devSalt01$hashedAdminPasswordToken', 'devSalt01', 'ARGON2ID', '2026-11-01T00:00:00Z', false, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('11000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', '$argon2id$v=19$m=65536,t=3,p=4$devSalt02$hashedRecruiterPasswordToken', 'devSalt02', 'ARGON2ID', '2026-11-01T00:00:00Z', false, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('11000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003', '$argon2id$v=19$m=65536,t=3,p=4$devSalt03$hashedCandidatePasswordToken', 'devSalt03', 'ARGON2ID', '2026-11-01T00:00:00Z', false, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('11000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000004', '$argon2id$v=19$m=65536,t=3,p=4$devSalt04$hashedGigWorkerPasswordToken', 'devSalt04', 'ARGON2ID', '2026-11-01T00:00:00Z', false, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;

-- User Roles
INSERT INTO identity.user_role (
  id, user_id, role_id, granted_by, granted_at, is_active
) VALUES
  ('12000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000081', '10000000-0000-4000-8000-000000000001', '2026-11-01T00:00:00Z', true),
  ('12000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000083', '10000000-0000-4000-8000-000000000001', '2026-11-01T00:00:00Z', true),
  ('12000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000084', '10000000-0000-4000-8000-000000000001', '2026-11-01T00:00:00Z', true),
  ('12000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000085', '10000000-0000-4000-8000-000000000001', '2026-11-01T00:00:00Z', true)
ON CONFLICT (id) DO NOTHING;
