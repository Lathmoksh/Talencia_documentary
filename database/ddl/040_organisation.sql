-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: organisation
-- =============================================================

-- -------------------------------------------------------------
-- Table: organisation.account
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.account (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    account_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(30) NOT NULL,
    account_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    billing_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT pk_account PRIMARY KEY (id),
    CONSTRAINT chk_account_account_status CHECK (account_status IN ('TRIAL_ACTIVE', 'PAID_ACTIVE', 'DELINQUENT_GRACE', 'SUSPENDED_NON_PAYMENT', 'TERMINATED_OFFBOARDED'))
);

-- -------------------------------------------------------------
-- Table: organisation.organisation
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    account_id UUID NOT NULL,
    legal_name VARCHAR(200) NOT NULL,
    trade_name VARCHAR(150),
    company_registration_number VARCHAR(100) NOT NULL,
    website_url VARCHAR(255),
    industry_id UUID NOT NULL,
    company_size_tier VARCHAR(30) NOT NULL,
    verification_status VARCHAR(30) DEFAULT 'UNVERIFIED' NOT NULL,
    logo_url VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT pk_organisation PRIMARY KEY (id),
    CONSTRAINT uq_organisation_company_registration_number UNIQUE (company_registration_number)
);

-- -------------------------------------------------------------
-- Table: organisation.organisation_location
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation_location (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    organisation_id UUID NOT NULL,
    location_type VARCHAR(30) NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city_id UUID NOT NULL,
    state_id UUID NOT NULL,
    country_id UUID NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_organisation_location PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: organisation.organisation_tax_identifier
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation_tax_identifier (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    organisation_id UUID NOT NULL,
    country_id UUID NOT NULL,
    tax_id_type VARCHAR(30) NOT NULL,
    encrypted_tax_id TEXT NOT NULL,
    tax_id_blind_index CHAR(64) NOT NULL,
    verification_status VARCHAR(30) DEFAULT 'PENDING' NOT NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_organisation_tax_identifier PRIMARY KEY (id),
    CONSTRAINT uq_organisation_tax_identifier_tax_id_blind_index UNIQUE (tax_id_blind_index)
);

-- -------------------------------------------------------------
-- Table: organisation.organisation_verification
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation_verification (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    organisation_id UUID NOT NULL,
    verification_provider VARCHAR(50) NOT NULL,
    reference_number VARCHAR(100) NOT NULL,
    verification_outcome VARCHAR(30) NOT NULL,
    rejection_reason VARCHAR(500),
    raw_payload_hash CHAR(64) NOT NULL,
    verified_by UUID,
    verified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_organisation_verification PRIMARY KEY (id),
    CONSTRAINT uq_organisation_verification_reference_number UNIQUE (reference_number)
);

-- -------------------------------------------------------------
-- Table: organisation.recruiter_seat_assignment
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.recruiter_seat_assignment (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    organisation_id UUID NOT NULL,
    user_id UUID NOT NULL,
    seat_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_recruiter_seat_assignment PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: organisation.organisation_hierarchy
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation_hierarchy (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    parent_organisation_id UUID NOT NULL,
    child_organisation_id UUID NOT NULL,
    relationship_type VARCHAR(30) NOT NULL,
    effective_date DATE DEFAULT CURRENT_DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_organisation_hierarchy PRIMARY KEY (id)
);

