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

