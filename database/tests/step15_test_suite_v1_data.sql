-- =============================================================
-- Talentra Test Suite v1: Data Integrity & Storage Engine Invariants
-- Milestone 15 · Phase 3 Prove
-- =============================================================

-- TEST 01: Primary Key Uniqueness & Non-Nullability
-- Asserts zero duplicate primary keys across core tables
SELECT 'T01_PK_UNIQUENESS_USER_ACCOUNT' AS test_name,
       COUNT(*) - COUNT(DISTINCT id) AS duplicate_count,
       CASE WHEN COUNT(*) = COUNT(DISTINCT id) THEN 'PASS' ELSE 'FAIL' END AS status
FROM identity.user_account;

SELECT 'T02_PK_UNIQUENESS_CANDIDATE_PROFILE' AS test_name,
       COUNT(*) - COUNT(DISTINCT id) AS duplicate_count,
       CASE WHEN COUNT(*) = COUNT(DISTINCT id) THEN 'PASS' ELSE 'FAIL' END AS status
FROM candidate.candidate_profile;

SELECT 'T03_PK_UNIQUENESS_ORGANISATION' AS test_name,
       COUNT(*) - COUNT(DISTINCT id) AS duplicate_count,
       CASE WHEN COUNT(*) = COUNT(DISTINCT id) THEN 'PASS' ELSE 'FAIL' END AS status
FROM organisation.organisation;

-- TEST 04: Foreign Key Integrity (Zero Orphan Child Records)
SELECT 'T04_NO_ORPHAN_CANDIDATE_USERS' AS test_name,
       COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM candidate.candidate_profile cp
LEFT JOIN identity.user_account ua ON cp.user_id = ua.id
WHERE ua.id IS NULL;

SELECT 'T05_NO_ORPHAN_JOB_REQUISITIONS' AS test_name,
       COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM recruitment.job_requisition jr
LEFT JOIN organisation.organisation o ON jr.organisation_id = o.id
WHERE o.id IS NULL;

SELECT 'T06_NO_ORPHAN_JOB_APPLICATIONS' AS test_name,
       COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM application.job_application ja
LEFT JOIN recruitment.job_requisition jr ON ja.requisition_id = jr.id
WHERE jr.id IS NULL;

-- TEST 07: NOT NULL Invariants Verification
SELECT 'T07_NOT_NULL_CANDIDATE_NAMES' AS test_name,
       COUNT(*) FILTER (WHERE first_name IS NULL OR last_name IS NULL) AS violation_count,
       CASE WHEN COUNT(*) FILTER (WHERE first_name IS NULL OR last_name IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM candidate.candidate_profile;

SELECT 'T08_NOT_NULL_USER_EMAILS' AS test_name,
       COUNT(*) FILTER (WHERE email IS NULL) AS violation_count,
       CASE WHEN COUNT(*) FILTER (WHERE email IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM identity.user_account;

-- TEST 09: Value Range & Numeric Bounds Constraints
SELECT 'T09_NON_NEGATIVE_SALARIES' AS test_name,
       COUNT(*) FILTER (WHERE current_salary_amount < 0.00 OR expected_salary_amount < 0.00) AS violation_count,
       CASE WHEN COUNT(*) FILTER (WHERE current_salary_amount < 0.00 OR expected_salary_amount < 0.00) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM candidate.candidate_profile;

SELECT 'T10_NON_NEGATIVE_WALLET_BALANCES' AS test_name,
       COUNT(*) FILTER (WHERE current_balance < 0.00 OR escrow_reserved_balance < 0.00) AS violation_count,
       CASE WHEN COUNT(*) FILTER (WHERE current_balance < 0.00 OR escrow_reserved_balance < 0.00) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM billing.wallet_account;
