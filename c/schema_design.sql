-- =============================================================================
-- Talentra Database Design
-- Module: Feature Subsystems, Gig Marketplace & Financial Ledgers
-- Engine: PostgreSQL 15+ (Requires btree_gist extension)
-- Adherence: Aligned with Hackathon Docket Section 4 & Section 5
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist"; -- Required for GiST multi-column exclusion constraints

CREATE SCHEMA IF NOT EXISTS profile;
CREATE SCHEMA IF NOT EXISTS gig;
CREATE SCHEMA IF NOT EXISTS licence;
CREATE SCHEMA IF NOT EXISTS billing;

-- -----------------------------------------------------------------------------
-- 1. Candidate Profiles & Resume Download Audit (Features F-01, F-13)
-- Rule: Download history records actor, subject, timestamp, and credit deduction (Rule Group 10)
-- -----------------------------------------------------------------------------

CREATE TABLE profile.candidate_profile (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    first_name VARCHAR(150) NOT NULL,
    last_name VARCHAR(150) NOT NULL,
    current_headline VARCHAR(200),
    total_experience_months INT NOT NULL DEFAULT 0,
    is_searchable BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID NOT NULL,
    deleted_at TIMESTAMPTZ,

    CONSTRAINT chk_candidate_profile_experience CHECK (total_experience_months >= 0)
);

CREATE TABLE profile.profile_download_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recruiter_user_id UUID NOT NULL,
    candidate_profile_id UUID NOT NULL REFERENCES profile.candidate_profile(id) ON DELETE RESTRICT,
    organisation_id UUID NOT NULL,
    wallet_ledger_transaction_id UUID NOT NULL, -- Directly ties to financial debit entry
    credit_deduction_amount NUMERIC(10, 2) NOT NULL DEFAULT 1.00,
    downloaded_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT chk_profile_download_deduction CHECK (credit_deduction_amount >= 0.00)
);

CREATE INDEX idx_profile_download_history_recruiter ON profile.profile_download_history(recruiter_user_id, downloaded_at DESC);
CREATE INDEX idx_profile_download_history_candidate ON profile.profile_download_history(candidate_profile_id);

-- Append-only trigger: prevents altering or clearing download logs
CREATE OR REPLACE FUNCTION profile.prevent_download_tampering()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit records are immutable. Table profile.profile_download_history is append-only.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profile_download_history_immutable
BEFORE UPDATE OR DELETE ON profile.profile_download_history
FOR EACH ROW EXECUTE FUNCTION profile.prevent_download_tampering();


-- -----------------------------------------------------------------------------
-- 2. Gig Marketplace: Non-Overlapping Booking Windows (Feature F-07)
-- Rule: "Gig windows cannot overlap for the same gig worker" (Milestone 10, Rule Group 2)
-- -----------------------------------------------------------------------------

