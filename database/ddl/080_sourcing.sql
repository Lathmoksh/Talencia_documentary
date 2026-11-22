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

