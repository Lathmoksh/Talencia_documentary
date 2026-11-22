-- ============================================================================
-- TALENTRA ENTERPRISE PLATFORM: MASTER ENUMERATION LOOKUP SEEDS
-- Rule Group 3: Canonical lookup table with per-language display names
-- Covers all 54 domain statuses, types, and categories across the platform
-- ============================================================================

INSERT INTO master_data.enum_lookup (
    id, enum_domain, enum_code, display_name, language_code, sort_order, is_active, created_by, updated_by
) VALUES
-- 1. User Account Statuses
(generate_uuid_v7(), 'account_status', 'REGISTERED_UNVERIFIED', 'Registered (Pending Verification)', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'account_status', 'ACTIVE_VERIFIED', 'Active & Verified', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'account_status', 'SUSPENDED_SECURITY', 'Suspended for Security Review', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'account_status', 'LOCKED_FAILED_LOGINS', 'Locked (Exceeded Failed Logins)', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'account_status', 'ANONYMIZED_DELETED', 'Anonymized & Forgotten', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 2. Organisation Account Statuses
(generate_uuid_v7(), 'org_account_status', 'TRIAL_ACTIVE', 'Trial Active', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'org_account_status', 'PAID_ACTIVE', 'Paid Active', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'org_account_status', 'DELINQUENT_GRACE', 'Delinquent Grace Period', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'org_account_status', 'SUSPENDED_NON_PAYMENT', 'Suspended for Non-Payment', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'org_account_status', 'TERMINATED_OFFBOARDED', 'Terminated & Offboarded', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 3. Job Requisition Publish Statuses
(generate_uuid_v7(), 'publish_status', 'DRAFT', 'Draft Requisition', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'PENDING_APPROVAL', 'Pending Internal Approval', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'APPROVED', 'Approved for Sourcing', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'PUBLISHED', 'Published Live to Marketplace', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'SOURCING_ACTIVE', 'Active Candidate Sourcing', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'INTERVIEWING', 'Interviews in Progress', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'OFFER_EXTENDED', 'Offer Extended to Finalist', 'en_US', 7, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'FILLED_CLOSED', 'Positions Successfully Filled', 'en_US', 8, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'CANCELLED_VOID', 'Cancelled & Voided', 'en_US', 9, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'publish_status', 'ON_HOLD', 'Temporarily on Hold', 'en_US', 10, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 4. Job Application Pipeline Stages
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

-- 5. Sourcing Consultant Authorisation Statuses
(generate_uuid_v7(), 'authorization_status', 'INVITED_PENDING', 'Authorization Invited (Pending)', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'authorization_status', 'ACCEPTED_ACTIVE', 'Authorized & Active', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'authorization_status', 'EXPIRED_TIMEOUT', 'Authorization Expired', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'authorization_status', 'REVOKED_EMPLOYER', 'Revoked by Employer', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'authorization_status', 'TERMINATED_HIRE', 'Terminated upon Successful Hire', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 6. Candidate Nomination Statuses
(generate_uuid_v7(), 'nomination_status', 'NOMINATED_PENDING', 'Nominated (Pending Review)', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'nomination_status', 'CLIENT_SHORTLISTED', 'Shortlisted by Client', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'nomination_status', 'CLIENT_REJECTED', 'Rejected by Client', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'nomination_status', 'HIRED_COMMISSION_EARNED', 'Hired (Commission Earned)', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'nomination_status', 'WITHDRAWN_CANDIDATE', 'Withdrawn by Candidate', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 7. Gig Request Statuses
(generate_uuid_v7(), 'request_status', 'DRAFT', 'Draft Request', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'request_status', 'OPEN_BIDDING', 'Open for Proposals', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'request_status', 'PROPOSALS_UNDER_REVIEW', 'Proposals Under Review', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'request_status', 'MATCH_CONFIRMED', 'Worker Confirmed', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'request_status', 'WORK_IN_PROGRESS', 'Work in Progress', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'request_status', 'COMPLETED_DELIVERED', 'Completed & Delivered', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'request_status', 'DISPUTED_ARBITRATION', 'In Arbitration Dispute', 'en_US', 7, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'request_status', 'CANCELLED_UNFILLED', 'Cancelled (Unfilled)', 'en_US', 8, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 8. Gig Proposal Statuses
(generate_uuid_v7(), 'proposal_status', 'SUBMITTED', 'Proposal Submitted', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'proposal_status', 'UNDER_CLIENT_REVIEW', 'Under Client Review', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'proposal_status', 'ACCEPTED_AWARDED', 'Proposal Accepted & Awarded', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'proposal_status', 'DECLINED_REJECTED', 'Declined by Client', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'proposal_status', 'WITHDRAWN_BY_WORKER', 'Withdrawn by Worker', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'proposal_status', 'EXPIRED', 'Proposal Expired', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 9. Gig Contract Statuses
(generate_uuid_v7(), 'contract_status', 'PENDING_ESCROW', 'Pending Escrow Funding', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'contract_status', 'ACTIVE_IN_PROGRESS', 'Active & in Progress', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'contract_status', 'PAUSED_REVISION', 'Paused for Revision', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'contract_status', 'PENDING_ACCEPTANCE', 'Pending Final Acceptance', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'contract_status', 'DISPUTED', 'Contract Disputed', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'contract_status', 'SETTLED_CLOSED', 'Settled & Closed', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'contract_status', 'TERMINATED_MUTUAL', 'Terminated by Mutual Consent', 'en_US', 7, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'contract_status', 'CANCELLED_PRE_START', 'Cancelled Pre-Start', 'en_US', 8, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 10. Gig Milestone Statuses
(generate_uuid_v7(), 'milestone_status', 'PENDING_FUNDING', 'Pending Client Escrow Funding', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'FUNDED_ESCROW_LOCKED', 'Funded & Escrow Locked', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'IN_PROGRESS', 'Work in Progress', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'SUBMITTED_FOR_REVIEW', 'Deliverable Submitted for Review', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'REVISION_REQUESTED', 'Revisions Requested by Client', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'APPROVED_RELEASED', 'Deliverable Approved & Escrow Released', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'DISPUTED_FROZEN', 'Disputed & Escrow Frozen', 'en_US', 7, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'milestone_status', 'REFUNDED_TO_CLIENT', 'Dispute Settled & Refunded to Client', 'en_US', 8, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 11. Subscription Licence Statuses
(generate_uuid_v7(), 'licence_status', 'PENDING_PROVISIONING', 'Pending Provisioning', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'ACTIVE_COMMISSIONED', 'Active & Commissioned', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'RENEWAL_DUE', 'Renewal Due', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'GRACE_PERIOD', 'Delinquent Grace Period', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'SUSPENDED_NON_PAYMENT', 'Suspended for Non-Payment', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'licence_status', 'TERMINATED_EXPIRED', 'Terminated & Expired', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 12. Wallet Ledger Entry Types
(generate_uuid_v7(), 'wallet_entry_type', 'DEBIT', 'Debit (Deduction)', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'wallet_entry_type', 'CREDIT', 'Credit (Addition)', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 13. Payment Order Statuses
(generate_uuid_v7(), 'order_status', 'INITIALIZED', 'Initialized', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'order_status', 'PROCESSING_PAYMENT', 'Payment Processing', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'order_status', 'SETTLED_SUCCESS', 'Settled & Successful', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'order_status', 'PAYMENT_FAILED', 'Payment Failed', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'order_status', 'EXPIRED_TIMEOUT', 'Order Expired', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'order_status', 'CANCELLED_USER', 'Cancelled by User', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 14. Invoice Statuses
(generate_uuid_v7(), 'invoice_status', 'DRAFT', 'Draft Invoice', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'invoice_status', 'ISSUED_UNPAID', 'Issued & Awaiting Payment', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'invoice_status', 'PAID_SETTLED', 'Paid & Fully Settled', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'invoice_status', 'PAYMENT_OVERDUE', 'Payment Overdue', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'invoice_status', 'VOID_CANCELLED', 'Void & Cancelled', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'invoice_status', 'WRITTEN_OFF_UNCOLLECTIBLE', 'Written Off (Uncollectible)', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 15. Message Thread Statuses
(generate_uuid_v7(), 'thread_status', 'ACTIVE_OPEN', 'Active & Open', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'thread_status', 'ARCHIVED_USER', 'Archived by User', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'thread_status', 'BLOCKED_BY_PARTY', 'Blocked by Participant', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'thread_status', 'FLAGGED_MODERATION', 'Flagged for Moderation', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'thread_status', 'PURGED_RETENTION', 'Purged per Data Retention Policy', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 16. Campus Placement Cohort Statuses
(generate_uuid_v7(), 'cohort_status', 'PLANNING_DRAFT', 'Planning & Draft', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'cohort_status', 'REGISTRATION_OPEN', 'Student Registration Open', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'cohort_status', 'SCREENING_IN_PROGRESS', 'Drive Screening in Progress', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'cohort_status', 'DRIVE_ACTIVE', 'Campus Drive Live & Active', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'cohort_status', 'OFFERS_CONCLUDED', 'Drive Offers Concluded', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'cohort_status', 'ARCHIVED_COMPLETED', 'Drive Concluded & Archived', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 17. Campus Student Placement Statuses
(generate_uuid_v7(), 'placement_status', 'REGISTERED_UNVERIFIED', 'Registered (Pending TPO Verification)', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'placement_status', 'VERIFIED_ELIGIBLE', 'TPO Verified & Eligible', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'placement_status', 'SHORTLISTED_DRIVE', 'Shortlisted by Campus Recruiter', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'placement_status', 'OFFER_RECEIVED', 'Campus Offer Received', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'placement_status', 'PLACED_ACCEPTED', 'Offer Accepted & Placed', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'placement_status', 'OPTED_OUT_INELIGIBLE', 'Opted Out / Ineligible', 'en_US', 6, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),

-- 18. DPDP Consent Record Statuses
(generate_uuid_v7(), 'status', 'PENDING_OPT_IN', 'Pending Candidate Opt-In', 'en_US', 1, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'status', 'EXPLICIT_GRANTED', 'Explicit Consent Granted', 'en_US', 2, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'status', 'EXPLICIT_REVOKED', 'Explicit Consent Revoked', 'en_US', 3, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'status', 'SYSTEM_SUPERSEDED', 'Superseded by Newer Policy', 'en_US', 4, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000'),
(generate_uuid_v7(), 'status', 'ANONYMIZED_EXPIRED', 'Consent Expired & Anonymized', 'en_US', 5, true, '00000000-0000-4000-8000-000000000000', '00000000-0000-4000-8000-000000000000');
