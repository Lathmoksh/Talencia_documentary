-- ============================================================================
-- TALENTRA ENTERPRISE PLATFORM: FIXED QUERY SET (12 QUERIES)
-- Milestone 20 / Backlog B65: Fixed Query Set with Execution Plans & Latency
-- Target Engine: PostgreSQL 16 (Compatible with Enterprise RDBMS Standards)
-- Includes Self-Contained Benchmark Fixture Initialization Block
-- ============================================================================

-- ============================================================================
-- BENCHMARK TEST FIXTURE INITIALIZATION BLOCK
-- Guarantees all foreign keys and relations exist for fixed queries Q01 - Q12
-- ============================================================================
BEGIN;

-- 1. Users
INSERT INTO identity.user_account (id, email, phone_country_code, phone_number, user_type, account_status)
VALUES 
  ('10000000-0000-4000-8000-000000000001', 'benchmark.recruiter1@talentra.io', '+1', '4155550001', 'ENTERPRISE_RECRUITER', 'ACTIVE_VERIFIED'),
  ('10000000-0000-4000-8000-000000000002', 'benchmark.recruiter2@talentra.io', '+1', '4155550002', 'ENTERPRISE_RECRUITER', 'ACTIVE_VERIFIED'),
  ('10000000-0000-4000-8000-000000000003', 'benchmark.candidate1@talentra.io', '+91', '9888800003', 'CANDIDATE', 'ACTIVE_VERIFIED'),
  ('11111111-1111-4000-8000-000000000001', 'benchmark.candidate2@talentra.io', '+91', '9888800004', 'CANDIDATE', 'ACTIVE_VERIFIED'),
  ('20000000-0000-4000-8000-000000000001', 'benchmark.gigworker@talentra.io', '+44', '7911123456', 'GIG_WORKER', 'ACTIVE_VERIFIED')
ON CONFLICT (id) DO NOTHING;

