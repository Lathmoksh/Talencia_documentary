-- =============================================================
-- Talentra Milestone 30: C-Suite Executive BI Dashboards & Mart Views
-- Multi-Perspective Analytics: CEO Overview, CFO Financial, COO Operational, VP Talent
-- =============================================================

-- VIEW 1: CEO High-Level Health Dashboard
CREATE OR REPLACE VIEW analytics.vw_ceo_executive_overview AS
SELECT 
    (SELECT COUNT(*) FROM organisation.organisation WHERE verification_status = 'VERIFIED_ACTIVE') AS active_enterprise_tenants,
    (SELECT COUNT(*) FROM recruitment.job_requisition WHERE publish_status = 'PUBLISHED_ACTIVE') AS active_open_job_requisitions,
    (SELECT COUNT(*) FROM candidate.candidate_profile WHERE is_profile_searchable = true) AS discoverable_candidate_talent_pool,
    (SELECT COUNT(*) FROM application.job_application WHERE application_status NOT IN ('REJECTED', 'WITHDRAWN')) AS active_in_flight_applications,
    (SELECT COALESCE(SUM(current_balance), 0.00) FROM billing.wallet_account) AS total_escrow_and_wallet_liquidity;

-- VIEW 2: CFO Financial Velocity & Double-Entry Ledger Summary
CREATE OR REPLACE VIEW analytics.vw_cfo_financial_velocity AS
SELECT 
    currency_code,
    COUNT(DISTINCT wallet_id) AS funded_wallet_count,
    SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE 0.00 END) AS gross_deposits,
    SUM(CASE WHEN entry_type = 'DEBIT' THEN amount ELSE 0.00 END) AS gross_withdrawals_and_disbursements,
    SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE -amount END) AS net_cash_balance
FROM billing.wallet_ledger
GROUP BY currency_code;

-- VIEW 3: Head of Talent: Recruitment Funnel Conversion Analysis
CREATE OR REPLACE VIEW analytics.vw_head_of_talent_funnel_summary AS
SELECT 
    r.job_category,
    COUNT(DISTINCT r.id) AS total_requisitions,
    COUNT(a.id) AS total_applications_received,
    COUNT(a.id) FILTER (WHERE a.application_status = 'SCREENING_PASSED') AS screening_passed_count,
    COUNT(a.id) FILTER (WHERE a.application_status = 'TECHNICAL_ASSESSMENT') AS tech_assessment_count,
    COUNT(a.id) FILTER (WHERE a.application_status = 'INTERVIEW_COMPLETED') AS interviews_completed_count,
    COUNT(a.id) FILTER (WHERE a.application_status IN ('OFFER_EXTENDED', 'OFFER_ACCEPTED')) AS offers_extended_count,
    COUNT(a.id) FILTER (WHERE a.application_status = 'OFFER_ACCEPTED') AS hires_confirmed_count
FROM recruitment.job_requisition r
LEFT JOIN application.job_application a ON r.id = a.requisition_id
GROUP BY r.job_category;

-- VIEW 4: VP of Marketplace: Gig Contract & Milestone Performance
CREATE OR REPLACE VIEW analytics.vw_vp_marketplace_gig_performance AS
SELECT 
    gc.contract_status,
    COUNT(DISTINCT gc.id) AS total_contracts,
    COALESCE(SUM(gc.agreed_amount), 0.00) AS total_contract_value,
    COUNT(gm.id) AS total_milestones,
    COUNT(gm.id) FILTER (WHERE gm.milestone_status = 'APPROVED_RELEASED') AS completed_milestones,
    COUNT(gm.id) FILTER (WHERE gm.milestone_status = 'DISPUTED_FROZEN') AS disputed_milestones
FROM gig.gig_contract gc
LEFT JOIN gig.gig_milestone gm ON gc.id = gm.contract_id
GROUP BY gc.contract_status;
