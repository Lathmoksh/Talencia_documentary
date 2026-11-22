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
    created_by UUID NOT NULL,
    updated_by UUID NOT NULL,
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
    created_by UUID NOT NULL,
    updated_by UUID NOT NULL,
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
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_by UUID NOT NULL,
    CONSTRAINT pk_licence_entitlement_usage PRIMARY KEY (id)
);