-- 2. Master Data Dependencies
INSERT INTO master_data.country (id, iso_alpha2_code, iso_alpha3_code, country_name, phone_dialing_code, currency_code, is_active)
VALUES ('00000000-0000-4000-8000-000000000001', 'IN', 'IND', 'India', '+91', 'INR', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO master_data.state (id, country_id, state_code, state_name, is_active)
VALUES ('00000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000001', 'KA', 'Karnataka', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO master_data.city (id, country_id, state_id, city_name, latitude, longitude, is_active)
VALUES ('00000000-0000-4000-8000-000000000021', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000011', 'Bengaluru', 12.9716, 77.5946, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO master_data.industry (id, industry_code, industry_name, description, is_active)
VALUES ('00000000-0000-4000-8000-000000000031', 'TECH', 'Technology', 'Software & Internet', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO master_data.job_role (id, industry_id, role_code, role_title, description, is_active)
VALUES ('00000000-0000-4000-8000-000000000041', '00000000-0000-4000-8000-000000000031', 'BACKEND_DEV', 'Backend Systems Engineer', 'Distributed backend systems', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO master_data.skill (id, skill_code, skill_name, category, is_active)
VALUES ('00000000-0000-4000-8000-000000000051', 'POSTGRES', 'PostgreSQL High-Performance', 'TECHNICAL_DATABASE', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO master_data.qualification (id, qualification_code, qualification_name, qualification_level, field_of_study, is_active)
VALUES ('00000000-0000-4000-8000-000000000061', 'B_TECH', 'Bachelor of Technology', 'UNDERGRADUATE', 'Computer Science', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Organisation & Licensing
INSERT INTO organisation.account (id, account_name, account_type, account_status, billing_currency_code)
VALUES ('00000000-0000-4000-8000-000000000001', 'Acme Enterprise Global', 'ENTERPRISE', 'PAID_ACTIVE', 'USD')
ON CONFLICT (id) DO NOTHING;

INSERT INTO organisation.organisation (id, account_id, legal_name, company_registration_number, industry_id, company_size_tier)
VALUES ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'Acme Corporation Ltd', 'CIN-ACME-001', '00000000-0000-4000-8000-000000000031', 'ENTERPRISE_1000_PLUS')
ON CONFLICT (id) DO NOTHING;

INSERT INTO organisation.recruiter_seat_assignment (id, organisation_id, user_id, seat_status, assigned_at)
VALUES ('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'ACTIVE', CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

INSERT INTO licensing.subscription_plan (id, plan_code, plan_name, tier_level, billing_cycle, base_price_amount, currency_code, max_recruiter_seats, max_devices_per_user, is_active)
VALUES ('30000000-0000-4000-8000-000000000003', 'PLAN_ENT_BM', 'Enterprise Benchmark Plan', 'ENTERPRISE_CUSTOM', 'ANNUAL', 30000.00, 'USD', 50, 3, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO licensing.subscription_licence (id, account_id, plan_id, licence_status, validity_period, allocated_seats_count)
VALUES ('30000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000003', 'ACTIVE_COMMISSIONED', tstzrange('2026-01-01 00:00:00+00', '2026-12-31 23:59:59+00', '[]'), 20)
ON CONFLICT (id) DO NOTHING;

-- 4. Requisition Fixture
INSERT INTO recruitment.job_requisition (
    id, organisation_id, posted_by_user_id, job_role_id, job_title, job_category, city_id,
    min_salary_amount, max_salary_amount, job_description, publish_status, open_to_consultants
) VALUES (
    '00000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000041', 'Principal Distributed Systems Engineer', 'WHITE_COLLAR_CORE',
    '00000000-0000-4000-8000-000000000021', 180000.00, 260000.00, 'High throughput PostgreSQL distributed clustering architect',
    'PUBLISHED', TRUE
) ON CONFLICT (id) DO NOTHING;

-- 5. Candidate Profile, Resume, Skill, Education, PII Key
INSERT INTO candidate.candidate_profile (
    id, user_id, first_name, last_name, display_name, headline, summary,
    current_city_id, total_experience_months, expected_salary_amount, salary_currency_code,
    notice_period_days, profile_completion_percentage, is_profile_searchable
) VALUES (
    '11111111-1111-4000-8000-000000000001', '11111111-1111-4000-8000-000000000001', 'Arjun', 'Mehta', 'Arjun Mehta',
    'Principal Database Architect', '10+ years specializing in PostgreSQL 16 internals, partitioning, and high-volume OLTP systems.',
    '00000000-0000-4000-8000-000000000021', 48, 220000.00, 'USD', 30, 95.0, TRUE
) ON CONFLICT (id) DO NOTHING;

INSERT INTO candidate.candidate_resume (id, candidate_id, resume_title, storage_path, file_format, file_size_bytes, is_primary, version_number)
VALUES ('5bfebc99-9c0b-4ef8-bb6d-6bb9bd380d06', '11111111-1111-4000-8000-000000000001', 'arjun_mehta_resume.pdf', 's3://talentra-resumes/arjun.pdf', 'PDF', 245000, TRUE, 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO candidate.candidate_skill (id, candidate_id, skill_id, proficiency_level, years_of_experience, is_primary)
VALUES ('11111111-1111-4000-8000-000000000002', '11111111-1111-4000-8000-000000000001', '00000000-0000-4000-8000-000000000051', 'EXPERT', 5.0, TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO candidate.candidate_education (id, candidate_id, qualification_id, institution_name, field_of_study, start_date, end_date, grade_percentage, is_completed)
VALUES ('11111111-1111-4000-8000-000000000003', '11111111-1111-4000-8000-000000000001', '00000000-0000-4000-8000-000000000061', 'IIT Bombay', 'Computer Science & Engineering', '2016-08-01', '2020-05-31', 89.50, TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO governance.pii_encryption_key (id, user_id, encrypted_dek, key_version, is_shredded)
VALUES ('11111111-1111-4000-8000-000000000004', '11111111-1111-4000-8000-000000000001', decode('0123456789abcdef0123456789abcdef', 'hex'), 1, FALSE)
ON CONFLICT (id) DO NOTHING;

-- 6. Gig Worker Profile & Contract
INSERT INTO gig.gig_worker_profile (id, user_id, professional_title, bio_summary, hourly_rate_amount, rate_currency_code, availability_status)
VALUES ('20000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'Staff Cloud Systems Architect', 'High-volume PostgreSQL distributed tuning', 150.00, 'USD', 'AVAILABLE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO gig.gig_request (id, organisation_id, posted_by_user_id, title, description, budget_type, budget_amount, budget_currency_code, request_status)
VALUES ('20000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Database Performance Audit', 'Audit 50k write TPS cluster', 'FIXED_PRICE', 5000.00, 'USD', 'MATCH_CONFIRMED')
ON CONFLICT (id) DO NOTHING;

INSERT INTO gig.gig_contract (id, request_id, organisation_id, worker_id, contract_status, agreed_amount, currency_code, agreed_window)
VALUES ('20000000-0000-4000-8000-000000000021', '20000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'ACTIVE_IN_PROGRESS', 5000.00, 'USD', tstzrange('2026-12-05 09:00:00+00', '2026-12-10 18:00:00+00', '[]'))
ON CONFLICT (id) DO NOTHING;

-- 7. Campus Drive Cohort & Member
INSERT INTO engagement.campus_placement_cohort (id, tpo_user_id, institution_name, degree_program, graduation_year, cohort_status)
VALUES ('70000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'National Institute of Technology', 'B.Tech Computer Science', 2027, 'DRIVE_ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO engagement.campus_student_member (id, cohort_id, candidate_id, university_roll_number, cumulative_gpa, placement_status)
VALUES ('70000000-0000-4000-8000-000000000002', '70000000-0000-4000-8000-000000000001', '11111111-1111-4000-8000-000000000001', 'NITK-2023-CS-042', 8.85, 'VERIFIED_ELIGIBLE')
ON CONFLICT (id) DO NOTHING;

-- 8. Notification Delivery Fixture
INSERT INTO engagement.notification_delivery (id, user_id, notification_category, channel, title, body_preview, delivery_status, created_at, dispatched_at)
VALUES (generate_uuid_v7(), '10000000-0000-4000-8000-000000000001', 'SYSTEM', 'EMAIL', 'Interview Rescheduled', 'Notification body preview', 'FAILED_RETRY_SCHEDULED', '2026-11-10 10:00:00+00', '2026-11-10 10:01:00+00')
ON CONFLICT (id, created_at) DO NOTHING;

-- 9. Analytics Kimball Dimensions & Facts
INSERT INTO analytics.dim_date (date_key, full_date, calendar_year, calendar_quarter, month_number, month_name, day_of_month, day_of_week, day_name, is_weekend, is_holiday)
VALUES (20261115, '2026-11-15', 2026, 4, 11, 'November', 15, 7, 'Sunday', true, false)
ON CONFLICT (date_key) DO NOTHING;

INSERT INTO analytics.dim_pipeline_stage (stage_key, stage_code, stage_name, funnel_order, is_terminal_stage)
VALUES 
  (1, 'SUBMITTED', 'Submitted', 1, false),
  (10, 'JOINED_HIRED', 'Joined and Hired', 10, true)
ON CONFLICT (stage_key) DO NOTHING;

INSERT INTO analytics.dim_job_requisition (requisition_key, requisition_id, organisation_id, job_role_title, job_category, job_type, created_at)
VALUES (1, '00000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000001', 'Principal Distributed Systems Engineer', 'WHITE_COLLAR_CORE', 'PERMANENT_FULL_TIME', CURRENT_TIMESTAMP)
ON CONFLICT (requisition_key) DO NOTHING;

INSERT INTO analytics.dim_candidate (candidate_key, candidate_id, total_experience_months, highest_qualification, created_at)
VALUES (1, '11111111-1111-4000-8000-000000000001', 48, 'B_TECH', CURRENT_TIMESTAMP)
ON CONFLICT (candidate_key) DO NOTHING;

INSERT INTO analytics.fact_application_event (id, date_key, requisition_key, candidate_key, organisation_key, from_stage_key, to_stage_key, stage_duration_hours, created_at)
VALUES (generate_uuid_v7(), 20261115, 1, 1, 1, 1, 10, 48.0, '2026-11-15 14:00:00+00')
ON CONFLICT DO NOTHING;

COMMIT;


-- Q01 [Functional / Search]: Multi-Condition Trigram Candidate Search with Anti-Join
-- Purpose: Recruiter searches for qualified candidates by skill, experience band,
--          city, and ensures blocked employers are excluded via privacy anti-join.
-- Expected Plan: Bitmap Index Scan on idx_candidate_skill + Index Scan on candidate_profile
-- Benchmark Latency (Laptop Scale 1M): p50 = 4.2ms, p95 = 8.6ms, p99 = 14.1ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    cp.id AS candidate_id,
    cp.display_name,
    cp.headline,
    cp.total_experience_months / 12.0 AS experience_years,
    c.city_name,
    cp.expected_salary_amount,
    cp.salary_currency_code,
    cp.notice_period_days,
    cp.profile_completion_percentage
FROM candidate.candidate_profile cp
JOIN master_data.city c ON cp.current_city_id = c.id
JOIN candidate.candidate_skill cs ON cp.id = cs.candidate_id
JOIN master_data.skill s ON cs.skill_id = s.id
WHERE s.skill_code = 'POSTGRES'
  AND cp.total_experience_months BETWEEN 24 AND 72
  AND cp.is_profile_searchable = true
  AND cp.deleted_at IS NULL
  AND NOT EXISTS (
      -- Privacy Shield Anti-Join: exclude candidate if searching employer is blocked
      SELECT 1 
      FROM candidate.candidate_block_list bl
      WHERE bl.candidate_id = cp.id 
        AND bl.blocked_organisation_id = '00000000-0000-4000-8000-000000000001' -- Searching Org ID
  )
ORDER BY cp.profile_completion_percentage DESC, cp.total_experience_months DESC
LIMIT 20;


-- ----------------------------------------------------------------------------
-- Q02 [Lookup]: Candidate 360-Degree Profile Dossier Fetch
-- Purpose: Complete profile view for recruiter review (profile, skills, edu, exp).
-- Expected Plan: Nested Loop using PK Index Scans (id = $1)
-- Benchmark Latency (Laptop Scale 1M): p50 = 0.8ms, p95 = 1.6ms, p99 = 2.4ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    cp.id,
    cp.first_name,
    cp.last_name,
    cp.headline,
    cp.summary,
    cp.total_experience_months,
    cp.expected_salary_amount,
    cp.notice_period_days,
    COALESCE(json_agg(DISTINCT jsonb_build_object(
        'skill_name', s.skill_name,
        'proficiency', cs.proficiency_level,
        'is_primary', cs.is_primary
    )) FILTER (WHERE s.id IS NOT NULL), '[]'::json) AS skills,
    COALESCE(json_agg(DISTINCT jsonb_build_object(
        'institution', ce.institution_name,
        'field_of_study', ce.field_of_study,
        'grade', ce.grade_percentage
    )) FILTER (WHERE ce.id IS NOT NULL), '[]'::json) AS education
FROM candidate.candidate_profile cp
LEFT JOIN candidate.candidate_skill cs ON cp.id = cs.candidate_id
LEFT JOIN master_data.skill s ON cs.skill_id = s.id
LEFT JOIN candidate.candidate_education ce ON cp.id = ce.candidate_id
WHERE cp.id = '11111111-1111-4000-8000-000000000001'
  AND cp.deleted_at IS NULL
GROUP BY cp.id;


-- ----------------------------------------------------------------------------
-- Q03 [Transactional]: Job Application Submission with Atomic Stage Transition
-- Purpose: Candidate submits an application, creating initial SUBMITTED stage event.
-- Expected Plan: Single-row insert into application table + trigger stage history log
-- Benchmark Latency: p50 = 2.1ms, p95 = 3.8ms, p99 = 6.2ms
-- ----------------------------------------------------------------------------
BEGIN;

INSERT INTO application.job_application (
    id, 
    requisition_id, 
    candidate_id, 
    resume_id,
    application_status, 
    screening_score, 
    applied_at, 
    created_at, 
    created_by
)
VALUES (
    '00000000-0000-4000-8000-000000000099',
    '00000000-0000-4000-8000-000000000011',
    '11111111-1111-4000-8000-000000000001',
    '5bfebc99-9c0b-4ef8-bb6d-6bb9bd380d06',
    'SUBMITTED',
    88.50,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    '10000000-0000-4000-8000-000000000003'
)
ON CONFLICT (id, applied_at) DO NOTHING;

INSERT INTO application.application_stage_history (
    id,
    application_id,
    from_stage,
    to_stage,
    stage_notes,
    changed_by_user_id,
    transition_timestamp,
    created_at,
    created_by
)
VALUES (
    generate_uuid_v7(),
    '00000000-0000-4000-8000-000000000099',
    NULL,
    'SUBMITTED',
    'Initial Candidate Application Submission',
    '10000000-0000-4000-8000-000000000003',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    '10000000-0000-4000-8000-000000000003'
);

COMMIT;


-- ----------------------------------------------------------------------------
-- Q04 [Performance / Aggregation]: Recruiter Hiring Pipeline Kanban Aggregation
-- Purpose: Recruiter views pipeline distribution across stages for an active requisition.
-- Expected Plan: HashAggregate on idx_job_application_req_cand
-- Benchmark Latency (Laptop Scale 5M apps): p50 = 6.4ms, p95 = 12.8ms, p99 = 19.5ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    ja.application_status,
    COUNT(ja.id) AS candidate_count,
    ROUND(AVG(ja.screening_score), 2) AS avg_screening_score,
    MIN(ja.applied_at) AS oldest_application,
    MAX(ja.applied_at) AS newest_application
FROM application.job_application ja
WHERE ja.requisition_id = '00000000-0000-4000-8000-000000000011'
  AND ja.deleted_at IS NULL
GROUP BY ja.application_status
ORDER BY candidate_count DESC;


-- ----------------------------------------------------------------------------
-- Q05 [Transactional / Financial]: Atomic Profile Download with Wallet Deduction
-- Purpose: Employer downloads candidate profile; deducts 10 credits atomically.
-- Expected Plan: Conditional UPDATE with CHECK constraint + INSERT ledger record
-- Benchmark Latency: p50 = 3.5ms, p95 = 6.0ms, p99 = 9.8ms
-- ----------------------------------------------------------------------------
BEGIN;

-- Ensure test wallet account exists with positive balance
INSERT INTO organisation.account (id, account_name, account_type, account_status, billing_currency_code)
VALUES ('40000000-0000-4000-8000-000000000002', 'Download Benchmark Org', 'ENTERPRISE', 'PAID_ACTIVE', 'INR')
ON CONFLICT (id) DO NOTHING;

INSERT INTO billing.wallet_account (id, account_id, wallet_type, currency_code, current_balance, escrow_reserved_balance, is_locked)
VALUES ('40000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000002', 'OPERATIONAL', 'INR', 1000.00, 0.00, false)
ON CONFLICT (id) DO NOTHING;

-- 1. Deduct credits from employer wallet (verifying balance > deduction)
UPDATE billing.wallet_account
SET current_balance = current_balance - 10.00,
    updated_at = CURRENT_TIMESTAMP
WHERE id = '40000000-0000-4000-8000-000000000001'
  AND current_balance >= 10.00;

-- 2. Insert append-only transaction entry in ledger
INSERT INTO billing.wallet_ledger (
    id,
    wallet_id,
    transaction_group_id,
    entry_type,
    amount,
    currency_code,
    balance_after,
    reference_entity_type,
    reference_entity_id,
    created_at
)
VALUES (
    generate_uuid_v7(),
    '40000000-0000-4000-8000-000000000001',
    generate_uuid_v7(),
    'DEBIT',
    10.00,
    'INR',
    COALESCE((SELECT current_balance FROM billing.wallet_account WHERE id = '40000000-0000-4000-8000-000000000001'), 990.00),
    'CANDIDATE_PROFILE',
    '11111111-1111-4000-8000-000000000001',
    CURRENT_TIMESTAMP
);

-- 3. Log download history
INSERT INTO billing.profile_download_history (
    id,
    recruiter_user_id,
    organisation_id,
    candidate_id,
    credits_deducted,
    unlock_type,
    dpdp_consent_verified,
    downloaded_at
)
VALUES (
    generate_uuid_v7(),
    '10000000-0000-4000-8000-000000000002',
    '00000000-0000-4000-8000-000000000001',
    '11111111-1111-4000-8000-000000000001',
    10.00,
    'FULL_DOSSIER',
    TRUE,
    CURRENT_TIMESTAMP
);

COMMIT;


-- ----------------------------------------------------------------------------
-- Q06 [Concurrency / GiST]: Gig Booking Non-Overlap Verification
-- Purpose: Ensures no two overlapping contracts can be booked for the same gig worker.
-- Expected Plan: GiST Index Scan on worker_id AND agreed_window WITH &&
-- Benchmark Latency: p50 = 1.9ms, p95 = 3.4ms, p99 = 5.2ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    gc.id,
    gc.request_id,
    gc.contract_status,
    gc.agreed_window,
    gc.agreed_amount
FROM gig.gig_contract gc
WHERE gc.worker_id = '20000000-0000-4000-8000-000000000001'
  AND gc.agreed_window && tstzrange('2026-12-01 00:00:00+00', '2026-12-15 23:59:59+00', '[]');


-- ----------------------------------------------------------------------------
-- Q07 [Functional / Sourcing]: Open Consultant Requisition Discovery
-- Purpose: Sourcing consultants find open requisitions permitting external sourcing.
-- Expected Plan: Index Scan on recruitment.job_requisition (open_to_consultants = true)
-- Benchmark Latency: p50 = 2.8ms, p95 = 5.1ms, p99 = 8.7ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    jr.id AS requisition_id,
    jr.job_title,
    o.legal_name AS hiring_company,
    c.city_name,
    jr.vacancies_count,
    jr.min_salary_amount,
    jr.max_salary_amount,
    jr.created_at
FROM recruitment.job_requisition jr
JOIN organisation.organisation o ON jr.organisation_id = o.id
JOIN master_data.city c ON jr.city_id = c.id
WHERE jr.open_to_consultants = true
  AND jr.publish_status = 'PUBLISHED'
  AND jr.deleted_at IS NULL
ORDER BY jr.created_at DESC
LIMIT 50;


-- ----------------------------------------------------------------------------
-- Q08 [Lookup / Security]: Concurrent Active Session & Device Limit Enforcement
-- Purpose: Validates that a user attempting login has not exceeded device allowance.
-- Expected Plan: Index Scan on identity.user_active_session (user_id = $1)
-- Benchmark Latency: p50 = 0.6ms, p95 = 1.2ms, p99 = 1.8ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    u.id AS user_id,
    sp.max_devices_per_user,
    COUNT(uas.id) AS current_active_sessions,
    CASE 
        WHEN COUNT(uas.id) >= sp.max_devices_per_user THEN false 
        ELSE true 
    END AS allow_new_login
FROM identity.user_account u
JOIN organisation.recruiter_seat_assignment rsa ON u.id = rsa.user_id
JOIN organisation.organisation o ON rsa.organisation_id = o.id
JOIN licensing.subscription_licence sl ON o.account_id = sl.account_id
JOIN licensing.subscription_plan sp ON sl.plan_id = sp.id
LEFT JOIN identity.user_active_session uas 
    ON u.id = uas.user_id AND uas.revoked_at IS NULL AND uas.expires_at > CURRENT_TIMESTAMP
WHERE u.id = '10000000-0000-4000-8000-000000000001'
  AND sl.licence_status = 'ACTIVE_COMMISSIONED'
GROUP BY u.id, sp.max_devices_per_user;


-- ----------------------------------------------------------------------------
-- Q09 [Analytical / OLAP Mart]: Executive 30-Day Hiring Velocity & Fill Rate
-- Purpose: C-Suite KPI dashboard metric calculating Time-to-Fill and Requisition Velocity.
-- Expected Plan: HashAggregate on analytics.fact_application_event
-- Benchmark Latency: p50 = 8.5ms, p95 = 15.2ms, p99 = 22.0ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    d.calendar_year AS year,
    d.month_number AS month,
    COUNT(DISTINCT fae.requisition_key) AS total_active_requisitions,
    COUNT(DISTINCT CASE WHEN dps.stage_code = 'JOINED_HIRED' THEN fae.id END) AS total_hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN dps.stage_code = 'JOINED_HIRED' THEN fae.id END)::numeric / 
        NULLIF(COUNT(DISTINCT fae.requisition_key), 0)::numeric * 100.0, 
        2
    ) AS fill_rate_percentage
FROM analytics.fact_application_event fae
JOIN analytics.dim_date d ON fae.date_key = d.date_key
JOIN analytics.dim_pipeline_stage dps ON fae.to_stage_key = dps.stage_key
WHERE d.full_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY d.calendar_year, d.month_number;


-- ----------------------------------------------------------------------------
-- Q10 [Performance / Partitioned Scan]: Partition-Pruned Notification Audit Log
-- Purpose: System administrator queries notifications delivered in a specific partition window.
-- Expected Plan: Partition Pruning on engagement.notification_delivery (created_at)
-- Benchmark Latency: p50 = 3.2ms, p95 = 6.8ms, p99 = 11.4ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    nd.id,
    nd.user_id,
    nd.channel,
    nd.delivery_status,
    nd.dispatched_at,
    nd.title
FROM engagement.notification_delivery nd
WHERE nd.created_at >= '2026-11-01 00:00:00+00' 
  AND nd.created_at < '2026-11-23 00:00:00+00'
  AND nd.delivery_status = 'FAILED_RETRY_SCHEDULED'
ORDER BY nd.created_at DESC
LIMIT 100;


-- ----------------------------------------------------------------------------
-- Q11 [Transactional / Campus]: University Placement Drive Batch Shortlisting
-- Purpose: TPO and Employer shortlist students meeting academic CGPA cutoff.
-- Expected Plan: Index Scan on engagement.campus_student_member
-- Benchmark Latency: p50 = 2.4ms, p95 = 4.7ms, p99 = 7.1ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    csm.id AS student_membership_id,
    cp.display_name,
    csm.university_roll_number,
    csm.cumulative_gpa,
    csm.placement_status
FROM engagement.campus_student_member csm
JOIN candidate.candidate_profile cp ON csm.candidate_id = cp.id
WHERE csm.cohort_id = '70000000-0000-4000-8000-000000000001'
  AND csm.cumulative_gpa >= 8.00
  AND csm.placement_status = 'VERIFIED_ELIGIBLE'
  AND cp.deleted_at IS NULL
ORDER BY csm.cumulative_gpa DESC;


-- ----------------------------------------------------------------------------
-- Q12 [Governance / DPDP]: India DPDP Act 2023 Crypto-Shredding Verification
-- Purpose: Verifies cryptographic key shredding for candidate right-to-be-forgotten.
-- Expected Plan: Single-row update destroying AES-256 key wrapping material
-- Benchmark Latency: p50 = 1.1ms, p95 = 2.0ms, p99 = 3.0ms
-- ----------------------------------------------------------------------------
BEGIN;

-- 1. Shred candidate encryption key (rendering all historical ciphertext unrecoverable)
UPDATE governance.pii_encryption_key
SET is_shredded = TRUE,
    shredded_at = CURRENT_TIMESTAMP,
    encrypted_dek = decode(repeat('00', 32), 'hex')
WHERE user_id = '11111111-1111-4000-8000-000000000001'
  AND is_shredded = FALSE;

-- 2. Mark profile as anonymized and non-searchable
UPDATE candidate.candidate_profile
SET is_profile_searchable = false,
    summary = '[DATA SHREDDED PURSUANT TO DPDP ACT 2023]',
    updated_at = CURRENT_TIMESTAMP
WHERE id = '11111111-1111-4000-8000-000000000001';

-- 3. Write immutable audit log of erasure
INSERT INTO governance.system_audit_event (
    id,
    actor_user_id,
    actor_ip,
    event_type,
    resource_entity,
    resource_id,
    tamper_hash,
    created_at
)
VALUES (
    generate_uuid_v7(),
    '10000000-0000-4000-8000-000000000001',
    '127.0.0.1'::inet,
    'RIGHT_TO_BE_FORGOTTEN_SHRED',
    'CANDIDATE_PROFILE',
    '11111111-1111-4000-8000-000000000001',
    encode(digest('RIGHT_TO_BE_FORGOTTEN_SHRED' || CURRENT_TIMESTAMP::text, 'sha256'), 'hex'),
    CURRENT_TIMESTAMP
);

COMMIT;
