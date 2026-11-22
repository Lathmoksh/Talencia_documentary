-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: recruitment
-- =============================================================

-- -------------------------------------------------------------
-- Table: recruitment.job_requisition
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.job_requisition (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
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
    application_deadline DATE,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT pk_job_requisition PRIMARY KEY (id),
    CONSTRAINT chk_job_requisition_publish_status CHECK (publish_status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'PUBLISHED', 'SOURCING_ACTIVE', 'INTERVIEWING', 'OFFER_EXTENDED', 'FILLED_CLOSED', 'CANCELLED_VOID', 'ON_HOLD')),
    CONSTRAINT chk_job_requisition_rule_1 CHECK (min_salary_amount IS NULL OR min_salary_amount >= 0.00),
    CONSTRAINT chk_job_requisition_rule_2 CHECK (max_salary_amount IS NULL OR max_salary_amount >= 0.00),
    CONSTRAINT chk_job_requisition_rule_3 CHECK (max_salary_amount IS NULL OR min_salary_amount IS NULL OR max_salary_amount >= min_salary_amount),
    CONSTRAINT chk_job_requisition_rule_4 CHECK (vacancies_count > 0)
);

-- -------------------------------------------------------------
-- Table: recruitment.job_requisition_skill
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.job_requisition_skill (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    requisition_id UUID NOT NULL,
    skill_id UUID NOT NULL,
    requirement_type VARCHAR(20) DEFAULT 'MANDATORY' NOT NULL,
    min_experience_months INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_job_requisition_skill PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: recruitment.job_questionnaire
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.job_questionnaire (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    requisition_id UUID NOT NULL,
    questionnaire_title VARCHAR(150) NOT NULL,
    passing_score_percentage NUMERIC(5,2) DEFAULT 70.00 NOT NULL,
    is_mandatory BOOLEAN DEFAULT TRUE NOT NULL,
    version_number SMALLINT DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_job_questionnaire PRIMARY KEY (id),
    CONSTRAINT uq_job_questionnaire_requisition_id UNIQUE (requisition_id)
);

-- -------------------------------------------------------------
-- Table: recruitment.questionnaire_question
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.questionnaire_question (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    questionnaire_id UUID NOT NULL,
    question_text VARCHAR(500) NOT NULL,
    question_type VARCHAR(30) NOT NULL,
    weight_points INTEGER DEFAULT 10 NOT NULL,
    is_disqualifying BOOLEAN DEFAULT FALSE NOT NULL,
    sort_order INTEGER DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_questionnaire_question PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: recruitment.question_option
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recruitment.question_option (
    id UUID DEFAULT generate_uuid_v7() NOT NULL,
    question_id UUID NOT NULL,
    option_text VARCHAR(255) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE NOT NULL,
    score_value INTEGER DEFAULT 0 NOT NULL,
    sort_order INTEGER DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT '00000000-0000-4000-8000-000000000000'::uuid NOT NULL,
    CONSTRAINT pk_question_option PRIMARY KEY (id)
);

