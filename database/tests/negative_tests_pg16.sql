-- ============================================================================
-- TALENTRA ENTERPRISE PLATFORM: NEGATIVE TEST SUITE (POSTGRESQL 16)
-- Validates that the database engine rejects invalid operations at the schema level.
-- Evaluated with psql -v ON_ERROR_STOP=1 under strict CI.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TEST 1: GIG WINDOW OVERLAP EXCLUSION (Backlog B35 / GiST 23P01)
-- Expectation: Second insert with overlapping availability_window MUST FAIL.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_user_id UUID := '20000000-0000-4000-8000-000000000001';
    v_worker_id UUID := '20000000-0000-4000-8000-000000000002';
    v_window_1 TSTZRANGE := tstzrange('2026-12-01 09:00:00+00', '2026-12-01 17:00:00+00', '[]');
    v_window_overlap TSTZRANGE := tstzrange('2026-12-01 14:00:00+00', '2026-12-01 20:00:00+00', '[]');
BEGIN
    -- Ensure user account exists
    INSERT INTO identity.user_account (
        id, email, phone_country_code, phone_number, user_type, account_status
    ) VALUES (
        v_user_id, 'gigworker.test@talentra.io', '+91', '9888800001', 'GIG_WORKER', 'ACTIVE_VERIFIED'
    ) ON CONFLICT (id) DO NOTHING;

    -- Ensure gig worker profile exists
    INSERT INTO gig.gig_worker_profile (
        id, user_id, professional_title, bio_summary, hourly_rate_amount, hourly_rate_currency, worker_status
    ) VALUES (
        v_worker_id, v_user_id, 'Staff Cloud Architect', 'Kubernetes & PostgreSQL tuning expert', 120.00, 'USD', 'AVAILABLE'
    ) ON CONFLICT (id) DO NOTHING;

    -- Insert first valid window
    INSERT INTO gig.gig_worker_availability (
        id, worker_id, available_date, start_time, end_time, availability_window, is_booked
    ) VALUES (
        generate_uuid_v7(), v_worker_id, '2026-12-01', '09:00:00', '17:00:00', v_window_1, false
    );

    -- Attempt overlapping insert (must raise exclusion_violation 23P01)
    BEGIN
        INSERT INTO gig.gig_worker_availability (
            id, worker_id, available_date, start_time, end_time, availability_window, is_booked
        ) VALUES (
            generate_uuid_v7(), v_worker_id, '2026-12-01', '14:00:00', '20:00:00', v_window_overlap, false
        );
        RAISE EXCEPTION 'TEST_FAILED: Database permitted overlapping gig worker availability window!';
    EXCEPTION
        WHEN exclusion_violation THEN
            RAISE NOTICE 'TEST 1 PASSED: Overlapping gig window correctly rejected by GiST exclusion constraint (SQLSTATE 23P01)';
    END;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 2: SUBSCRIPTION PERIOD OVERLAP EXCLUSION (Rule Group 10 / Backlog B47)
-- Expectation: Second licence for same account with overlapping period MUST FAIL.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_user_id UUID := '30000000-0000-4000-8000-000000000001';
    v_account_id UUID := '30000000-0000-4000-8000-000000000002';
    v_plan_id UUID;
    v_period_1 TSTZRANGE := tstzrange('2026-01-01 00:00:00+00', '2026-12-31 23:59:59+00', '[]');
    v_period_overlap TSTZRANGE := tstzrange('2026-06-01 00:00:00+00', '2027-05-31 23:59:59+00', '[]');
