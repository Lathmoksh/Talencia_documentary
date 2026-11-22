-- =============================================================
-- Talentra Enterprise Workforce Platform
-- Module: engagement
-- =============================================================

-- -------------------------------------------------------------
-- Table: engagement.candidate_saved_search
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.candidate_saved_search (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    recruiter_user_id UUID NOT NULL,
    search_name VARCHAR(100) NOT NULL,
    criteria_json TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_saved_search PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.job_alert_subscription
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.job_alert_subscription (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    candidate_id UUID NOT NULL,
    alert_title VARCHAR(100) NOT NULL,
    filters_json TEXT NOT NULL,
    frequency VARCHAR(20) DEFAULT 'DAILY' NOT NULL,
    channel VARCHAR(20) DEFAULT 'EMAIL' NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    last_notified_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_job_alert_subscription PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.notification_delivery
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.notification_delivery (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    user_id UUID NOT NULL,
    notification_category VARCHAR(40) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    title VARCHAR(150) NOT NULL,
    body_preview VARCHAR(500) NOT NULL,
    delivery_status VARCHAR(20) DEFAULT 'QUEUED' NOT NULL,
    external_delivery_reference VARCHAR(100) DEFAULT 'NULL',
    read_at TIMESTAMPTZ DEFAULT 'NULL',
    dispatched_at TIMESTAMPTZ DEFAULT 'NULL',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_notification_delivery PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.message_thread
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.message_thread (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    recruiter_user_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    requisition_id UUID DEFAULT 'NULL',
    unlock_receipt_id UUID NOT NULL,
    thread_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_message_thread PRIMARY KEY (id),
    CONSTRAINT chk_message_thread_thread_status CHECK (thread_status IN ('ACTIVE_OPEN', 'ARCHIVED_USER', 'BLOCKED_BY_PARTY', 'FLAGGED_MODERATION', 'PURGED_RETENTION'))
);

-- -------------------------------------------------------------
-- Table: engagement.thread_message
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.thread_message (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    thread_id UUID NOT NULL,
    sender_user_id UUID NOT NULL,
    message_body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_thread_message PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.candidate_referral_link
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.candidate_referral_link (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    referrer_user_id UUID NOT NULL,
    unique_referral_token VARCHAR(64) NOT NULL,
    channel_medium VARCHAR(30) DEFAULT 'DIRECT' NOT NULL,
    click_count INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_candidate_referral_link PRIMARY KEY (id),
    CONSTRAINT uq_candidate_referral_link_unique_referral_token UNIQUE (unique_referral_token)
);

-- -------------------------------------------------------------
-- Table: engagement.referral_attribution_event
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.referral_attribution_event (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    referral_link_id UUID NOT NULL,
    referred_user_id UUID NOT NULL,
    milestone_type VARCHAR(30) NOT NULL,
    reward_points_awarded INTEGER DEFAULT 0 NOT NULL,
    attributed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_referral_attribution_event PRIMARY KEY (id)
);

-- -------------------------------------------------------------
-- Table: engagement.campus_placement_cohort
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.campus_placement_cohort (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    tpo_user_id UUID NOT NULL,
    institution_name VARCHAR(200) NOT NULL,
    degree_program VARCHAR(100) NOT NULL,
    graduation_year SMALLINT DEFAULT 'EXTRACT(YEAR FROM CURRENT_DATE)' NOT NULL,
    cohort_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_campus_placement_cohort PRIMARY KEY (id),
    CONSTRAINT chk_campus_placement_cohort_cohort_status CHECK (cohort_status IN ('PLANNING_DRAFT', 'REGISTRATION_OPEN', 'SCREENING_IN_PROGRESS', 'DRIVE_ACTIVE', 'OFFERS_CONCLUDED', 'ARCHIVED_COMPLETED'))
);

-- -------------------------------------------------------------
-- Table: engagement.campus_student_member
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS engagement.campus_student_member (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    cohort_id UUID NOT NULL,
    candidate_id UUID NOT NULL,
    university_roll_number VARCHAR(50) NOT NULL,
    cumulative_gpa NUMERIC(4,2) NOT NULL,
    placement_status VARCHAR(20) DEFAULT 'UNPLACED' NOT NULL,
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_campus_student_member PRIMARY KEY (id),
    CONSTRAINT uq_campus_student_member_university_roll_number UNIQUE (university_roll_number),
    CONSTRAINT chk_campus_student_member_placement_status CHECK (placement_status IN ('REGISTERED_UNVERIFIED', 'VERIFIED_ELIGIBLE', 'SHORTLISTED_DRIVE', 'OFFER_RECEIVED', 'PLACED_ACCEPTED', 'OPTED_OUT_INELIGIBLE'))
);