CREATE TABLE gig.gig_worker_profile (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    service_title VARCHAR(150) NOT NULL,
    hourly_rate_amount NUMERIC(12, 2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'INR',
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    rating_average NUMERIC(3, 2) NOT NULL DEFAULT 5.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID NOT NULL,

    CONSTRAINT chk_gig_worker_hourly_rate CHECK (hourly_rate_amount > 0.00),
    CONSTRAINT chk_gig_worker_rating CHECK (rating_average BETWEEN 1.00 AND 5.00)
);

CREATE TABLE gig.gig_contract (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gig_worker_id UUID NOT NULL REFERENCES gig.gig_worker_profile(id) ON DELETE RESTRICT,
    requester_user_id UUID NOT NULL,
    title VARCHAR(150) NOT NULL,
    contract_status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'COMPLETED', 'CANCELLED', 'DISPUTED'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    fixed_price_amount NUMERIC(12, 2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'INR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT chk_gig_contract_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_gig_contract_price CHECK (fixed_price_amount > 0.00),
    CONSTRAINT chk_gig_contract_status CHECK (contract_status IN ('ACTIVE', 'COMPLETED', 'CANCELLED', 'DISPUTED')),

    -- GiST exclusion constraint: Prevents overlapping active contract windows for the same gig worker
    CONSTRAINT uq_gig_worker_no_overlapping_active_window
    EXCLUDE USING gist (
        gig_worker_id WITH =,
        daterange(start_date, end_date, '[]') WITH &&
    ) WHERE (contract_status = 'ACTIVE')
);

CREATE INDEX idx_gig_contract_worker ON gig.gig_contract(gig_worker_id);


-- -----------------------------------------------------------------------------
-- 3. Licensing & Append-Only Financial Wallet (Features F-10, F-11, F-12)
-- Rule: "Payment and wallet ledgers are append-only. A correction is recorded as a new entry" (Rule Group 10)
-- -----------------------------------------------------------------------------

CREATE TABLE licence.subscription_licence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID NOT NULL,
    plan_tier_code VARCHAR(50) NOT NULL,
    max_users INT NOT NULL,
    max_devices_per_user INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT chk_subscription_licence_users CHECK (max_users > 0),
    CONSTRAINT chk_subscription_licence_devices CHECK (max_devices_per_user > 0)
);

CREATE TABLE billing.wallet_account (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID NOT NULL UNIQUE,
    cached_credit_balance NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    currency_code CHAR(3) NOT NULL DEFAULT 'INR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT chk_wallet_account_balance CHECK (cached_credit_balance >= 0.00)
);

CREATE TABLE billing.wallet_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_account_id UUID NOT NULL REFERENCES billing.wallet_account(id) ON DELETE RESTRICT,
    entry_type VARCHAR(20) NOT NULL,           -- 'CREDIT' (Recharge/Refund), 'DEBIT' (Resume View / Outreach)
    amount NUMERIC(12, 2) NOT NULL,
    running_balance NUMERIC(14, 2) NOT NULL,
    reference_order_uuid UUID,
    reversal_reference_id UUID REFERENCES billing.wallet_ledger(id) ON DELETE RESTRICT,
    description_text VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID NOT NULL,

    CONSTRAINT chk_wallet_ledger_type CHECK (entry_type IN ('CREDIT', 'DEBIT')),
    CONSTRAINT chk_wallet_ledger_amount CHECK (amount > 0.00)
);

CREATE INDEX idx_wallet_ledger_account ON billing.wallet_ledger(wallet_account_id, created_at DESC);

-- Trigger: Strictly bars UPDATE or DELETE on wallet ledger
CREATE OR REPLACE FUNCTION billing.prevent_wallet_ledger_tampering()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Financial Integrity Violation: billing.wallet_ledger is append-only. Updates and deletions are barred.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_wallet_ledger_immutable
BEFORE UPDATE OR DELETE ON billing.wallet_ledger
FOR EACH ROW EXECUTE FUNCTION billing.prevent_wallet_ledger_tampering();

-- Trigger: Keeps cached_credit_balance synchronized upon new ledger inserts
CREATE OR REPLACE FUNCTION billing.sync_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.entry_type = 'CREDIT' THEN
        UPDATE billing.wallet_account
        SET cached_credit_balance = cached_credit_balance + NEW.amount,
            updated_at = clock_timestamp()
        WHERE id = NEW.wallet_account_id;
    ELSIF NEW.entry_type = 'DEBIT' THEN
        UPDATE billing.wallet_account
        SET cached_credit_balance = cached_credit_balance - NEW.amount,
            updated_at = clock_timestamp()
        WHERE id = NEW.wallet_account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_wallet_balance_after_insert
AFTER INSERT ON billing.wallet_ledger
FOR EACH ROW EXECUTE FUNCTION billing.sync_wallet_balance();

-- -----------------------------------------------------------------------------
-- 4. Realistic Seed Fixture (Student Notes Page 15: High-Value Realistic Data)
-- -----------------------------------------------------------------------------

