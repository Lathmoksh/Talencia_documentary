-- =============================================================
-- Talentra Enterprise Workforce Platform: Triggers & Stored Procedures
-- Module: Core Database Logic & Invariant Enforcement
-- Database Engine: PostgreSQL 16
-- =============================================================

-- -------------------------------------------------------------
-- 1. Automatic updated_at Maintenance Triggers
-- -------------------------------------------------------------
-- Set updated_at trigger function is defined in 001_extensions_and_types.sql

-- -------------------------------------------------------------
-- 2. Immutable Append-Only Ledger Enforcement
-- -------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_wallet_ledger_append_only ON billing.wallet_ledger;
CREATE TRIGGER trg_wallet_ledger_append_only
    BEFORE UPDATE OR DELETE ON billing.wallet_ledger
    FOR EACH ROW
    EXECUTE FUNCTION enforce_append_only();

DROP TRIGGER IF EXISTS trg_audit_event_append_only ON governance.system_audit_event;
CREATE TRIGGER trg_audit_event_append_only
    BEFORE UPDATE OR DELETE ON governance.system_audit_event
    FOR EACH ROW
    EXECUTE FUNCTION enforce_append_only();

DROP TRIGGER IF EXISTS trg_app_stage_hist_append_only ON application.application_stage_history;
CREATE TRIGGER trg_app_stage_hist_append_only
    BEFORE UPDATE OR DELETE ON application.application_stage_history
    FOR EACH ROW
    EXECUTE FUNCTION enforce_append_only();

-- -------------------------------------------------------------
-- 3. Live Double-Entry Wallet Balance Cache Synchronization
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION billing.fn_sync_wallet_account_balance()
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

DROP TRIGGER IF EXISTS trg_sync_wallet_balance ON billing.wallet_ledger;
CREATE TRIGGER trg_sync_wallet_balance
    AFTER INSERT ON billing.wallet_ledger
    FOR EACH ROW
    EXECUTE FUNCTION billing.fn_sync_wallet_account_balance();

-- -------------------------------------------------------------
-- 4. Corporate Tenancy Hierarchy Cycle Prevention
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION organisation.fn_check_hierarchy_cycle()
RETURNS TRIGGER AS $$
DECLARE
    v_cycle_detected BOOLEAN;
BEGIN
    -- Recursive CTE to detect circular ancestry
    WITH RECURSIVE hierarchy_path AS (
        SELECT parent_organisation_id, child_organisation_id, ARRAY[parent_organisation_id, child_organisation_id] AS path
        FROM organisation.organisation_hierarchy
        WHERE parent_organisation_id = NEW.child_organisation_id
        
        UNION ALL
        
        SELECT h.parent_organisation_id, h.child_organisation_id, path || h.child_organisation_id
        FROM organisation.organisation_hierarchy h
        JOIN hierarchy_path p ON h.parent_organisation_id = p.child_organisation_id
        WHERE NOT (h.child_organisation_id = ANY(path))
    )
    SELECT EXISTS (
        SELECT 1 FROM hierarchy_path WHERE child_organisation_id = NEW.parent_organisation_id
    ) INTO v_cycle_detected;

    IF v_cycle_detected THEN
        RAISE EXCEPTION 'ILLEGAL HIERARCHY CYCLE: Organisation % cannot be both an ancestor and a descendant of Organisation %',
            NEW.parent_organisation_id, NEW.child_organisation_id
            USING ERRCODE = '22023';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_hierarchy_cycle_guard ON organisation.organisation_hierarchy;
CREATE TRIGGER trg_hierarchy_cycle_guard
    BEFORE INSERT OR UPDATE ON organisation.organisation_hierarchy
    FOR EACH ROW
    EXECUTE FUNCTION organisation.fn_check_hierarchy_cycle();

-- -------------------------------------------------------------
-- 5. Gig Marketplace: Self-Application Guard
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION gig.fn_prevent_self_application()
RETURNS TRIGGER AS $$
DECLARE
    v_requester_user_id UUID;
    v_worker_user_id UUID;
