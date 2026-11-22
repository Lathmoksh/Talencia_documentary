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