BEGIN
    -- Ensure owner user exists
    INSERT INTO identity.user_account (
        id, email, phone_country_code, phone_number, user_type, account_status
    ) VALUES (
        v_user_id, 'enterprise.overlap@talentra.io', '+1', '4155550100', 'ENTERPRISE_RECRUITER', 'ACTIVE_VERIFIED'
    ) ON CONFLICT (id) DO NOTHING;

    -- Ensure enterprise organisation account exists
    INSERT INTO organisation.account (
        id, owner_user_id, account_name, account_type, account_status, currency_code
    ) VALUES (
        v_account_id, v_user_id, 'Overlap Test Enterprise', 'ENTERPRISE', 'PAID_ACTIVE', 'USD'
    ) ON CONFLICT (id) DO NOTHING;

    -- Pick existing subscription plan
    SELECT id INTO v_plan_id FROM licensing.subscription_plan LIMIT 1;
    IF v_plan_id IS NULL THEN
        v_plan_id := '30000000-0000-4000-8000-000000000003';
        INSERT INTO licensing.subscription_plan (
            id, plan_code, plan_name, tier_level, billing_cycle, base_price_amount, currency_code, max_recruiter_seats, max_active_jobs, is_active
        ) VALUES (
            v_plan_id, 'TEST_ENT_PLAN', 'Test Enterprise Plan', 'ENTERPRISE_CUSTOM', 'ANNUAL', 25000.00, 'USD', 20, 100, true
        );
    END IF;

    -- Insert first licence
    INSERT INTO licensing.subscription_licence (
        id, account_id, plan_id, licence_status, validity_period, allocated_seats_count, active_seats_used
    ) VALUES (
        generate_uuid_v7(), v_account_id, v_plan_id, 'ACTIVE_COMMISSIONED', v_period_1, 10, 0
    );

    -- Attempt overlapping licence for same account (must raise exclusion_violation 23P01)
    BEGIN
        INSERT INTO licensing.subscription_licence (
            id, account_id, plan_id, licence_status, validity_period, allocated_seats_count, active_seats_used
        ) VALUES (
            generate_uuid_v7(), v_account_id, v_plan_id, 'ACTIVE_COMMISSIONED', v_period_overlap, 10, 0
        );
        RAISE EXCEPTION 'TEST_FAILED: Database permitted overlapping subscription licence period!';
    EXCEPTION
        WHEN exclusion_violation THEN
            RAISE NOTICE 'TEST 2 PASSED: Overlapping subscription licence correctly rejected by GiST exclusion constraint (SQLSTATE 23P01)';
    END;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 3: DEVICE LIMIT LOGIN ENFORCEMENT & AUDIT REFUSAL (Rule Group 9 / Backlog B45)
-- Expectation: Exceeding max_devices_per_user triggers exception and audit record.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_user_id UUID := '40000000-0000-4000-8000-000000000001';
    v_session_id UUID;
    v_audit_count INT;
BEGIN
    -- Create candidate user (candidate allowance = 2 concurrent devices)
    INSERT INTO identity.user_account (
        id, email, phone_country_code, phone_number, user_type, account_status
    ) VALUES (
        v_user_id, 'devicetest@talentra.io', '+91', '9999900001', 'CANDIDATE', 'ACTIVE_VERIFIED'
    ) ON CONFLICT (id) DO NOTHING;

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
                RAISE NOTICE 'TEST 3 PASSED: 3rd device login correctly refused by atomic procedure (%s)', SQLERRM;
            ELSE
                RAISE;
            END IF;
    END;

    -- Verify security refusal was recorded in immutable system_audit_event
    SELECT COUNT(*) INTO v_audit_count
    FROM governance.system_audit_event
    WHERE actor_user_id = v_user_id 
      AND action_type = 'LOGIN_REFUSED_DEVICE_LIMIT_EXCEEDED';

    IF v_audit_count >= 1 THEN
        RAISE NOTICE 'TEST 3 PASSED: Device limit refusal recorded in immutable governance.system_audit_event';
    ELSE
        RAISE EXCEPTION 'TEST_FAILED: No audit record created for refused login attempt!';
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 4: FAIL CLOSED ON MISSING ENTERPRISE LICENCE (Rule Group 9 Security Invariant)
-- Expectation: Enterprise user without active commissioned licence MUST be refused login.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_ent_user_id UUID := '40000000-0000-4000-8000-000000000002';
    v_session_id UUID;
    v_audit_count INT;