BEGIN
    SELECT requester_user_id INTO v_requester_user_id
    FROM gig.gig_request WHERE id = NEW.request_id;

    SELECT user_id INTO v_worker_user_id
    FROM gig.gig_worker_profile WHERE id = NEW.worker_id;

    IF (v_requester_user_id = v_worker_user_id) THEN
        RAISE EXCEPTION 'SELF APPLICATION FORBIDDEN: User cannot submit a gig proposal to their own gig request'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_self_proposal ON gig.gig_proposal;
CREATE TRIGGER trg_prevent_self_proposal
    BEFORE INSERT OR UPDATE ON gig.gig_proposal
    FOR EACH ROW
    EXECUTE FUNCTION gig.fn_prevent_self_application();

-- -------------------------------------------------------------
-- 6. Application Pipeline Status Sync & History Logging
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION application.fn_sync_application_status_history()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.application_status <> NEW.application_status) THEN
        INSERT INTO application.application_stage_history (
            id, application_id, from_stage, to_stage, transitioned_by_user_id, transition_reason, created_at
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            OLD.application_status,
            NEW.application_status,
            NEW.updated_by,
            'Automated state machine advancement',
            CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_app_history ON application.job_application;
CREATE TRIGGER trg_sync_app_history
    AFTER UPDATE ON application.job_application
    FOR EACH ROW
    WHEN (OLD.application_status IS DISTINCT FROM NEW.application_status)
    EXECUTE FUNCTION application.fn_sync_application_status_history();

-- -------------------------------------------------------------
-- 7. India DPDP Act 2023: Candidate Cryptographic Key Shredding
-- -------------------------------------------------------------
CREATE OR REPLACE PROCEDURE governance.sp_shred_candidate_dek(
    p_candidate_user_id UUID,
    p_requested_by UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Mark DEK as shredded and purge encrypted key material
    UPDATE governance.pii_encryption_key
    SET status = 'SHREDDED',
        encrypted_dek = 'SHREDDED_PURGED_DPDP_2023',
        key_shredded_at = CURRENT_TIMESTAMP
    WHERE user_id = p_candidate_user_id;
    
    -- Record governance audit event
    INSERT INTO governance.system_audit_event (
        id, event_type, actor_user_id, resource_name, resource_id, action_description, payload_hash, created_at
    ) VALUES (
        gen_random_uuid(),
        'DPDP_RIGHT_TO_ERASURE_KEY_SHREDDED',
        p_requested_by,
        'candidate.candidate_profile',
        p_candidate_user_id,
        'Cryptographic Data Encryption Key permanently shredded under India DPDP Act 2023 Section 12',
        encode(digest(p_candidate_user_id::text, 'sha256'), 'hex'),
        CURRENT_TIMESTAMP
    );
END;
$$;

-- -------------------------------------------------------------
-- 8. Candidate Privacy Shield Security Definer Visibility Function
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION identity.candidate_visible_to(
    p_candidate_profile_id UUID,
    p_recruiter_organisation_id UUID
)
RETURNS BOOLEAN
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_searchable BOOLEAN;
    v_is_blocked BOOLEAN;
BEGIN
    -- Check if candidate profile is discoverable
    SELECT is_profile_searchable INTO v_is_searchable
    FROM candidate.candidate_profile
    WHERE id = p_candidate_profile_id;

    IF (v_is_searchable IS NOT TRUE) THEN
        RETURN FALSE;
    END IF;

    -- Check if candidate has blocked the recruiter's organisation
    SELECT EXISTS (
        SELECT 1 
        FROM candidate.candidate_block_list
        WHERE candidate_id = p_candidate_profile_id
          AND blocked_organisation_id = p_recruiter_organisation_id
    ) INTO v_is_blocked;

    IF v_is_blocked THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;
