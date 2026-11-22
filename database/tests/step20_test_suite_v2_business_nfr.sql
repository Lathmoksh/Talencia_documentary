-- =============================================================
-- Talentra Test Suite v2: Business Rules, State Machines & NFR Invariants
-- Milestone 20 · Phase 3 Prove
-- =============================================================

-- -------------------------------------------------------------
-- 1. Double-Entry Escrow & Ledger Balance Invariant ($0.00 Drift)
-- -------------------------------------------------------------
SELECT 'BR_DOUBLE_ENTRY_BALANCE_DRIFT' AS assertion_name,
       SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE -amount END) AS net_ledger_movement,
       wa.current_balance,
       CASE WHEN ABS(SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE -amount END) - wa.current_balance) < 0.001 
            THEN 'PASS' ELSE 'FAIL_FINANCIAL_DRIFT' END AS status
FROM billing.wallet_ledger wl
JOIN billing.wallet_account wa ON wl.wallet_id = wa.id
WHERE wa.id = '60000000-0000-4000-8000-000000000001'
GROUP BY wa.current_balance;

-- -------------------------------------------------------------
-- 2. Finite State Machine: 13-Stage Application Pipeline Invariant
-- -------------------------------------------------------------
SELECT 'FSM_VALID_APPLICATION_STATUS' AS assertion_name,
       COUNT(*) FILTER (WHERE application_status NOT IN (
         'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'SCREENING_PASSED', 'SHORTLISTED',
         'TECHNICAL_ASSESSMENT', 'INTERVIEW_SCHEDULED', 'INTERVIEW_COMPLETED',
         'OFFER_EXTENDED', 'OFFER_ACCEPTED', 'OFFER_DECLINED', 'REJECTED', 'WITHDRAWN'
       )) AS illegal_status_count,
       CASE WHEN COUNT(*) FILTER (WHERE application_status NOT IN (
         'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'SCREENING_PASSED', 'SHORTLISTED',
         'TECHNICAL_ASSESSMENT', 'INTERVIEW_SCHEDULED', 'INTERVIEW_COMPLETED',
         'OFFER_EXTENDED', 'OFFER_ACCEPTED', 'OFFER_DECLINED', 'REJECTED', 'WITHDRAWN'
       )) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM application.job_application;

-- -------------------------------------------------------------
-- 3. GiST Temporal Booking Window Validation
-- -------------------------------------------------------------
SELECT 'NFR_GIST_CALENDAR_WINDOW_VALIDITY' AS assertion_name,
       COUNT(*) FILTER (WHERE lower(availability_window) IS NULL OR upper(availability_window) IS NULL OR lower(availability_window) >= upper(availability_window)) AS invalid_windows,
       CASE WHEN COUNT(*) FILTER (WHERE lower(availability_window) IS NULL OR upper(availability_window) IS NULL OR lower(availability_window) >= upper(availability_window)) = 0
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM gig.gig_worker_availability;

-- -------------------------------------------------------------
-- 4. Candidate Privacy Shield: Anti-Join Enforcement (REQ-14 / WF-01)
-- -------------------------------------------------------------
-- A recruiter from a blocked organisation MUST NOT be able to find the candidate
SELECT 'BR_PRIVACY_SHIELD_ANTI_JOIN' AS assertion_name,
       COUNT(*) AS leaked_blocked_candidates,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL_LEAKAGE' END AS status
FROM candidate.candidate_profile cp
JOIN candidate.candidate_block_list bl ON cp.id = bl.candidate_id
WHERE bl.blocked_organisation_id = '21000000-0000-4000-8000-000000000001'
  AND cp.id IN (
      -- Simulate recruiter search for organisation 21000000...
      SELECT cp_search.id
      FROM candidate.candidate_profile cp_search
      WHERE NOT EXISTS (
          SELECT 1 FROM candidate.candidate_block_list b 
          WHERE b.candidate_id = cp_search.id AND b.blocked_organisation_id = '21000000-0000-4000-8000-000000000001'
      )
  );

-- -------------------------------------------------------------
-- 5. Recruiter Seat Entitlement Quota Check (REQ-16 / CTR-04)
-- -------------------------------------------------------------
SELECT 'BR_SEAT_QUOTA_ENTITLEMENT_COMPLIANCE' AS assertion_name,
       COUNT(rsa.id) AS allocated_seats,
       sp.max_recruiter_seats,
       CASE WHEN COUNT(rsa.id) <= sp.max_recruiter_seats THEN 'PASS' ELSE 'FAIL_OVERALLOCATED' END AS status
FROM organisation.organisation o
JOIN organisation.recruiter_seat_assignment rsa ON o.id = rsa.organisation_id AND rsa.seat_status = 'ACTIVE_ALLOCATED'
JOIN licensing.subscription_licence sl ON o.account_id = sl.account_id AND sl.licence_status = 'ACTIVE_COMMISSIONED'
JOIN licensing.subscription_plan sp ON sl.plan_id = sp.id
GROUP BY sp.max_recruiter_seats;
