# Phase 1: Actor & Stakeholder Specification
**Platform:** Talentra Enterprise Workforce Platform  
**Stage:** Phase 1 — Discover ("Understand Before You Model")  
**Scope:** Canonical Persona Archetypes, Stakeholder Taxonomy & Role Vocabulary  
**Status:** Canonical Baseline Established  

---

## 1. Single Canonical Role Vocabulary

To eliminate role vocabulary drift, all documentation, requirements, features, permissions, and workflows across Talentra reference this single canonical dictionary of twelve roles:

| Role Code | Canonical Title | Primary Category | Typical Operational Environment |
| :--- | :--- | :--- | :--- |
| `RECRUITER` | Corporate Senior Recruiter | Core Human | Enterprise In-House Talent Acquisition Department |
| `CANDIDATE` | Job Seeker / Professional Talent | Core Human | Self-Service Web & Mobile Talent Portal |
| `GIG_WORKER` | Independent Freelance Contractor | Core Human | Contingent Workforce Marketplace |
| `EXECUTIVE` | VP of Talent Acquisition / CHRO | Core Human | Executive KPI & Recruitment Analytics Dashboard |
| `STAFFING_CONSULTANT`| Third-Party Recruitment Agency Director | Core Human | Multi-Client Sourcing & Placement Workspace |
| `ACCOUNT_ADMIN` | Corporate IT Tenancy Administrator | Core Human | Enterprise Organization & Seat Management Console |
| `ACADEMIC_PARTNER` | University Placement & Career Officer | Core Human | Campus Cohort Ingestion & Career Drive Portal |
| `COMPLIANCE_OFFICER` | Chief Data Privacy & Compliance Officer | Core Human | Data Protection & DPDP Consent Audit Console |
| `SMB_EMPLOYER` | Startup Founder & Small Business Client| Core Human | Pay-As-You-Go Talent Sourcing & Milestone Dashboard |
| `STATUTORY_REGULATOR`| External Labor & Data Protection Auditor| Edge Human | Statutory Non-Repudiation Audit & Log Review Vault |
| `SUPPORT_SPECIALIST` | Tier-2/3 Technical Support Specialist | Edge Human | Technical Operations & Session Management Console |
| `SYSTEM_DAEMON` | Automated Background Maintenance Worker | Edge System | Non-Interactive Database Worker & Queue Processor |

---

## 2. Comprehensive Persona Profiles (`P-01` to `P-12`)

### P-01: Asha — Corporate Senior Recruiter
* **Role Code**: `RECRUITER` | **Category**: Core Human
* **Operational Scope**: Enterprise Talent Acquisition for large multi-branch corporate accounts.
* **Frequency of Use**: Daily Continuous (50–150 operational actions per day).
* **Core Responsibilities**: Create and publish job requisitions, evaluate candidate application questionnaires, schedule interviews, and unlock full resume profiles.
* **Mapped Requirements**: `REQ-01`, `REQ-02`, `REQ-04`, `REQ-06`, `REQ-07`, `REQ-08`, `REQ-12`, `REQ-13`, `REQ-14`, `REQ-18`, `REQ-22`, `REQ-23`, `REQ-24`, `REQ-28`.
* **Primary Workflows**: `WF-02`, `WF-03`, `WF-04`.

### P-02: Rohan — Mid-Level Software Engineer (Candidate)
* **Role Code**: `CANDIDATE` | **Category**: Core Human
* **Operational Scope**: Active and passive job seeker seeking full-time and contract opportunities.
* **Frequency of Use**: Weekly Interactive (5–15 portal interactions per week).
* **Core Responsibilities**: Maintain profile details, upload verified resumes, complete pre-qualification questionnaires, and configure employer block lists.
* **Mapped Requirements**: `REQ-01`, `REQ-02`, `REQ-06`, `REQ-07`, `REQ-10`, `REQ-12`, `REQ-14`, `REQ-23`, `REQ-26`, `REQ-27`, `REQ-28`, `REQ-29`.
* **Primary Workflows**: `WF-01`, `WF-03`.

### P-03: Kabir — Independent Cloud Solutions Architect (Gig Freelancer)
* **Role Code**: `GIG_WORKER` | **Category**: Core Human
* **Operational Scope**: Specialized independent consultant delivering milestone-based technical projects.
* **Frequency of Use**: Daily On-Demand (10–30 interactions during active contract proposals).
* **Core Responsibilities**: Publish trade specialties, define hourly and milestone rates, maintain calendar availability, and receive wallet payouts.
* **Mapped Requirements**: `REQ-01`, `REQ-02`, `REQ-04`, `REQ-06`, `REQ-12`, `REQ-15`, `REQ-17`, `REQ-20`.
* **Primary Workflows**: `WF-05`, `WF-07`.

### P-04: Meera — VP of Talent Acquisition (Executive Leader)
* **Role Code**: `EXECUTIVE` | **Category**: Core Human
* **Operational Scope**: Strategic oversight of corporate workforce planning, time-to-hire velocity, and hiring spend.
* **Frequency of Use**: Weekly Strategic (1–3 dashboard review sessions per week).
* **Core Responsibilities**: Monitor hiring funnel conversion rates, review recruiter capacity utilization, and manage subscription tier investments.
* **Mapped Requirements**: `REQ-04`, `REQ-13`, `REQ-17`, `REQ-19`.
* **Primary Workflows**: `WF-06`, `WF-07`.

