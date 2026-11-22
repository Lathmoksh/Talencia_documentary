-- =============================================================
-- Talentra Milestone 26: Automated Six-Dimension Data Quality Suite
-- Evaluates: Completeness, Accuracy, Consistency, Timeliness, Uniqueness, Validity
-- =============================================================

-- 1. COMPLETENESS DIMENSION (DQ-CMP-01 to DQ-CMP-04)
SELECT 'DQ_CMP_01_CANDIDATE_PRIMARY_ATTRIBUTES' AS assertion_id,
       COUNT(*) AS total_records,
       COUNT(*) FILTER (WHERE first_name IS NULL OR last_name IS NULL OR current_city_id IS NULL) AS missing_count,
       CASE WHEN COUNT(*) FILTER (WHERE first_name IS NULL OR last_name IS NULL OR current_city_id IS NULL) = 0 
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM candidate.candidate_profile;

-- 2. ACCURACY DIMENSION (DQ-ACC-01 & DQ-ACC-02)
-- Invoice Calculation Invariant: total = subtotal + tax
SELECT 'DQ_ACC_01_INVOICE_ARITHMETIC_INVARIANT' AS assertion_id,
       COUNT(*) AS evaluated_invoices,
       COUNT(*) FILTER (WHERE total_amount <> (subtotal_amount + tax_amount)) AS arithmetic_errors,
       CASE WHEN COUNT(*) FILTER (WHERE total_amount <> (subtotal_amount + tax_amount)) = 0 
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM billing.invoice;

-- 3. CONSISTENCY DIMENSION (DQ-CNS-01)
-- Published Requisitions vs Verified Organisation Check (CTR-01 / DR-031)
SELECT 'DQ_CNS_01_PUBLISHED_JOBS_VERIFIED_ORGS' AS assertion_id,
       COUNT(*) AS unverified_published_jobs,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL_UNVERIFIED_PUBLICATION' END AS status
FROM recruitment.job_requisition r
JOIN organisation.organisation o ON r.organisation_id = o.id
WHERE r.publish_status = 'PUBLISHED_ACTIVE'
  AND o.verification_status <> 'VERIFIED_ACTIVE';

-- 4. TIMELINESS DIMENSION (DQ-TML-01)
-- End date cannot precede start date
SELECT 'DQ_TML_01_WORK_HISTORY_CHRONOLOGY' AS assertion_id,
       COUNT(*) FILTER (WHERE end_date < start_date) AS anachronistic_records,
       CASE WHEN COUNT(*) FILTER (WHERE end_date < start_date) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM candidate.candidate_work_experience;

-- 5. UNIQUENESS DIMENSION (DQ-UNQ-01)
-- Email uniqueness
SELECT 'DQ_UNQ_01_USER_ACCOUNT_EMAIL' AS assertion_id,
       COUNT(*) - COUNT(DISTINCT LOWER(email)) AS duplicate_emails,
       CASE WHEN COUNT(*) = COUNT(DISTINCT LOWER(email)) THEN 'PASS' ELSE 'FAIL' END AS status
FROM identity.user_account;

-- 6. VALIDITY DIMENSION (DQ-VAL-01)
-- Profile completion percentage range (0.0 to 100.0)
SELECT 'DQ_VAL_01_PROFILE_COMPLETION_BOUNDS' AS assertion_id,
       COUNT(*) FILTER (WHERE profile_completion_percentage < 0.0 OR profile_completion_percentage > 100.0) AS invalid_scores,
       CASE WHEN COUNT(*) FILTER (WHERE profile_completion_percentage < 0.0 OR profile_completion_percentage > 100.0) = 0 
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM candidate.candidate_profile;
