-- =============================================================
-- Talentra Zero-Loss Ingestion Pipeline Verification Procedure
-- Milestone 25: sp_verify_and_commit_ingestion
-- Mathematical Invariant: source_rows = loaded_rows + quarantined_rows
-- =============================================================

CREATE OR REPLACE PROCEDURE governance.sp_verify_and_commit_ingestion(
    p_batch_id UUID,
    p_expected_source_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_loaded_count INTEGER;
    v_quarantined_count INTEGER;
    v_variance INTEGER;
BEGIN
    -- Query actual loaded rows for this batch
    SELECT COUNT(*) INTO v_loaded_count
    FROM governance.system_audit_event
    WHERE resource_id = p_batch_id AND event_type = 'INGESTION_ROW_LOADED';

    -- Query actual quarantined rows for this batch
    SELECT COUNT(*) INTO v_quarantined_count
    FROM governance.system_audit_event
    WHERE resource_id = p_batch_id AND event_type = 'INGESTION_ROW_QUARANTINED';

    -- Compute variance
    v_variance := p_expected_source_count - (v_loaded_count + v_quarantined_count);

    IF v_variance <> 0 THEN
        RAISE EXCEPTION 'CRITICAL INGESTION ERROR: Reconciliation variance detected in batch %. Expected: %, Loaded: %, Quarantined: %, Variance: %',
            p_batch_id, p_expected_source_count, v_loaded_count, v_quarantined_count, v_variance;
    END IF;

    -- Update batch audit record
    INSERT INTO governance.system_audit_event (
        id, event_type, actor_user_id, resource_name, resource_id,
        action_description, payload_hash, created_at
    ) VALUES (
        gen_random_uuid(),
        'INGESTION_BATCH_RECONCILED_COMMITTED',
        NULL,
        'governance.ingestion_batch',
        p_batch_id,
        format('Batch %s passed zero-loss reconciliation. Loaded: %s, Quarantined: %s', p_batch_id, v_loaded_count, v_quarantined_count),
        md5(p_batch_id::text),
        CURRENT_TIMESTAMP
    );
END;
$$;
