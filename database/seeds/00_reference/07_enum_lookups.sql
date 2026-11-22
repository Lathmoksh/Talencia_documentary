-- ============================================================================
-- TALENTRA ENTERPRISE PLATFORM: MASTER ENUMERATION LOOKUP SEEDS
-- Rule Group 3: Canonical lookup table with per-language display names
-- ============================================================================

INSERT INTO master_data.enum_lookup (
    id, enum_domain, enum_code, display_name, language_code, sort_order, is_active, created_by, updated_by
) VALUES
-- User Account Statuses
(generate_uuid_v7(), 'account_status', 'REGISTERED_UNVERIFIED', 'Registered (Pending Verification)', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'account_status', 'ACTIVE_VERIFIED', 'Active & Verified', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'account_status', 'SUSPENDED_SECURITY', 'Suspended for Security Review', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'account_status', 'LOCKED_FAILED_LOGINS', 'Locked (Exceeded Failed Logins)', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'account_status', 'ANONYMIZED_DELETED', 'Anonymized & Forgotten', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- Job Requisition Statuses
(generate_uuid_v7(), 'requisition_status', 'DRAFT', 'Draft Requisition', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'PENDING_APPROVAL', 'Pending Internal Approval', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'APPROVED', 'Approved for Sourcing', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'PUBLISHED', 'Published Live to Marketplace', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'SOURCING_ACTIVE', 'Active Candidate Sourcing', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'INTERVIEWING', 'Interviews in Progress', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'OFFER_EXTENDED', 'Offer Extended to Finalist', 'en_US', 7, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'FILLED_CLOSED', 'Positions Successfully Filled', 'en_US', 8, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'CANCELLED_VOID', 'Cancelled & Voided', 'en_US', 9, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'requisition_status', 'ON_HOLD', 'Temporarily on Hold', 'en_US', 10, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- Job Application Pipeline Stages
(generate_uuid_v7(), 'application_status', 'SUBMITTED', 'Application Submitted', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'SCREENING_PASSED', 'Automated Screener Passed', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'SCREENING_FAILED', 'Automated Screener Disqualified', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'SHORTLISTED', 'Shortlisted by Recruiter', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'INTERVIEW_SCHEDULED', 'Interview Scheduled', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'INTERVIEWED', 'Interview Completed', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'OFFER_EXTENDED', 'Official Offer Extended', 'en_US', 7, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'OFFER_ACCEPTED', 'Offer Accepted by Candidate', 'en_US', 8, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'OFFER_DECLINED', 'Offer Declined by Candidate', 'en_US', 9, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'JOINED_HIRED', 'Onboarded & Formally Joined', 'en_US', 10, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'REJECTED', 'Application Rejected', 'en_US', 11, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'application_status', 'WITHDRAWN_CANDIDATE', 'Withdrawn by Candidate', 'en_US', 12, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- Gig Milestone Statuses
(generate_uuid_v7(), 'milestone_status', 'PENDING_FUNDING', 'Pending Client Escrow Funding', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'FUNDED_ESCROW_LOCKED', 'Funded & Escrow Locked', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'IN_PROGRESS', 'Work in Progress', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'SUBMITTED_FOR_REVIEW', 'Deliverable Submitted for Review', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'REVISION_REQUESTED', 'Revisions Requested by Client', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'APPROVED_RELEASED', 'Deliverable Approved & Escrow Released', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'DISPUTED_FROZEN', 'Disputed & Escrow Frozen', 'en_US', 7, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'REFUNDED_TO_CLIENT', 'Dispute Settled & Refunded to Client', 'en_US', 8, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- Subscription Licence Statuses
(generate_uuid_v7(), 'licence_status', 'PENDING_PROVISIONING', 'Pending Provisioning', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'ACTIVE_COMMISSIONED', 'Active & Commissioned', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'RENEWAL_DUE', 'Renewal Due', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'GRACE_PERIOD', 'Delinquent Grace Period', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'SUSPENDED_NON_PAYMENT', 'Suspended for Non-Payment', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'TERMINATED_EXPIRED', 'Terminated & Expired', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000');
