# Talentra — Feature Discovery & Competitive Analysis Docket
**Document Reference**: Deliverable C3 — Strategic Feature Inventory & Market Benchmarking  
**Step / Activity**: Step 03 — Feature Discovery  
**Platform**: Talentra Enterprise Workforce Platform  
**Architecture Domain**: Product Capabilities, Monetization & Differentiation  
**Status**: Approved & Frozen Baseline  

---

## Executive Summary: Step 03 — Feature Discovery

### 1. Executive Purpose & Strategic Framing
The Feature Discovery Docket establishes the functional capability baseline for the Talentra Enterprise Workforce Platform. Designed for Northbridge Workforce Systems, Talentra unifies enterprise permanent hiring, contingent gig labor mobilization, and university campus early-career programs under a single, highly performant multi-tenant platform.

This deliverable represents **Step 03: Feature Discovery** under Phase 1 Discover (Gate G1). Its objective is to define the platform's core functional capabilities, categorize them via MoSCoW prioritization, establish rigorous two-way traceability back to foundational business requirements (`REQ-01` to `REQ-29`), and demonstrate concrete architectural and commercial superiority over legacy competitors (LinkedIn Talent Solutions, InfoEdge Naukri, Monster Worldwide, and Upwork Enterprise).

### 2. Key Accomplishments of Step 03
* **Master 23-Feature Inventory (`F-01` to `F-23`)**: Comprehensive capability catalog spanning 7 strategic pillars, with every single feature accompanied by an explicit `trace_note` proving requirement satisfaction.
* **Rigorous MoSCoW Prioritization**:
  * **17 Must-Have Features**: Critical operational capabilities (registration, multi-tenancy, job publishing, screening questionnaires, semantic search, application tracking, seat quotas, audit logging, DPDP consent, faceted search, alerts, messaging, journey tracker).
  * **2 Should-Have Features**: High-impact enterprise capabilities (Candidate Referral Program, University Campus Cohort Ingestion).
  * **4 Commercial Differentiators**: Distinctive market innovations:
    * `F-03` Candidate Privacy Shield (anti-join employer block masking).
    * `F-08` Consultant Sourcing Marketplace (agency split bounties with 180-day lock).
    * `F-11` Corporate Prepaid Wallet & Milestone Escrow (zero-variance double-entry accounting).
    * `F-14` Conflict-Free Freelance Calendar Booking (temporal GiST exclusion constraints).
* **15-Dimension Competitor Coverage Benchmark**: Rigorous comparative matrix evaluating LinkedIn, Naukri, Monster, and Upwork, backed by live documentation deep links, access timestamps (`2026-10-23`), and commercial gap analyses.

---

## 1. Competitive Benchmarking Matrix & Architectural Gap Analysis

The following matrix benchmarks Talentra across 15 critical capability dimensions against industry leaders:

