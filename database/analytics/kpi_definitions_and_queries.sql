-- =============================================================
-- Talentra Milestone 29: Master KPI Calculation Query Catalogue
-- Computes executive & operational metrics directly from verified schema
-- =============================================================

-- KPI-001: Requisition Fill Rate (%)
-- Formula: (Closed Filled Requisitions / Total Closed Requisitions) * 100
SELECT 'KPI-001' AS kpi_id,
       'Requisition Fill Rate' AS kpi_name,
       ROUND(
         (COUNT(*) FILTER (WHERE publish_status = 'CLOSED_FILLED')::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE publish_status IN ('CLOSED_FILLED', 'CANCELLED_EXPIRED')), 0)) * 100.0, 2
       ) AS metric_value,
       '%' AS unit,
       'Executive Talent Acquisition Outcome' AS business_dimension
FROM recruitment.job_requisition;

-- KPI-003: Application-to-Offer Conversion Rate (%)
-- Formula: (Offers Extended / Total Submitted Applications) * 100
SELECT 'KPI-003' AS kpi_id,
       'Application-to-Offer Conversion Rate' AS kpi_name,
       ROUND(
         (COUNT(*) FILTER (WHERE application_status IN ('OFFER_EXTENDED', 'OFFER_ACCEPTED', 'OFFER_DECLINED'))::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE application_status <> 'DRAFT'), 0)) * 100.0, 2
       ) AS metric_value,
       '%' AS unit,
       'Hiring Funnel Efficiency' AS business_dimension
FROM application.job_application;

-- KPI-007: Candidate Activation Rate (%)
-- Formula: (Verified Discoverable Candidates / Total Registered Candidates) * 100
SELECT 'KPI-007' AS kpi_id,
       'Candidate Activation Rate' AS kpi_name,
       ROUND(
         (COUNT(cp.id) FILTER (WHERE cp.is_profile_searchable = true AND ua.account_status = 'ACTIVE_VERIFIED')::numeric / 
          NULLIF(COUNT(ua.id), 0)) * 100.0, 2
       ) AS metric_value,
       '%' AS unit,
       'Talent Supply Health' AS business_dimension
FROM identity.user_account ua
LEFT JOIN candidate.candidate_profile cp ON ua.id = cp.user_id
WHERE ua.user_type = 'CANDIDATE';

-- KPI-008: Average Candidate Profile Completeness (%)
SELECT 'KPI-008' AS kpi_id,
       'Average Candidate Profile Completeness' AS kpi_name,
       ROUND(AVG(profile_completion_percentage), 2) AS metric_value,
       '%' AS unit,
       'Data Quality & Match Readiness' AS business_dimension
FROM candidate.candidate_profile;

-- KPI-011: Gig Milestone Delivery Completion Rate (%)
-- Formula: (Approved Milestones / Total Milestones Committed) * 100
SELECT 'KPI-011' AS kpi_id,
       'Gig Milestone Delivery Completion Rate' AS kpi_name,
       ROUND(
         (COUNT(*) FILTER (WHERE milestone_status = 'APPROVED_RELEASED')::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE milestone_status IN ('APPROVED_RELEASED', 'REFUNDED_TO_CLIENT', 'DISPUTED_FROZEN')), 0)) * 100.0, 2
       ) AS metric_value,
       '%' AS unit,
       'Marketplace Fulfillment' AS business_dimension
FROM gig.gig_milestone;

-- KPI-014: Net Platform Wallet Inflow (Sovereign Currency: INR)
-- Formula: Total Deposit Credits - Total Withdrawal Debits
SELECT 'KPI-014' AS kpi_id,
       'Net Platform Wallet Inflow' AS kpi_name,
       COALESCE(SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE -amount END), 0.00) AS metric_value,
       'INR' AS unit,
       'Commercial Financial Velocity' AS business_dimension
FROM billing.wallet_ledger;

-- KPI-021: Recruiter Seat Quota Utilisation (%)
-- Formula: (Active Allocated Recruiter Seats / Total Licensed Recruiter Capacity) * 100
SELECT 'KPI-021' AS kpi_id,
       'Recruiter Seat Quota Utilisation' AS kpi_name,
       ROUND(
         (COUNT(rsa.id)::numeric / NULLIF(SUM(sp.max_recruiter_seats), 0)) * 100.0, 2
       ) AS metric_value,
       '%' AS unit,
       'SaaS Licensing Revenue Efficiency' AS business_dimension
FROM organisation.organisation o
JOIN licensing.subscription_licence sl ON o.account_id = sl.account_id AND sl.licence_status = 'ACTIVE_COMMISSIONED'
JOIN licensing.subscription_plan sp ON sl.plan_id = sp.id
LEFT JOIN organisation.recruiter_seat_assignment rsa ON o.id = rsa.organisation_id AND rsa.seat_status = 'ACTIVE_ALLOCATED';
