-- ============================================================================
-- Talentra Database Design — Deliverable E (Business Workflow Analysis)
-- Architecture: Workflow State Machines, Transition Rules & Exception Queues
-- Target Engine: PostgreSQL 15+ Enterprise
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS workflow;

-- ============================================================================
-- 1. Workflow Master Definition Catalog
-- ============================================================================
CREATE TABLE workflow.workflow_definition (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_code VARCHAR(16) NOT NULL UNIQUE,
    workflow_title VARCHAR(128) NOT NULL,
    lifecycle_domain VARCHAR(32) NOT NULL,
    initiating_actor_role VARCHAR(32) NOT NULL,
    trigger_event VARCHAR(64) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_wf_code CHECK (workflow_code ~ '^WF-[0-9]{2}$'),
    CONSTRAINT chk_wf_domain CHECK (lifecycle_domain IN (
        'IDENTITY', 'RECRUITMENT', 'SOURCING', 'GIG_MARKETPLACE',
        'LICENSING', 'BILLING', 'GOVERNANCE'
    ))
);

-- ============================================================================
-- 2. Finite State Machine Allowed Transitions Rulebook
-- ============================================================================
CREATE TABLE workflow.workflow_state_transition_rule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(32) NOT NULL,
    state_from VARCHAR(32) NOT NULL,
    state_to VARCHAR(32) NOT NULL,
    is_terminal BOOLEAN NOT NULL DEFAULT FALSE,
    guard_description VARCHAR(256),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_entity_type CHECK (entity_type IN (
        'JOB_APPLICATION', 'GIG_CONTRACT', 'SUBSCRIPTION_LICENCE', 'WALLET_ESCROW'
    )),
    CONSTRAINT uq_state_transition UNIQUE (entity_type, state_from, state_to)
);

-- ============================================================================
-- 3. Workflow Execution Instances
-- ============================================================================
CREATE TABLE workflow.workflow_instance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflow.workflow_definition(id),
    target_entity_type VARCHAR(32) NOT NULL,
    target_entity_id UUID NOT NULL,
    current_state VARCHAR(32) NOT NULL,
    is_in_exception BOOLEAN NOT NULL DEFAULT FALSE,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_transition_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_target_type CHECK (target_entity_type IN (
        'JOB_APPLICATION', 'GIG_CONTRACT', 'SUBSCRIPTION_LICENCE', 'WALLET_ESCROW'
    ))
);

-- ============================================================================
-- 4. Immutable State Transition Audit History
-- ============================================================================
CREATE TABLE workflow.workflow_state_transition_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_instance_id UUID NOT NULL REFERENCES workflow.workflow_instance(id) ON DELETE RESTRICT,
    actor_user_id UUID NOT NULL,
    prior_state VARCHAR(32) NOT NULL,
    next_state VARCHAR(32) NOT NULL,
    transition_reason VARCHAR(256),
    transitioned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wf_history_instance 
ON workflow.workflow_state_transition_history(workflow_instance_id);

-- Enforce append-only on transition history
CREATE OR REPLACE FUNCTION workflow.fn_prevent_wf_history_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'PERMISSION DENIED: workflow_state_transition_history is immutable and append-only.'
        USING ERRCODE = '55000';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_wf_history_mutation
BEFORE UPDATE OR DELETE ON workflow.workflow_state_transition_history
FOR EACH ROW EXECUTE FUNCTION workflow.fn_prevent_wf_history_mutation();

-- ============================================================================
-- 5. Exception, Retry & Compensation Dead-Letter Queue (EXC-01 to EXC-07)
-- ============================================================================
CREATE TABLE workflow.workflow_exception_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_instance_id UUID REFERENCES workflow.workflow_instance(id),
    exception_code VARCHAR(16) NOT NULL,
    failure_condition VARCHAR(128) NOT NULL,
    payload_snapshot JSONB NOT NULL,
    retry_attempt_count INT NOT NULL DEFAULT 0,
    max_retry_limit INT NOT NULL DEFAULT 5,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    resolution_status VARCHAR(24) NOT NULL DEFAULT 'OPEN',
    resolution_notes TEXT,
    logged_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_exc_code CHECK (exception_code ~ '^EXC-[0-9]{2}$'),
    CONSTRAINT chk_resolution_status CHECK (resolution_status IN (
        'OPEN', 'RETRYING', 'RESOLVED_RETRY', 'COMPENSATED_ROLLBACK', 'MANUAL_INTERVENTION'
    ))
);

-- ============================================================================
-- 6. State Machine Validation Trigger: Block Illegal State Jumps
-- ============================================================================
CREATE OR REPLACE FUNCTION workflow.fn_validate_state_transition()
RETURNS TRIGGER AS $$
DECLARE
    v_is_valid BOOLEAN;
BEGIN
    -- Check if transition from OLD.current_state to NEW.current_state is permitted in rulebook
    SELECT EXISTS (
        SELECT 1 
        FROM workflow.workflow_state_transition_rule
        WHERE entity_type = NEW.target_entity_type
          AND state_from = OLD.current_state
          AND state_to = NEW.current_state
    ) INTO v_is_valid;

    IF NOT v_is_valid THEN
        RAISE EXCEPTION 'ILLEGAL STATE TRANSITION: Transition from % to % for entity % is not permitted by workflow state machine.',
            OLD.current_state, NEW.current_state, NEW.target_entity_type
            USING ERRCODE = '22023';
    END IF;

    NEW.last_transition_at := CURRENT_TIMESTAMP;
    
    -- Check if destination state is terminal
    IF EXISTS (
        SELECT 1 
        FROM workflow.workflow_state_transition_rule
        WHERE entity_type = NEW.target_entity_type
          AND state_to = NEW.current_state
          AND is_terminal = TRUE
    ) THEN
        NEW.completed_at := CURRENT_TIMESTAMP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_workflow_instance_transition
