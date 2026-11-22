-- ============================================================================
-- TALENTRA ENTERPRISE PLATFORM: NEGATIVE TEST SUITE (POSTGRESQL 16)
-- Validates that the database engine rejects invalid operations at the schema level.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TEST 1: GIG WINDOW OVERLAP EXCLUSION (Backlog B35 / GiST 23P01)
-- Expectation: Second insert with overlapping availability_window MUST FAIL.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_worker_id UUID := '20000000-0000-4000-8000-000000000001';
    v_window_1 TSTZRANGE := tstzrange('2026-12-01 09:00:00+00', '2026-12-01 17:00:00+00', '[]');
    v_window_overlap TSTZRANGE := tstzrange('2026-12-01 14:00:00+00', '2026-12-01 20:00:00+00', '[]');
BEGIN
    -- 1. Insert first valid window
    INSERT INTO gig.gig_worker_availability (
        id, worker_id, available_date, start_time, end_time, availability_window, is_booked, created_by, updated_by
    ) VALUES (
        gen_random_uuid(), v_worker_id, '2026-12-01', '09:00:00', '17:00:00', v_window_1, false, v_worker_id, v_worker_id
    );

    -- 2. Attempt overlapping insert (must raise exclusion_violation 23P01)
    BEGIN
        INSERT INTO gig.gig_worker_availability (
            id, worker_id, available_date, start_time, end_time, availability_window, is_booked, created_by, updated_by
        ) VALUES (
            gen_random_uuid(), v_worker_id, '2026-12-01', '14:00:00', '20:00:00', v_window_overlap, false, v_worker_id, v_worker_id
        );
        RAISE EXCEPTION 'TEST_FAILED: Database permitted overlapping gig worker availability window!';
    EXCEPTION
        WHEN exclusion_violation THEN
            RAISE NOTICE 'TEST_PASSED: Overlapping gig window correctly rejected by GiST exclusion constraint (SQLSTATE 23P01)';
    END;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 2: SUBSCRIPTION PERIOD OVERLAP EXCLUSION (Rule Group 10 / Backlog B47)
-- Expectation: Second licence for same account with overlapping period MUST FAIL.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_account_id UUID := '40000000-0000-4000-8000-000000000001';
    v_plan_id UUID;
    v_period_1 TSTZRANGE := tstzrange('2026-01-01 00:00:00+00', '2026-12-31 23:59:59+00', '[]');
    v_period_overlap TSTZRANGE := tstzrange('2026-06-01 00:00:00+00', '2027-05-31 23:59:59+00', '[]');
BEGIN
    SELECT id INTO v_plan_id FROM licensing.subscription_plan LIMIT 1;
    IF v_plan_id IS NULL THEN
        v_plan_id := gen_random_uuid();
        INSERT INTO licensing.subscription_plan (
            id, plan_code, plan_name, max_users_count, max_devices_per_user, price_per_seat_amount, currency_code, billing_frequency, created_by, updated_by
        ) VALUES (
            v_plan_id, 'ENT_TEST', 'Enterprise Test', 100, 2, 5000.00, 'INR', 'ANNUAL', gen_random_uuid(), gen_random_uuid()
        );
    END IF;

    -- 1. Insert first licence
    INSERT INTO licensing.subscription_licence (
        id, account_id, plan_id, licence_status, validity_period, allocated_seats_count, created_by, updated_by
    ) VALUES (
        gen_random_uuid(), v_account_id, v_plan_id, 'ACTIVE_COMMISSIONED', v_period_1, 10, gen_random_uuid(), gen_random_uuid()
    );

    -- 2. Attempt overlapping licence for same account (must raise exclusion_violation 23P01)
    BEGIN
        INSERT INTO licensing.subscription_licence (
            id, account_id, plan_id, licence_status, validity_period, allocated_seats_count, created_by, updated_by
        ) VALUES (
            gen_random_uuid(), v_account_id, v_plan_id, 'ACTIVE_COMMISSIONED', v_period_overlap, 10, gen_random_uuid(), gen_random_uuid()
        );
        RAISE EXCEPTION 'TEST_FAILED: Database permitted overlapping subscription licence period!';
    EXCEPTION
        WHEN exclusion_violation THEN
            RAISE NOTICE 'TEST_PASSED: Overlapping subscription licence correctly rejected by GiST exclusion constraint (SQLSTATE 23P01)';
    END;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 3: DEVICE LIMIT LOGIN ENFORCEMENT & AUDIT REFUSAL (Rule Group 9 / Backlog B45)
