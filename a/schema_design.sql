-- =============================================================================
-- Talentra Database Design
-- Module: Foundation, System Audit & External Integration Boundaries
-- Engine: PostgreSQL 15+
-- Adherence: Aligned with Hackathon Docket Section 5 (Rule Groups 1 to 10)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS administration;

-- -----------------------------------------------------------------------------
-- 1. System Audit Event Log (Rule Group 4 & 10: Append-Only)
-- Rule: Sensitive actions must be recorded in an immutable audit trail.
-- -----------------------------------------------------------------------------

CREATE TABLE audit.system_audit_event (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID NOT NULL,
    actor_role_code VARCHAR(50) NOT NULL,
    client_ip INET NOT NULL,
    user_agent VARCHAR(255),
    action_type VARCHAR(100) NOT NULL,
    target_entity VARCHAR(100) NOT NULL,
    target_record_id UUID NOT NULL,
    metadata_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_system_audit_event_actor ON audit.system_audit_event(actor_user_id, created_at DESC);
CREATE INDEX idx_system_audit_event_target ON audit.system_audit_event(target_entity, target_record_id);
CREATE INDEX idx_system_audit_event_created_at ON audit.system_audit_event(created_at DESC);

-- Trigger: Strictly bars UPDATE or DELETE operations on audit trail
CREATE OR REPLACE FUNCTION audit.prevent_audit_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit records are immutable. Table audit.system_audit_event is append-only.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_system_audit_event_immutable
BEFORE UPDATE OR DELETE ON audit.system_audit_event
FOR EACH ROW EXECUTE FUNCTION audit.prevent_audit_modification();


-- -----------------------------------------------------------------------------
-- 2. External Integration Boundary Registry (Docket Section 6)
-- Tracks the 9 external services connecting to Talentra
-- -----------------------------------------------------------------------------

CREATE TABLE integration.external_system_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_code VARCHAR(50) NOT NULL,
    system_name VARCHAR(150) NOT NULL,
    data_ownership VARCHAR(50) NOT NULL,
    failure_mode VARCHAR(50) NOT NULL,
    idempotency_type VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID NOT NULL,
    deleted_at TIMESTAMPTZ,

    CONSTRAINT uq_external_system_registry_code UNIQUE (system_code),
    CONSTRAINT chk_data_ownership CHECK (data_ownership IN ('TALENTRA_OWNED', 'EXTERNAL_OWNED', 'BIDIRECTIONAL_RECONCILED')),
    CONSTRAINT chk_failure_mode CHECK (failure_mode IN ('CIRCUIT_BREAKER_QUEUE', 'GRACEFUL_DEGRADATION', 'SYNCHRONOUS_REJECT', 'FALLBACK_CACHED'))
);

