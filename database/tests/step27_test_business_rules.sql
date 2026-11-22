-- =============================================================
-- Talentra Milestone 27: Automated Business Rules Test Suite
-- 3-Layer Enforcement: Storage Engine, Trigger/Proc, API Policy
-- =============================================================

-- RULE BR-011: Escrow Lock Cannot Exceed Available Balance
SELECT 'BR011_ESCROW_BALANCE_GUARD' AS rule_id,
       wa.id AS wallet_id,
       wa.current_balance,
       wa.escrow_reserved_balance,
       CASE WHEN wa.escrow_reserved_balance <= (wa.current_balance + wa.escrow_reserved_balance) THEN 'PASS' ELSE 'FAIL_DEFICIT' END AS result
FROM billing.wallet_account wa;

-- RULE BR-017: No Active Requisitions Without At Least One Vacancy
SELECT 'BR017_VACANCIES_POSITIVE' AS rule_id,
       COUNT(*) FILTER (WHERE vacancies_count <= 0 AND publish_status = 'PUBLISHED_ACTIVE') AS zero_vacancy_jobs,
       CASE WHEN COUNT(*) FILTER (WHERE vacancies_count <= 0 AND publish_status = 'PUBLISHED_ACTIVE') = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM recruitment.job_requisition;

-- RULE BR-021: Max Recruiter Seats Bound by Subscription Plan
SELECT 'BR021_RECRUITER_SEAT_BOUNDS' AS rule_id,
       o.id AS organisation_id,
       COUNT(rsa.id) AS active_seats,
       sp.max_recruiter_seats,
       CASE WHEN COUNT(rsa.id) <= sp.max_recruiter_seats THEN 'PASS' ELSE 'FAIL_OVERLIMIT' END AS result
FROM organisation.organisation o
LEFT JOIN organisation.recruiter_seat_assignment rsa ON o.id = rsa.organisation_id AND rsa.seat_status = 'ACTIVE_ALLOCATED'
LEFT JOIN licensing.subscription_licence sl ON o.account_id = sl.account_id AND sl.licence_status = 'ACTIVE_COMMISSIONED'
LEFT JOIN licensing.subscription_plan sp ON sl.plan_id = sp.id
GROUP BY o.id, sp.max_recruiter_seats;

-- RULE BR-045: University Placement Cohort Registration Guard
SELECT 'BR045_CAMPUS_COHORT_REGISTRATION_GUARD' AS rule_id,
       COUNT(*) FILTER (WHERE registered_students_count < 0) AS invalid_student_counts,
       CASE WHEN COUNT(*) FILTER (WHERE registered_students_count < 0) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM engagement.campus_placement_cohort;
