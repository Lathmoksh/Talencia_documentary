-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: governance
-- =============================================================

-- -------------------------------------------------------------
-- Table: governance.dpdp_consent_record
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS governance.dpdp_consent_record (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    consent_purpose VARCHAR(50) NOT NULL,
    consent_version VARCHAR(20) DEFAULT 'v2026.1' NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    granted_ip_address INET NOT NULL,
    granted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    revoked_at TIMESTAMPTZ DEFAULT 'NULL',
    withdrawal_reason VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_dpdp_consent_record PRIMARY KEY (id),
    CONSTRAINT chk_dpdp_consent_record_status CHECK (status IN ('PENDING_OPT_IN', 'EXPLICIT_GRANTED', 'EXPLICIT_REVOKED', 'SYSTEM_SUPERSEDED', 'ANONYMIZED_EXPIRED'))
);

-- -------------------------------------------------------------
-- Table: governance.pii_encryption_key
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS governance.pii_encryption_key (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    encrypted_dek TEXT NOT NULL,
    key_version SMALLINT DEFAULT 1 NOT NULL,
    is_shredded BOOLEAN DEFAULT FALSE NOT NULL,
    shredded_at TIMESTAMPTZ DEFAULT 'NULL',
    shredded_by_user_id UUID DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_pii_encryption_key PRIMARY KEY (id),
    CONSTRAINT uq_pii_encryption_key_user_id UNIQUE (user_id)
);

-- -------------------------------------------------------------
-- Table: governance.system_audit_event
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS governance.system_audit_event (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    actor_user_id UUID NOT NULL,
    actor_ip INET NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    resource_entity VARCHAR(50) NOT NULL,
    resource_id UUID NOT NULL,
    payload_before_json TEXT DEFAULT 'NULL',
    payload_after_json TEXT DEFAULT 'NULL',
    tamper_hash CHAR(64) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_system_audit_event PRIMARY KEY (id),
    CONSTRAINT uq_system_audit_event_tamper_hash UNIQUE (tamper_hash)
);

-- -------------------------------------------------------------
-- Table: governance.data_retention_policy
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS governance.data_retention_policy (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    retention_duration_days INTEGER DEFAULT 365 NOT NULL,
    action_on_expiry VARCHAR(30) DEFAULT 'ANONYMIZE' NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_data_retention_policy PRIMARY KEY (id),
    CONSTRAINT uq_data_retention_policy_entity_type UNIQUE (entity_type)
);

