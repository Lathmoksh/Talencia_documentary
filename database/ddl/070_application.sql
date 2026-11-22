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
    screening_score NUMERIC(5,2),
    is_passed_screening BOOLEAN,
    source_type VARCHAR(30) DEFAULT 'DIRECT_APPLY' NOT NULL,
    consultant_id UUID,
    applied_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    withdrawn_at TIMESTAMPTZ,
    rejection_reason VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by UUID NOT NULL,
    updated_by UUID NOT NULL,
    CONSTRAINT pk_job_application PRIMARY KEY (id, applied_at),
    CONSTRAINT chk_job_application_application_status CHECK (application_status IN ('SUBMITTED', 'SCREENING_PASSED', 'SCREENING_FAILED', 'SHORTLISTED', 'INTERVIEW_SCHEDULED', 'INTERVIEWED', 'OFFER_EXTENDED', 'OFFER_ACCEPTED', 'OFFER_DECLINED', 'JOINED_HIRED', 'REJECTED', 'WITHDRAWN_CANDIDATE'))
) PARTITION BY RANGE (applied_at);

-- Partitions for application.job_application
CREATE TABLE IF NOT EXISTS application.job_application_p2026_q1 PARTITION OF application.job_application
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS application.job_application_p2026_q2 PARTITION OF application.job_application
    FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS application.job_application_p2026_q3 PARTITION OF application.job_application
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS application.job_application_p2026_q4 PARTITION OF application.job_application
    FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS application.job_application_default PARTITION OF application.job_application DEFAULT;

-- -------------------------------------------------------------
-- Table: application.application_question_answer
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application.application_question_answer (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    application_id UUID NOT NULL,
    question_id UUID NOT NULL,
    selected_option_id UUID,
    free_text_answer TEXT,
    score_awarded INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NOT NULL,
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
    stage_notes VARCHAR(500),
    transition_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    CONSTRAINT pk_application_stage_history PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Partitions for application.application_stage_history
CREATE TABLE IF NOT EXISTS application.application_stage_history_p2026_q1 PARTITION OF application.application_stage_history
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS application.application_stage_history_p2026_q2 PARTITION OF application.application_stage_history
    FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS application.application_stage_history_p2026_q3 PARTITION OF application.application_stage_history
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS application.application_stage_history_p2026_q4 PARTITION OF application.application_stage_history
    FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS application.application_stage_history_default PARTITION OF application.application_stage_history DEFAULT;

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
    meeting_link VARCHAR(255),
    interviewer_user_id UUID NOT NULL,
    interview_status VARCHAR(30) DEFAULT 'SCHEDULED' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_by UUID NOT NULL,
    CONSTRAINT pk_job_interview PRIMARY KEY (id)
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
    strengths TEXT,
    weaknesses TEXT,
    feedback_notes TEXT,
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NOT NULL,
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
    responded_at TIMESTAMPTZ,
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by UUID NOT NULL,
    CONSTRAINT pk_job_offer PRIMARY KEY (id),
    CONSTRAINT uq_job_offer_application_id UNIQUE (application_id)
);