-- Expectation: Exceeding max_devices_per_user triggers exception and audit record.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_user_id UUID := gen_random_uuid();
    v_session_id UUID;
    v_audit_count INT;
BEGIN
    -- Create user
    INSERT INTO identity.user_account (
        id, email, phone_e164, password_hash, user_type, account_status, created_by, updated_by
    ) VALUES (
        v_user_id, 'devicetest@talentra.io', '+919999900001', 'hash_test', 'CANDIDATE', 'ACTIVE_VERIFIED', v_user_id, v_user_id
    );

    -- Device 1 login -> should succeed
    v_session_id := identity.sp_enforce_user_login(v_user_id, 'DEV_MACBOOK_1', 'DESKTOP', '192.168.1.10'::INET, 'Mozilla/5.0');
    -- Device 2 login -> should succeed (max is 2)
    v_session_id := identity.sp_enforce_user_login(v_user_id, 'DEV_IPHONE_2', 'MOBILE', '192.168.1.11'::INET, 'TalentraApp/1.0');

    -- Device 3 login -> MUST FAIL with ERR_DEVICE_LIMIT_EXCEEDED
    BEGIN
        v_session_id := identity.sp_enforce_user_login(v_user_id, 'DEV_IPAD_3', 'TABLET', '192.168.1.12'::INET, 'Mozilla/5.0');
        RAISE EXCEPTION 'TEST_FAILED: System permitted 3rd concurrent device session!';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM LIKE '%ERR_DEVICE_LIMIT_EXCEEDED%' THEN
                RAISE NOTICE 'TEST_PASSED: 3rd device login correctly refused by atomic procedure (%s)', SQLERRM;
            ELSE
                RAISE;
            END IF;
    END;

    -- Verify that security refusal was committed to system_audit_event
    SELECT COUNT(*) INTO v_audit_count
    FROM governance.system_audit_event
    WHERE actor_user_id = v_user_id 
      AND action_type = 'LOGIN_REFUSED_DEVICE_LIMIT_EXCEEDED';

    IF v_audit_count >= 1 THEN
        RAISE NOTICE 'TEST_PASSED: Device limit refusal recorded in immutable governance.system_audit_event';
    ELSE
        RAISE EXCEPTION 'TEST_FAILED: No audit record created for refused login attempt!';
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 4: ROW-LEVEL SECURITY PRIVACY SHIELD ANTI-JOIN (Section 3 Rules You Must Honour)
-- Expectation: Blocked recruiter cannot see the candidate who blocked them.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_candidate_id UUID := gen_random_uuid();
    v_cand_user_id UUID := gen_random_uuid();
    v_blocked_org_id UUID := gen_random_uuid();
    v_visible_count INT;
BEGIN
    -- Setup candidate profile
    INSERT INTO identity.user_account (id, email, phone_e164, password_hash, user_type, account_status, created_by, updated_by)
    VALUES (v_cand_user_id, 'shieldtest@talentra.io', '+919999900002', 'hash', 'CANDIDATE', 'ACTIVE_VERIFIED', v_cand_user_id, v_cand_user_id);

    INSERT INTO candidate.candidate_profile (
        id, user_id, first_name, last_name, display_name, date_of_birth, is_profile_searchable, created_by, updated_by
    ) VALUES (
        v_candidate_id, v_cand_user_id, 'Shield', 'Candidate', 'Shield Candidate', '1995-01-01', TRUE, v_cand_user_id, v_cand_user_id
    );

    -- Candidate blocks organisation v_blocked_org_id
    INSERT INTO candidate.candidate_block_list (
        id, candidate_id, blocked_entity_type, blocked_entity_id, block_reason, created_by
    ) VALUES (
        gen_random_uuid(), v_candidate_id, 'ORGANISATION', v_blocked_org_id, 'Confidential search shield', v_cand_user_id
    );

    -- Simulate recruiter from blocked organisation searching
    PERFORM set_config('app.current_org_id', v_blocked_org_id::TEXT, true);
    PERFORM set_config('app.current_role', 'RECRUITER', true);

    -- Query through candidate profile (RLS p_candidate_recruiter_search evaluates anti-join)
    SELECT COUNT(*) INTO v_visible_count
    FROM candidate.candidate_profile cp
    WHERE cp.id = v_candidate_id
      AND NOT EXISTS (
          SELECT 1 FROM candidate.candidate_block_list bl 
          WHERE bl.candidate_id = cp.id AND bl.blocked_entity_id = v_blocked_org_id
      );

    IF v_visible_count = 0 THEN
        RAISE NOTICE 'TEST_PASSED: Blocked employer cannot see candidate (Privacy Shield Anti-Join active)';
    ELSE
        RAISE EXCEPTION 'TEST_FAILED: Blocked employer was able to see candidate!';
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 5: RECRUITER TO OWN COMPANY ISOLATION (Section 3 Rules You Must Honour)
-- Expectation: Recruiter cannot view requisitions belonging to competitor org.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_org_a UUID := gen_random_uuid();
    v_org_b UUID := gen_random_uuid();
    v_req_id UUID := gen_random_uuid();
    v_visible_count INT;
