-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Baseline Migration V1__baseline.sql
-- Engine: PostgreSQL 16 (Tiered NVMe Storage, RLS, GiST Exclusion)
-- Architecture: 13 Domain Schemas, 90 Tables, 893 Columns
-- =============================================================

-- >>> Start of 001_extensions_and_types.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform: Extensions & Core Functions
-- Database Engine: PostgreSQL 16
-- =============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Trigger function for automatic updated_at maintenance
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to enforce immutable append-only ledgers
CREATE OR REPLACE FUNCTION enforce_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Table % is strictly append-only. UPDATE and DELETE operations are prohibited by law.', TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;

-- >>> End of 001_extensions_and_types.sql <<<

-- >>> Start of 010_schemas.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform: 13 Domain Schemas
-- =============================================================

CREATE SCHEMA IF NOT EXISTS master_data;
CREATE SCHEMA IF NOT EXISTS identity;
CREATE SCHEMA IF NOT EXISTS organisation;
CREATE SCHEMA IF NOT EXISTS candidate;
CREATE SCHEMA IF NOT EXISTS recruitment;
CREATE SCHEMA IF NOT EXISTS application;
CREATE SCHEMA IF NOT EXISTS sourcing;
CREATE SCHEMA IF NOT EXISTS gig;
CREATE SCHEMA IF NOT EXISTS licensing;
CREATE SCHEMA IF NOT EXISTS billing;
CREATE SCHEMA IF NOT EXISTS engagement;
CREATE SCHEMA IF NOT EXISTS governance;
CREATE SCHEMA IF NOT EXISTS analytics;

-- >>> End of 010_schemas.sql <<<

-- >>> Start of 020_master_data.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: master_data
-- =============================================================

-- -------------------------------------------------------------
-- Table: master_data.country
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.country (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    iso_alpha2_code CHAR(2) NOT NULL,
    iso_alpha3_code CHAR(3) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    phone_dialing_code VARCHAR(10) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    sort_order INTEGER DEFAULT 100 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_country PRIMARY KEY (id),
    CONSTRAINT uq_country_iso_alpha2_code UNIQUE (iso_alpha2_code),
    CONSTRAINT uq_country_iso_alpha3_code UNIQUE (iso_alpha3_code)
);