### P-05: Dev — Staffing Agency Account Director (Third-Party Consultant)
* **Role Code**: `STAFFING_CONSULTANT` | **Category**: Core Human
* **Operational Scope**: Agency recruiter managing split-fee candidate representations across enterprise client requisitions.
* **Frequency of Use**: Daily Continuous (100+ sourcing queries and candidate submissions per day).
* **Core Responsibilities**: Source specialized talent for partner requisitions, submit candidates for bounty placements, and track placement fee distributions.
* **Mapped Requirements**: `REQ-02`, `REQ-07`, `REQ-08`, `REQ-14`, `REQ-18`, `REQ-24`.
* **Primary Workflows**: `WF-04`.

### P-06: Nisha — Corporate IT Tenancy Administrator (Account Admin)
* **Role Code**: `ACCOUNT_ADMIN` | **Category**: Core Human
* **Operational Scope**: Enterprise tenant governance, branch organization hierarchy, and recruiter seat allocation.
* **Frequency of Use**: Weekly Administrative (5–10 configuration sessions per week).
* **Core Responsibilities**: Provision recruiter team accounts, assign corporate branch permissions, govern license seat quotas, and verify corporate tax identifiers.
* **Mapped Requirements**: `REQ-01`, `REQ-03`, `REQ-05`, `REQ-12`, `REQ-13`, `REQ-15`, `REQ-16`, `REQ-17`, `REQ-18`, `REQ-19`, `REQ-20`.
* **Primary Workflows**: `WF-02`, `WF-05`, `WF-06`, `WF-07`.

### P-07: Prof. Verma — University Placement Officer (Academic Partner)
* **Role Code**: `ACADEMIC_PARTNER` | **Category**: Core Human
* **Operational Scope**: University career placement management, campus batch cohort management, and early-career drives.
* **Frequency of Use**: Seasonal Cohort (High-volume bursts during annual campus placement cycles).
* **Core Responsibilities**: Ingest verified campus graduate cohort lists, validate institutional graduation credentials, and coordinate campus interview drives.
* **Mapped Requirements**: `REQ-06`, `REQ-07`, `REQ-22`.
* **Primary Workflows**: `WF-02`, `WF-03`.

### P-08: Ira — Chief Data Privacy Officer (Compliance Auditor)
* **Role Code**: `COMPLIANCE_OFFICER` | **Category**: Core Human
* **Operational Scope**: Enterprise regulatory compliance, DPDP Act 2023 oversight, and statutory data retention audit.
* **Frequency of Use**: Monthly Audit (Periodic governance reviews and on-demand statutory investigations).
* **Core Responsibilities**: Inspect purpose-bound consent registers, audit column sensitivity classifications, and review automated erasure cascade logs.
* **Mapped Requirements**: `REQ-09`, `REQ-10`, `REQ-11`, `REQ-20`.
* **Primary Workflows**: `WF-01`, `WF-04`.

### P-09: Vikram — Startup Founder & Small Business Employer
* **Role Code**: `SMB_EMPLOYER` | **Category**: Core Human
* **Operational Scope**: Fast, flexible hiring for early-stage companies and specialized freelance project delivery.
* **Frequency of Use**: Monthly On-Demand (Triggered as business milestones arise).
* **Core Responsibilities**: Create immediate gig milestone awards, evaluate local talent proposals, and disburse wallet compensation upon milestone sign-off.
* **Mapped Requirements**: `REQ-04`, `REQ-15`, `REQ-17`.
* **Primary Workflows**: `WF-05`, `WF-07`.

### P-10: Elena — Statutory Data Protection Regulator & External Auditor
* **Role Code**: `STATUTORY_REGULATOR` | **Category**: Edge Human
* **Operational Scope**: Independent external statutory inspection under the DPDP Act 2023, GDPR, and ISO/IEC 27001.
* **Frequency of Use**: Quarterly Formal Audit / On-Demand Regulatory Inquiry.
* **Core Responsibilities**: Verify forensic non-repudiation of audit trails, inspect affirmative consent revocation timing, and validate cryptographic key shredding.
* **Mapped Requirements**: `REQ-09`, `REQ-10`, `REQ-11`, `REQ-20`, `REQ-25`.
* **Primary Workflows**: `WF-01`, `WF-07`.

### P-11: Tariq — Tier-2/3 Technical Platform Support Specialist
* **Role Code**: `SUPPORT_SPECIALIST` | **Category**: Edge Human
* **Operational Scope**: Escalated operational problem resolution, session lockout clearance, and webhook failure mitigation.
* **Frequency of Use**: Daily Operational (20–40 operational tickets resolved per day).
* **Core Responsibilities**: Investigate session conflict clashes, trace failed payment webhook deliveries, and assist recruiters with credential lockouts.
* **Mapped Requirements**: `REQ-12`, `REQ-16`, `REQ-21`.
* **Primary Workflows**: `WF-04`, `WF-07`.

### P-12: Daemon — Automated Background Maintenance & Retention Cleaner
* **Role Code**: `SYSTEM_DAEMON` | **Category**: Edge System
* **Operational Scope**: Automated, non-interactive platform maintenance, partition rotation, and queue execution.
* **Frequency of Use**: Sub-Second Continuous (Automated background daemon workers).
* **Core Responsibilities**: Rotate monthly audit partitions, purge expired session tokens, execute asynchronous DPDP erasure cascades, and monitor WAL replication lag.
* **Mapped Requirements**: `REQ-03`, `REQ-05`, `REQ-09`, `REQ-11`, `REQ-16`, `REQ-19`, `REQ-21`, `REQ-25`.
* **Primary Workflows**: `WF-01`, `WF-02`, `WF-03`, `WF-04`, `WF-05`, `WF-06`, `WF-07`.
