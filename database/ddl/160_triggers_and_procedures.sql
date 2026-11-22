-- =============================================================
-- Talentra Enterprise Workforce Platform: Triggers & Stored Procedures
-- Engine: PostgreSQL 16 Enterprise
-- =============================================================

-- -------------------------------------------------------------
-- ATOMIC DEVICE LIMIT & LOGIN PROCEDURE (Rule Group 9 / Backlog B45)
-- Fails closed if enterprise user has no active commissioned license!
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION identity.sp_enforce_user_login(
    p_user_id UUID,
    p_device_identifier VARCHAR,
    p_device_type VARCHAR,
    p_ip_address INET,
    p_user_agent TEXT,
    p_session_duration_minutes INT DEFAULT 1440
)
RETURNS TABLE (
    session_id UUID,
    login_status VARCHAR(64),
    refusal_reason TEXT
) AS $$
DECLARE
    v_user_account_id UUID;
    v_user_type VARCHAR(32);
    v_max_devices INT;
    v_active_count INT;
    v_new_session_id UUID;
BEGIN
    -- 1. Atomically lock user record to serialize concurrent logins (Rule Group 9)
    SELECT id, user_type INTO v_user_account_id, v_user_type
    FROM identity.user_account
    WHERE id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        session_id := NULL;
        login_status := 'ERR_USER_NOT_FOUND';
        refusal_reason := format('User %s does not exist', p_user_id);
        RETURN NEXT;
        RETURN;
    END IF;

    -- 2. Lookup maximum devices allowed per user under the active subscription licence
    -- First check recruiter seat assignment, then fallback to account creator
    SELECT sp.max_devices_per_user INTO v_max_devices
    FROM organisation.recruiter_seat_assignment rsa
    JOIN organisation.organisation o ON rsa.organisation_id = o.id
    JOIN licensing.subscription_licence sl ON o.account_id = sl.account_id
    JOIN licensing.subscription_plan sp ON sl.plan_id = sp.id
    WHERE rsa.user_id = p_user_id
      AND sl.licence_status = 'ACTIVE_COMMISSIONED'
    LIMIT 1;

    IF v_max_devices IS NULL THEN
        SELECT sp.max_devices_per_user INTO v_max_devices
        FROM organisation.account a
        JOIN licensing.subscription_licence sl ON a.id = sl.account_id
        JOIN licensing.subscription_plan sp ON sl.plan_id = sp.id
        WHERE a.created_by = p_user_id
          AND sl.licence_status = 'ACTIVE_COMMISSIONED'
        LIMIT 1;
    END IF;

    -- Fail-closed logic: if no active licence found, check if candidate or fail closed
    IF v_max_devices IS NULL OR v_max_devices <= 0 THEN
        IF v_user_type = 'CANDIDATE' THEN
            v_max_devices := 2; -- Standard allowance for individual candidate users
        ELSE
            -- Enterprise user with missing/expired licence: FAIL CLOSED!
            -- Record refusal in immutable audit log (Rule Group 9) and commit normally
            INSERT INTO governance.system_audit_event (
                id, actor_user_id, actor_ip, event_type, resource_entity, resource_id, tamper_hash, created_at
            ) VALUES (
                generate_uuid_v7(), p_user_id, p_ip_address, 'LOGIN_REFUSED_NO_ACTIVE_LICENCE', 'USER_ACTIVE_SESSION', p_user_id,
                encode(digest(p_user_id::text || CURRENT_TIMESTAMP::text || 'NO_LICENCE', 'sha256'), 'hex'), CURRENT_TIMESTAMP
            );

            session_id := NULL;
            login_status := 'ERR_NO_ACTIVE_LICENCE';
            refusal_reason := format('User %s has no active commissioned enterprise licence', p_user_id);
            RETURN NEXT;
            RETURN;
        END IF;
    END IF;

    -- 3. Count current active, non-expired sessions
    SELECT COUNT(*) INTO v_active_count
    FROM identity.user_active_session
    WHERE user_id = p_user_id
      AND revoked_at IS NULL
      AND expires_at > CURRENT_TIMESTAMP;

    -- 4. Check device limit breach
    IF v_active_count >= v_max_devices THEN
        -- Record security refusal in immutable audit log (Rule Group 9) and commit normally
        INSERT INTO governance.system_audit_event (
            id, actor_user_id, actor_ip, event_type, resource_entity, resource_id, tamper_hash, created_at
        ) VALUES (
            generate_uuid_v7(), p_user_id, p_ip_address, 'LOGIN_REFUSED_DEVICE_LIMIT_EXCEEDED', 'USER_ACTIVE_SESSION', p_user_id,
            encode(digest(p_user_id::text || CURRENT_TIMESTAMP::text || p_device_identifier, 'sha256'), 'hex'), CURRENT_TIMESTAMP
        );

        session_id := NULL;
        login_status := 'ERR_DEVICE_LIMIT_EXCEEDED';
        refusal_reason := format('Maximum allowed devices (%s) reached for user %s', v_max_devices, p_user_id);
        RETURN NEXT;
        RETURN;
    END IF;

    -- 5. Successfully insert new active session
    v_new_session_id := generate_uuid_v7();
    INSERT INTO identity.user_active_session (
        id, user_id, session_token_hash, device_id, device_type, client_ip, user_agent,
        started_at, last_activity_at, expires_at,
        created_at, created_by, updated_at, updated_by
    ) VALUES (
        v_new_session_id, p_user_id, encode(digest(v_new_session_id::text || CURRENT_TIMESTAMP::text, 'sha256'), 'hex'),
        p_device_identifier, p_device_type, p_ip_address, p_user_agent, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + (p_session_duration_minutes || ' minutes')::INTERVAL,
        CURRENT_TIMESTAMP, p_user_id, CURRENT_TIMESTAMP, p_user_id
    );

    session_id := v_new_session_id;
    login_status := 'SUCCESS';
    refusal_reason := NULL;
    RETURN NEXT;
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------
-- INDIA DPDP ACT 2023 CRYPTOGRAPHIC KEY-SHREDDING PROCEDURE
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION governance.sp_dpdp_crypto_shred(
    p_candidate_id UUID,
    p_actor_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE governance.pii_encryption_key
    SET is_shredded = TRUE,
        encrypted_dek = decode(repeat('00', 32), 'hex'),
        shredded_at = CURRENT_TIMESTAMP,
        shredded_by_user_id = p_actor_user_id
    WHERE user_id = (SELECT user_id FROM candidate.candidate_profile WHERE id = p_candidate_id)
      AND is_shredded = FALSE;

    UPDATE candidate.candidate_profile
    SET is_profile_searchable = FALSE,
        summary = '[DATA SHREDDED PURSUANT TO DPDP ACT 2023]',
        headline = 'Anonymized Candidate',
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_actor_user_id
    WHERE id = p_candidate_id;

    INSERT INTO governance.system_audit_event (
        id, actor_user_id, actor_ip, event_type, resource_entity, resource_id, tamper_hash, created_at
    ) VALUES (
        generate_uuid_v7(), p_actor_user_id, '127.0.0.1'::inet, 'RIGHT_TO_BE_FORGOTTEN_SHRED', 'CANDIDATE_PROFILE', p_candidate_id,
        encode(digest(p_actor_user_id::text || CURRENT_TIMESTAMP::text || p_candidate_id::text, 'sha256'), 'hex'), CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------
-- APPEND-ONLY AUDIT & LEDGER IMMUTABILITY TRIGGERS
-- -------------------------------------------------------------
CREATE TRIGGER trg_immutable_audit_events
    BEFORE UPDATE OR DELETE ON governance.system_audit_event
    FOR EACH ROW EXECUTE FUNCTION enforce_append_only();

CREATE TRIGGER trg_immutable_wallet_ledger
    BEFORE UPDATE OR DELETE ON billing.wallet_ledger
    FOR EACH ROW EXECUTE FUNCTION enforce_append_only();

CREATE TRIGGER trg_immutable_download_history
    BEFORE UPDATE OR DELETE ON billing.profile_download_history
    FOR EACH ROW EXECUTE FUNCTION enforce_append_only();

-- -------------------------------------------------------------
-- DOUBLE-ENTRY LEDGER BALANCE SYNCHRONIZATION TRIGGER
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION billing.sync_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.entry_type = 'CREDIT' THEN
        UPDATE billing.wallet_account
        SET current_balance = current_balance + NEW.amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.wallet_id;
    ELSIF NEW.entry_type = 'DEBIT' THEN
        UPDATE billing.wallet_account
        SET current_balance = current_balance - NEW.amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.wallet_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_wallet_balance_sync
    AFTER INSERT ON billing.wallet_ledger
    FOR EACH ROW EXECUTE FUNCTION billing.sync_wallet_balance();
