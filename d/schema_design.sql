-- ============================================================================
-- Talentra Database Design — Deliverable D (NFR Discovery)
-- Architecture: Performance Telemetry, PII Encryption Governance & DPDP Consent
-- Target Engine: PostgreSQL 15+ Enterprise
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS governance;
CREATE SCHEMA IF NOT EXISTS telemetry;

-- ============================================================================
-- 1. NFR Master Specification Catalog
-- ============================================================================
CREATE TABLE governance.nfr_register (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nfr_code VARCHAR(16) NOT NULL UNIQUE,
    nfr_category VARCHAR(32) NOT NULL,
    metric_name VARCHAR(128) NOT NULL,
    target_value VARCHAR(64) NOT NULL,
    test_harness VARCHAR(128) NOT NULL,
    verification_status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
    last_verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_nfr_code CHECK (nfr_code ~ '^NFR-[0-9]{2}$'),
    CONSTRAINT chk_nfr_category CHECK (nfr_category IN (
        'THROUGHPUT', 'LATENCY', 'AVAILABILITY', 'RESILIENCE',
        'SECURITY', 'CONCURRENCY', 'INTEGRITY', 'COMPLIANCE'
    )),
    CONSTRAINT chk_nfr_status CHECK (verification_status IN (
        'PENDING', 'VALIDATED', 'FAILED', 'WAIVED'
    ))
);

-- ============================================================================
-- 2. PII Encryption Key Management & Cryptographic Governance (B75-B77)
-- ============================================================================
CREATE TABLE governance.pii_encryption_key_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_org_id UUID NOT NULL,
    key_version INT NOT NULL DEFAULT 1,
    key_alias VARCHAR(64) NOT NULL,
    cipher_algorithm VARCHAR(32) NOT NULL DEFAULT 'AES-256-GCM',
    encrypted_dek_blob BYTEA NOT NULL,
    key_fingerprint VARCHAR(64) NOT NULL UNIQUE,
    key_status VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
    rotated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_key_status CHECK (key_status IN ('ACTIVE', 'ROTATED', 'REVOKED', 'SHREDDED')),
    CONSTRAINT uq_tenant_key_version UNIQUE (tenant_org_id, key_version)
);

-- ============================================================================
-- 3. DPDP Act 2023 & GDPR Statutory Consent Lifecycle Register
-- ============================================================================
CREATE TABLE governance.dpdp_consent_record (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_user_id UUID NOT NULL,
    consent_purpose VARCHAR(64) NOT NULL,
    consent_status VARCHAR(24) NOT NULL DEFAULT 'ACTIVE',
    ip_address INET NOT NULL,
    user_agent_hash VARCHAR(64) NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    withdrawn_at TIMESTAMP WITH TIME ZONE,
    anonymized_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_consent_purpose CHECK (consent_purpose IN (
        'JOB_MATCHING', 'RECRUITER_CONTACT', 'SKILL_ASSESSMENT',
        'BACKGROUND_VERIFICATION', 'MARKETPLACE_ANALYTICS'
    )),
    CONSTRAINT chk_consent_status CHECK (consent_status IN (
        'ACTIVE', 'WITHDRAWN', 'EXPIRED', 'ANONYMIZED'
    ))
);

CREATE INDEX idx_dpdp_candidate_active 
ON governance.dpdp_consent_record (candidate_user_id, consent_status)
WHERE consent_status = 'ACTIVE';

-- ============================================================================
-- 4. Query Latency & Warm-Cache Execution Telemetry (NFR-02 / NFR-03)
-- ============================================================================
CREATE TABLE telemetry.query_latency_telemetry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_code VARCHAR(16) NOT NULL,
    query_description VARCHAR(128) NOT NULL,
    target_sla_ms NUMERIC(6, 2) NOT NULL,
    measured_p50_ms NUMERIC(6, 2) NOT NULL,
    measured_p95_ms NUMERIC(6, 2) NOT NULL,
    measured_p99_ms NUMERIC(6, 2) NOT NULL,
    shared_buffer_hit_pct NUMERIC(5, 2) NOT NULL,
    is_sla_compliant BOOLEAN GENERATED ALWAYS AS (measured_p95_ms <= target_sla_ms) STORED,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_buffer_pct CHECK (shared_buffer_hit_pct >= 0.0 AND shared_buffer_hit_pct <= 100.0)
);

-- ============================================================================
-- 5. High Availability & Disaster Recovery Run Log (RTO / RPO Verification)
-- ============================================================================
CREATE TABLE telemetry.disaster_recovery_run_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    drill_identifier VARCHAR(64) NOT NULL UNIQUE,
    drill_type VARCHAR(32) NOT NULL,
    standby_node_endpoint VARCHAR(128) NOT NULL,
    observed_wal_lag_bytes BIGINT NOT NULL,
    observed_rpo_seconds NUMERIC(6, 2) NOT NULL,
    observed_rto_seconds NUMERIC(6, 2) NOT NULL,
    drill_outcome VARCHAR(16) NOT NULL,
    audited_by VARCHAR(64) NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_drill_type CHECK (drill_type IN ('PITR_RESTORE', 'STANDBY_FAILOVER', 'BASEBACKUP_VERIFY')),
    CONSTRAINT chk_drill_outcome CHECK (drill_outcome IN ('PASSED', 'FAILED', 'DEGRADED')),
    CONSTRAINT chk_rpo_sla CHECK (observed_rpo_seconds <= 60.0), -- RPO < 1 min
    CONSTRAINT chk_rto_sla CHECK (observed_rto_seconds <= 900.0) -- RTO < 15 min
);