-- Realistic Candidate Profile for Asha
INSERT INTO profile.candidate_profile (
    id, user_id, first_name, last_name, current_headline, total_experience_months, is_searchable, created_by, updated_by
) VALUES (
    'c0000001-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Asha',
    'Verma',
    'Lead Full-Stack Engineer | Python, PostgreSQL, React | Ex-Infosys',
    78, -- 6.5 years
    TRUE,
    '10000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001'
) ON CONFLICT (id) DO NOTHING;

-- Realistic Gig Worker Profile for Dev
INSERT INTO gig.gig_worker_profile (
    id, user_id, service_title, hourly_rate_amount, currency_code, is_available, rating_average, created_by, updated_by
) VALUES (
    'g0000001-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000005', -- Dev
    'Senior AWS Cloud Architect & Terraform Automation',
    1800.00,
    'INR',
    TRUE,
    4.95,
    '10000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000005'
) ON CONFLICT (id) DO NOTHING;

-- Realistic Active Gig Contract (Non-overlapping booking window: Oct 15 - Nov 15, 2026)
INSERT INTO gig.gig_contract (
    id, gig_worker_id, requester_user_id, title, contract_status, start_date, end_date, fixed_price_amount, currency_code
) VALUES (
    'g0000002-0000-0000-0000-000000000002',
    'g0000001-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002', -- Rohan / TechCorp India
    'PostgreSQL Cluster Multi-Region HA Architecture Setup',
    'ACTIVE',
    '2026-10-15',
    '2026-11-15',
    75000.00,
    'INR'
) ON CONFLICT (id) DO NOTHING;

-- Realistic Subscription License for TechCorp India (10 recruiter seats, 3 devices/user)
INSERT INTO licence.subscription_licence (
    id, organisation_id, plan_tier_code, max_users, max_devices_per_user, is_active
) VALUES (
    'l0000001-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'ENTERPRISE_GROWTH_10',
    10,
    3,
    TRUE
) ON CONFLICT (id) DO NOTHING;

-- Realistic Wallet Account for TechCorp India
INSERT INTO billing.wallet_account (
    id, organisation_id, cached_credit_balance, currency_code
) VALUES (
    'w0000001-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    0.00, -- will be updated automatically by trigger
    'INR'
) ON CONFLICT (id) DO NOTHING;

-- Realistic Wallet Transactions: Initial Recharge + Profile Download Debit
INSERT INTO billing.wallet_ledger (
    id, wallet_account_id, entry_type, amount, running_balance, description_text, created_by
) VALUES (
    'w0000002-0000-0000-0000-000000000002',
    'w0000001-0000-0000-0000-000000000001',
    'CREDIT',
    50000.00,
    50000.00,
    'Prepaid Wallet Recharge via Stripe (Invoice #INV-2026-0012)',
    '10000000-0000-0000-0000-000000000002'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO billing.wallet_ledger (
    id, wallet_account_id, entry_type, amount, running_balance, description_text, created_by
) VALUES (
    'w0000003-0000-0000-0000-000000000003',
    'w0000001-0000-0000-0000-000000000001',
    'DEBIT',
    100.00,
    49900.00,
    'Profile Download Unlock - Candidate Asha Verma',
    '10000000-0000-0000-0000-000000000003'
) ON CONFLICT (id) DO NOTHING;

-- Realistic Profile Download Audit Event tied to the debit transaction
INSERT INTO profile.profile_download_history (
    id, recruiter_user_id, candidate_profile_id, organisation_id, wallet_ledger_transaction_id, credit_deduction_amount
) VALUES (
    'd0000001-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000003', -- Recruiter Meera
    'c0000001-0000-0000-0000-000000000001', -- Candidate Asha
    '20000000-0000-0000-0000-000000000001', -- TechCorp India
    'w0000003-0000-0000-0000-000000000003', -- Wallet Debit UUID
    100.00
) ON CONFLICT (id) DO NOTHING;
