-- =============================================================================
-- Talentra Database Design
-- Module: Administration, Organisation & Access Control
-- Engine: PostgreSQL 15+
-- Adherence: Aligned with Hackathon Docket Section 3 & Section 5
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS administration;
CREATE SCHEMA IF NOT EXISTS organisation;
CREATE SCHEMA IF NOT EXISTS recruitment;

-- -----------------------------------------------------------------------------
-- 1. User Accounts & Credentials (Rule Groups 1, 2, 3)
-- -----------------------------------------------------------------------------

CREATE TABLE administration.user_account (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(254) NOT NULL,
    phone_e164 VARCHAR(20) NOT NULL,
    country_code CHAR(2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID NOT NULL,
    deleted_at TIMESTAMPTZ,

    CONSTRAINT uq_user_account_email UNIQUE (email),
    CONSTRAINT chk_user_account_email CHECK (email ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$')
);

CREATE TABLE administration.role (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NOT NULL,
    is_system_role BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT uq_role_code UNIQUE (code)
);

-- Seed the 9 human actors + 2 system roles from Section 3 of the Hackathon Docket
INSERT INTO administration.role (code, name, description)
VALUES
    ('SUPER_ADMIN', 'Super Administrator', 'Global platform infrastructure & configuration'),
    ('ADMIN', 'Platform Administrator', 'Operational moderation and tenant onboarding'),
    ('ACCOUNT_ADMIN', 'Tenant Account Administrator', 'Corporate seat, subscription and recruiter allocation'),
    ('GUEST', 'Public Guest User', 'Public unauthenticated browsing'),
    ('CANDIDATE', 'Talent Candidate', 'Job seeker, resume owner and applicant'),
    ('EMPLOYER', 'Client / Hiring Enterprise', 'Enterprise employer posting requisitions and hiring'),
    ('RECRUITER', 'Corporate Recruiter', 'In-house recruiter screening and managing pipeline'),
    ('CONSULTANT', 'Freelance Sourcing Consultant', 'External headhunter sourcing for approved openings'),
    ('TPO', 'Training & Placement Officer', 'Campus recruitment officer managing college cohorts'),
    ('AUDITOR', 'Security & Financial Auditor', 'Read-only audit trail and compliance verification'),
    ('SYSTEM_WORKER', 'System Integration Worker', 'Automated queue consumer, billing & ETL worker')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE administration.user_role (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES administration.user_account(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES administration.role(id) ON DELETE RESTRICT,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    assigned_by UUID NOT NULL,

    CONSTRAINT uq_user_role UNIQUE (user_id, role_id)
);


-- -----------------------------------------------------------------------------
-- 2. Organisation Hierarchy & Effective-Dated Recruiter Mapping
-- -----------------------------------------------------------------------------

CREATE TABLE organisation.organisation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legal_name VARCHAR(150) NOT NULL,
    trade_name VARCHAR(150),
    registration_identifier VARCHAR(100) NOT NULL,
    tax_identifier VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL,
    verification_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID NOT NULL,
    deleted_at TIMESTAMPTZ,

    CONSTRAINT uq_organisation_tax UNIQUE (country_code, tax_identifier),
    CONSTRAINT chk_organisation_verification CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED'))
);

CREATE TABLE organisation.organisation_recruiter_mapping (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID NOT NULL REFERENCES organisation.organisation(id) ON DELETE RESTRICT,
    recruiter_user_id UUID NOT NULL REFERENCES administration.user_account(id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,

    CONSTRAINT chk_recruiter_mapping_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_recruiter_mapping_active ON organisation.organisation_recruiter_mapping(recruiter_user_id) WHERE is_active = TRUE;


-- -----------------------------------------------------------------------------
-- 3. Candidate Privacy & Blocking List (Docket Section 3 Rule)
-- Rule: "A candidate may block employers, recruiters, or consultants, and a blocked party must not see that candidate."
-- -----------------------------------------------------------------------------

CREATE TABLE administration.candidate_block_list (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_user_id UUID NOT NULL REFERENCES administration.user_account(id) ON DELETE CASCADE,
    blocked_organisation_id UUID REFERENCES organisation.organisation(id) ON DELETE CASCADE,
    blocked_user_id UUID REFERENCES administration.user_account(id) ON DELETE CASCADE,
    reason_code VARCHAR(50) NOT NULL DEFAULT 'UNSPECIFIED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT chk_candidate_block_target CHECK (blocked_organisation_id IS NOT NULL OR blocked_user_id IS NOT NULL)
);

CREATE INDEX idx_candidate_block_org ON administration.candidate_block_list(blocked_organisation_id);
CREATE INDEX idx_candidate_block_user ON administration.candidate_block_list(blocked_user_id);


-- -----------------------------------------------------------------------------
-- 4. Session Tracking & Concurrent Device Limits (Rule Group 9)
-- Rule: "A user cannot hold more active sessions than the number of devices allowed by their licence."
-- -----------------------------------------------------------------------------

CREATE TABLE administration.user_active_session (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES administration.user_account(id) ON DELETE CASCADE,
    device_fingerprint VARCHAR(128) NOT NULL,
    ip_address INET NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'EXPIRED', 'REVOKED'
    started_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    last_activity_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    ended_at TIMESTAMPTZ,

    CONSTRAINT chk_session_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED'))
);

CREATE INDEX idx_user_active_session_active ON administration.user_active_session(user_id) WHERE status = 'ACTIVE';

-- Stored procedure invoked on login to atomically check device count and prevent seat sharing
CREATE OR REPLACE FUNCTION administration.authenticate_session(
    p_user_id UUID,
    p_device_fingerprint VARCHAR(128),
    p_ip INET,
    p_max_allowed_devices INT
)
RETURNS UUID AS $$
DECLARE
    v_active_count INT;
    v_new_session_id UUID;
BEGIN
    -- Acquire exclusive row lock on active sessions for this user to serialize concurrent logins
    SELECT COUNT(*) INTO v_active_count
    FROM administration.user_active_session
    WHERE user_id = p_user_id AND status = 'ACTIVE'
    FOR UPDATE;

    IF v_active_count >= p_max_allowed_devices THEN
        RAISE EXCEPTION 'Device Limit Exceeded: User % already has % active sessions (Maximum: %).',
            p_user_id, v_active_count, p_max_allowed_devices
            USING ERRCODE = '54000';
    END IF;

    INSERT INTO administration.user_active_session (user_id, device_fingerprint, ip_address, status)
    VALUES (p_user_id, p_device_fingerprint, p_ip, 'ACTIVE')
    RETURNING id INTO v_new_session_id;

    RETURN v_new_session_id;
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- 5. Row-Level Security: Recruiter Tenant Isolation (Docket Section 3 Rule)
-- Rule: "A recruiter may only see and act on job requirements assigned to their own company."
-- -----------------------------------------------------------------------------

CREATE TABLE recruitment.job_requirement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID NOT NULL REFERENCES organisation.organisation(id) ON DELETE RESTRICT,
    title VARCHAR(150) NOT NULL,
    open_to_consultants BOOLEAN NOT NULL DEFAULT FALSE,
    publish_status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID NOT NULL,
    deleted_at TIMESTAMPTZ
);

ALTER TABLE recruitment.job_requirement ENABLE ROW LEVEL SECURITY;

CREATE POLICY recruiter_org_isolation ON recruitment.job_requirement
FOR ALL
USING (
    organisation_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID
);

-- -----------------------------------------------------------------------------
-- 6. Realistic Seed Fixture (Student Notes Page 15: High-Value Realistic Data)
-- -----------------------------------------------------------------------------

-- Realistic Users: Candidate Asha, Employer Rohan, Recruiter Meera
INSERT INTO administration.user_account (
    id, email, phone_e164, country_code, is_active, created_by, updated_by
) VALUES
    ('10000000-0000-0000-0000-000000000001', 'asha.verma@example.in', '+919876543210', 'IN', TRUE, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('10000000-0000-0000-0000-000000000002', 'rohan.mehta@techcorp.in', '+919822334455', 'IN', TRUE, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('10000000-0000-0000-0000-000000000003', 'meera.recruiter@techcorp.in', '+919811223344', 'IN', TRUE, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- Map roles
INSERT INTO administration.user_role (user_id, role_id, assigned_by)
VALUES
    ('10000000-0000-0000-0000-000000000001', (SELECT id FROM administration.role WHERE code = 'CANDIDATE'), '00000000-0000-0000-0000-000000000001'),
    ('10000000-0000-0000-0000-000000000002', (SELECT id FROM administration.role WHERE code = 'EMPLOYER'), '00000000-0000-0000-0000-000000000001'),
    ('10000000-0000-0000-0000-000000000003', (SELECT id FROM administration.role WHERE code = 'RECRUITER'), '00000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- Realistic Organisation: TechCorp India Technologies Pvt Ltd
INSERT INTO organisation.organisation (
    id, legal_name, trade_name, registration_identifier, tax_identifier, country_code, verification_status, created_by, updated_by
) VALUES (
    '20000000-0000-0000-0000-000000000001',
    'TechCorp Technologies India Private Limited',
    'TechCorp India',
    'U72200KA2021PTC145678',
    '29AABCT1332L1Z5', -- Valid Karnataka GSTN format
    'IN',
    'VERIFIED',
    '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002'
) ON CONFLICT (id) DO NOTHING;

-- Map Recruiter Meera to TechCorp India with active dates
INSERT INTO organisation.organisation_recruiter_mapping (
    organisation_id, recruiter_user_id, start_date, is_active, created_by
) VALUES (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000003',
    '2026-01-01',
    TRUE,
    '10000000-0000-0000-0000-000000000002'
) ON CONFLICT DO NOTHING;

-- Realistic Candidate Blocking Entry: Asha blocks TechCorp India
INSERT INTO administration.candidate_block_list (
    candidate_user_id, blocked_organisation_id, reason_code
) VALUES (
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'CURRENT_EMPLOYER_PRIVACY'
) ON CONFLICT DO NOTHING;