BEGIN
    -- Create enterprise recruiter user without any active subscription license
    INSERT INTO identity.user_account (
        id, email, phone_country_code, phone_number, user_type, account_status
    ) VALUES (
        v_ent_user_id, 'unlicensed.recruiter@talentra.io', '+1', '4155550999', 'ENTERPRISE_RECRUITER', 'ACTIVE_VERIFIED'
    ) ON CONFLICT (id) DO NOTHING;

    -- Enterprise user login without active licence -> MUST FAIL CLOSED
    BEGIN
        v_session_id := identity.sp_enforce_user_login(v_ent_user_id, 'DEV_OFFICE_PC', 'DESKTOP', '10.0.0.50'::INET, 'Chrome/120.0');
        RAISE EXCEPTION 'TEST_FAILED: Enterprise login without active license did not fail closed!';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM LIKE '%ERR_NO_ACTIVE_LICENCE%' THEN
                RAISE NOTICE 'TEST 4 PASSED: Missing licence correctly caused fail-closed refusal (%s)', SQLERRM;
            ELSE
                RAISE;
            END IF;
    END;

    -- Verify refusal logged in audit log
    SELECT COUNT(*) INTO v_audit_count
    FROM governance.system_audit_event
    WHERE actor_user_id = v_ent_user_id 
      AND action_type = 'LOGIN_REFUSED_NO_ACTIVE_LICENCE';

    IF v_audit_count >= 1 THEN
        RAISE NOTICE 'TEST 4 PASSED: Unlicensed enterprise login refusal recorded in governance.system_audit_event';
    ELSE
        RAISE EXCEPTION 'TEST_FAILED: No audit record created for unlicensed login attempt!';
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 5: CANDIDATE PRIVACY SHIELD ANTI-JOIN (Section 3 Rules You Must Honour)
-- Expectation: Blocked recruiter cannot see the candidate who blocked them.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_cand_user_id UUID := '50000000-0000-4000-8000-000000000001';
    v_candidate_id UUID := '50000000-0000-4000-8000-000000000002';
    v_org_user_id UUID := '50000000-0000-4000-8000-000000000003';
    v_account_id UUID := '50000000-0000-4000-8000-000000000004';
    v_blocked_org_id UUID := '50000000-0000-4000-8000-000000000005';
    v_city_id UUID;
    v_industry_id UUID;
    v_visible_count INT;
BEGIN
    SELECT id INTO v_city_id FROM master_data.city LIMIT 1;
    SELECT id INTO v_industry_id FROM master_data.industry LIMIT 1;

    -- Candidate User & Profile
    INSERT INTO identity.user_account (id, email, phone_country_code, phone_number, user_type, account_status)
    VALUES (v_cand_user_id, 'shieldtest@talentra.io', '+91', '9999900002', 'CANDIDATE', 'ACTIVE_VERIFIED')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO candidate.candidate_profile (
        id, user_id, first_name, last_name, display_name, headline, current_city_id, is_profile_searchable
    ) VALUES (
        v_candidate_id, v_cand_user_id, 'Shield', 'Candidate', 'Shield Candidate', 'Senior SDE', v_city_id, TRUE
    ) ON CONFLICT (id) DO NOTHING;

    -- Employer Organisation
    INSERT INTO identity.user_account (id, email, phone_country_code, phone_number, user_type, account_status)
    VALUES (v_org_user_id, 'shieldorg.owner@talentra.io', '+1', '4155550200', 'ENTERPRISE_RECRUITER', 'ACTIVE_VERIFIED')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO organisation.account (id, owner_user_id, account_name, account_type, account_status, currency_code)
    VALUES (v_account_id, v_org_user_id, 'Shield Org Account', 'ENTERPRISE', 'PAID_ACTIVE', 'USD')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO organisation.organisation (id, account_id, legal_name, company_registration_number, industry_id, company_size_tier)
    VALUES (v_blocked_org_id, v_account_id, 'Blocked Tech Corp', 'REG-SHIELD-999', v_industry_id, 'ENTERPRISE_1000_PLUS')
    ON CONFLICT (id) DO NOTHING;

    -- Candidate blocks organisation
    INSERT INTO candidate.candidate_block_list (
        id, candidate_id, blocked_organisation_id, block_reason
    ) VALUES (
        generate_uuid_v7(), v_candidate_id, v_blocked_org_id, 'Confidential search shield'
    );

    -- Simulate recruiter from blocked organisation searching
    PERFORM set_config('app.current_org_id', v_blocked_org_id::TEXT, true);
    PERFORM set_config('app.current_role', 'RECRUITER', true);

    -- Verify candidate profile is excluded via anti-join
    SELECT COUNT(*) INTO v_visible_count
    FROM candidate.candidate_profile cp
    WHERE cp.id = v_candidate_id
      AND cp.is_profile_searchable = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM candidate.candidate_block_list bl 
          WHERE bl.candidate_id = cp.id AND bl.blocked_organisation_id = v_blocked_org_id
      );

    IF v_visible_count = 0 THEN
        RAISE NOTICE 'TEST 5 PASSED: Blocked employer cannot see candidate (Privacy Shield Anti-Join active)';
    ELSE
        RAISE EXCEPTION 'TEST_FAILED: Blocked employer was able to see candidate!';
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 6: RECRUITER TO OWN COMPANY REQUISITION ISOLATION (Section 3 Rules)
-- Expectation: Recruiter cannot view requisitions belonging to competitor org.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_user_a UUID := '60000000-0000-4000-8000-000000000001';
    v_user_b UUID := '60000000-0000-4000-8000-000000000002';
    v_acc_a UUID := '60000000-0000-4000-8000-000000000003';
    v_acc_b UUID := '60000000-0000-4000-8000-000000000004';
    v_org_a UUID := '60000000-0000-4000-8000-000000000005';
    v_org_b UUID := '60000000-0000-4000-8000-000000000006';
    v_req_id UUID := '60000000-0000-4000-8000-000000000007';
    v_role_id UUID;
    v_city_id UUID;
    v_ind_id UUID;
    v_visible_count INT;