BEFORE UPDATE OF current_state ON workflow.workflow_instance
FOR EACH ROW
WHEN (OLD.current_state IS DISTINCT FROM NEW.current_state)
EXECUTE FUNCTION workflow.fn_validate_state_transition();

-- ============================================================================
-- 7. Seed Fixtures & Baseline Verification
-- ============================================================================
INSERT INTO workflow.workflow_definition 
(workflow_code, workflow_title, lifecycle_domain, initiating_actor_role, trigger_event)
VALUES
    ('WF-01', 'Candidate Onboarding & Privacy Shield', 'IDENTITY', 'CANDIDATE', 'PROFILE_REGISTERED'),
    ('WF-02', 'Multi-Tenant Requisition Publication', 'RECRUITMENT', 'RECRUITER', 'JOB_APPROVED'),
    ('WF-03', 'Application Pipeline & Assessment', 'SOURCING', 'CANDIDATE', 'APPLICATION_SUBMITTED'),
    ('WF-04', 'Talent Sourcing & Resume Unlock', 'SOURCING', 'RECRUITER', 'RESUME_UNLOCK_REQUESTED'),
    ('WF-05', 'Gig Contracting & Conflict Guard', 'GIG_MARKETPLACE', 'ENTERPRISE_ADMIN', 'CONTRACT_AWARDED'),
    ('WF-06', 'Subscription Licensing & Seat Quotas', 'LICENSING', 'EXECUTIVE_LEADER', 'LICENCE_PURCHASED'),
    ('WF-07', 'Wallet Payout & Dispute Resolution', 'BILLING', 'GIG_WORKER', 'MILESTONE_COMPLETED');

-- Seed Allowed Transition Rules for Job Applications
INSERT INTO workflow.workflow_state_transition_rule
(entity_type, state_from, state_to, is_terminal, guard_description)
VALUES
    ('JOB_APPLICATION', 'SUBMITTED', 'UNDER_REVIEW', FALSE, 'Recruiter opens application candidate record'),
    ('JOB_APPLICATION', 'UNDER_REVIEW', 'SHORTLISTED', FALSE, 'Recruiter passes resume screening'),
    ('JOB_APPLICATION', 'UNDER_REVIEW', 'REJECTED', TRUE, 'Application fails initial screening'),
    ('JOB_APPLICATION', 'SHORTLISTED', 'TECHNICAL_ASSESSMENT', FALSE, 'Skills assessment dispatched to candidate'),
    ('JOB_APPLICATION', 'TECHNICAL_ASSESSMENT', 'INTERVIEW_SCHEDULED', FALSE, 'Candidate achieves benchmark assessment score'),
    ('JOB_APPLICATION', 'TECHNICAL_ASSESSMENT', 'REJECTED', TRUE, 'Candidate fails minimum score threshold'),
    ('JOB_APPLICATION', 'INTERVIEW_SCHEDULED', 'OFFER_EXTENDED', FALSE, 'Hiring manager approves interview performance'),
    ('JOB_APPLICATION', 'INTERVIEW_SCHEDULED', 'REJECTED', TRUE, 'Candidate fails interview stage'),
    ('JOB_APPLICATION', 'OFFER_EXTENDED', 'OFFER_ACCEPTED', FALSE, 'Candidate signs offer letter'),
    ('JOB_APPLICATION', 'OFFER_EXTENDED', 'OFFER_DECLINED', TRUE, 'Candidate declines compensation package'),
    ('JOB_APPLICATION', 'OFFER_ACCEPTED', 'HIRED', TRUE, 'Onboarding completed and candidate joins');

-- Seed an Active Workflow Instance
INSERT INTO workflow.workflow_instance
(id, workflow_id, target_entity_type, target_entity_id, current_state)
SELECT 
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::UUID,
    id,
    'JOB_APPLICATION',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479'::UUID,
    'SUBMITTED'
FROM workflow.workflow_definition
WHERE workflow_code = 'WF-03';

-- Record initial transition into history
INSERT INTO workflow.workflow_state_transition_history
(workflow_instance_id, actor_user_id, prior_state, next_state, transition_reason)
VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::UUID,
    '00000000-0000-0000-0000-000000000001'::UUID,
    'DRAFT',
    'SUBMITTED',
    'Candidate submitted application via portal'
);

-- Seed a Sample Exception Event in Queue
INSERT INTO workflow.workflow_exception_queue
(workflow_instance_id, exception_code, failure_condition, payload_snapshot, resolution_status, resolution_notes)
VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::UUID,
    'EXC-05',
    'Webhook timeout during assessment score sync',
    '{"candidate_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479", "partner_code": "HACKERRANK", "retry_count": 1}'::JSONB,
    'RETRYING',
    'Dispatched background exponential retry worker'
);

-- ============================================================================
-- 8. Verification Queries
-- ============================================================================
-- 1. Verify all workflows defined
SELECT workflow_code, workflow_title, lifecycle_domain, initiating_actor_role 
FROM workflow.workflow_definition 
ORDER BY workflow_code;

-- 2. Verify state transition rules
SELECT entity_type, state_from, state_to, is_terminal, guard_description
FROM workflow.workflow_state_transition_rule
ORDER BY entity_type, state_from;

-- 3. Verify active instance and transition history
SELECT 
    i.id AS instance_id, 
    d.workflow_code, 
    i.target_entity_type, 
    i.current_state, 
    h.prior_state, 
    h.next_state, 
    h.transitioned_at
FROM workflow.workflow_instance i
JOIN workflow.workflow_definition d ON i.workflow_id = d.id
LEFT JOIN workflow.workflow_state_transition_history h ON i.id = h.workflow_instance_id;
