-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: identity
-- =============================================================

-- -------------------------------------------------------------
-- Table: identity.user_account
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.user_account (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    email VARCHAR(254) NOT NULL,
    phone_country_code VARCHAR(5) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    user_type VARCHAR(30) NOT NULL,
    account_status VARCHAR(20) DEFAULT 'PENDING_VERIFICATION' NOT NULL,
    is_email_verified BOOLEAN DEFAULT FALSE NOT NULL,
    is_phone_verified BOOLEAN DEFAULT FALSE NOT NULL,
    two_factor_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    failed_login_attempts SMALLINT DEFAULT 0 NOT NULL,
    locked_until TIMESTAMPTZ DEFAULT 'NULL',
    last_login_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT 'NULL',
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT 'NULL',
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_user_account PRIMARY KEY (id),
    CONSTRAINT uq_user_account_email UNIQUE (email),
    CONSTRAINT uq_user_account_phone_number UNIQUE (phone_number),
    CONSTRAINT chk_user_account_account_status CHECK (account_status IN ('REGISTERED_UNVERIFIED', 'ACTIVE_VERIFIED', 'SUSPENDED_SECURITY', 'LOCKED_FAILED_LOGINS', 'ANONYMIZED_PURGED'))
);

-- -------------------------------------------------------------
-- Table: identity.user_credential
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.user_credential (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    password_salt VARCHAR(64) NOT NULL,
    hash_algorithm VARCHAR(30) DEFAULT 'ARGON2ID' NOT NULL,
    password_changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    must_change_password BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_user_credential PRIMARY KEY (id),
    CONSTRAINT uq_user_credential_user_id UNIQUE (user_id)
);

-- -------------------------------------------------------------
-- Table: identity.role
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.role (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    role_code VARCHAR(50) NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    role_scope VARCHAR(30) NOT NULL,
    description VARCHAR(500) DEFAULT 'NULL',
    is_system_role BOOLEAN DEFAULT TRUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_role PRIMARY KEY (id),
    CONSTRAINT uq_role_role_code UNIQUE (role_code)
);

-- -------------------------------------------------------------
-- Table: identity.user_role
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.user_role (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    granted_by UUID NOT NULL,
    granted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMPTZ DEFAULT 'NULL',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT pk_user_role PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: identity.user_active_session
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.user_active_session (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    session_token_hash CHAR(64) NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    device_type VARCHAR(30) NOT NULL,
    client_ip INET NOT NULL,
    user_agent VARCHAR(500) DEFAULT 'NULL',
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_activity_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ DEFAULT 'NULL',
    revocation_reason VARCHAR(100) DEFAULT 'NULL',
    CONSTRAINT pk_user_active_session PRIMARY KEY (id),
    CONSTRAINT uq_user_active_session_session_token_hash UNIQUE (session_token_hash)
);

-- -------------------------------------------------------------
-- Table: identity.service_api_key
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.service_api_key (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    key_prefix VARCHAR(16) NOT NULL,
    key_hash CHAR(64) NOT NULL,
    key_name VARCHAR(100) NOT NULL,
    scopes TEXT DEFAULT '["read:requisitions","write:applications"]' NOT NULL,
    rate_limit_per_minute INTEGER DEFAULT 600 NOT NULL,
    last_used_at TIMESTAMPTZ DEFAULT 'NULL',
    expires_at TIMESTAMPTZ DEFAULT 'NULL',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    revoked_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_service_api_key PRIMARY KEY (id),
    CONSTRAINT uq_service_api_key_key_prefix UNIQUE (key_prefix),
    CONSTRAINT uq_service_api_key_key_hash UNIQUE (key_hash)
);