-- Seed the 9 integration boundaries from Section 6 of the Hackathon Docket
INSERT INTO integration.external_system_registry (system_code, system_name, data_ownership, failure_mode, idempotency_type, created_by, updated_by)
VALUES
    ('PAYMENT_GATEWAY', 'Stripe / Razorpay Payment Services', 'EXTERNAL_OWNED', 'GRACEFUL_DEGRADATION', 'IDEMPOTENCY_KEY', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('IDENTITY_VERIFICATION', 'National Identity / KYC Service', 'EXTERNAL_OWNED', 'CIRCUIT_BREAKER_QUEUE', 'HASH_COMPARISON', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('COMPANY_REGISTRATION', 'Ministry of Corporate Affairs / Tax Registry', 'EXTERNAL_OWNED', 'FALLBACK_CACHED', 'NATURAL_KEY_LOOKUP', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('GIG_FULFILMENT', 'External Gig Task Fulfilment Engine', 'EXTERNAL_OWNED', 'CIRCUIT_BREAKER_QUEUE', 'TRANSACTION_TOKEN', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('LEGACY_JOB_CANDIDATE', 'Northbridge Legacy Sync & Migration Hub', 'BIDIRECTIONAL_RECONCILED', 'CIRCUIT_BREAKER_QUEUE', 'SOURCE_RECORD_ID', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('MESSAGING_PROVIDER', 'SendGrid / Twilio Notification Hub', 'EXTERNAL_OWNED', 'CIRCUIT_BREAKER_QUEUE', 'BATCH_DISPATCH_UUID', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('SOCIAL_SHARING', 'Social Inbound & Outbound Sharing (LinkedIn, X)', 'EXTERNAL_OWNED', 'GRACEFUL_DEGRADATION', 'EVENT_UUID', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('GEOLOCATION_SERVICE', 'Google Maps / Mapbox Geocoding Provider', 'EXTERNAL_OWNED', 'FALLBACK_CACHED', 'COORDINATE_PRECISION', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('MARKET_SALARY_DATA', 'External Benchmark Salary & Company Reviews', 'EXTERNAL_OWNED', 'FALLBACK_CACHED', 'PERIOD_HASH', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (system_code) DO NOTHING;

CREATE TABLE integration.integration_exchange_event (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_system_id UUID NOT NULL REFERENCES integration.external_system_registry(id) ON DELETE RESTRICT,
    idempotency_key VARCHAR(128) NOT NULL,
    external_reference_token VARCHAR(255),
    exchange_direction VARCHAR(10) NOT NULL,     -- 'INBOUND' or 'OUTBOUND'
    status VARCHAR(50) NOT NULL,                 -- 'PENDING', 'SUCCESS', 'FAILED', 'RETRY'
    request_digest CHAR(64) NOT NULL,            -- SHA-256 hash of payload
    response_code INT,
    error_message VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT uq_integration_exchange_key UNIQUE (external_system_id, idempotency_key),
    CONSTRAINT chk_exchange_direction CHECK (exchange_direction IN ('INBOUND', 'OUTBOUND')),
    CONSTRAINT chk_exchange_status CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'RETRY'))
);

CREATE INDEX idx_integration_exchange_system ON integration.integration_exchange_event(external_system_id, created_at DESC);


-- -----------------------------------------------------------------------------
-- 3. Sensitive Data Classification Register (Rule Group 6)
-- -----------------------------------------------------------------------------

CREATE TABLE administration.data_classification_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schema_name VARCHAR(63) NOT NULL,
    table_name VARCHAR(63) NOT NULL,
    column_name VARCHAR(63) NOT NULL,
    classification_class VARCHAR(20) NOT NULL,   -- 'PUBLIC', 'INTERNAL', 'PERSONAL', 'SENSITIVE'
    protection_technique VARCHAR(50) NOT NULL,   -- 'PLAINTEXT', 'RLS_ISOLATED', 'MASKED_VIEW', 'ENCRYPTED'
    handling_policy_text VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,

    CONSTRAINT uq_data_classification_target UNIQUE (schema_name, table_name, column_name),
    CONSTRAINT chk_classification_class CHECK (classification_class IN ('PUBLIC', 'INTERNAL', 'PERSONAL', 'SENSITIVE'))
);

-- -----------------------------------------------------------------------------
-- 4. Realistic Seed Fixture (Student Notes Page 15: High-Value Realistic Data)
-- -----------------------------------------------------------------------------

-- Realistic sample audit entry: Candidate profile creation event
INSERT INTO audit.system_audit_event (
    id, actor_user_id, actor_role_code, client_ip, user_agent, action_type, target_entity, target_record_id, metadata_payload
) VALUES (
    'a0000001-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001', -- Asha (Candidate)
    'CANDIDATE',
    '103.21.124.5',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36',
    'CREATE_PROFILE',
    'candidate_profile',
    'c0000001-0000-0000-0000-000000000001',
    '{"event": "Initial resume uploaded", "file_name": "Asha_Verma_Lead_FullStack.pdf", "language": "en"}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Realistic sample integration event: Stripe wallet recharge webhook
INSERT INTO integration.integration_exchange_event (
    id, external_system_id, idempotency_key, external_reference_token, exchange_direction, status, request_digest, response_code
) VALUES (
    'a0000002-0000-0000-0000-000000000002',
    (SELECT id FROM integration.external_system_registry WHERE system_code = 'PAYMENT_GATEWAY'),
    'idem_stripe_order_9847291',
    'ch_3N4yXkLkdIwHu7ix0ABCD123',
    'INBOUND',
    'SUCCESS',
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    200
) ON CONFLICT DO NOTHING;

-- Realistic sample data classification tags
INSERT INTO administration.data_classification_catalog (
    schema_name, table_name, column_name, classification_class, protection_technique, handling_policy_text, created_by
) VALUES
    ('administration', 'user_account', 'email', 'PERSONAL', 'RLS_ISOLATED', 'Requires candidate consent; used for system notifications and login', '00000000-0000-0000-0000-000000000001'),
    ('administration', 'user_account', 'phone_e164', 'SENSITIVE', 'MASKED_VIEW', 'Masked until recruiter spends wallet credits to unlock contact details', '00000000-0000-0000-0000-000000000001'),
    ('organisation', 'organisation', 'tax_identifier', 'SENSITIVE', 'ENCRYPTED', 'Stored encrypted; displayed only to verified account administrators', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (schema_name, table_name, column_name) DO NOTHING;
