-- =============================================================
-- Talentra Enterprise Workforce Platform: Triggers & Stored Procedures
-- Engine: PostgreSQL 16 Enterprise
-- =============================================================

-- -------------------------------------------------------------
-- ATOMIC DEVICE LIMIT & LOGIN PROCEDURE (Rule Group 9 / Backlog B45)
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION identity.sp_enforce_user_login(
    p_user_id UUID,
    p_device_identifier VARCHAR,
    p_device_type VARCHAR,
    p_ip_address INET,
    p_user_agent TEXT,
    p_session_duration_minutes INT DEFAULT 1440
)
RETURNS UUID AS $$
DECLARE
    v_user_account_id UUID;
    v_max_devices INT := 3;
    v_active_count INT;
    v_new_session_id UUID;
BEGIN
    -- 1. Atomically lock user record to serialize concurrent logins (Rule Group 9)
    SELECT id INTO v_user_account_id
    FROM identity.user_account
    WHERE id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ERR_USER_NOT_FOUND: User % does not exist', p_user_id;
    END IF;

    -- 2. Lookup maximum devices allowed per user under the active subscription licence
    SELECT sp.max_devices_per_user INTO v_max_devices
    FROM organisation.account a
    JOIN licensing.subscription_licence sl ON a.id = sl.account_id
    JOIN licensing.subscription_plan sp ON sl.plan_id = sp.id
    WHERE a.owner_user_id = p_user_id
      AND sl.licence_status = 'ACTIVE_COMMISSIONED'
    LIMIT 1;

    IF v_max_devices IS NULL OR v_max_devices <= 0 THEN
        v_max_devices := 2; -- Default individual candidate limit
    END IF;

    -- 3. Count current active, non-expired sessions
    SELECT COUNT(*) INTO v_active_count
    FROM identity.user_active_session
    WHERE user_id = p_user_id
      AND is_active = TRUE
      AND expires_at > CURRENT_TIMESTAMP;

    -- 4. Check device limit breach
    IF v_active_count >= v_max_devices THEN
        -- Record security refusal in immutable audit log (Rule Group 9)
        INSERT INTO governance.system_audit_event (
            id,
            actor_user_id,
            action_type,
            resource_type,
            resource_id,
            ip_address,
            event_timestamp,
            created_at,
            created_by
        )
        VALUES (
            gen_random_uuid(),
            p_user_id,
            'LOGIN_REFUSED_DEVICE_LIMIT_EXCEEDED',
            'USER_ACTIVE_SESSION',
            p_user_id,
            p_ip_address,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP,
            p_user_id
        );

        RAISE EXCEPTION 'ERR_DEVICE_LIMIT_EXCEEDED: Maximum allowed devices (%) reached for user %', v_max_devices, p_user_id;
    END IF;

    -- 5. Successfully insert new active session
    v_new_session_id := gen_random_uuid();
    INSERT INTO identity.user_active_session (
        id,
        user_id,
        session_token_hash,
        device_identifier,
        ip_address,
        user_agent,
        login_timestamp,
        last_activity_timestamp,
        expires_at,
        is_active,
        created_at,
        created_by,
        updated_at,
        updated_by
    )
    VALUES (
        v_new_session_id,
        p_user_id,
        encode(digest(v_new_session_id::text || CURRENT_TIMESTAMP::text, 'sha256'), 'hex'),
        p_device_identifier,
        p_ip_address,
        p_user_agent,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + (p_session_duration_minutes || ' minutes')::INTERVAL,
        TRUE,
        CURRENT_TIMESTAMP,
        p_user_id,
        CURRENT_TIMESTAMP,
        p_user_id
    );

    RETURN v_new_session_id;
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
    -- 1. Shred candidate cryptographic key material
    UPDATE governance.pii_encryption_key
    SET key_status = 'SHREDDED',
        wrapped_key_material = '0000000000000000000000000000000000000000000000000000000000000000',
        shredded_at = CURRENT_TIMESTAMP
    WHERE entity_id = p_candidate_id
      AND key_status = 'ACTIVE';

    -- 2. Anonymize candidate profile and mask searchability
    UPDATE candidate.candidate_profile
    SET is_profile_searchable = FALSE,
        summary = '[DATA SHREDDED PURSUANT TO DPDP ACT 2023]',
        headline = 'Anonymized Candidate',
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_actor_user_id
    WHERE id = p_candidate_id;

    -- 3. Record statutory erasure in immutable audit trail
    INSERT INTO governance.system_audit_event (
        id,
        actor_user_id,
        action_type,
        resource_type,
        resource_id,
        event_timestamp,
        created_at,
        created_by
    )
    VALUES (
        gen_random_uuid(),
        p_actor_user_id,
        'RIGHT_TO_BE_FORGOTTEN_SHRED',
        'CANDIDATE_PROFILE',
        p_candidate_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        p_actor_user_id
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
        WHERE id = NEW.wallet_account_id;
    ELSIF NEW.entry_type = 'DEBIT' THEN
        UPDATE billing.wallet_account
        SET current_balance = current_balance - NEW.amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.wallet_account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_wallet_balance_sync
    AFTER INSERT ON billing.wallet_ledger
    FOR EACH ROW EXECUTE FUNCTION billing.sync_wallet_balance();
