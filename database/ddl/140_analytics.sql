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
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
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
    current_salary_usd NUMERIC(12,2),
    profile_completion_percentage NUMERIC(5,2) DEFAULT 0.00 NOT NULL,
    row_effective_date DATE NOT NULL,
    row_expiration_date DATE DEFAULT '9999-12-31' NOT NULL,
    is_current BOOLEAN DEFAULT TRUE NOT NULL,
    salary_currency_code CHAR(3) DEFAULT 'INR' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NOT NULL,
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
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NOT NULL,
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
    salary_currency_code CHAR(3) DEFAULT 'INR' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NOT NULL,
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
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NOT NULL,
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
    created_by UUID NOT NULL,
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
    created_by UUID NOT NULL,
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
    final_performance_rating NUMERIC(3,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
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
    currency_code CHAR(3) DEFAULT 'INR' NOT NULL,
    created_by UUID NOT NULL,
    CONSTRAINT pk_fact_wallet_transaction PRIMARY KEY (id)
);

