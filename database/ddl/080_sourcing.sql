-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: sourcing
-- =============================================================

-- -------------------------------------------------------------
-- Table: sourcing.consultant_authorization
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sourcing.consultant_authorization (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    requisition_id UUID NOT NULL,
    consultant_user_id UUID NOT NULL,
    commission_rate_percentage NUMERIC(5,2) DEFAULT 8.33 NOT NULL,
    authorization_status VARCHAR(20) DEFAULT 'PENDING' NOT NULL,
    authorized_by_user_id UUID,
    authorized_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_consultant_authorization PRIMARY KEY (id),
    CONSTRAINT chk_consultant_authorization_authorization_status CHECK (authorization_status IN ('INVITED_PENDING', 'ACCEPTED_ACTIVE', 'EXPIRED_TIMEOUT', 'REVOKED_EMPLOYER', 'TERMINATED_HIRE')),
    CONSTRAINT chk_consultant_authorization_rule_1 CHECK (commission_rate_percentage >= 0.00 AND commission_rate_percentage <= 100.00)
);

-- -------------------------------------------------------------
-- Table: sourcing.candidate_nomination
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sourcing.candidate_nomination (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    authorization_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    nomination_status VARCHAR(30) DEFAULT 'NOMINATED' NOT NULL,
    review_notes VARCHAR(500),
    nominated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_candidate_nomination PRIMARY KEY (id),
    CONSTRAINT chk_candidate_nomination_nomination_status CHECK (nomination_status IN ('NOMINATED_PENDING', 'CLIENT_SHORTLISTED', 'CLIENT_REJECTED', 'HIRED_COMMISSION_EARNED', 'WITHDRAWN_CANDIDATE'))
);

-- -------------------------------------------------------------
-- Table: sourcing.outreach_campaign
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sourcing.outreach_campaign (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    organisation_id UUID NOT NULL,
    created_by_user_id UUID NOT NULL,
    campaign_name VARCHAR(150) NOT NULL,
    channel_type VARCHAR(20) NOT NULL,
    message_template TEXT NOT NULL,
    total_recipients_count INTEGER DEFAULT 0 NOT NULL,
    credits_deducted INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_outreach_campaign PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: sourcing.outreach_recipient
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sourcing.outreach_recipient (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    campaign_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    delivery_status VARCHAR(20) DEFAULT 'QUEUED' NOT NULL,
    sent_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    error_message VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_outreach_recipient PRIMARY KEY (id)
);