| Capability Area | Talentra Implementation | LinkedIn Verdict & Proof | Naukri Verdict & Proof | Monster Verdict & Proof | Upwork Verdict & Proof | Competitor Gap & Market Impact |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **1. Candidate Faceted Job Search** | Candidate-side multi-filter discovery by salary band, location hierarchy, skills, and employment model. | [✓ Supported](https://www.linkedin.com/help/linkedin/answer/a505436/search-for-jobs) *(2026-10-23)* | [✓ Supported](https://www.naukri.com/faq/jobseeker-faq) *(2026-10-23)* | [Partial](https://hiring.monster.com/resources/recruiting-strategies/job-descriptions) *(2026-10-23)* | [Partial](https://support.upwork.com/hc/en-us/articles/211063068-Search-for-Jobs) *(2026-10-23)* | Traditional portals silo full-time jobs from gig projects. Talentra unifies all employment models into one faceted search. |
| **2. Automated Job Alerts & Push Notifications** | Personalized daily/instant notification subscriptions matching candidate skill profile and preferences. | [✓ Supported](https://www.linkedin.com/help/linkedin/answer/a505436/manage-job-alerts) *(2026-10-23)* | [Partial](https://www.naukri.com/faq/jobseeker-faq) *(2026-10-23)* | [Partial](https://hiring.monster.com/resources/recruiting-strategies/talent-acquisition) *(2026-10-23)* | [✓ Supported](https://support.upwork.com/hc/en-us/articles/211063068-Job-Alerts) *(2026-10-23)* | Competitors lock high-frequency alerts behind candidate upsell packages. Talentra provides real-time alerts natively. |
| **3. In-App Direct Recruiter-Candidate Messaging** | Real-time messaging thread linking recruiter and candidate once application or unlock is authorized. | [Partial](https://business.linkedin.com/talent-solutions/recruiter) *(2026-10-23)* | [✗ Absent](https://resdex.naukri.com/v2/pricing) *(2026-10-23)* | [✗ Absent](https://hiring.monster.com/plans/pricing-options) *(2026-10-23)* | [✓ Supported](https://support.upwork.com/hc/en-us/articles/211062898-Direct-Contracts-with-Clients) *(2026-10-23)* | InMail credits cost up to $10 per message on LinkedIn. Talentra includes direct messaging automatically upon authorized unlock. |
| **4. Application Status Tracking Dashboard** | Live candidate tracker showing progression across 13 pipeline stages from submission to offer acceptance. | [Partial](https://www.linkedin.com/help/linkedin/answer/a544990/tracking-job-applications) *(2026-10-23)* | [Partial](https://www.naukri.com/faq/jobseeker-faq) *(2026-10-23)* | [✗ Absent](https://hiring.monster.com/resources/workforce-management/talent-acquisition) *(2026-10-23)* | [Partial](https://support.upwork.com/hc/en-us/articles/211063068-Search-for-Jobs) *(2026-10-23)* | Candidates face an application black hole on legacy portals. Talentra guarantees stage transparency across every pipeline milestone. |
| **5. Candidate Privacy Shield & Employer Blocking** | Candidates designate specific corporate organization IDs to completely hide profile from search and sourcing. | [Partial](https://www.linkedin.com/help/recruiter/answer/a524332/manage-your-open-to-work-visibility) *(2026-10-23)* | [Partial](https://www.naukri.com/privacypolicy) *(2026-10-23)* | [✗ Absent](https://www.monster.com/privacy-center/privacy-policy) *(2026-10-23)* | [✗ Absent](https://support.upwork.com/hc/en-us/articles/211062948-Profile-Visibility) *(2026-10-23)* | Candidates risk accidental exposure to current employers or competitor agencies. Talentra provides airtight verifiable privacy guaranteed to exclude designated organizations. |
| **6. Dual-Track Workforce Model** | Unified hiring account supporting permanent full-time hiring, contingent gig milestones, and campus cohorts. | [✗ Absent](https://business.linkedin.com/talent-solutions/recruiter) *(2026-10-23)* | [✗ Absent](https://www.naukri.com/terms-and-conditions) *(2026-10-23)* | [✗ Absent](https://hiring.monster.com/plans/pricing-options) *(2026-10-23)* | [Partial](https://www.upwork.com/enterprise/contingent-workforce) *(2026-10-23)* | Enterprises are forced to purchase multiple disparate platforms with disjointed billing. Talentra enables agile labor reallocation under one corporate roof. |
| **7. Freelance Scheduling Safety** | Automated calendar availability conflict check preventing concurrent double-booking of talent. | [✗ Absent](https://business.linkedin.com/talent-solutions/recruiter) *(2026-10-23)* | [✗ Absent](https://www.naukri.com/terms-and-conditions) *(2026-10-23)* | [✗ Absent](https://hiring.monster.com/plans/pricing-options) *(2026-10-23)* | [Partial](https://www.upwork.com/resources/how-to-manage-multiple-freelance-projects) *(2026-10-23)* | Application race conditions in competitor marketplaces lead to double-booked talent. Talentra guarantees temporal availability exclusivity. |
| **8. Prepaid Corporate Wallet & Milestone Escrow** | Prepaid corporate wallet with instant running balance updates and transparent escrow locks. | [✗ Absent](https://business.linkedin.com/talent-solutions/recruiter) *(2026-10-23)* | [Partial](https://www.naukri.com/terms-and-conditions) *(2026-10-23)* | [Partial](https://hiring.monster.com/plans/pricing-options) *(2026-10-23)* | [✓ Supported](https://support.upwork.com/hc/en-us/articles/211063668-Fixed-Price-Protection) *(2026-10-23)* | Batch reconciliations and multi-day clearing cycles cause billing disputes. Talentra provides real-time transaction transparency with zero balance variance. |
| **9. Recruiter Seat Governance & Session Control** | Single active session protection terminating prior device sessions upon new login to prevent seat sharing. | [Partial](https://business.linkedin.com/talent-solutions/recruiter) *(2026-10-23)* | [Partial](https://www.naukri.com/terms-and-conditions) *(2026-10-23)* | [Partial](https://hiring.monster.com/plans/pricing-options) *(2026-10-23)* | [Partial](https://www.upwork.com/enterprise/contingent-workforce) *(2026-10-23)* | Competitors suffer millions in commercial leakage due to unmetered credential sharing. Talentra strictly enforces purchased recruiter seat limits at the device level. |
| **10. Screening Questionnaires & Qualification Thresholds** | Versioned screening questionnaires with weighted scoring and automated qualification thresholds. | [✓ Supported](https://www.linkedin.com/help/recruiter/answer/a544990/screening-questions-in-recruiter) *(2026-10-23)* | [Partial](https://www.naukri.com/faq/jobseeker-faq) *(2026-10-23)* | [Partial](https://hiring.monster.com/resources/recruiting-strategies/screening-and-interviewing) *(2026-10-23)* | [Partial](https://support.upwork.com/hc/en-us/articles/211063068-Search-for-Jobs) *(2026-10-23)* | Competitor pre-screening requires extensive manual recruiter triage. Talentra automates qualification scoring to instantly eliminate unqualified applications. |
| **11. Statutory DPDP Consent & Instant Erasure** | Purpose-bound consent tracking with instant automated personal data erasure upon candidate revocation. | [Partial](https://business.linkedin.com/talent-solutions/recruiter) *(2026-10-23)* | [Partial](https://www.naukri.com/privacypolicy) *(2026-10-23)* | [Partial](https://www.monster.com/privacy-center/privacy-policy) *(2026-10-23)* | [Partial](https://support.upwork.com/hc/en-us/articles/211062948-Profile-Visibility) *(2026-10-23)* | DPDP Act 2023 mandates instant erasure upon consent withdrawal with heavy statutory fines. Talentra implements automated erasure by design. |
| **12. University Graduate Campus Cohort Onboarding** | Bulk graduate cohort ingestion with academic degree, branch, and graduation year pipeline management. | [Partial](https://business.linkedin.com/talent-solutions/campus) *(2026-10-23)* | [✓ Supported](https://www.firstnaukri.com/recruiters/campus-hiring) *(2026-10-23)* | [Partial](https://hiring.monster.com/resources/workforce-management/talent-acquisition) *(2026-10-23)* | [✗ Absent](https://www.upwork.com/enterprise/contingent-workforce) *(2026-10-23)* | Enterprises managing annual fresher hiring drives are forced onto expensive standalone campus tools. Talentra natively manages university cohorts alongside lateral requisitions. |
| **13. Resume Contact Unlocking & Metering** | Metered resume contact unlocking deducting monthly credits or debiting cleared corporate wallet. | [✓ Supported](https://business.linkedin.com/talent-solutions/recruiter) *(2026-10-23)* | [✓ Supported](https://resdex.naukri.com/v2/pricing) *(2026-10-23)* | [✓ Supported](https://hiring.monster.com/plans/pricing-options) *(2026-10-23)* | [✗ Absent](https://support.upwork.com/hc/en-us/articles/211062898-Direct-Contracts-with-Clients) *(2026-10-23)* | Competitor models either charge steep subscription fees or opaque per-message fees. Talentra enables flexible pay-per-unlock alongside tiered subscriptions. |
| **14. External Staffing Agency Split Placement** | External staffing agencies represent pre-screened talent for split placement bounties. | [✗ Absent](https://business.linkedin.com/talent-solutions/recruiter) *(2026-10-23)* | [✗ Absent](https://resdex.naukri.com/v2/pricing) *(2026-10-23)* | [✗ Absent](https://hiring.monster.com/plans/pricing-options) *(2026-10-23)* | [Partial](https://www.upwork.com/enterprise/contingent-workforce) *(2026-10-23)* | Enterprise hiring teams struggle to coordinate external agencies without overlapping fees. Talentra provides transparent agency representation with locked 180-day attribution. |
| **15. Skills Assessment & Verified Badging** | Standardized technical assessments producing verified proficiency badges on candidate dossiers. | [✓ Supported](https://www.linkedin.com/help/linkedin/answer/a544990/screening-questions-in-recruiter) *(2026-10-23)* | [Partial](https://resdex.naukri.com/v2/pricing) *(2026-10-23)* | [✗ Absent](https://hiring.monster.com/resources/recruiting-strategies/screening-and-interviewing) *(2026-10-23)* | [✓ Supported](https://support.upwork.com/hc/en-us/articles/211062898-Direct-Contracts-with-Clients) *(2026-10-23)* | Fragmented assessment platforms require external testing subscriptions. Talentra integrates skill assessment directly into the candidate pipeline. |

---

## 2. Master 23-Feature Modular Inventory (`F-01` to `F-23`)

### Pillar 1: Identity, Tenancy & Security
* **F-01: User Account Registration & Contact Normalization**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-01`, `REQ-02`, `REQ-03`, `REQ-12`.
  * **Trace Note**: F-01 implements lowercase normalization (`REQ-01`), E.164 phone validation (`REQ-02`), immutable entity keys (`REQ-03`), and slow password transformations (`REQ-12`).
  * **User Description**: Self-service user registration with case-insensitive lowercase email normalization and international E.164 phone validation.
* **F-02: Multi-Tenant Organization Governance & Branch Hierarchy**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-05`, `REQ-13`.
  * **Trace Note**: F-02 provides active state flags for branch lookups (`REQ-05`) and enforces strict cross-tenant pipeline isolation (`REQ-13`).
  * **User Description**: Corporate enterprise account provisioning with branch location hierarchies and isolated candidate pipelines.
* **F-03: Candidate Privacy Shield & Employer Block List**
  * **Classification**: **Differentiator** | **Mapped REQs**: `REQ-14`.
  * **Trace Note**: F-03 directly satisfies `REQ-14` by allowing candidates to designate specific corporate organization IDs for search exclusion.
  * **User Description**: Candidates can select current employers and competitors to completely hide their active search profile via indexed anti-joins.

### Pillar 2: Recruitment & Sourcing Pipeline
* **F-04: Structured Job Requisition Publishing**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-04`, `REQ-13`.
  * **Trace Note**: F-04 enforces fixed-precision salary bands with ISO currency (`REQ-04`) within tenant-isolated organizational units (`REQ-13`).
  * **User Description**: Create and publish job requisitions with fixed-precision compensation bands and skill requirements.
* **F-05: Automated Screening Questionnaires & Assessments**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-07`, `REQ-08`.
  * **Trace Note**: F-05 attaches versioned screening questionnaires (`REQ-07`) and custom pre-qualification criteria (`REQ-08`) to requisitions.
  * **User Description**: Attach versioned questionnaires to requisitions with automated scoring and minimum pass thresholds.
* **F-06: Semantic Skill Search & Resume Parsing**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-06`, `REQ-24`.
  * **Trace Note**: F-06 supports localized multilingual search terms (`REQ-06`) and delivers low-latency talent search results (`REQ-24`).
  * **User Description**: Interactive low-latency candidate keyword and skill vector similarity matching across large resume pools.
* **F-07: Job Application Pipeline & Funnel Progression**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-07`, `REQ-08`.
  * **Trace Note**: F-07 tracks candidate progression against questionnaire qualification thresholds (`REQ-07`) and custom form evaluations (`REQ-08`).
  * **User Description**: Structured candidate progression from applied through review, assessment, interview, and offer stages.
* **F-08: Consultant Placement & Sourcing Marketplace**
  * **Classification**: **Differentiator** | **Mapped REQs**: `REQ-04`, `REQ-18`.
  * **Trace Note**: F-08 tracks split placement fees in ISO currency (`REQ-04`) and coordinates metered recruiter contact unlocks (`REQ-18`).
  * **User Description**: External staffing agencies can represent candidates on enterprise openings for split placement bounties with 180-day attribution.

### Pillar 3: Monetization, Licensing & Billing
* **F-09: Resume Contact Unlocking & Quota Metering**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-18`.
  * **Trace Note**: F-09 implements metered access to candidate contact info and resumes, deducting monthly credits or debiting wallet balance (`REQ-18`).
  * **User Description**: Metered access to candidate contact info and resumes, deducting monthly credits or debiting wallet balance with immutable receipts.
* **F-10: Tiered Enterprise Recruiter Seat Licensing**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-16`, `REQ-19`.
  * **Trace Note**: F-10 terminates concurrent multi-device logins (`REQ-16`) and enforces hard corporate recruiter seat caps (`REQ-19`).
  * **User Description**: Subscription management enforcing hard caps on assigned recruiter seats per corporate tier with device concurrency locks.
* **F-11: Corporate Prepaid Wallet & Milestone Escrow**
  * **Classification**: **Differentiator** | **Mapped REQs**: `REQ-04`, `REQ-17`, `REQ-21`.
  * **Trace Note**: F-11 holds project funds in fixed-precision currency (`REQ-04`), governed by double-entry escrow accounting (`REQ-17`), with idempotent webhook processing (`REQ-21`).
  * **User Description**: Corporate prepaid wallet holding funds in escrow during active gig projects with zero accounting variance.
* **F-12: Candidate & Client Wallet Statements & Payout Ledger**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-17`.
  * **Trace Note**: F-12 displays transparent running balances and transaction receipts derived directly from the double-entry ledger (`REQ-17`).
  * **User Description**: Transparent user statements displaying real-time cleared balance, pending escrow holds, and itemized payout history.

### Pillar 4: Contingent Gig Labor Marketplace
* **F-13: Freelancer Trade Showcase & Skill Verification**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-05`, `REQ-20`.
  * **Trace Note**: F-13 references standardized trade category lookups (`REQ-05`) and displays verified status for national tax IDs (`REQ-20`).
  * **User Description**: Gig worker profiles showcasing specialized trade categories, hourly rates, and verified background badges.
* **F-14: Conflict-Free Freelance Calendar Booking**
  * **Classification**: **Differentiator** | **Mapped REQs**: `REQ-15`.
  * **Trace Note**: F-14 directly implements temporal non-overlapping booking validation across active gig contracts (`REQ-15`).
  * **User Description**: Automated calendar availability check preventing clients from booking the same freelancer for overlapping dates.
* **F-15: Milestone Sign-Off & Escrow Payout**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-04`, `REQ-17`.
  * **Trace Note**: F-15 executes milestone payouts in fixed-precision currency (`REQ-04`) via double-entry ledger transfers (`REQ-17`).
  * **User Description**: Client sign-off on delivered project milestones releasing locked escrow funds to worker wallet accounts.

### Pillar 5: Governance, Compliance & Security
* **F-16: Forensic Compliance Audit & Activity Logging**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-09`, `REQ-11`, `REQ-25`.
  * **Trace Note**: F-16 records immutable append-only audit trails (`REQ-09`), applies data retention tiers (`REQ-11`), and survives disaster events (`REQ-25`).
  * **User Description**: Immutable activity logging capturing pre- and post-mutation state, actor IDs, and IP addresses.
* **F-17: Statutory DPDP Consent & Erasure Management**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-10`.
  * **Trace Note**: F-17 implements purpose-bound consent collection and immediate automated PII erasure upon withdrawal (`REQ-10`).
  * **User Description**: Affirmative purpose-bound consent collection with immediate automated data erasure upon withdrawal.

### Pillar 6: Talent Engagement & Campus Programs
* **F-18: Tracked Candidate Referral Program**
  * **Classification**: **Should-Have** | **Mapped REQs**: `REQ-23`.
  * **Trace Note**: F-18 generates attribution-tracked candidate referral links and calculates verified hiring bonuses (`REQ-23`).
  * **User Description**: Unique alphanumeric referral link generation with automated hiring attribution and referral bonuses.
* **F-19: Campus Batch Cohort Management**
  * **Classification**: **Should-Have** | **Mapped REQs**: `REQ-22`.
  * **Trace Note**: F-19 enables academic placement partners to bulk-onboard graduate student cohorts grouped by university and degree (`REQ-22`).
  * **User Description**: Bulk graduate candidate ingestion for university placement officers with degree, branch, and graduation year grouping.

### Pillar 7: Candidate Experience & Discovery
* **F-20: Candidate Faceted Job Search & Filter**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-26`.
  * **Trace Note**: F-20 implements candidate-facing faceted discovery across published requisitions by salary, location, and skills (`REQ-26`).
  * **User Description**: Candidate-facing faceted search allowing talent to filter openings by salary band, location hierarchy, remote status, and required skills.
* **F-21: Automated Job Alerts & Notification Subscriptions**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-27`.
  * **Trace Note**: F-21 enables candidates to subscribe to real-time notification feeds matching their skill and compensation criteria (`REQ-27`).
  * **User Description**: Personalized real-time job alerts and email notification subscriptions matching candidate skill preferences.
* **F-22: In-App Direct Recruiter-Candidate Messaging**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-28`.
  * **Trace Note**: F-22 provides real-time in-app direct messaging between candidates and recruiters with session security controls (`REQ-28`).
  * **User Description**: Direct, secure communication thread between recruiters and unlocked candidates for interview scheduling and role clarification.
* **F-23: Candidate Application Journey Tracker & Timeline**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-29`.
  * **Trace Note**: F-23 provides full stage-by-stage transparency to candidates regarding application review and interview progress (`REQ-29`).
  * **User Description**: Interactive candidate dashboard displaying real-time application stage progression, screening results, and interview schedule timeline.

---

## 3. MoSCoW Prioritization & Value Stratification

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       MOSCOW FEATURE STRATIFICATION                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ MUST-HAVE (17 Features) - 73.9%                                             │
│ F-01, F-02, F-04, F-05, F-06, F-07, F-09, F-10, F-12, F-13, F-15, F-16,     │
│ F-17, F-20, F-21, F-22, F-23                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ DIFFERENTIATORS (4 Features) - 17.4%                                        │
│ F-03 (Privacy Shield), F-08 (Agency Marketplace),                           │
│ F-11 (Wallet Escrow), F-14 (Calendar Guard)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ SHOULD-HAVE (2 Features) - 8.7%                                             │
│ F-18 (Tracked Referrals), F-19 (Campus Cohort Ingestion)                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Discovery Boundaries & Next Stage Linkage

In strict accordance with Phase 1 Discover principles, **no database tables, DDL scripts, or UI components are modeled in this document**.

This completes **Step 03: Feature Discovery**. The established 23 features and competitive benchmark feed directly into **Step 04: NFR Discovery (`d/`)**, where operational quality parameters and mathematical volumetric derivations are formalized.
