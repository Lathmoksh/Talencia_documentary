-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: candidate
-- =============================================================

-- -------------------------------------------------------------
-- Table: candidate.candidate_profile
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_profile (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    first_name VARCHAR(75) NOT NULL,
    middle_name VARCHAR(75) DEFAULT 'NULL',
    last_name VARCHAR(75) NOT NULL,
    display_name VARCHAR(150) NOT NULL,
    date_of_birth DATE DEFAULT 'NULL',
    gender VARCHAR(20) DEFAULT 'NULL',
    headline VARCHAR(200) NOT NULL,
    summary TEXT DEFAULT 'NULL',
    current_city_id UUID NOT NULL,
    total_experience_months INTEGER DEFAULT 0 NOT NULL,
    current_salary_amount NUMERIC(12,2) DEFAULT 'NULL',
    expected_salary_amount NUMERIC(12,2) DEFAULT 'NULL',
    salary_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    notice_period_days INTEGER DEFAULT 30 NOT NULL,
    profile_completion_percentage NUMERIC(5,2) DEFAULT 0.00 NOT NULL,
    is_profile_searchable BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID DEFAULT 'NULL',
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_candidate_profile PRIMARY KEY (id),
    CONSTRAINT uq_candidate_profile_user_id UNIQUE (user_id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_education
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_education (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    qualification_id UUID NOT NULL,
    institution_name VARCHAR(200) NOT NULL,
    field_of_study VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT 'NULL',
    grade_or_gpa VARCHAR(20) DEFAULT 'NULL',
    grade_system VARCHAR(30) DEFAULT 'NULL',
    is_completed BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_education PRIMARY KEY (id),
    CONSTRAINT chk_candidate_education_rule_1 CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),
    CONSTRAINT chk_candidate_education_rule_2 CHECK (grade_percentage IS NULL OR (grade_percentage >= 0.00 AND grade_percentage <= 100.00))
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_work_experience
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_work_experience (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    job_role_id UUID NOT NULL,
    industry_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT 'NULL',
    is_current_job BOOLEAN DEFAULT FALSE NOT NULL,
    description TEXT DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_work_experience PRIMARY KEY (id),
    CONSTRAINT chk_candidate_work_experience_rule_1 CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_skill
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_skill (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    skill_id UUID NOT NULL,
    proficiency_level VARCHAR(20) DEFAULT 'INTERMEDIATE' NOT NULL,
    years_of_experience NUMERIC(3,1) DEFAULT 1.0 NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE NOT NULL,
    last_used_year SMALLINT DEFAULT 'EXTRACT(YEAR FROM CURRENT_DATE)' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_skill PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_project
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_project (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    project_title VARCHAR(150) NOT NULL,
    project_role VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE DEFAULT 'NULL',
    description TEXT NOT NULL,
    project_url VARCHAR(255) DEFAULT 'NULL',
    outcome VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_project PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_resume
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_resume (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    resume_title VARCHAR(150) NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    file_format VARCHAR(20) NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    parsed_text_search TEXT DEFAULT 'NULL',
    is_primary BOOLEAN DEFAULT TRUE NOT NULL,
    version_number SMALLINT DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_candidate_resume PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_preference
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_preference (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    preferred_job_type VARCHAR(30) DEFAULT 'PERMANENT_FULL_TIME' NOT NULL,
    preferred_work_mode VARCHAR(30) DEFAULT 'HYBRID' NOT NULL,
    willing_to_relocate BOOLEAN DEFAULT FALSE NOT NULL,
    preferred_locations_json TEXT DEFAULT '[]' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_preference PRIMARY KEY (id),
    CONSTRAINT uq_candidate_preference_candidate_id UNIQUE (candidate_id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_block_list
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_block_list (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    blocked_organisation_id UUID DEFAULT 'NULL',
    blocked_recruiter_user_id UUID DEFAULT 'NULL',
    block_reason VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_block_list PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: candidate.candidate_language
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidate.candidate_language (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    language_code CHAR(2) NOT NULL,
    proficiency_level VARCHAR(20) DEFAULT 'PROFICIENT' NOT NULL,
    can_read BOOLEAN DEFAULT TRUE NOT NULL,
    can_write BOOLEAN DEFAULT TRUE NOT NULL,
    can_speak BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_language PRIMARY KEY (id)
);

