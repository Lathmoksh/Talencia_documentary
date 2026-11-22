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