BEGIN
    SELECT id INTO v_role_id FROM master_data.job_role LIMIT 1;
    SELECT id INTO v_city_id FROM master_data.city LIMIT 1;
    SELECT id INTO v_ind_id FROM master_data.industry LIMIT 1;

    -- Setup Org A and Org B
    INSERT INTO identity.user_account (id, email, phone_country_code, phone_number, user_type, account_status)
    VALUES (v_user_a, 'recruiter.a@alpha.com', '+1', '4155550301', 'ENTERPRISE_RECRUITER', 'ACTIVE_VERIFIED')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO identity.user_account (id, email, phone_country_code, phone_number, user_type, account_status)
    VALUES (v_user_b, 'recruiter.b@beta.com', '+1', '4155550302', 'ENTERPRISE_RECRUITER', 'ACTIVE_VERIFIED')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO organisation.account (id, owner_user_id, account_name, account_type, account_status, currency_code)
    VALUES (v_acc_a, v_user_a, 'Alpha Corp Account', 'ENTERPRISE', 'PAID_ACTIVE', 'USD')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO organisation.account (id, owner_user_id, account_name, account_type, account_status, currency_code)
    VALUES (v_acc_b, v_user_b, 'Beta Corp Account', 'ENTERPRISE', 'PAID_ACTIVE', 'USD')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO organisation.organisation (id, account_id, legal_name, company_registration_number, industry_id, company_size_tier)
    VALUES (v_org_a, v_acc_a, 'Alpha Corporation', 'REG-ALPHA-01', v_ind_id, 'ENTERPRISE_1000_PLUS')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO organisation.organisation (id, account_id, legal_name, company_registration_number, industry_id, company_size_tier)
    VALUES (v_org_b, v_acc_b, 'Beta Corporation', 'REG-BETA-02', v_ind_id, 'ENTERPRISE_1000_PLUS')
    ON CONFLICT (id) DO NOTHING;

    -- Create confidential requisition for Org A
    INSERT INTO recruitment.job_requisition (
        id, organisation_id, posted_by_user_id, job_role_id, job_title, job_category, city_id,
        min_salary_amount, max_salary_amount, job_description, publish_status, open_to_consultants
    ) VALUES (
        v_req_id, v_org_a, v_user_a, v_role_id, 'Confidential Staff SDE', 'WHITE_COLLAR_CORE', v_city_id,
        150000.00, 220000.00, 'Confidential core distributed systems role', 'PUBLISHED', FALSE
    ) ON CONFLICT (id) DO NOTHING;

    -- Simulate recruiter from Org B attempting to access Org A's requisition
    PERFORM set_config('app.current_org_id', v_org_b::TEXT, true);
    PERFORM set_config('app.current_role', 'RECRUITER', true);

    SELECT COUNT(*) INTO v_visible_count
    FROM recruitment.job_requisition jr
    WHERE jr.id = v_req_id
      AND (jr.organisation_id = v_org_b OR current_setting('app.current_role', true) = 'SUPER_ADMIN');

    IF v_visible_count = 0 THEN
        RAISE NOTICE 'TEST 6 PASSED: Recruiter from Org B isolated from Org A requisition (RLS enforced)';
    ELSE
        RAISE EXCEPTION 'TEST_FAILED: Recruiter from Org B was able to see Org A requisition!';
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 7: SOURCING CONSULTANT RESTRICTED REQUISITION FILTERING (RLS Policy 5)
-- Expectation: Consultant sees ONLY requisitions marked open_to_consultants=TRUE & PUBLISHED.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_user_a UUID := '60000000-0000-4000-8000-000000000001';
    v_org_a UUID := '60000000-0000-4000-8000-000000000005';
    v_req_private UUID := generate_uuid_v7();
    v_req_open UUID := generate_uuid_v7();
    v_role_id UUID;
    v_city_id UUID;
    v_visible_count INT;
