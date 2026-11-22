-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: application
-- =============================================================

-- -------------------------------------------------------------
-- Table: application.job_application
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.job_application (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    requisition_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    resume_id UUID NOT NULL,
    application_status VARCHAR(30) DEFAULT 'SUBMITTED' NOT NULL,
    screening_score NUMERIC(5,2) DEFAULT 'NULL',
    is_passed_screening BOOLEAN DEFAULT 'NULL',
    source_type VARCHAR(30) DEFAULT 'DIRECT_APPLY' NOT NULL,
    consultant_id UUID DEFAULT 'NULL',
    applied_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    withdrawn_at TIMESTAMPTZ DEFAULT 'NULL',
    rejection_reason VARCHAR(255) DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ DEFAULT 'NULL',
    CONSTRAINT pk_job_application PRIMARY KEY (id),
    CONSTRAINT chk_job_application_application_status CHECK (application_status IN ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'SCREENING_PASSED', 'SHORTLISTED', 'TECHNICAL_ASSESSMENT', 'INTERVIEW_SCHEDULED', 'INTERVIEW_COMPLETED', 'OFFER_EXTENDED', 'OFFER_ACCEPTED', 'OFFER_DECLINED', 'REJECTED', 'WITHDRAWN'))
);

-- -------------------------------------------------------------
-- Table: application.application_question_answer
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.application_question_answer (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    question_id UUID NOT NULL,
    selected_option_id UUID DEFAULT 'NULL',
    free_text_answer TEXT DEFAULT 'NULL',
    score_awarded INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_application_question_answer PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: application.application_stage_history
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.application_stage_history (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    from_stage VARCHAR(30) NOT NULL,
    to_stage VARCHAR(30) NOT NULL,
    changed_by_user_id UUID NOT NULL,
    stage_notes VARCHAR(500) DEFAULT 'NULL',
    transition_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_application_stage_history PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: application.job_interview
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.job_interview (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    interview_round SMALLINT DEFAULT 1 NOT NULL,
    interview_format VARCHAR(30) NOT NULL,
    scheduled_start_time TIMESTAMPTZ NOT NULL,
    scheduled_end_time TIMESTAMPTZ NOT NULL,
    meeting_link VARCHAR(255) DEFAULT 'NULL',
    interviewer_user_id UUID NOT NULL,
    interview_status VARCHAR(30) DEFAULT 'SCHEDULED' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_interview PRIMARY KEY (id),
    CONSTRAINT chk_job_interview_interview_status CHECK (interview_status IN ('SCHEDULED', 'CONFIRMED_ATTENDING', 'RESCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANDIDATE_NO_SHOW', 'CANCELLED'))
);

-- -------------------------------------------------------------
-- Table: application.interview_feedback
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.interview_feedback (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    interview_id UUID NOT NULL,
    interviewer_user_id UUID NOT NULL,
    technical_score NUMERIC(3,1) NOT NULL,
    cultural_score NUMERIC(3,1) NOT NULL,
    overall_score NUMERIC(3,1) NOT NULL,
    recommendation VARCHAR(30) NOT NULL,
    strengths TEXT DEFAULT 'NULL',
    weaknesses TEXT DEFAULT 'NULL',
    feedback_notes TEXT DEFAULT 'NULL',
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_interview_feedback PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: application.job_offer
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.job_offer (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    offered_salary_amount NUMERIC(12,2) NOT NULL,
    salary_currency_code CHAR(3) DEFAULT 'USD' NOT NULL,
    joining_date DATE NOT NULL,
    offer_validity_date DATE NOT NULL,
    offer_letter_storage_path VARCHAR(500) NOT NULL,
    offer_status VARCHAR(30) DEFAULT 'EXTENDED' NOT NULL,
    responded_at TIMESTAMPTZ DEFAULT 'NULL',
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_offer PRIMARY KEY (id),
    CONSTRAINT uq_job_offer_application_id UNIQUE (application_id),
    CONSTRAINT chk_job_offer_offer_status CHECK (offer_status IN ('DRAFT_GENERATED', 'INTERNAL_APPROVED', 'EXTENDED_TO_CANDIDATE', 'ACCEPTED_PENDING_ONBOARD', 'REJECTED_BY_CANDIDATE', 'REVISED_COUNTER', 'RESCINDED_BY_EMPLOYER', 'EXPIRED'))
);