-- -------------------------------------------------------------
-- Table: master_data.state
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.state (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    country_id UUID NOT NULL,
    state_code VARCHAR(10) NOT NULL,
    state_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    sort_order INTEGER DEFAULT 100 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_state PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: master_data.city
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.city (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    country_id UUID NOT NULL,
    state_id UUID NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    latitude NUMERIC(9,6) DEFAULT 'NULL',
    longitude NUMERIC(9,6) DEFAULT 'NULL',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_city PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: master_data.currency
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.currency (
    currency_code CHAR(3) NOT NULL,
    currency_name VARCHAR(50) NOT NULL,
    currency_symbol VARCHAR(5) NOT NULL,
    decimal_precision SMALLINT DEFAULT 2 NOT NULL,
    iso_numeric_code CHAR(3) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_currency PRIMARY KEY (currency_code),
    CONSTRAINT uq_currency_iso_numeric_code UNIQUE (iso_numeric_code)
);

-- -------------------------------------------------------------
-- Table: master_data.language
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.language (
    language_code CHAR(2) NOT NULL,
    language_name VARCHAR(50) NOT NULL,
    native_name VARCHAR(100) NOT NULL,
    is_rtl BOOLEAN DEFAULT FALSE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_language PRIMARY KEY (language_code)
);

-- -------------------------------------------------------------
-- Table: master_data.industry
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.industry (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    industry_code VARCHAR(30) NOT NULL,
    industry_name VARCHAR(100) NOT NULL,
    description VARCHAR(500) DEFAULT 'NULL',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    sort_order INTEGER DEFAULT 100 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_industry PRIMARY KEY (id),
    CONSTRAINT uq_industry_industry_code UNIQUE (industry_code)
);

-- -------------------------------------------------------------
-- Table: master_data.job_role
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.job_role (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    industry_id UUID NOT NULL,
    role_code VARCHAR(50) NOT NULL,
    role_title VARCHAR(100) NOT NULL,
    description VARCHAR(500) DEFAULT 'NULL',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    sort_order INTEGER DEFAULT 100 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_role PRIMARY KEY (id),
    CONSTRAINT uq_job_role_role_code UNIQUE (role_code)
);

-- -------------------------------------------------------------
-- Table: master_data.skill
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.skill (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    skill_code VARCHAR(50) NOT NULL,
    skill_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    is_verified BOOLEAN DEFAULT TRUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_skill PRIMARY KEY (id),
    CONSTRAINT uq_skill_skill_code UNIQUE (skill_code)
);

-- -------------------------------------------------------------
-- Table: master_data.qualification
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.qualification (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    qualification_code VARCHAR(50) NOT NULL,
    qualification_name VARCHAR(150) NOT NULL,
    qualification_level VARCHAR(30) NOT NULL,
    field_of_study VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    sort_order INTEGER DEFAULT 100 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_qualification PRIMARY KEY (id),
    CONSTRAINT uq_qualification_qualification_code UNIQUE (qualification_code)
);

-- -------------------------------------------------------------
-- Table: master_data.ui_translation_key
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.ui_translation_key (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    translation_key VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description VARCHAR(500) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_ui_translation_key PRIMARY KEY (id),
    CONSTRAINT uq_ui_translation_key_translation_key UNIQUE (translation_key)
);

-- -------------------------------------------------------------
-- Table: master_data.ui_translation
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS master_data.ui_translation (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    key_id UUID NOT NULL,
    language_code CHAR(2) NOT NULL,
    translated_text TEXT NOT NULL,
    is_reviewed BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_ui_translation PRIMARY KEY (id)
);


-- >>> End of 020_master_data.sql <<<

-- >>> Start of 030_identity.sql <<<
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


-- >>> End of 030_identity.sql <<<

-- >>> Start of 040_organisation.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: organisation
-- =============================================================

-- -------------------------------------------------------------
-- Table: organisation.account
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.account (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    account_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(30) NOT NULL,
    account_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    billing_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT 'NULL',
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_account PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: organisation.organisation
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    account_id UUID NOT NULL,
    legal_name VARCHAR(200) NOT NULL,
    trade_name VARCHAR(150) DEFAULT 'NULL',
    company_registration_number VARCHAR(100) NOT NULL,
    website_url VARCHAR(255) DEFAULT 'NULL',
    industry_id UUID NOT NULL,
    company_size_tier VARCHAR(30) NOT NULL,
    verification_status VARCHAR(30) DEFAULT 'UNVERIFIED' NOT NULL,
    logo_url VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT 'NULL',
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_organisation PRIMARY KEY (id),
    CONSTRAINT uq_organisation_company_registration_number UNIQUE (company_registration_number),
    CONSTRAINT chk_organisation_verification_status CHECK (verification_status IN ('PENDING_SUBMISSION', 'UNDER_REVIEW', 'DOCUMENTS_REJECTED', 'VERIFIED_ACTIVE', 'SUSPENDED_REGULATORY', 'DEACTIVATED'))
);

-- -------------------------------------------------------------
-- Table: organisation.organisation_location
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation_location (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    organisation_id UUID NOT NULL,
    location_type VARCHAR(30) NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255) DEFAULT 'NULL',
    city_id UUID NOT NULL,
    state_id UUID NOT NULL,
    country_id UUID NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_organisation_location PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: organisation.organisation_tax_identifier
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation_tax_identifier (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    organisation_id UUID NOT NULL,
    country_id UUID NOT NULL,
    tax_id_type VARCHAR(30) NOT NULL,
    encrypted_tax_id TEXT NOT NULL,
    tax_id_blind_index CHAR(64) NOT NULL,
    verification_status VARCHAR(30) DEFAULT 'PENDING' NOT NULL,
    verified_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_organisation_tax_identifier PRIMARY KEY (id),
    CONSTRAINT uq_organisation_tax_identifier_tax_id_blind_index UNIQUE (tax_id_blind_index)
);

-- -------------------------------------------------------------
-- Table: organisation.organisation_verification
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation_verification (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    organisation_id UUID NOT NULL,
    verification_provider VARCHAR(50) NOT NULL,
    reference_number VARCHAR(100) NOT NULL,
    verification_outcome VARCHAR(30) NOT NULL,
    rejection_reason VARCHAR(500) DEFAULT 'NULL',
    raw_payload_hash CHAR(64) NOT NULL,
    verified_by UUID DEFAULT 'NULL',
    verified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_organisation_verification PRIMARY KEY (id),
    CONSTRAINT uq_organisation_verification_reference_number UNIQUE (reference_number)
);

-- -------------------------------------------------------------
-- Table: organisation.recruiter_seat_assignment
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.recruiter_seat_assignment (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    organisation_id UUID NOT NULL,
    user_id UUID NOT NULL,
    seat_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    revoked_at TIMESTAMPTZ DEFAULT 'NULL',
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_recruiter_seat_assignment PRIMARY KEY (id),
    CONSTRAINT chk_recruiter_seat_assignment_seat_status CHECK (seat_status IN ('INVITED_PENDING', 'ACTIVE_ALLOCATED', 'SUSPENDED_ADMIN', 'REVOKED_DEALLOCATED'))
);

-- -------------------------------------------------------------
-- Table: organisation.organisation_hierarchy
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organisation.organisation_hierarchy (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    parent_organisation_id UUID NOT NULL,
    child_organisation_id UUID NOT NULL,
    relationship_type VARCHAR(30) NOT NULL,
    effective_date DATE DEFAULT 'CURRENT_DATE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_organisation_hierarchy PRIMARY KEY (id)
);


-- >>> End of 040_organisation.sql <<<

-- >>> Start of 050_candidate.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: candidate
-- =============================================================

-- -------------------------------------------------------------
-- Table: candidate.candidate_profile
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_profile (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    first_name VARCHAR(75) NOT NULL,
    middle_name VARCHAR(75) DEFAULT 'NULL',
    last_name VARCHAR(75) NOT NULL,
    display_name VARCHAR(150) NOT NULL,
    date_of_birth DATE DEFAULT 'NULL',
    gender VARCHAR(20) DEFAULT 'NULL',
    headline VARCHAR(200) NOT NULL,
    summary TEXT DEFAULT 'NULL',
    current_city_id UUID NOT NULL,
    total_experience_months INTEGER DEFAULT 0 NOT NULL,
    current_salary_amount NUMERIC(12,2) DEFAULT 'NULL',
    expected_salary_amount NUMERIC(12,2) DEFAULT 'NULL',
    salary_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    notice_period_days INTEGER DEFAULT 30 NOT NULL,
    profile_completion_percentage NUMERIC(5,2) DEFAULT 0.00 NOT NULL,
    is_profile_searchable BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT 'NULL',
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_candidate_profile PRIMARY KEY (id),
    CONSTRAINT uq_candidate_profile_user_id UNIQUE (user_id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_education
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_education (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    qualification_id UUID NOT NULL,
    institution_name VARCHAR(200) NOT NULL,
    field_of_study VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT 'NULL',
    grade_or_gpa VARCHAR(20) DEFAULT 'NULL',
    grade_system VARCHAR(30) DEFAULT 'NULL',
    is_completed BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_education PRIMARY KEY (id),
    CONSTRAINT chk_candidate_education_rule_1 CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),
    CONSTRAINT chk_candidate_education_rule_2 CHECK (grade_percentage IS NULL OR (grade_percentage >= 0.00 AND grade_percentage <= 100.00))
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_work_experience
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_work_experience (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    job_role_id UUID NOT NULL,
    industry_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT 'NULL',
    is_current_job BOOLEAN DEFAULT FALSE NOT NULL,
    description TEXT DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_work_experience PRIMARY KEY (id),
    CONSTRAINT chk_candidate_work_experience_rule_1 CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_skill
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_skill (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    skill_id UUID NOT NULL,
    proficiency_level VARCHAR(20) DEFAULT 'INTERMEDIATE' NOT NULL,
    years_of_experience NUMERIC(3,1) DEFAULT 1.0 NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE NOT NULL,
    last_used_year SMALLINT DEFAULT 'EXTRACT(YEAR FROM CURRENT_DATE)' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_skill PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_project
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_project (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    project_title VARCHAR(150) NOT NULL,
    project_role VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT 'NULL',
    description TEXT NOT NULL,
    project_url VARCHAR(255) DEFAULT 'NULL',
    outcome VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_project PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_resume
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_resume (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    resume_title VARCHAR(150) NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    file_format VARCHAR(20) NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    parsed_text_search TEXT DEFAULT 'NULL',
    is_primary BOOLEAN DEFAULT TRUE NOT NULL,
    version_number SMALLINT DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_candidate_resume PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_preference
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_preference (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    preferred_job_type VARCHAR(30) DEFAULT 'PERMANENT_FULL_TIME' NOT NULL,
    preferred_work_mode VARCHAR(30) DEFAULT 'HYBRID' NOT NULL,
    willing_to_relocate BOOLEAN DEFAULT FALSE NOT NULL,
    preferred_locations_json TEXT DEFAULT '[]' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_preference PRIMARY KEY (id),
    CONSTRAINT uq_candidate_preference_candidate_id UNIQUE (candidate_id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_block_list
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_block_list (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    blocked_organisation_id UUID DEFAULT 'NULL',
    blocked_recruiter_user_id UUID DEFAULT 'NULL',
    block_reason VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_block_list PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_language
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_language (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    language_code CHAR(2) NOT NULL,
    proficiency_level VARCHAR(20) DEFAULT 'PROFICIENT' NOT NULL,
    can_read BOOLEAN DEFAULT TRUE NOT NULL,
    can_write BOOLEAN DEFAULT TRUE NOT NULL,
    can_speak BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_language PRIMARY KEY (id)
);


-- >>> End of 050_candidate.sql <<<

-- >>> Start of 060_recruitment.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: recruitment
-- =============================================================

-- -------------------------------------------------------------
-- Table: recruitment.job_requisition
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.job_requisition (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    organisation_id UUID NOT NULL,
    posted_by_user_id UUID NOT NULL,
    job_role_id UUID NOT NULL,
    job_title VARCHAR(150) NOT NULL,
    job_category VARCHAR(40) NOT NULL,
    job_type VARCHAR(30) DEFAULT 'FULL_TIME' NOT NULL,
    work_mode VARCHAR(30) DEFAULT 'HYBRID' NOT NULL,
    vacancies_count INTEGER DEFAULT 1 NOT NULL,
    city_id UUID NOT NULL,
    min_experience_months INTEGER DEFAULT 0 NOT NULL,
    max_experience_months INTEGER DEFAULT 0 NOT NULL,
    min_salary_amount NUMERIC(12,2) NOT NULL,
    max_salary_amount NUMERIC(12,2) NOT NULL,
    salary_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    is_salary_negotiable BOOLEAN DEFAULT FALSE NOT NULL,
    job_description TEXT NOT NULL,
    publish_status VARCHAR(20) DEFAULT 'DRAFT' NOT NULL,
    open_to_consultants BOOLEAN DEFAULT FALSE NOT NULL,
    application_deadline DATE DEFAULT 'NULL',
    published_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT 'NULL',
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_job_requisition PRIMARY KEY (id),
    CONSTRAINT chk_job_requisition_publish_status CHECK (publish_status IN ('DRAFT', 'PENDING_APPROVAL', 'PUBLISHED_ACTIVE', 'ON_HOLD', 'CLOSED_FILLED', 'CANCELLED_EXPIRED')),
    CONSTRAINT chk_job_requisition_rule_1 CHECK (min_salary_amount IS NULL OR min_salary_amount >= 0.00),
    CONSTRAINT chk_job_requisition_rule_2 CHECK (max_salary_amount IS NULL OR max_salary_amount >= 0.00),
    CONSTRAINT chk_job_requisition_rule_3 CHECK (max_salary_amount IS NULL OR min_salary_amount IS NULL OR max_salary_amount >= min_salary_amount),
    CONSTRAINT chk_job_requisition_rule_4 CHECK (vacancies_count > 0)
);

-- -------------------------------------------------------------
-- Table: recruitment.job_requisition_skill
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.job_requisition_skill (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    requisition_id UUID NOT NULL,
    skill_id UUID NOT NULL,
    requirement_type VARCHAR(20) DEFAULT 'MANDATORY' NOT NULL,
    min_experience_months INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_requisition_skill PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: recruitment.job_questionnaire
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.job_questionnaire (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    requisition_id UUID NOT NULL,
    questionnaire_title VARCHAR(150) NOT NULL,
    passing_score_percentage NUMERIC(5,2) DEFAULT 70.00 NOT NULL,
    is_mandatory BOOLEAN DEFAULT TRUE NOT NULL,
    version_number SMALLINT DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_questionnaire PRIMARY KEY (id),
    CONSTRAINT uq_job_questionnaire_requisition_id UNIQUE (requisition_id)
);

-- -------------------------------------------------------------
-- Table: recruitment.questionnaire_question
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.questionnaire_question (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    questionnaire_id UUID NOT NULL,
    question_text VARCHAR(500) NOT NULL,
    question_type VARCHAR(30) NOT NULL,
    weight_points INTEGER DEFAULT 10 NOT NULL,
    is_disqualifying BOOLEAN DEFAULT FALSE NOT NULL,
    sort_order INTEGER DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_questionnaire_question PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: recruitment.question_option
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.question_option (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    question_id UUID NOT NULL,
    option_text VARCHAR(255) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE NOT NULL,
    score_value INTEGER DEFAULT 0 NOT NULL,
    sort_order INTEGER DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_question_option PRIMARY KEY (id)
);


-- >>> End of 060_recruitment.sql <<<

-- >>> Start of 070_application.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: application
-- =============================================================

-- -------------------------------------------------------------
-- Table: application.job_application
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.job_application (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    requisition_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    resume_id UUID NOT NULL,
    application_status VARCHAR(30) DEFAULT 'SUBMITTED' NOT NULL,
    screening_score NUMERIC(5,2) DEFAULT 'NULL',
    is_passed_screening BOOLEAN DEFAULT 'NULL',
    source_type VARCHAR(30) DEFAULT 'DIRECT_APPLY' NOT NULL,
    consultant_id UUID DEFAULT 'NULL',
    applied_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    withdrawn_at TIMESTAMPTZ DEFAULT 'NULL',
    rejection_reason VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_job_application PRIMARY KEY (id),
    CONSTRAINT chk_job_application_application_status CHECK (application_status IN ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'SCREENING_PASSED', 'SHORTLISTED', 'TECHNICAL_ASSESSMENT', 'INTERVIEW_SCHEDULED', 'INTERVIEW_COMPLETED', 'OFFER_EXTENDED', 'OFFER_ACCEPTED', 'OFFER_DECLINED', 'REJECTED', 'WITHDRAWN'))
);

-- -------------------------------------------------------------
-- Table: application.application_question_answer
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.application_question_answer (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    question_id UUID NOT NULL,
    selected_option_id UUID DEFAULT 'NULL',
    free_text_answer TEXT DEFAULT 'NULL',
    score_awarded INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_application_question_answer PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: application.application_stage_history
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.application_stage_history (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    from_stage VARCHAR(30) NOT NULL,
    to_stage VARCHAR(30) NOT NULL,
    changed_by_user_id UUID NOT NULL,
    stage_notes VARCHAR(500) DEFAULT 'NULL',
    transition_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_application_stage_history PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: application.job_interview
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.job_interview (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    interview_round SMALLINT DEFAULT 1 NOT NULL,
    interview_format VARCHAR(30) NOT NULL,
    scheduled_start_time TIMESTAMPTZ NOT NULL,
    scheduled_end_time TIMESTAMPTZ NOT NULL,
    meeting_link VARCHAR(255) DEFAULT 'NULL',
    interviewer_user_id UUID NOT NULL,
    interview_status VARCHAR(30) DEFAULT 'SCHEDULED' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_interview PRIMARY KEY (id),
    CONSTRAINT chk_job_interview_interview_status CHECK (interview_status IN ('SCHEDULED', 'CONFIRMED_ATTENDING', 'RESCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANDIDATE_NO_SHOW', 'CANCELLED'))
);

-- -------------------------------------------------------------
-- Table: application.interview_feedback
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.interview_feedback (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    interview_id UUID NOT NULL,
    interviewer_user_id UUID NOT NULL,
    technical_score NUMERIC(3,1) NOT NULL,
    cultural_score NUMERIC(3,1) NOT NULL,
    overall_score NUMERIC(3,1) NOT NULL,
    recommendation VARCHAR(30) NOT NULL,
    strengths TEXT DEFAULT 'NULL',
    weaknesses TEXT DEFAULT 'NULL',
    feedback_notes TEXT DEFAULT 'NULL',
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_interview_feedback PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: application.job_offer
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.job_offer (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    offered_salary_amount NUMERIC(12,2) NOT NULL,
    salary_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    joining_date DATE NOT NULL,
    offer_validity_date DATE NOT NULL,
    offer_letter_storage_path VARCHAR(500) NOT NULL,
    offer_status VARCHAR(30) DEFAULT 'EXTENDED' NOT NULL,
    responded_at TIMESTAMPTZ DEFAULT 'NULL',
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_offer PRIMARY KEY (id),
    CONSTRAINT uq_job_offer_application_id UNIQUE (application_id),
    CONSTRAINT chk_job_offer_offer_status CHECK (offer_status IN ('DRAFT_GENERATED', 'INTERNAL_APPROVED', 'EXTENDED_TO_CANDIDATE', 'ACCEPTED_PENDING_ONBOARD', 'REJECTED_BY_CANDIDATE', 'REVISED_COUNTER', 'RESCINDED_BY_EMPLOYER', 'EXPIRED'))
);


-- >>> End of 070_application.sql <<<

-- >>> Start of 080_sourcing.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: sourcing
-- =============================================================

-- -------------------------------------------------------------
-- Table: sourcing.consultant_authorization
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sourcing.consultant_authorization (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    requisition_id UUID NOT NULL,
    consultant_user_id UUID NOT NULL,
    commission_rate_percentage NUMERIC(5,2) DEFAULT 8.33 NOT NULL,
    authorization_status VARCHAR(20) DEFAULT 'PENDING' NOT NULL,
    authorized_by_user_id UUID DEFAULT 'NULL',
    authorized_at TIMESTAMPTZ DEFAULT 'NULL',
    expires_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_consultant_authorization PRIMARY KEY (id),
    CONSTRAINT chk_consultant_authorization_authorization_status CHECK (authorization_status IN ('PROPOSED', 'ACTIVE_AUTHORIZED', 'REVOKED_EARLY', 'COMPLETED_CLOSED', 'EXPIRED'))
);

-- -------------------------------------------------------------
-- Table: sourcing.candidate_nomination
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sourcing.candidate_nomination (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    authorization_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    nomination_status VARCHAR(30) DEFAULT 'NOMINATED' NOT NULL,
    review_notes VARCHAR(500) DEFAULT 'NULL',
    nominated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_nomination PRIMARY KEY (id),
    CONSTRAINT chk_candidate_nomination_nomination_status CHECK (nomination_status IN ('NOMINATED_PENDING', 'CLIENT_SHORTLISTED', 'CLIENT_REJECTED', 'HIRED_COMMISSION_EARNED', 'WITHDRAWN_CANDIDATE'))
);

-- -------------------------------------------------------------
-- Table: sourcing.outreach_campaign
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sourcing.outreach_campaign (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    organisation_id UUID NOT NULL,
    created_by_user_id UUID NOT NULL,
    campaign_name VARCHAR(150) NOT NULL,
    channel_type VARCHAR(20) NOT NULL,
    message_template TEXT NOT NULL,
    total_recipients_count INTEGER DEFAULT 0 NOT NULL,
    credits_deducted INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_outreach_campaign PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: sourcing.outreach_recipient
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sourcing.outreach_recipient (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    campaign_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    delivery_status VARCHAR(20) DEFAULT 'QUEUED' NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT 'NULL',
    opened_at TIMESTAMPTZ DEFAULT 'NULL',
    clicked_at TIMESTAMPTZ DEFAULT 'NULL',
    responded_at TIMESTAMPTZ DEFAULT 'NULL',
    error_message VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_outreach_recipient PRIMARY KEY (id)
);


-- >>> End of 080_sourcing.sql <<<

-- >>> Start of 090_gig.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: gig
-- =============================================================

-- -------------------------------------------------------------
-- Table: gig.gig_worker_profile
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.gig_worker_profile (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    professional_title VARCHAR(150) NOT NULL,
    bio_summary TEXT NOT NULL,
    hourly_rate_amount NUMERIC(10,2) NOT NULL,
    daily_rate_amount NUMERIC(10,2) DEFAULT 'NULL',
    rate_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    total_completed_gigs INTEGER DEFAULT 0 NOT NULL,
    average_rating_score NUMERIC(3,2) DEFAULT 5.00 NOT NULL,
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE' NOT NULL,
    portfolio_url VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_gig_worker_profile PRIMARY KEY (id),
    CONSTRAINT uq_gig_worker_profile_user_id UNIQUE (user_id)
);

-- -------------------------------------------------------------
-- Table: gig.gig_worker_service
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.gig_worker_service (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    worker_id UUID NOT NULL,
    service_title VARCHAR(150) NOT NULL,
    service_category_id UUID NOT NULL,
    pricing_model VARCHAR(20) DEFAULT 'FIXED_PRICE' NOT NULL,
    base_price_amount NUMERIC(10,2) NOT NULL,
    price_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    delivery_time_days INTEGER DEFAULT 5 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_gig_worker_service PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: gig.gig_worker_availability
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.gig_worker_availability (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    worker_id UUID NOT NULL,
    available_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_booked BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_gig_worker_availability PRIMARY KEY (id),
    CONSTRAINT excl_gig_worker_avail_overlap EXCLUDE USING gist (worker_id WITH =, availability_window WITH &&)
);

-- -------------------------------------------------------------
-- Table: gig.gig_request
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.gig_request (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    organisation_id UUID NOT NULL,
    posted_by_user_id UUID NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    project_category_id UUID NOT NULL,
    budget_type VARCHAR(20) DEFAULT 'FIXED_PRICE' NOT NULL,
    budget_amount NUMERIC(12,2) NOT NULL,
    budget_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    booking_window TSTZRANGE NOT NULL,
    request_status VARCHAR(20) DEFAULT 'OPEN' NOT NULL,
    required_worker_count SMALLINT DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_gig_request PRIMARY KEY (id),
    CONSTRAINT chk_gig_request_request_status CHECK (request_status IN ('DRAFT', 'OPEN_BIDDING', 'PROPOSALS_UNDER_REVIEW', 'MATCH_CONFIRMED', 'WORK_IN_PROGRESS', 'COMPLETED_DELIVERED', 'DISPUTED_ARBITRATION', 'CANCELLED_UNFILLED'))
);

-- -------------------------------------------------------------
-- Table: gig.gig_proposal
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.gig_proposal (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    request_id UUID NOT NULL,
    worker_id UUID NOT NULL,
    cover_letter TEXT NOT NULL,
    proposed_rate_amount NUMERIC(12,2) NOT NULL,
    proposed_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    estimated_completion_days INTEGER DEFAULT 10 NOT NULL,
    proposal_status VARCHAR(20) DEFAULT 'SUBMITTED' NOT NULL,
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_gig_proposal PRIMARY KEY (id),
    CONSTRAINT chk_gig_proposal_proposal_status CHECK (proposal_status IN ('SUBMITTED', 'UNDER_CLIENT_REVIEW', 'ACCEPTED_AWARDED', 'DECLINED_REJECTED', 'WITHDRAWN_BY_WORKER', 'EXPIRED'))
);

-- -------------------------------------------------------------
-- Table: gig.gig_contract
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.gig_contract (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    request_id UUID NOT NULL,
    proposal_id UUID NOT NULL,
    worker_id UUID NOT NULL,
    organisation_id UUID NOT NULL,
    contract_title VARCHAR(150) NOT NULL,
    agreed_window TSTZRANGE NOT NULL,
    agreed_amount NUMERIC(12,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    contract_status VARCHAR(20) DEFAULT 'SIGNED' NOT NULL,
    external_fulfillment_reference VARCHAR(100) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    signed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at TIMESTAMPTZ DEFAULT 'NULL',
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_gig_contract PRIMARY KEY (id),
    CONSTRAINT uq_gig_contract_proposal_id UNIQUE (proposal_id),
    CONSTRAINT chk_gig_contract_contract_status CHECK (contract_status IN ('PENDING_ESCROW', 'ACTIVE_IN_PROGRESS', 'PAUSED_REVISION', 'PENDING_ACCEPTANCE', 'DISPUTED', 'SETTLED_CLOSED', 'TERMINATED_MUTUAL', 'CANCELLED_PRE_START')),
    CONSTRAINT chk_gig_contract_rule_1 CHECK (agreed_amount >= 0.00)
);

-- -------------------------------------------------------------
-- Table: gig.gig_milestone
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.gig_milestone (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    contract_id UUID NOT NULL,
    milestone_index SMALLINT DEFAULT 1 NOT NULL,
    milestone_title VARCHAR(150) NOT NULL,
    deliverable_description TEXT NOT NULL,
    due_date DATE NOT NULL,
    milestone_amount NUMERIC(12,2) NOT NULL,
    escrow_allocation_amount NUMERIC(12,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    milestone_status VARCHAR(20) DEFAULT 'PENDING' NOT NULL,
    submitted_at TIMESTAMPTZ DEFAULT 'NULL',
    approved_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_gig_milestone PRIMARY KEY (id),
    CONSTRAINT chk_gig_milestone_milestone_status CHECK (milestone_status IN ('PENDING_FUNDING', 'FUNDED_ESCROW_LOCKED', 'IN_PROGRESS', 'SUBMITTED_FOR_REVIEW', 'REVISION_REQUESTED', 'APPROVED_RELEASED', 'DISPUTED_FROZEN', 'REFUNDED_TO_CLIENT')),
    CONSTRAINT chk_gig_milestone_rule_1 CHECK (amount >= 0.00)
);

-- -------------------------------------------------------------
-- Table: gig.gig_rating
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.gig_rating (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    contract_id UUID NOT NULL,
    rater_user_id UUID NOT NULL,
    rated_user_id UUID NOT NULL,
    rating_score NUMERIC(3,2) NOT NULL,
    review_text TEXT DEFAULT 'NULL',
    communication_score NUMERIC(3,2) NOT NULL,
    quality_score NUMERIC(3,2) NOT NULL,
    timeliness_score NUMERIC(3,2) NOT NULL,
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_gig_rating PRIMARY KEY (id),
    CONSTRAINT chk_gig_rating_rule_1 CHECK (score >= 1.0 AND score <= 5.0)
);

-- -------------------------------------------------------------
-- Table: gig.client_gig_worker_preference
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gig.client_gig_worker_preference (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    organisation_id UUID NOT NULL,
    worker_id UUID NOT NULL,
    preference_type VARCHAR(20) NOT NULL,
    notes VARCHAR(500) DEFAULT 'NULL',
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_client_gig_worker_preference PRIMARY KEY (id)
);


-- >>> End of 090_gig.sql <<<

-- >>> Start of 100_licensing.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: licensing
-- =============================================================

-- -------------------------------------------------------------
-- Table: licensing.subscription_plan
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS licensing.subscription_plan (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    plan_code VARCHAR(50) NOT NULL,
    plan_name VARCHAR(100) NOT NULL,
    tier_level VARCHAR(20) NOT NULL,
    billing_cycle VARCHAR(20) DEFAULT 'MONTHLY' NOT NULL,
    base_price_amount NUMERIC(12,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    max_recruiter_seats INTEGER DEFAULT 1 NOT NULL,
    max_devices_per_user SMALLINT DEFAULT 2 NOT NULL,
    monthly_profile_unlock_quota INTEGER DEFAULT 50 NOT NULL,
    monthly_outreach_credits INTEGER DEFAULT 100 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_subscription_plan PRIMARY KEY (id),
    CONSTRAINT uq_subscription_plan_plan_code UNIQUE (plan_code)
);

-- -------------------------------------------------------------
-- Table: licensing.subscription_licence
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS licensing.subscription_licence (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    account_id UUID NOT NULL,
    plan_id UUID NOT NULL,
    licence_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    validity_period TSTZRANGE NOT NULL,
    allocated_seats_count INTEGER DEFAULT 1 NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_subscription_licence PRIMARY KEY (id),
    CONSTRAINT chk_subscription_licence_licence_status CHECK (licence_status IN ('PENDING_PROVISIONING', 'ACTIVE_COMMISSIONED', 'RENEWAL_DUE', 'GRACE_PERIOD', 'SUSPENDED_NON_PAYMENT', 'TERMINATED_EXPIRED'))
);

-- -------------------------------------------------------------
-- Table: licensing.licence_entitlement_usage
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS licensing.licence_entitlement_usage (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    licence_id UUID NOT NULL,
    entitlement_type VARCHAR(40) NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    allocated_quota INTEGER DEFAULT 0 NOT NULL,
    consumed_quota INTEGER DEFAULT 0 NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_licence_entitlement_usage PRIMARY KEY (id)
);


-- >>> End of 100_licensing.sql <<<

-- >>> Start of 110_billing.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: billing
-- =============================================================

-- -------------------------------------------------------------
-- Table: billing.wallet_account
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.wallet_account (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    account_id UUID NOT NULL,
    wallet_type VARCHAR(20) DEFAULT 'OPERATIONAL' NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    current_balance NUMERIC(14,2) DEFAULT 0.00 NOT NULL,
    escrow_reserved_balance NUMERIC(14,2) DEFAULT 0.00 NOT NULL,
    is_locked BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_wallet_account PRIMARY KEY (id),
    CONSTRAINT uq_wallet_account_account_id UNIQUE (account_id),
    CONSTRAINT chk_wallet_account_rule_1 CHECK (current_balance >= 0.00),
    CONSTRAINT chk_wallet_account_rule_2 CHECK (escrow_reserved_balance >= 0.00)
);

-- -------------------------------------------------------------
-- Table: billing.wallet_ledger
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.wallet_ledger (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    wallet_id UUID NOT NULL,
    transaction_group_id UUID NOT NULL,
    entry_type VARCHAR(10) NOT NULL,
    amount NUMERIC(14,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    balance_after NUMERIC(14,2) NOT NULL,
    reference_entity_type VARCHAR(40) NOT NULL,
    reference_entity_id UUID NOT NULL,
    notes VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_wallet_ledger PRIMARY KEY (id),
    CONSTRAINT chk_wallet_ledger_rule_1 CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    CONSTRAINT chk_wallet_ledger_rule_2 CHECK (amount > 0.00)
);

-- -------------------------------------------------------------
-- Table: billing.payment_order
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.payment_order (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    account_id UUID NOT NULL,
    order_type VARCHAR(30) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    order_status VARCHAR(20) DEFAULT 'CREATED' NOT NULL,
    payment_gateway_order_reference VARCHAR(100) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_payment_order PRIMARY KEY (id),
    CONSTRAINT uq_payment_order_payment_gateway_order_reference UNIQUE (payment_gateway_order_reference),
    CONSTRAINT chk_payment_order_order_status CHECK (order_status IN ('INITIALIZED', 'PROCESSING_PAYMENT', 'SETTLED_SUCCESS', 'PAYMENT_FAILED', 'EXPIRED_TIMEOUT', 'CANCELLED_USER'))
);

-- -------------------------------------------------------------
-- Table: billing.payment_transaction
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.payment_transaction (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    order_id UUID NOT NULL,
    wallet_id UUID DEFAULT 'NULL',
    gateway_transaction_reference VARCHAR(100) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    transaction_status VARCHAR(20) NOT NULL,
    gateway_response_code VARCHAR(50) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_payment_transaction PRIMARY KEY (id),
    CONSTRAINT uq_payment_transaction_gateway_transaction_reference UNIQUE (gateway_transaction_reference)
);

-- -------------------------------------------------------------
-- Table: billing.payment_gateway_event
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.payment_gateway_event (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    gateway_event_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    payload_json TEXT NOT NULL,
    processing_status VARCHAR(20) DEFAULT 'RECEIVED' NOT NULL,
    error_message VARCHAR(500) DEFAULT 'NULL',
    received_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_payment_gateway_event PRIMARY KEY (id),
    CONSTRAINT uq_payment_gateway_event_gateway_event_id UNIQUE (gateway_event_id)
);

-- -------------------------------------------------------------
-- Table: billing.invoice
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.invoice (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    account_id UUID NOT NULL,
    order_id UUID NOT NULL,
    invoice_number VARCHAR(50) NOT NULL,
    invoice_date DATE DEFAULT 'CURRENT_DATE' NOT NULL,
    due_date DATE DEFAULT 'CURRENT_DATE' NOT NULL,
    subtotal_amount NUMERIC(12,2) NOT NULL,
    tax_amount NUMERIC(12,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    invoice_status VARCHAR(20) DEFAULT 'PAID' NOT NULL,
    pdf_storage_path VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_invoice PRIMARY KEY (id),
    CONSTRAINT uq_invoice_order_id UNIQUE (order_id),
    CONSTRAINT uq_invoice_invoice_number UNIQUE (invoice_number),
    CONSTRAINT chk_invoice_invoice_status CHECK (invoice_status IN ('DRAFT', 'ISSUED_UNPAID', 'PAID_SETTLED', 'PAYMENT_OVERDUE', 'VOID_CANCELLED', 'WRITTEN_OFF_UNCOLLECTIBLE')),
    CONSTRAINT chk_invoice_rule_1 CHECK (subtotal_amount >= 0.00),
    CONSTRAINT chk_invoice_rule_2 CHECK (tax_amount >= 0.00),
    CONSTRAINT chk_invoice_rule_3 CHECK (total_amount >= 0.00),
    CONSTRAINT chk_invoice_rule_4 CHECK (total_amount = subtotal_amount + tax_amount)
);

-- -------------------------------------------------------------
-- Table: billing.invoice_item
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.invoice_item (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    invoice_id UUID NOT NULL,
    item_description VARCHAR(255) NOT NULL,
    quantity INTEGER DEFAULT 1 NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    total_price NUMERIC(12,2) NOT NULL,
    currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    tax_rate_percentage NUMERIC(5,2) DEFAULT 18.00 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_invoice_item PRIMARY KEY (id),
    CONSTRAINT chk_invoice_item_rule_1 CHECK (quantity > 0),
    CONSTRAINT chk_invoice_item_rule_2 CHECK (unit_price >= 0.00),
    CONSTRAINT chk_invoice_item_rule_3 CHECK (total_price >= 0.00)
);

-- -------------------------------------------------------------
-- Table: billing.profile_download_history
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.profile_download_history (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    recruiter_user_id UUID NOT NULL,
    organisation_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    credits_deducted INTEGER DEFAULT 1 NOT NULL,
    unlock_type VARCHAR(30) DEFAULT 'RESUME_DOWNLOAD' NOT NULL,
    dpdp_consent_verified BOOLEAN DEFAULT TRUE NOT NULL,
    downloaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_profile_download_history PRIMARY KEY (id)
);


-- >>> End of 110_billing.sql <<<

-- >>> Start of 120_engagement.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: engagement
-- =============================================================

-- -------------------------------------------------------------
-- Table: engagement.candidate_saved_search
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.candidate_saved_search (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    recruiter_user_id UUID NOT NULL,
    search_name VARCHAR(100) NOT NULL,
    criteria_json TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_saved_search PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.job_alert_subscription
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.job_alert_subscription (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    alert_title VARCHAR(100) NOT NULL,
    filters_json TEXT NOT NULL,
    frequency VARCHAR(20) DEFAULT 'DAILY' NOT NULL,
    channel VARCHAR(20) DEFAULT 'EMAIL' NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    last_notified_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_alert_subscription PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.notification_delivery
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.notification_delivery (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    notification_category VARCHAR(40) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    title VARCHAR(150) NOT NULL,
    body_preview VARCHAR(500) NOT NULL,
    delivery_status VARCHAR(20) DEFAULT 'QUEUED' NOT NULL,
    external_delivery_reference VARCHAR(100) DEFAULT 'NULL',
    read_at TIMESTAMPTZ DEFAULT 'NULL',
    dispatched_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_notification_delivery PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.message_thread
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.message_thread (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    recruiter_user_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    requisition_id UUID DEFAULT 'NULL',
    unlock_receipt_id UUID NOT NULL,
    thread_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_message_thread PRIMARY KEY (id),
    CONSTRAINT chk_message_thread_thread_status CHECK (thread_status IN ('ACTIVE_OPEN', 'ARCHIVED_USER', 'BLOCKED_BY_PARTY', 'FLAGGED_MODERATION', 'PURGED_RETENTION'))
);

-- -------------------------------------------------------------
-- Table: engagement.thread_message
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.thread_message (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    thread_id UUID NOT NULL,
    sender_user_id UUID NOT NULL,
    message_body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_thread_message PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.candidate_referral_link
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.candidate_referral_link (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    referrer_user_id UUID NOT NULL,
    unique_referral_token VARCHAR(64) NOT NULL,
    channel_medium VARCHAR(30) DEFAULT 'DIRECT' NOT NULL,
    click_count INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_referral_link PRIMARY KEY (id),
    CONSTRAINT uq_candidate_referral_link_unique_referral_token UNIQUE (unique_referral_token)
);

-- -------------------------------------------------------------
-- Table: engagement.referral_attribution_event
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.referral_attribution_event (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    referral_link_id UUID NOT NULL,
    referred_user_id UUID NOT NULL,
    milestone_type VARCHAR(30) NOT NULL,
    reward_points_awarded INTEGER DEFAULT 0 NOT NULL,
    attributed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_referral_attribution_event PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.campus_placement_cohort
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.campus_placement_cohort (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    tpo_user_id UUID NOT NULL,
    institution_name VARCHAR(200) NOT NULL,
    degree_program VARCHAR(100) NOT NULL,
    graduation_year SMALLINT DEFAULT 'EXTRACT(YEAR FROM CURRENT_DATE)' NOT NULL,
    cohort_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_campus_placement_cohort PRIMARY KEY (id),
    CONSTRAINT chk_campus_placement_cohort_cohort_status CHECK (cohort_status IN ('PLANNING_DRAFT', 'REGISTRATION_OPEN', 'SCREENING_IN_PROGRESS', 'DRIVE_ACTIVE', 'OFFERS_CONCLUDED', 'ARCHIVED_COMPLETED'))
);

-- -------------------------------------------------------------
-- Table: engagement.campus_student_member
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.campus_student_member (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    cohort_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    university_roll_number VARCHAR(50) NOT NULL,
    cumulative_gpa NUMERIC(4,2) NOT NULL,
    placement_status VARCHAR(20) DEFAULT 'UNPLACED' NOT NULL,
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_campus_student_member PRIMARY KEY (id),
    CONSTRAINT uq_campus_student_member_university_roll_number UNIQUE (university_roll_number),
    CONSTRAINT chk_campus_student_member_placement_status CHECK (placement_status IN ('REGISTERED_UNVERIFIED', 'VERIFIED_ELIGIBLE', 'SHORTLISTED_DRIVE', 'OFFER_RECEIVED', 'PLACED_ACCEPTED', 'OPTED_OUT_INELIGIBLE'))
);


-- >>> End of 120_engagement.sql <<<

-- >>> Start of 130_governance.sql <<<
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


-- >>> End of 130_governance.sql <<<

-- >>> Start of 140_analytics.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: analytics
-- =============================================================

-- -------------------------------------------------------------
-- Table: analytics.dim_date
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.dim_date (
    date_key INTEGER NOT NULL,
    full_date DATE NOT NULL,
    day_of_week SMALLINT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    day_of_month SMALLINT NOT NULL,
    month_number SMALLINT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    calendar_quarter SMALLINT NOT NULL,
    calendar_year SMALLINT NOT NULL,
    is_weekend BOOLEAN DEFAULT FALSE NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE NOT NULL,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key),
    CONSTRAINT uq_dim_date_full_date UNIQUE (full_date)
);

-- -------------------------------------------------------------
-- Table: analytics.dim_candidate
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.dim_candidate (
    candidate_key INTEGER NOT NULL,
    candidate_id UUID NOT NULL,
    user_id UUID NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    state_name VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    total_experience_months INTEGER DEFAULT 0 NOT NULL,
    highest_qualification VARCHAR(150) NOT NULL,
    current_salary_usd NUMERIC(12,2) DEFAULT 'NULL',
    profile_completion_percentage NUMERIC(5,2) DEFAULT 0.00 NOT NULL,
    row_effective_date DATE NOT NULL,
    row_expiration_date DATE DEFAULT '9999-12-31' NOT NULL,
    is_current BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT pk_dim_candidate PRIMARY KEY (candidate_key)
);

-- -------------------------------------------------------------
-- Table: analytics.dim_organisation
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.dim_organisation (
    organisation_key INTEGER NOT NULL,
    organisation_id UUID NOT NULL,
    account_id UUID NOT NULL,
    legal_name VARCHAR(200) NOT NULL,
    industry_name VARCHAR(100) NOT NULL,
    company_size_tier VARCHAR(30) NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    is_verified BOOLEAN DEFAULT TRUE NOT NULL,
    row_effective_date DATE NOT NULL,
    row_expiration_date DATE DEFAULT '9999-12-31' NOT NULL,
    is_current BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT pk_dim_organisation PRIMARY KEY (organisation_key)
);

-- -------------------------------------------------------------
-- Table: analytics.dim_job_requisition
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.dim_job_requisition (
    requisition_key INTEGER NOT NULL,
    requisition_id UUID NOT NULL,
    organisation_id UUID NOT NULL,
    job_role_title VARCHAR(100) NOT NULL,
    job_category VARCHAR(40) NOT NULL,
    job_type VARCHAR(30) NOT NULL,
    work_mode VARCHAR(30) NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    min_salary_usd NUMERIC(12,2) NOT NULL,
    max_salary_usd NUMERIC(12,2) NOT NULL,
    open_to_consultants BOOLEAN DEFAULT TRUE NOT NULL,
    row_effective_date DATE NOT NULL,
    row_expiration_date DATE DEFAULT '9999-12-31' NOT NULL,
    is_current BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT pk_dim_job_requisition PRIMARY KEY (requisition_key)
);

-- -------------------------------------------------------------
-- Table: analytics.dim_pipeline_stage
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.dim_pipeline_stage (
    stage_key INTEGER NOT NULL,
    stage_code VARCHAR(30) NOT NULL,
    stage_name VARCHAR(50) NOT NULL,
    funnel_order SMALLINT NOT NULL,
    is_terminal_stage BOOLEAN DEFAULT FALSE NOT NULL,
    CONSTRAINT pk_dim_pipeline_stage PRIMARY KEY (stage_key),
    CONSTRAINT uq_dim_pipeline_stage_stage_code UNIQUE (stage_code)
);

-- -------------------------------------------------------------
-- Table: analytics.fact_application_event
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.fact_application_event (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    date_key INTEGER NOT NULL,
    candidate_key INTEGER NOT NULL,
    organisation_key INTEGER NOT NULL,
    requisition_key INTEGER NOT NULL,
    from_stage_key INTEGER NOT NULL,
    to_stage_key INTEGER NOT NULL,
    stage_duration_hours NUMERIC(8,2) DEFAULT 0.00 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_fact_application_event PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: analytics.fact_profile_download
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.fact_profile_download (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    date_key INTEGER NOT NULL,
    organisation_key INTEGER NOT NULL,
    candidate_key INTEGER NOT NULL,
    recruiter_user_id UUID NOT NULL,
    credits_consumed INTEGER DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_fact_profile_download PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: analytics.fact_gig_contract
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.fact_gig_contract (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    date_key INTEGER NOT NULL,
    organisation_key INTEGER NOT NULL,
    worker_user_id UUID NOT NULL,
    contract_duration_days INTEGER NOT NULL,
    total_value_usd NUMERIC(12,2) NOT NULL,
    final_performance_rating NUMERIC(3,2) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_fact_gig_contract PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: analytics.fact_wallet_transaction
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.fact_wallet_transaction (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    date_key INTEGER NOT NULL,
    organisation_key INTEGER NOT NULL,
    transaction_category VARCHAR(30) NOT NULL,
    total_debit_amount NUMERIC(14,2) DEFAULT 0.00 NOT NULL,
    total_credit_amount NUMERIC(14,2) DEFAULT 0.00 NOT NULL,
    net_variance NUMERIC(14,2) DEFAULT 0.00 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_fact_wallet_transaction PRIMARY KEY (id)
);


-- >>> End of 140_analytics.sql <<<

-- >>> Start of 150_constraints_indexes_rls.sql <<<
-- =============================================================
-- Talentra Enterprise Workforce Platform: Foreign Keys, Indexes & RLS
-- =============================================================

-- -------------------------------------------------------------
-- FOREIGN KEY CONSTRAINTS
-- -------------------------------------------------------------
ALTER TABLE master_data.country ADD CONSTRAINT fk_country_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE master_data.state ADD CONSTRAINT fk_state_country_id FOREIGN KEY (country_id) REFERENCES master_data.country(id) ON DELETE RESTRICT;
ALTER TABLE master_data.city ADD CONSTRAINT fk_city_country_id FOREIGN KEY (country_id) REFERENCES master_data.country(id) ON DELETE RESTRICT;
ALTER TABLE master_data.city ADD CONSTRAINT fk_city_state_id FOREIGN KEY (state_id) REFERENCES master_data.state(id) ON DELETE RESTRICT;
ALTER TABLE master_data.job_role ADD CONSTRAINT fk_job_role_industry_id FOREIGN KEY (industry_id) REFERENCES master_data.industry(id) ON DELETE RESTRICT;
ALTER TABLE master_data.ui_translation ADD CONSTRAINT fk_ui_translation_key_id FOREIGN KEY (key_id) REFERENCES master_data.ui_translation_key(id) ON DELETE RESTRICT;
ALTER TABLE master_data.ui_translation ADD CONSTRAINT fk_ui_translation_language_code FOREIGN KEY (language_code) REFERENCES master_data.language(language_code) ON DELETE RESTRICT;
ALTER TABLE identity.user_account ADD CONSTRAINT fk_user_account_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE identity.user_credential ADD CONSTRAINT fk_user_credential_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE identity.user_role ADD CONSTRAINT fk_user_role_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE identity.user_role ADD CONSTRAINT fk_user_role_role_id FOREIGN KEY (role_id) REFERENCES identity.role(id) ON DELETE RESTRICT;
ALTER TABLE identity.user_role ADD CONSTRAINT fk_user_role_granted_by FOREIGN KEY (granted_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE identity.user_active_session ADD CONSTRAINT fk_user_active_session_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE identity.service_api_key ADD CONSTRAINT fk_service_api_key_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.account ADD CONSTRAINT fk_account_billing_currency_code FOREIGN KEY (billing_currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE organisation.account ADD CONSTRAINT fk_account_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.account ADD CONSTRAINT fk_account_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation ADD CONSTRAINT fk_organisation_account_id FOREIGN KEY (account_id) REFERENCES organisation.account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation ADD CONSTRAINT fk_organisation_industry_id FOREIGN KEY (industry_id) REFERENCES master_data.industry(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation ADD CONSTRAINT fk_organisation_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation ADD CONSTRAINT fk_organisation_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_city_id FOREIGN KEY (city_id) REFERENCES master_data.city(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_state_id FOREIGN KEY (state_id) REFERENCES master_data.state(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_country_id FOREIGN KEY (country_id) REFERENCES master_data.country(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_tax_identifier ADD CONSTRAINT fk_organisation_tax_identifier_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_tax_identifier ADD CONSTRAINT fk_organisation_tax_identifier_country_id FOREIGN KEY (country_id) REFERENCES master_data.country(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_verification ADD CONSTRAINT fk_organisation_verification_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_verification ADD CONSTRAINT fk_organisation_verification_verified_by FOREIGN KEY (verified_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.recruiter_seat_assignment ADD CONSTRAINT fk_recruiter_seat_assignment_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE organisation.recruiter_seat_assignment ADD CONSTRAINT fk_recruiter_seat_assignment_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.recruiter_seat_assignment ADD CONSTRAINT fk_recruiter_seat_assignment_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_hierarchy ADD CONSTRAINT fk_organisation_hierarchy_parent_organisation_id FOREIGN KEY (parent_organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_hierarchy ADD CONSTRAINT fk_organisation_hierarchy_child_organisation_id FOREIGN KEY (child_organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_current_city_id FOREIGN KEY (current_city_id) REFERENCES master_data.city(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_salary_currency_code FOREIGN KEY (salary_currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_education ADD CONSTRAINT fk_candidate_education_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_education ADD CONSTRAINT fk_candidate_education_qualification_id FOREIGN KEY (qualification_id) REFERENCES master_data.qualification(id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_work_experience ADD CONSTRAINT fk_candidate_work_experience_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_work_experience ADD CONSTRAINT fk_candidate_work_experience_job_role_id FOREIGN KEY (job_role_id) REFERENCES master_data.job_role(id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_work_experience ADD CONSTRAINT fk_candidate_work_experience_industry_id FOREIGN KEY (industry_id) REFERENCES master_data.industry(id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_skill ADD CONSTRAINT fk_candidate_skill_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_skill ADD CONSTRAINT fk_candidate_skill_skill_id FOREIGN KEY (skill_id) REFERENCES master_data.skill(id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_project ADD CONSTRAINT fk_candidate_project_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_resume ADD CONSTRAINT fk_candidate_resume_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_preference ADD CONSTRAINT fk_candidate_preference_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_block_list ADD CONSTRAINT fk_candidate_block_list_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_block_list ADD CONSTRAINT fk_candidate_block_list_blocked_organisation_id FOREIGN KEY (blocked_organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_block_list ADD CONSTRAINT fk_candidate_block_list_blocked_recruiter_user_id FOREIGN KEY (blocked_recruiter_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_language ADD CONSTRAINT fk_candidate_language_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_language ADD CONSTRAINT fk_candidate_language_language_code FOREIGN KEY (language_code) REFERENCES master_data.language(language_code) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_posted_by_user_id FOREIGN KEY (posted_by_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_job_role_id FOREIGN KEY (job_role_id) REFERENCES master_data.job_role(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_city_id FOREIGN KEY (city_id) REFERENCES master_data.city(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_salary_currency_code FOREIGN KEY (salary_currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition_skill ADD CONSTRAINT fk_job_requisition_skill_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition_skill ADD CONSTRAINT fk_job_requisition_skill_skill_id FOREIGN KEY (skill_id) REFERENCES master_data.skill(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_questionnaire ADD CONSTRAINT fk_job_questionnaire_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.questionnaire_question ADD CONSTRAINT fk_questionnaire_question_questionnaire_id FOREIGN KEY (questionnaire_id) REFERENCES recruitment.job_questionnaire(id) ON DELETE RESTRICT;
ALTER TABLE recruitment.question_option ADD CONSTRAINT fk_question_option_question_id FOREIGN KEY (question_id) REFERENCES recruitment.questionnaire_question(id) ON DELETE CASCADE;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition(id) ON DELETE RESTRICT;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_resume_id FOREIGN KEY (resume_id) REFERENCES candidate.candidate_resume(id) ON DELETE RESTRICT;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_consultant_id FOREIGN KEY (consultant_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE application.application_question_answer ADD CONSTRAINT fk_application_question_answer_application_id FOREIGN KEY (application_id) REFERENCES application.job_application(id) ON DELETE RESTRICT;
ALTER TABLE application.application_question_answer ADD CONSTRAINT fk_application_question_answer_question_id FOREIGN KEY (question_id) REFERENCES recruitment.questionnaire_question(id) ON DELETE RESTRICT;
ALTER TABLE application.application_question_answer ADD CONSTRAINT fk_application_question_answer_selected_option_id FOREIGN KEY (selected_option_id) REFERENCES recruitment.question_option(id) ON DELETE RESTRICT;
ALTER TABLE application.application_stage_history ADD CONSTRAINT fk_application_stage_history_application_id FOREIGN KEY (application_id) REFERENCES application.job_application(id) ON DELETE RESTRICT;
ALTER TABLE application.application_stage_history ADD CONSTRAINT fk_application_stage_history_changed_by_user_id FOREIGN KEY (changed_by_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE application.job_interview ADD CONSTRAINT fk_job_interview_application_id FOREIGN KEY (application_id) REFERENCES application.job_application(id) ON DELETE RESTRICT;
ALTER TABLE application.job_interview ADD CONSTRAINT fk_job_interview_interviewer_user_id FOREIGN KEY (interviewer_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE application.interview_feedback ADD CONSTRAINT fk_interview_feedback_interview_id FOREIGN KEY (interview_id) REFERENCES application.job_interview(id) ON DELETE CASCADE;
ALTER TABLE application.interview_feedback ADD CONSTRAINT fk_interview_feedback_interviewer_user_id FOREIGN KEY (interviewer_user_id) REFERENCES identity.user_account(id) ON DELETE CASCADE;
ALTER TABLE application.job_offer ADD CONSTRAINT fk_job_offer_application_id FOREIGN KEY (application_id) REFERENCES application.job_application(id) ON DELETE RESTRICT;
ALTER TABLE application.job_offer ADD CONSTRAINT fk_job_offer_salary_currency_code FOREIGN KEY (salary_currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE application.job_offer ADD CONSTRAINT fk_job_offer_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.consultant_authorization ADD CONSTRAINT fk_consultant_authorization_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.consultant_authorization ADD CONSTRAINT fk_consultant_authorization_consultant_user_id FOREIGN KEY (consultant_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.consultant_authorization ADD CONSTRAINT fk_consultant_authorization_authorized_by_user_id FOREIGN KEY (authorized_by_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.candidate_nomination ADD CONSTRAINT fk_candidate_nomination_authorization_id FOREIGN KEY (authorization_id) REFERENCES sourcing.consultant_authorization(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.candidate_nomination ADD CONSTRAINT fk_candidate_nomination_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_campaign ADD CONSTRAINT fk_outreach_campaign_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_campaign ADD CONSTRAINT fk_outreach_campaign_created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_recipient ADD CONSTRAINT fk_outreach_recipient_campaign_id FOREIGN KEY (campaign_id) REFERENCES sourcing.outreach_campaign(id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_recipient ADD CONSTRAINT fk_outreach_recipient_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_profile ADD CONSTRAINT fk_gig_worker_profile_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_profile ADD CONSTRAINT fk_gig_worker_profile_rate_currency_code FOREIGN KEY (rate_currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_service ADD CONSTRAINT fk_gig_worker_service_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_service ADD CONSTRAINT fk_gig_worker_service_service_category_id FOREIGN KEY (service_category_id) REFERENCES master_data.industry(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_service ADD CONSTRAINT fk_gig_worker_service_price_currency_code FOREIGN KEY (price_currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_availability ADD CONSTRAINT fk_gig_worker_availability_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_posted_by_user_id FOREIGN KEY (posted_by_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_project_category_id FOREIGN KEY (project_category_id) REFERENCES master_data.industry(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_budget_currency_code FOREIGN KEY (budget_currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_proposal ADD CONSTRAINT fk_gig_proposal_request_id FOREIGN KEY (request_id) REFERENCES gig.gig_request(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_proposal ADD CONSTRAINT fk_gig_proposal_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_proposal ADD CONSTRAINT fk_gig_proposal_proposed_currency_code FOREIGN KEY (proposed_currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_request_id FOREIGN KEY (request_id) REFERENCES gig.gig_request(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_proposal_id FOREIGN KEY (proposal_id) REFERENCES gig.gig_proposal(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_milestone ADD CONSTRAINT fk_gig_milestone_contract_id FOREIGN KEY (contract_id) REFERENCES gig.gig_contract(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_milestone ADD CONSTRAINT fk_gig_milestone_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_rating ADD CONSTRAINT fk_gig_rating_contract_id FOREIGN KEY (contract_id) REFERENCES gig.gig_contract(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_rating ADD CONSTRAINT fk_gig_rating_rater_user_id FOREIGN KEY (rater_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_rating ADD CONSTRAINT fk_gig_rating_rated_user_id FOREIGN KEY (rated_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE gig.client_gig_worker_preference ADD CONSTRAINT fk_client_gig_worker_preference_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE gig.client_gig_worker_preference ADD CONSTRAINT fk_client_gig_worker_preference_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile(id) ON DELETE RESTRICT;
ALTER TABLE gig.client_gig_worker_preference ADD CONSTRAINT fk_client_gig_worker_preference_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_plan ADD CONSTRAINT fk_subscription_plan_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_licence ADD CONSTRAINT fk_subscription_licence_account_id FOREIGN KEY (account_id) REFERENCES organisation.account(id) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_licence ADD CONSTRAINT fk_subscription_licence_plan_id FOREIGN KEY (plan_id) REFERENCES licensing.subscription_plan(id) ON DELETE RESTRICT;
ALTER TABLE licensing.licence_entitlement_usage ADD CONSTRAINT fk_licence_entitlement_usage_licence_id FOREIGN KEY (licence_id) REFERENCES licensing.subscription_licence(id) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_account ADD CONSTRAINT fk_wallet_account_account_id FOREIGN KEY (account_id) REFERENCES organisation.account(id) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_account ADD CONSTRAINT fk_wallet_account_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_ledger ADD CONSTRAINT fk_wallet_ledger_wallet_id FOREIGN KEY (wallet_id) REFERENCES billing.wallet_account(id) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_ledger ADD CONSTRAINT fk_wallet_ledger_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.payment_order ADD CONSTRAINT fk_payment_order_account_id FOREIGN KEY (account_id) REFERENCES organisation.account(id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_order ADD CONSTRAINT fk_payment_order_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.payment_transaction ADD CONSTRAINT fk_payment_transaction_order_id FOREIGN KEY (order_id) REFERENCES billing.payment_order(id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_transaction ADD CONSTRAINT fk_payment_transaction_wallet_id FOREIGN KEY (wallet_id) REFERENCES billing.wallet_account(id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_transaction ADD CONSTRAINT fk_payment_transaction_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.invoice ADD CONSTRAINT fk_invoice_account_id FOREIGN KEY (account_id) REFERENCES organisation.account(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice ADD CONSTRAINT fk_invoice_order_id FOREIGN KEY (order_id) REFERENCES billing.payment_order(id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice ADD CONSTRAINT fk_invoice_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_item ADD CONSTRAINT fk_invoice_item_invoice_id FOREIGN KEY (invoice_id) REFERENCES billing.invoice(id) ON DELETE CASCADE;
ALTER TABLE billing.invoice_item ADD CONSTRAINT fk_invoice_item_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency(currency_code) ON DELETE CASCADE;
ALTER TABLE billing.profile_download_history ADD CONSTRAINT fk_profile_download_history_recruiter_user_id FOREIGN KEY (recruiter_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE billing.profile_download_history ADD CONSTRAINT fk_profile_download_history_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE billing.profile_download_history ADD CONSTRAINT fk_profile_download_history_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE engagement.candidate_saved_search ADD CONSTRAINT fk_candidate_saved_search_recruiter_user_id FOREIGN KEY (recruiter_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE engagement.job_alert_subscription ADD CONSTRAINT fk_job_alert_subscription_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE engagement.notification_delivery ADD CONSTRAINT fk_notification_delivery_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_recruiter_user_id FOREIGN KEY (recruiter_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition(id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_unlock_receipt_id FOREIGN KEY (unlock_receipt_id) REFERENCES billing.profile_download_history(id) ON DELETE RESTRICT;
ALTER TABLE engagement.thread_message ADD CONSTRAINT fk_thread_message_thread_id FOREIGN KEY (thread_id) REFERENCES engagement.message_thread(id) ON DELETE RESTRICT;
ALTER TABLE engagement.thread_message ADD CONSTRAINT fk_thread_message_sender_user_id FOREIGN KEY (sender_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE engagement.candidate_referral_link ADD CONSTRAINT fk_candidate_referral_link_referrer_user_id FOREIGN KEY (referrer_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE engagement.referral_attribution_event ADD CONSTRAINT fk_referral_attribution_event_referral_link_id FOREIGN KEY (referral_link_id) REFERENCES engagement.candidate_referral_link(id) ON DELETE RESTRICT;
ALTER TABLE engagement.referral_attribution_event ADD CONSTRAINT fk_referral_attribution_event_referred_user_id FOREIGN KEY (referred_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_placement_cohort ADD CONSTRAINT fk_campus_placement_cohort_tpo_user_id FOREIGN KEY (tpo_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_student_member ADD CONSTRAINT fk_campus_student_member_cohort_id FOREIGN KEY (cohort_id) REFERENCES engagement.campus_placement_cohort(id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_student_member ADD CONSTRAINT fk_campus_student_member_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE governance.dpdp_consent_record ADD CONSTRAINT fk_dpdp_consent_record_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE governance.pii_encryption_key ADD CONSTRAINT fk_pii_encryption_key_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE governance.pii_encryption_key ADD CONSTRAINT fk_pii_encryption_key_shredded_by_user_id FOREIGN KEY (shredded_by_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE governance.system_audit_event ADD CONSTRAINT fk_system_audit_event_actor_user_id FOREIGN KEY (actor_user_id) REFERENCES identity.user_account(id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_candidate ADD CONSTRAINT fk_dim_candidate_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile(id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_organisation ADD CONSTRAINT fk_dim_organisation_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation(id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_job_requisition ADD CONSTRAINT fk_dim_job_requisition_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition(id) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_date_key FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_candidate_key FOREIGN KEY (candidate_key) REFERENCES analytics.dim_candidate(candidate_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_organisation_key FOREIGN KEY (organisation_key) REFERENCES analytics.dim_organisation(organisation_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_requisition_key FOREIGN KEY (requisition_key) REFERENCES analytics.dim_job_requisition(requisition_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_from_stage_key FOREIGN KEY (from_stage_key) REFERENCES analytics.dim_pipeline_stage(stage_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_to_stage_key FOREIGN KEY (to_stage_key) REFERENCES analytics.dim_pipeline_stage(stage_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_profile_download ADD CONSTRAINT fk_fact_profile_download_date_key FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_profile_download ADD CONSTRAINT fk_fact_profile_download_organisation_key FOREIGN KEY (organisation_key) REFERENCES analytics.dim_organisation(organisation_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_profile_download ADD CONSTRAINT fk_fact_profile_download_candidate_key FOREIGN KEY (candidate_key) REFERENCES analytics.dim_candidate(candidate_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_gig_contract ADD CONSTRAINT fk_fact_gig_contract_date_key FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_gig_contract ADD CONSTRAINT fk_fact_gig_contract_organisation_key FOREIGN KEY (organisation_key) REFERENCES analytics.dim_organisation(organisation_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_wallet_transaction ADD CONSTRAINT fk_fact_wallet_transaction_date_key FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_wallet_transaction ADD CONSTRAINT fk_fact_wallet_transaction_organisation_key FOREIGN KEY (organisation_key) REFERENCES analytics.dim_organisation(organisation_key) ON DELETE RESTRICT;

-- -------------------------------------------------------------
-- PERFORMANCE INDEXES
-- -------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_country_currency_code ON master_data.country(currency_code);
CREATE INDEX IF NOT EXISTS idx_state_country_id ON master_data.state(country_id);
CREATE INDEX IF NOT EXISTS idx_city_country_id ON master_data.city(country_id);
CREATE INDEX IF NOT EXISTS idx_city_state_id ON master_data.city(state_id);
CREATE INDEX IF NOT EXISTS idx_job_role_industry_id ON master_data.job_role(industry_id);
CREATE INDEX IF NOT EXISTS idx_ui_translation_key_id ON master_data.ui_translation(key_id);
CREATE INDEX IF NOT EXISTS idx_ui_translation_language_code ON master_data.ui_translation(language_code);
CREATE INDEX IF NOT EXISTS idx_user_account_updated_by ON identity.user_account(updated_by);
CREATE INDEX IF NOT EXISTS idx_user_credential_user_id ON identity.user_credential(user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_user_id ON identity.user_role(user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_role_id ON identity.user_role(role_id);
CREATE INDEX IF NOT EXISTS idx_user_role_granted_by ON identity.user_role(granted_by);
CREATE INDEX IF NOT EXISTS idx_user_active_session_user_id ON identity.user_active_session(user_id);
CREATE INDEX IF NOT EXISTS idx_service_api_key_user_id ON identity.service_api_key(user_id);
CREATE INDEX IF NOT EXISTS idx_account_billing_currency_code ON organisation.account(billing_currency_code);
CREATE INDEX IF NOT EXISTS idx_account_created_by ON organisation.account(created_by);
CREATE INDEX IF NOT EXISTS idx_account_updated_by ON organisation.account(updated_by);
CREATE INDEX IF NOT EXISTS idx_organisation_account_id ON organisation.organisation(account_id);
CREATE INDEX IF NOT EXISTS idx_organisation_industry_id ON organisation.organisation(industry_id);
CREATE INDEX IF NOT EXISTS idx_organisation_created_by ON organisation.organisation(created_by);
CREATE INDEX IF NOT EXISTS idx_organisation_updated_by ON organisation.organisation(updated_by);
CREATE INDEX IF NOT EXISTS idx_organisation_location_organisation_id ON organisation.organisation_location(organisation_id);
CREATE INDEX IF NOT EXISTS idx_organisation_location_city_id ON organisation.organisation_location(city_id);
CREATE INDEX IF NOT EXISTS idx_organisation_location_state_id ON organisation.organisation_location(state_id);
CREATE INDEX IF NOT EXISTS idx_organisation_location_country_id ON organisation.organisation_location(country_id);
CREATE INDEX IF NOT EXISTS idx_organisation_tax_identifier_organisation_id ON organisation.organisation_tax_identifier(organisation_id);
CREATE INDEX IF NOT EXISTS idx_organisation_tax_identifier_country_id ON organisation.organisation_tax_identifier(country_id);
CREATE INDEX IF NOT EXISTS idx_organisation_verification_organisation_id ON organisation.organisation_verification(organisation_id);
CREATE INDEX IF NOT EXISTS idx_organisation_verification_verified_by ON organisation.organisation_verification(verified_by);
CREATE INDEX IF NOT EXISTS idx_recruiter_seat_assignment_organisation_id ON organisation.recruiter_seat_assignment(organisation_id);
CREATE INDEX IF NOT EXISTS idx_recruiter_seat_assignment_user_id ON organisation.recruiter_seat_assignment(user_id);
CREATE INDEX IF NOT EXISTS idx_recruiter_seat_assignment_created_by ON organisation.recruiter_seat_assignment(created_by);
CREATE INDEX IF NOT EXISTS idx_organisation_hierarchy_parent_organisation_id ON organisation.organisation_hierarchy(parent_organisation_id);
CREATE INDEX IF NOT EXISTS idx_organisation_hierarchy_child_organisation_id ON organisation.organisation_hierarchy(child_organisation_id);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_user_id ON candidate.candidate_profile(user_id);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_current_city_id ON candidate.candidate_profile(current_city_id);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_salary_currency_code ON candidate.candidate_profile(salary_currency_code);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_created_by ON candidate.candidate_profile(created_by);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_updated_by ON candidate.candidate_profile(updated_by);
CREATE INDEX IF NOT EXISTS idx_candidate_education_candidate_id ON candidate.candidate_education(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_education_qualification_id ON candidate.candidate_education(qualification_id);
CREATE INDEX IF NOT EXISTS idx_candidate_work_experience_candidate_id ON candidate.candidate_work_experience(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_work_experience_job_role_id ON candidate.candidate_work_experience(job_role_id);
CREATE INDEX IF NOT EXISTS idx_candidate_work_experience_industry_id ON candidate.candidate_work_experience(industry_id);
CREATE INDEX IF NOT EXISTS idx_candidate_skill_candidate_id ON candidate.candidate_skill(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_skill_skill_id ON candidate.candidate_skill(skill_id);
CREATE INDEX IF NOT EXISTS idx_candidate_project_candidate_id ON candidate.candidate_project(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_resume_candidate_id ON candidate.candidate_resume(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_preference_candidate_id ON candidate.candidate_preference(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_block_list_candidate_id ON candidate.candidate_block_list(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_block_list_blocked_organisation_id ON candidate.candidate_block_list(blocked_organisation_id);
CREATE INDEX IF NOT EXISTS idx_candidate_block_list_blocked_recruiter_user_id ON candidate.candidate_block_list(blocked_recruiter_user_id);
CREATE INDEX IF NOT EXISTS idx_candidate_language_candidate_id ON candidate.candidate_language(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_language_language_code ON candidate.candidate_language(language_code);
CREATE INDEX IF NOT EXISTS idx_job_requisition_organisation_id ON recruitment.job_requisition(organisation_id);
CREATE INDEX IF NOT EXISTS idx_job_requisition_posted_by_user_id ON recruitment.job_requisition(posted_by_user_id);
CREATE INDEX IF NOT EXISTS idx_job_requisition_job_role_id ON recruitment.job_requisition(job_role_id);
CREATE INDEX IF NOT EXISTS idx_job_requisition_city_id ON recruitment.job_requisition(city_id);
CREATE INDEX IF NOT EXISTS idx_job_requisition_salary_currency_code ON recruitment.job_requisition(salary_currency_code);
CREATE INDEX IF NOT EXISTS idx_job_requisition_created_by ON recruitment.job_requisition(created_by);
CREATE INDEX IF NOT EXISTS idx_job_requisition_updated_by ON recruitment.job_requisition(updated_by);
CREATE INDEX IF NOT EXISTS idx_job_requisition_skill_requisition_id ON recruitment.job_requisition_skill(requisition_id);
CREATE INDEX IF NOT EXISTS idx_job_requisition_skill_skill_id ON recruitment.job_requisition_skill(skill_id);
CREATE INDEX IF NOT EXISTS idx_job_questionnaire_requisition_id ON recruitment.job_questionnaire(requisition_id);
CREATE INDEX IF NOT EXISTS idx_questionnaire_question_questionnaire_id ON recruitment.questionnaire_question(questionnaire_id);
CREATE INDEX IF NOT EXISTS idx_question_option_question_id ON recruitment.question_option(question_id);
CREATE INDEX IF NOT EXISTS idx_job_application_requisition_id ON application.job_application(requisition_id);
CREATE INDEX IF NOT EXISTS idx_job_application_candidate_id ON application.job_application(candidate_id);
CREATE INDEX IF NOT EXISTS idx_job_application_resume_id ON application.job_application(resume_id);
CREATE INDEX IF NOT EXISTS idx_job_application_consultant_id ON application.job_application(consultant_id);
CREATE INDEX IF NOT EXISTS idx_application_question_answer_application_id ON application.application_question_answer(application_id);
CREATE INDEX IF NOT EXISTS idx_application_question_answer_question_id ON application.application_question_answer(question_id);
CREATE INDEX IF NOT EXISTS idx_application_question_answer_selected_option_id ON application.application_question_answer(selected_option_id);
CREATE INDEX IF NOT EXISTS idx_application_stage_history_application_id ON application.application_stage_history(application_id);
CREATE INDEX IF NOT EXISTS idx_application_stage_history_changed_by_user_id ON application.application_stage_history(changed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_job_interview_application_id ON application.job_interview(application_id);
CREATE INDEX IF NOT EXISTS idx_job_interview_interviewer_user_id ON application.job_interview(interviewer_user_id);
CREATE INDEX IF NOT EXISTS idx_interview_feedback_interview_id ON application.interview_feedback(interview_id);
CREATE INDEX IF NOT EXISTS idx_interview_feedback_interviewer_user_id ON application.interview_feedback(interviewer_user_id);
CREATE INDEX IF NOT EXISTS idx_job_offer_application_id ON application.job_offer(application_id);
CREATE INDEX IF NOT EXISTS idx_job_offer_salary_currency_code ON application.job_offer(salary_currency_code);
CREATE INDEX IF NOT EXISTS idx_job_offer_created_by ON application.job_offer(created_by);
CREATE INDEX IF NOT EXISTS idx_consultant_authorization_requisition_id ON sourcing.consultant_authorization(requisition_id);
CREATE INDEX IF NOT EXISTS idx_consultant_authorization_consultant_user_id ON sourcing.consultant_authorization(consultant_user_id);
CREATE INDEX IF NOT EXISTS idx_consultant_authorization_authorized_by_user_id ON sourcing.consultant_authorization(authorized_by_user_id);
CREATE INDEX IF NOT EXISTS idx_candidate_nomination_authorization_id ON sourcing.candidate_nomination(authorization_id);
CREATE INDEX IF NOT EXISTS idx_candidate_nomination_candidate_id ON sourcing.candidate_nomination(candidate_id);
CREATE INDEX IF NOT EXISTS idx_outreach_campaign_organisation_id ON sourcing.outreach_campaign(organisation_id);
CREATE INDEX IF NOT EXISTS idx_outreach_campaign_created_by_user_id ON sourcing.outreach_campaign(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_outreach_recipient_campaign_id ON sourcing.outreach_recipient(campaign_id);
CREATE INDEX IF NOT EXISTS idx_outreach_recipient_candidate_id ON sourcing.outreach_recipient(candidate_id);
CREATE INDEX IF NOT EXISTS idx_gig_worker_profile_user_id ON gig.gig_worker_profile(user_id);
CREATE INDEX IF NOT EXISTS idx_gig_worker_profile_rate_currency_code ON gig.gig_worker_profile(rate_currency_code);
CREATE INDEX IF NOT EXISTS idx_gig_worker_service_worker_id ON gig.gig_worker_service(worker_id);
CREATE INDEX IF NOT EXISTS idx_gig_worker_service_service_category_id ON gig.gig_worker_service(service_category_id);
CREATE INDEX IF NOT EXISTS idx_gig_worker_service_price_currency_code ON gig.gig_worker_service(price_currency_code);
CREATE INDEX IF NOT EXISTS idx_gig_worker_availability_worker_id ON gig.gig_worker_availability(worker_id);
CREATE INDEX IF NOT EXISTS idx_gig_request_organisation_id ON gig.gig_request(organisation_id);
CREATE INDEX IF NOT EXISTS idx_gig_request_posted_by_user_id ON gig.gig_request(posted_by_user_id);
CREATE INDEX IF NOT EXISTS idx_gig_request_project_category_id ON gig.gig_request(project_category_id);
CREATE INDEX IF NOT EXISTS idx_gig_request_budget_currency_code ON gig.gig_request(budget_currency_code);
CREATE INDEX IF NOT EXISTS idx_gig_proposal_request_id ON gig.gig_proposal(request_id);
CREATE INDEX IF NOT EXISTS idx_gig_proposal_worker_id ON gig.gig_proposal(worker_id);
CREATE INDEX IF NOT EXISTS idx_gig_proposal_proposed_currency_code ON gig.gig_proposal(proposed_currency_code);
CREATE INDEX IF NOT EXISTS idx_gig_contract_request_id ON gig.gig_contract(request_id);
CREATE INDEX IF NOT EXISTS idx_gig_contract_proposal_id ON gig.gig_contract(proposal_id);
CREATE INDEX IF NOT EXISTS idx_gig_contract_worker_id ON gig.gig_contract(worker_id);
CREATE INDEX IF NOT EXISTS idx_gig_contract_organisation_id ON gig.gig_contract(organisation_id);
CREATE INDEX IF NOT EXISTS idx_gig_contract_currency_code ON gig.gig_contract(currency_code);
CREATE INDEX IF NOT EXISTS idx_gig_milestone_contract_id ON gig.gig_milestone(contract_id);
CREATE INDEX IF NOT EXISTS idx_gig_milestone_currency_code ON gig.gig_milestone(currency_code);
CREATE INDEX IF NOT EXISTS idx_gig_rating_contract_id ON gig.gig_rating(contract_id);
CREATE INDEX IF NOT EXISTS idx_gig_rating_rater_user_id ON gig.gig_rating(rater_user_id);
CREATE INDEX IF NOT EXISTS idx_gig_rating_rated_user_id ON gig.gig_rating(rated_user_id);
CREATE INDEX IF NOT EXISTS idx_client_gig_worker_preference_organisation_id ON gig.client_gig_worker_preference(organisation_id);
CREATE INDEX IF NOT EXISTS idx_client_gig_worker_preference_worker_id ON gig.client_gig_worker_preference(worker_id);
CREATE INDEX IF NOT EXISTS idx_client_gig_worker_preference_created_by ON gig.client_gig_worker_preference(created_by);
CREATE INDEX IF NOT EXISTS idx_subscription_plan_currency_code ON licensing.subscription_plan(currency_code);
CREATE INDEX IF NOT EXISTS idx_subscription_licence_account_id ON licensing.subscription_licence(account_id);
CREATE INDEX IF NOT EXISTS idx_subscription_licence_plan_id ON licensing.subscription_licence(plan_id);
CREATE INDEX IF NOT EXISTS idx_licence_entitlement_usage_licence_id ON licensing.licence_entitlement_usage(licence_id);
CREATE INDEX IF NOT EXISTS idx_wallet_account_account_id ON billing.wallet_account(account_id);
CREATE INDEX IF NOT EXISTS idx_wallet_account_currency_code ON billing.wallet_account(currency_code);
CREATE INDEX IF NOT EXISTS idx_wallet_ledger_wallet_id ON billing.wallet_ledger(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_ledger_currency_code ON billing.wallet_ledger(currency_code);
CREATE INDEX IF NOT EXISTS idx_payment_order_account_id ON billing.payment_order(account_id);
CREATE INDEX IF NOT EXISTS idx_payment_order_currency_code ON billing.payment_order(currency_code);
CREATE INDEX IF NOT EXISTS idx_payment_transaction_order_id ON billing.payment_transaction(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transaction_wallet_id ON billing.payment_transaction(wallet_id);
CREATE INDEX IF NOT EXISTS idx_payment_transaction_currency_code ON billing.payment_transaction(currency_code);
CREATE INDEX IF NOT EXISTS idx_invoice_account_id ON billing.invoice(account_id);
CREATE INDEX IF NOT EXISTS idx_invoice_order_id ON billing.invoice(order_id);
CREATE INDEX IF NOT EXISTS idx_invoice_currency_code ON billing.invoice(currency_code);
CREATE INDEX IF NOT EXISTS idx_invoice_item_invoice_id ON billing.invoice_item(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_item_currency_code ON billing.invoice_item(currency_code);
CREATE INDEX IF NOT EXISTS idx_profile_download_history_recruiter_user_id ON billing.profile_download_history(recruiter_user_id);
CREATE INDEX IF NOT EXISTS idx_profile_download_history_organisation_id ON billing.profile_download_history(organisation_id);
CREATE INDEX IF NOT EXISTS idx_profile_download_history_candidate_id ON billing.profile_download_history(candidate_id);
CREATE INDEX IF NOT EXISTS idx_candidate_saved_search_recruiter_user_id ON engagement.candidate_saved_search(recruiter_user_id);
CREATE INDEX IF NOT EXISTS idx_job_alert_subscription_candidate_id ON engagement.job_alert_subscription(candidate_id);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_user_id ON engagement.notification_delivery(user_id);
CREATE INDEX IF NOT EXISTS idx_message_thread_recruiter_user_id ON engagement.message_thread(recruiter_user_id);
CREATE INDEX IF NOT EXISTS idx_message_thread_candidate_id ON engagement.message_thread(candidate_id);
CREATE INDEX IF NOT EXISTS idx_message_thread_requisition_id ON engagement.message_thread(requisition_id);
CREATE INDEX IF NOT EXISTS idx_message_thread_unlock_receipt_id ON engagement.message_thread(unlock_receipt_id);
CREATE INDEX IF NOT EXISTS idx_thread_message_thread_id ON engagement.thread_message(thread_id);
CREATE INDEX IF NOT EXISTS idx_thread_message_sender_user_id ON engagement.thread_message(sender_user_id);
CREATE INDEX IF NOT EXISTS idx_candidate_referral_link_referrer_user_id ON engagement.candidate_referral_link(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_referral_attribution_event_referral_link_id ON engagement.referral_attribution_event(referral_link_id);
CREATE INDEX IF NOT EXISTS idx_referral_attribution_event_referred_user_id ON engagement.referral_attribution_event(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_campus_placement_cohort_tpo_user_id ON engagement.campus_placement_cohort(tpo_user_id);
CREATE INDEX IF NOT EXISTS idx_campus_student_member_cohort_id ON engagement.campus_student_member(cohort_id);
CREATE INDEX IF NOT EXISTS idx_campus_student_member_candidate_id ON engagement.campus_student_member(candidate_id);
CREATE INDEX IF NOT EXISTS idx_dpdp_consent_record_user_id ON governance.dpdp_consent_record(user_id);
CREATE INDEX IF NOT EXISTS idx_pii_encryption_key_user_id ON governance.pii_encryption_key(user_id);
CREATE INDEX IF NOT EXISTS idx_pii_encryption_key_shredded_by_user_id ON governance.pii_encryption_key(shredded_by_user_id);
CREATE INDEX IF NOT EXISTS idx_system_audit_event_actor_user_id ON governance.system_audit_event(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_dim_candidate_candidate_id ON analytics.dim_candidate(candidate_id);
CREATE INDEX IF NOT EXISTS idx_dim_organisation_organisation_id ON analytics.dim_organisation(organisation_id);
CREATE INDEX IF NOT EXISTS idx_dim_job_requisition_requisition_id ON analytics.dim_job_requisition(requisition_id);
CREATE INDEX IF NOT EXISTS idx_fact_application_event_date_key ON analytics.fact_application_event(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_application_event_candidate_key ON analytics.fact_application_event(candidate_key);
CREATE INDEX IF NOT EXISTS idx_fact_application_event_organisation_key ON analytics.fact_application_event(organisation_key);
CREATE INDEX IF NOT EXISTS idx_fact_application_event_requisition_key ON analytics.fact_application_event(requisition_key);
CREATE INDEX IF NOT EXISTS idx_fact_application_event_from_stage_key ON analytics.fact_application_event(from_stage_key);
CREATE INDEX IF NOT EXISTS idx_fact_application_event_to_stage_key ON analytics.fact_application_event(to_stage_key);
CREATE INDEX IF NOT EXISTS idx_fact_profile_download_date_key ON analytics.fact_profile_download(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_profile_download_organisation_key ON analytics.fact_profile_download(organisation_key);
CREATE INDEX IF NOT EXISTS idx_fact_profile_download_candidate_key ON analytics.fact_profile_download(candidate_key);
CREATE INDEX IF NOT EXISTS idx_fact_gig_contract_date_key ON analytics.fact_gig_contract(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_gig_contract_organisation_key ON analytics.fact_gig_contract(organisation_key);
CREATE INDEX IF NOT EXISTS idx_fact_wallet_transaction_date_key ON analytics.fact_wallet_transaction(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_wallet_transaction_organisation_key ON analytics.fact_wallet_transaction(organisation_key);

-- Partial indexes for high-frequency queries
CREATE INDEX IF NOT EXISTS idx_user_account_active ON identity.user_account(id) WHERE account_status = 'ACTIVE_VERIFIED';
CREATE INDEX IF NOT EXISTS idx_job_req_published ON recruitment.job_requisition(id, organisation_id) WHERE publish_status = 'PUBLISHED_ACTIVE';
CREATE INDEX IF NOT EXISTS idx_job_app_active ON application.job_application(requisition_id, candidate_id) WHERE application_status NOT IN ('REJECTED', 'WITHDRAWN');
CREATE INDEX IF NOT EXISTS idx_candidate_discoverable ON candidate.candidate_profile(id) WHERE profile_status = 'ACTIVE_DISCOVERABLE';
CREATE INDEX IF NOT EXISTS idx_gig_active_requests ON gig.gig_request(id, requester_user_id) WHERE request_status = 'OPEN_BIDDING';
CREATE INDEX IF NOT EXISTS idx_ledger_account_created ON billing.wallet_ledger(wallet_account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_created ON governance.system_audit_event(created_at DESC);

-- -------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) POLICIES
-- -------------------------------------------------------------
ALTER TABLE candidate.candidate_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidate.candidate_resume ENABLE ROW LEVEL SECURITY;
ALTER TABLE organisation.organisation ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruitment.job_requisition ENABLE ROW LEVEL SECURITY;
ALTER TABLE application.job_application ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing.wallet_account ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing.wallet_ledger ENABLE ROW LEVEL SECURITY;

-- Candidates can view/update their own profile
CREATE POLICY p_candidate_own_profile ON candidate.candidate_profile
    FOR ALL USING (user_account_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

-- Organization members can view their organization
CREATE POLICY p_org_member ON organisation.organisation
    FOR SELECT USING (id = NULLIF(current_setting('app.current_organisation_id', true), '')::uuid);

-- >>> End of 150_constraints_indexes_rls.sql <<<

-- >>> Start of 160_triggers_and_procedures.sql <<<
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

-- >>> End of 160_triggers_and_procedures.sql <<<