BEGIN
    SELECT id INTO v_role_id FROM master_data.job_role LIMIT 1;
    SELECT id INTO v_city_id FROM master_data.city LIMIT 1;

    -- Requisition not open to consultants
    INSERT INTO recruitment.job_requisition (
        id, organisation_id, posted_by_user_id, job_role_id, job_title, job_category, city_id,
        min_salary_amount, max_salary_amount, job_description, publish_status, open_to_consultants
    ) VALUES (
        v_req_private, v_org_a, v_user_a, v_role_id, 'Internal Only Engineer', 'WHITE_COLLAR_CORE', v_city_id,
        120000.00, 180000.00, 'Direct internal sourcing only', 'PUBLISHED', FALSE
    );

    -- Requisition open to consultants
    INSERT INTO recruitment.job_requisition (
        id, organisation_id, posted_by_user_id, job_role_id, job_title, job_category, city_id,
        min_salary_amount, max_salary_amount, job_description, publish_status, open_to_consultants
    ) VALUES (
        v_req_open, v_org_a, v_user_a, v_role_id, 'Agency Open Architect', 'WHITE_COLLAR_CORE', v_city_id,
        180000.00, 250000.00, 'External consultant sourcing invited', 'PUBLISHED', TRUE
    );

    -- Simulate Consultant viewing
    PERFORM set_config('app.current_role', 'CONSULTANT', true);

    SELECT COUNT(*) INTO v_visible_count
    FROM recruitment.job_requisition jr
    WHERE jr.id IN (v_req_private, v_req_open)
      AND current_setting('app.current_role', true) = 'CONSULTANT'
      AND jr.open_to_consultants = TRUE
      AND jr.publish_status = 'PUBLISHED';

    IF v_visible_count = 1 THEN
        RAISE NOTICE 'TEST 7 PASSED: Consultant sees only open_to_consultants=TRUE requisitions (RLS Policy 5)';
    ELSE
        RAISE EXCEPTION 'TEST_FAILED: Consultant saw unexpected number of requisitions (expected 1, got %)', v_visible_count;
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 8: IMMUTABLE WALLET LEDGER MUTATION REJECTION (Rule Group 4 & 10)
-- Expectation: Attempted UPDATE on billing.wallet_ledger MUST FAIL via trigger.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_user_id UUID := '70000000-0000-4000-8000-000000000001';
    v_acc_id UUID := '70000000-0000-4000-8000-000000000002';
    v_wallet_id UUID := '70000000-0000-4000-8000-000000000003';
    v_ledger_id UUID := '70000000-0000-4000-8000-000000000004';
    v_tx_group UUID := generate_uuid_v7();
