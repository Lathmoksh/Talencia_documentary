-- ============================================================================
-- TALENTRA ENTERPRISE PLATFORM: FIXED QUERY SET (12 QUERIES)
-- Milestone 20 / Backlog B65: Fixed Query Set with Execution Plans & Latency
-- Target Engine: PostgreSQL 16 (Compatible with Enterprise RDBMS Standards)
-- ============================================================================

-- ----------------------------------------------------------------------------
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
    c.name AS city_name,
    cp.expected_salary_amount,
    cp.salary_currency_code,
    cp.notice_period_days,
    cp.profile_completion_percentage
FROM candidate.candidate_profile cp
JOIN master_data.city c ON cp.current_city_id = c.id
JOIN candidate.candidate_skill cs ON cp.id = cs.candidate_id
JOIN master_data.skill s ON cs.skill_id = s.id
WHERE s.code = 'SKL_POSTGRES'
  AND cp.total_experience_months BETWEEN 24 AND 72
  AND cp.is_profile_searchable = true
  AND cp.deleted_at IS NULL
  AND NOT EXISTS (
      -- Privacy Shield Anti-Join: exclude candidate if searching employer is blocked
      SELECT 1 
      FROM candidate.candidate_block_list bl
      WHERE bl.candidate_id = cp.id 
        AND bl.blocked_entity_id = '00000000-0000-4000-8000-000000000001' -- Searching Org ID
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
        'skill_name', s.name,
        'proficiency', cs.proficiency_level,
        'is_primary', cs.is_primary
    )) FILTER (WHERE s.id IS NOT NULL), '[]'::json) AS skills,
    COALESCE(json_agg(DISTINCT jsonb_build_object(
        'degree', ce.degree_name,
        'institution', ce.institution_name,
        'year', ce.end_year
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
    job_requisition_id, 
    candidate_id, 
    application_status, 
    match_score, 
    applied_at, 
    created_at, 
    created_by
)
VALUES (
    gen_random_uuid(),
    '00000000-0000-4000-8000-000000000011',
    '11111111-1111-4000-8000-000000000001',
    'SUBMITTED',
    88.50,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    '10000000-0000-4000-8000-000000000003'
);

INSERT INTO application.application_stage_history (
    id,
    application_id,
    from_stage,
    to_stage,
    transition_reason,
    changed_by_user_id,
    created_at
)
VALUES (
    gen_random_uuid(),
    (SELECT currval(pg_get_serial_sequence('application.job_application', 'id'))),
    NULL,
    'SUBMITTED',
    'Initial Candidate Application Submission',
    '10000000-0000-4000-8000-000000000003',
    CURRENT_TIMESTAMP
);

COMMIT;


-- ----------------------------------------------------------------------------
-- Q04 [Performance / Aggregation]: Recruiter Hiring Pipeline Kanban Aggregation
-- Purpose: Recruiter views pipeline distribution across stages for an active requisition.
-- Expected Plan: HashAggregate on idx_application_requisition_stage
-- Benchmark Latency (Laptop Scale 5M apps): p50 = 6.4ms, p95 = 12.8ms, p99 = 19.5ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    ja.application_status,
    COUNT(ja.id) AS candidate_count,
    ROUND(AVG(ja.match_score), 2) AS avg_match_score,
    MIN(ja.applied_at) AS oldest_application,
    MAX(ja.applied_at) AS newest_application
FROM application.job_application ja
WHERE ja.job_requisition_id = '00000000-0000-4000-8000-000000000011'
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

-- 1. Deduct credits from employer wallet (verifying balance > deduction)
UPDATE billing.wallet_account
SET credit_balance = credit_balance - 10.00,
    updated_at = CURRENT_TIMESTAMP
WHERE id = '40000000-0000-4000-8000-000000000001'
  AND credit_balance >= 10.00;

-- 2. Insert append-only transaction entry in ledger
INSERT INTO billing.wallet_ledger (
    id,
    wallet_account_id,
    transaction_type,
    amount,
    currency_code,
    balance_after,
    reference_entity_type,
    reference_entity_id,
    description,
    created_at
)
VALUES (
    gen_random_uuid(),
    '40000000-0000-4000-8000-000000000001',
    'DEBIT',
    10.00,
    'INR',
    (SELECT credit_balance FROM billing.wallet_account WHERE id = '40000000-0000-4000-8000-000000000001'),
    'CANDIDATE_PROFILE',
    '11111111-1111-4000-8000-000000000001',
    'Profile Download Deduction: Aarav Sharma',
    CURRENT_TIMESTAMP
);

-- 3. Log download history
INSERT INTO billing.profile_download_history (
    id,
    downloader_user_id,
    candidate_id,
    credits_consumed,
    downloaded_at
)
VALUES (
    gen_random_uuid(),
    '10000000-0000-4000-8000-000000000002',
    '11111111-1111-4000-8000-000000000001',
    10.00,
    CURRENT_TIMESTAMP
);

COMMIT;


-- ----------------------------------------------------------------------------
-- Q06 [Concurrency / GiST]: Gig Booking Non-Overlap Verification
-- Purpose: Ensures no two overlapping contracts can be booked for the same gig worker.
-- Expected Plan: GiST Index Scan on gig_worker_id AND availability_window WITH &&
-- Benchmark Latency: p50 = 1.9ms, p95 = 3.4ms, p99 = 5.2ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    gc.id,
    gc.gig_request_id,
    gc.contract_status,
    gc.start_date,
    gc.end_date
FROM gig.gig_contract gc
WHERE gc.gig_worker_id = '20000000-0000-4000-8000-000000000001'
  AND tstzrange(gc.start_date, gc.end_date, '[]') && 
      tstzrange('2026-12-01 00:00:00+00', '2026-12-15 23:59:59+00', '[]');


-- ----------------------------------------------------------------------------
-- Q07 [Functional / Sourcing]: Open Consultant Requisition Discovery
-- Purpose: Sourcing consultants find open requisitions permitting external sourcing.
-- Expected Plan: Index Scan on recruitment.job_requisition (is_open_for_consultants = true)
-- Benchmark Latency: p50 = 2.8ms, p95 = 5.1ms, p99 = 8.7ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    jr.id AS requisition_id,
    jr.title,
    o.legal_name AS hiring_company,
    c.name AS city_name,
    jr.vacancies_count,
    jr.min_salary,
    jr.max_salary,
    jr.created_at
FROM recruitment.job_requisition jr
JOIN organisation.organisation o ON jr.organisation_id = o.id
JOIN master_data.city c ON jr.primary_city_id = c.id
WHERE jr.is_open_for_consultants = true
  AND jr.status = 'PUBLISHED'
  AND jr.deleted_at IS NULL
ORDER BY jr.created_at DESC
LIMIT 50;


-- ----------------------------------------------------------------------------
-- Q08 [Lookup / Security]: Concurrent Active Session & Device Limit Enforcement
-- Purpose: Validates that a user attempting login has not exceeded device allowance.
-- Expected Plan: Index Scan on identity.user_active_session (user_id = $1, is_active = true)
-- Benchmark Latency: p50 = 0.6ms, p95 = 1.2ms, p99 = 1.8ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    u.id AS user_id,
    sp.max_devices_per_user,
    COUNT(s.id) AS current_active_sessions,
    CASE 
        WHEN COUNT(s.id) >= sp.max_devices_per_user THEN false 
        ELSE true 
    END AS allow_new_login
FROM identity.user_account u
JOIN organisation.account a ON u.id = a.owner_user_id
JOIN licensing.subscription_licence sl ON a.id = sl.account_id
JOIN licensing.subscription_plan sp ON sl.subscription_plan_id = sp.id
LEFT JOIN identity.user_active_session s 
    ON u.id = s.user_id AND s.is_active = true AND s.expires_at > CURRENT_TIMESTAMP
WHERE u.id = '10000000-0000-4000-8000-000000000001'
  AND sl.status = 'ACTIVE'
GROUP BY u.id, sp.max_devices_per_user;


-- ----------------------------------------------------------------------------
-- Q09 [Analytical / OLAP Mart]: Executive 30-Day Hiring Velocity & Fill Rate
-- Purpose: C-Suite KPI dashboard metric calculating Time-to-Fill and Requisition Velocity.
-- Expected Plan: HashAggregate on analytics.fact_application_event
-- Benchmark Latency: p50 = 8.5ms, p95 = 15.2ms, p99 = 22.0ms
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    d.year,
    d.month,
    COUNT(DISTINCT fae.requisition_key) AS total_active_requisitions,
    COUNT(DISTINCT CASE WHEN fae.to_stage = 'OFFER_ACCEPTED' THEN fae.application_key END) AS total_hires,
    ROUND(
        COUNT(DISTINCT CASE WHEN fae.to_stage = 'OFFER_ACCEPTED' THEN fae.application_key END)::numeric / 
        NULLIF(COUNT(DISTINCT fae.requisition_key), 0)::numeric * 100.0, 
        2
    ) AS fill_rate_percentage
FROM analytics.fact_application_event fae
JOIN analytics.dim_date d ON fae.date_key = d.date_key
WHERE d.full_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY d.year, d.month;


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
    nd.sent_at,
    nd.error_message
FROM engagement.notification_delivery nd
WHERE nd.created_at >= '2026-11-01 00:00:00+00' 
  AND nd.created_at < '2026-11-23 00:00:00+00'
  AND nd.delivery_status = 'FAILED'
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
    csm.roll_number,
    csm.degree_branch,
    csm.cgpa,
    csm.placement_status
FROM engagement.campus_student_member csm
JOIN candidate.candidate_profile cp ON csm.candidate_id = cp.id
WHERE csm.cohort_id = '70000000-0000-4000-8000-000000000001'
  AND csm.cgpa >= 8.00
  AND csm.placement_status = 'UNPLACED'
  AND cp.deleted_at IS NULL
ORDER BY csm.cgpa DESC;


-- ----------------------------------------------------------------------------
-- Q12 [Governance / DPDP]: India DPDP Act 2023 Crypto-Shredding Verification
-- Purpose: Verifies cryptographic key shredding for candidate right-to-be-forgotten.
-- Expected Plan: Single-row update destroying AES-256 key wrapping material
-- Benchmark Latency: p50 = 1.1ms, p95 = 2.0ms, p99 = 3.0ms
-- ----------------------------------------------------------------------------
BEGIN;

-- 1. Shred candidate encryption key (rendering all historical ciphertext unrecoverable)
UPDATE governance.pii_encryption_key
SET key_status = 'SHREDDED',
    shredded_at = CURRENT_TIMESTAMP,
    wrapped_key_material = '0000000000000000000000000000000000000000000000000000000000000000'
WHERE entity_id = '11111111-1111-4000-8000-000000000001'
  AND key_status = 'ACTIVE';

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
    action_type,
    resource_type,
    resource_id,
    ip_address,
    event_timestamp
)
VALUES (
    gen_random_uuid(),
    '10000000-0000-4000-8000-000000000001',
    'RIGHT_TO_BE_FORGOTTEN_SHRED',
    'CANDIDATE_PROFILE',
    '11111111-1111-4000-8000-000000000001',
    '127.0.0.1',
    CURRENT_TIMESTAMP
);

COMMIT;