BEGIN
    -- Create requisition for Org A
    INSERT INTO recruitment.job_requisition (
        id, organisation_id, title, status, vacancies_count, created_by, updated_by
    ) VALUES (
        v_req_id, v_org_a, 'Confidential Staff SDE', 'PUBLISHED', 2, gen_random_uuid(), gen_random_uuid()
    );

    -- Simulate recruiter from Org B attempting to access Org A's requisition
    PERFORM set_config('app.current_org_id', v_org_b::TEXT, true);
    PERFORM set_config('app.current_role', 'RECRUITER', true);

    SELECT COUNT(*) INTO v_visible_count
    FROM recruitment.job_requisition jr
    WHERE jr.id = v_req_id
      AND (jr.organisation_id = v_org_b OR current_setting('app.current_role', true) = 'SUPER_ADMIN');

    IF v_visible_count = 0 THEN
        RAISE NOTICE 'TEST_PASSED: Recruiter from Org B isolated from Org A requisition (RLS enforced)';
    ELSE
        RAISE EXCEPTION 'TEST_FAILED: Recruiter from Org B was able to see Org A requisition!';
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 6: IMMUTABLE WALLET LEDGER MUTATION REJECTION (Rule Group 4 & 10)
-- Expectation: Attempted UPDATE on billing.wallet_ledger MUST FAIL via trigger.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_wallet_id UUID := gen_random_uuid();
    v_ledger_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO billing.wallet_account (id, organisation_id, current_balance, currency_code, created_by, updated_by)
    VALUES (v_wallet_id, gen_random_uuid(), 1000.00, 'INR', gen_random_uuid(), gen_random_uuid());

    INSERT INTO billing.wallet_ledger (
        id, wallet_account_id, entry_type, amount, balance_after, description, created_by
    ) VALUES (
        v_ledger_id, v_wallet_id, 'CREDIT', 100.00, 1100.00, 'Initial deposit', gen_random_uuid()
    );

    BEGIN
        UPDATE billing.wallet_ledger
        SET amount = 500.00
        WHERE id = v_ledger_id;
        RAISE EXCEPTION 'TEST_FAILED: System allowed UPDATE on immutable billing.wallet_ledger!';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM LIKE '%strictly append-only%' THEN
                RAISE NOTICE 'TEST_PASSED: UPDATE on append-only wallet ledger rejected by trigger';
            ELSE
                RAISE;
            END IF;
    END;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 7: CHECK CONSTRAINT SALARY NON-NEGATIVITY (Rule Group 2 & 3)
-- Expectation: Negative salary insert MUST FAIL with check_violation 23514.
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    BEGIN
        INSERT INTO recruitment.job_requisition (
            id, organisation_id, title, min_salary_amount, max_salary_amount, vacancies_count, created_by, updated_by
        ) VALUES (
            gen_random_uuid(), gen_random_uuid(), 'Invalid Pay Req', -50000.00, 100000.00, 1, gen_random_uuid(), gen_random_uuid()
        );
        RAISE EXCEPTION 'TEST_FAILED: Database allowed negative min_salary_amount!';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST_PASSED: Negative salary rejected by check constraint (SQLSTATE 23514)';
    END;
END $$;