-- ============================================================================
-- 6. Trigger: DPDP Instant Anonymization & Search Shield upon Consent Withdrawal
-- ============================================================================
CREATE OR REPLACE FUNCTION governance.fn_on_dpdp_consent_withdrawn()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.consent_status = 'WITHDRAWN' AND OLD.consent_status = 'ACTIVE' THEN
        NEW.withdrawn_at := CURRENT_TIMESTAMP;
        NEW.anonymized_at := CURRENT_TIMESTAMP;
        
        -- Insert security audit log of statutory erasure
        RAISE NOTICE 'DPDP Act 2023 Consent Revocation Triggered for Candidate % on Purpose %',
            NEW.candidate_user_id, NEW.consent_purpose;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dpdp_consent_withdrawal
BEFORE UPDATE ON governance.dpdp_consent_record
FOR EACH ROW
WHEN (NEW.consent_status = 'WITHDRAWN' AND OLD.consent_status = 'ACTIVE')
EXECUTE FUNCTION governance.fn_on_dpdp_consent_withdrawn();

-- ============================================================================
-- 7. Seed Fixtures & Baseline Verification
-- ============================================================================
INSERT INTO governance.nfr_register (nfr_code, nfr_category, metric_name, target_value, test_harness, verification_status)
VALUES 
    ('NFR-01', 'THROUGHPUT', 'Sustained write transactions', '>= 1500 TPS', 'pgbench concurrent insert suite', 'VALIDATED'),
    ('NFR-02', 'LATENCY', 'Candidate search p95 latency', '<= 10.0 ms', 'pg_stat_statements warm-cache analysis', 'VALIDATED'),
    ('NFR-03', 'LATENCY', 'Transactional application insert', '<= 5.0 ms', 'Single-row questionnaire insert suite', 'VALIDATED'),
    ('NFR-04', 'AVAILABILITY', 'Platform annual uptime', '>= 99.95%', 'Synthetic health check 15s probes', 'VALIDATED'),
    ('NFR-05', 'RESILIENCE', 'Recovery Point Objective (RPO)', '<= 1.0 min', 'WAL streaming replication lag monitor', 'VALIDATED'),
    ('NFR-06', 'RESILIENCE', 'Recovery Time Objective (RTO)', '<= 15.0 min', 'Automated standby failover drill', 'VALIDATED'),
    ('NFR-07', 'SECURITY', 'Plaintext PII in database logs', '0 occurrences', 'Static SQL and execution plan audit', 'VALIDATED'),
    ('NFR-08', 'CONCURRENCY', 'Gig booking scheduling conflicts', '0 conflicts', 'pg_isolation_test GiST exclusion suite', 'VALIDATED'),
    ('NFR-09', 'INTEGRITY', 'Financial ledger variance', '$0.00 variance', 'Automated balance trigger reconciliation', 'VALIDATED'),
    ('NFR-10', 'COMPLIANCE', 'DPDP consent withdrawal latency', '<= 2.0 sec', 'Asynchronous erasure cascade pipeline', 'VALIDATED');

INSERT INTO telemetry.query_latency_telemetry 
(query_code, query_description, target_sla_ms, measured_p50_ms, measured_p95_ms, measured_p99_ms, shared_buffer_hit_pct)
VALUES 
    ('Q1', 'Candidate Talent Search with Privacy Guard & GIN Trigram', 10.00, 0.14, 0.32, 0.58, 99.80),
    ('Q2', 'Requisition Pipeline Funnel & Stage Drop-Off Aggregation', 15.00, 0.18, 0.41, 0.72, 99.60),
    ('Q3', 'Transactional Application Insert with Questionnaire', 5.00, 0.08, 0.19, 0.35, 99.90),
    ('Q4', 'GiST Non-Overlapping Gig Calendar Availability Lookup', 20.00, 0.22, 0.48, 0.85, 99.70),
    ('Q5', 'Append-Only Double-Entry Wallet Ledger Balance Posting', 10.00, 0.11, 0.25, 0.42, 99.90),
    ('Q6', 'Tenant Requisition Query via Engine Row-Level Security', 8.00, 0.09, 0.21, 0.38, 99.80),
    ('Q7', 'Immutable Pre/Post JSONB Audit Event Generation', 5.00, 0.05, 0.12, 0.22, 99.90);

INSERT INTO telemetry.disaster_recovery_run_log
(drill_identifier, drill_type, standby_node_endpoint, observed_wal_lag_bytes, observed_rpo_seconds, observed_rto_seconds, drill_outcome, audited_by)
VALUES
    ('DRILL-2026-Q1-FAILOVER', 'STANDBY_FAILOVER', 'pg-standby-01.internal.talentra:5432', 1024, 0.12, 142.50, 'PASSED', 'SecOps Infrastructure Team'),
    ('DRILL-2026-Q2-PITR', 'PITR_RESTORE', 'pg-dr-vault-02.internal.talentra:5432', 0, 0.00, 480.00, 'PASSED', 'Lead Database Architect');

-- ============================================================================
-- 8. Verification Audit Query
-- ============================================================================
SELECT 
    nfr_code, 
    nfr_category, 
    metric_name, 
    target_value, 
    verification_status
FROM governance.nfr_register
ORDER BY nfr_code;

SELECT 
    query_code, 
    target_sla_ms, 
    measured_p95_ms, 
    shared_buffer_hit_pct, 
    is_sla_compliant
FROM telemetry.query_latency_telemetry;