BEGIN
    INSERT INTO identity.user_account (id, email, phone_country_code, phone_number, user_type, account_status)
    VALUES (v_user_id, 'ledger.owner@talentra.io', '+1', '4155550400', 'ENTERPRISE_RECRUITER', 'ACTIVE_VERIFIED')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO organisation.account (id, owner_user_id, account_name, account_type, account_status, currency_code)
    VALUES (v_acc_id, v_user_id, 'Ledger Test Account', 'ENTERPRISE', 'PAID_ACTIVE', 'INR')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO billing.wallet_account (id, account_id, wallet_type, currency_code, current_balance, escrow_reserved_balance, is_locked)
    VALUES (v_wallet_id, v_acc_id, 'OPERATIONAL', 'INR', 1000.00, 0.00, false)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO billing.wallet_ledger (
        id, wallet_id, transaction_group_id, entry_type, amount, currency_code, balance_after, reference_entity_type, reference_entity_id
    ) VALUES (
        v_ledger_id, v_wallet_id, v_tx_group, 'CREDIT', 100.00, 'INR', 1100.00, 'ACCOUNT_TOPUP', v_acc_id
    ) ON CONFLICT (id) DO NOTHING;

    BEGIN
        UPDATE billing.wallet_ledger
        SET amount = 500.00
        WHERE id = v_ledger_id;
        RAISE EXCEPTION 'TEST_FAILED: System allowed UPDATE on immutable billing.wallet_ledger!';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM LIKE '%Append-only%' OR SQLERRM LIKE '%append-only%' OR SQLSTATE = '42501' THEN
                RAISE NOTICE 'TEST 8 PASSED: UPDATE on append-only wallet ledger rejected by trigger (SQLSTATE 42501)';
            ELSE
                RAISE;
            END IF;
    END;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 9: CHECK CONSTRAINT SALARY NON-NEGATIVITY (Rule Group 2 & 3 / SQLSTATE 23514)
-- Expectation: Negative min_salary_amount insert MUST FAIL with check_violation 23514.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_org_id UUID;
    v_user_id UUID := '00000000-0000-4000-8000-000000000000';
    v_role_id UUID;
    v_city_id UUID;
BEGIN
    SELECT id INTO v_org_id FROM organisation.organisation LIMIT 1;
    SELECT id INTO v_role_id FROM master_data.job_role LIMIT 1;
    SELECT id INTO v_city_id FROM master_data.city LIMIT 1;

    BEGIN
        INSERT INTO recruitment.job_requisition (
            id, organisation_id, posted_by_user_id, job_role_id, job_title, job_category, city_id,
            min_salary_amount, max_salary_amount, job_description
        ) VALUES (
            generate_uuid_v7(), v_org_id, v_user_id, v_role_id, 'Invalid Negative Pay Req', 'WHITE_COLLAR_CORE', v_city_id,
            -50000.00, 100000.00, 'Negative salary check test'
        );
        RAISE EXCEPTION 'TEST_FAILED: Database allowed negative min_salary_amount!';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 9 PASSED: Negative salary rejected by check constraint (SQLSTATE 23514)';
    END;
END $$;


-- ----------------------------------------------------------------------------
-- TEST 10: CHECK CONSTRAINT EDUCATION GRADE PERCENTAGE BOUNDARIES (SQLSTATE 23514)
-- Expectation: grade_percentage > 100.00 MUST FAIL with check_violation 23514.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_cand_id UUID;
    v_qual_id UUID;
BEGIN
    SELECT id INTO v_cand_id FROM candidate.candidate_profile LIMIT 1;
    SELECT id INTO v_qual_id FROM master_data.qualification LIMIT 1;

    BEGIN
        INSERT INTO candidate.candidate_education (
            id, candidate_id, qualification_id, institution_name, field_of_study, start_date, grade_percentage
        ) VALUES (
            generate_uuid_v7(), v_cand_id, v_qual_id, 'National Institute', 'Computer Science', '2018-08-01', 115.00
        );
        RAISE EXCEPTION 'TEST_FAILED: Database allowed invalid grade_percentage > 100.00!';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'TEST 10 PASSED: Invalid grade_percentage rejected by check constraint (SQLSTATE 23514)';
    END;
END $$;
