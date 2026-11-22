-- =============================================================
-- Talentra Milestone 16: Schema Coverage Against Business Workflows
-- Simulates end-to-end execution of Phase 1 Core Business Workflows
-- =============================================================

-- -------------------------------------------------------------
-- WORKFLOW WF-01: Candidate Registration & Profile Onboarding
-- -------------------------------------------------------------
-- Step 1: Register Account
INSERT INTO identity.user_account (
  id, email, phone_country_code, phone_number, user_type, account_status,
  is_email_verified, is_phone_verified, created_at, updated_at
) VALUES (
  '90000000-0000-4000-8000-000000000001', 'wf01.candidate@simulation.talentra', '+91', '9123456780',
  'CANDIDATE', 'ACTIVE_VERIFIED', true, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- Step 2: Build Profile
INSERT INTO candidate.candidate_profile (
  id, user_id, first_name, last_name, display_name, date_of_birth, gender,
  headline, summary, current_city_id, total_experience_months,
  current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days,
  profile_completion_percentage, is_profile_searchable, created_at, updated_at
) VALUES (
  '91000000-0000-4000-8000-000000000001', '90000000-0000-4000-8000-000000000001',
  'Workflow01', 'Candidate', 'WF01 Candidate', '1998-04-12', 'FEMALE',
  'Junior Fullstack Developer', 'Enthusiastic developer onboarding through WF-01.',
  '00000000-0000-4000-8000-000000000021', 18,
  800000.00, 1200000.00, 'INR', 15, 80.0, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- Step 3: Configure Privacy Block (Anti-Join Filter)
INSERT INTO candidate.candidate_block_list (
  id, candidate_id, blocked_organisation_id, block_reason, created_at, updated_at
) VALUES (
  '92000000-0000-4000-8000-000000000001', '91000000-0000-4000-8000-000000000001',
  '21000000-0000-4000-8000-000000000001', 'Employer block requested during onboarding', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- -------------------------------------------------------------
-- WORKFLOW WF-03: Candidate Application & Stage Advancement
-- -------------------------------------------------------------
-- Step 1: Submit Application
INSERT INTO application.job_application (
  id, requisition_id, candidate_id, application_status,
  screening_score, applied_at, created_at, created_by, updated_at, updated_by
) VALUES (
  '93000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001',
  '91000000-0000-4000-8000-000000000001', 'SUBMITTED',
  88.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'
) ON CONFLICT (id) DO NOTHING;

-- Step 2: Recruiter Shortlists Application
INSERT INTO application.application_stage_history (
  id, application_id, from_stage, to_stage, changed_by_user_id, stage_notes, transition_timestamp, created_at, created_by
) VALUES (
  '94000000-0000-4000-8000-000000000001', '93000000-0000-4000-8000-000000000001',
  'SUBMITTED', 'SHORTLISTED', '10000000-0000-4000-8000-000000000002', 'Profile match score meets bar', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'
) ON CONFLICT (id) DO NOTHING;

-- -------------------------------------------------------------
-- WORKFLOW WF-10: DPDP Right to Erasure (Cryptographic DEK Shredding)
-- -------------------------------------------------------------
-- Register candidate DEK key
INSERT INTO governance.pii_encryption_key (
  id, user_id, encrypted_dek, key_version, is_shredded, created_at, created_by, updated_at, updated_by
) VALUES (
  '95000000-0000-4000-8000-000000000001', '90000000-0000-4000-8000-000000000001',
  decode('11223344556677889900aabbccddeeff', 'hex'), 1, false, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'
) ON CONFLICT (id) DO NOTHING;

-- Execute Key Shredding Stored Procedure
CALL governance.sp_dpdp_crypto_shred('91000000-0000-4000-8000-000000000001'::uuid, '10000000-0000-4000-8000-000000000001'::uuid);

-- Verify Key Shredding
SELECT 'WF10_DPDP_KEY_SHREDDED_SUCCESS' AS test_name,
       is_shredded,
       encrypted_dek,
       CASE WHEN is_shredded = TRUE THEN 'PASS' ELSE 'FAIL' END AS result
FROM governance.pii_encryption_key
WHERE user_id = '90000000-0000-4000-8000-000000000001';
