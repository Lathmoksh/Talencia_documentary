# Talentra — Stakeholders, Personas & Roles Docket
**Document Reference**: Deliverable B3 — Actor Modeling & Authorization Governance  
**Step / Activity**: Step 02 — Stakeholders, Personas and Roles  
**Platform**: Talentra Enterprise Workforce Platform  
**Architecture Domain**: Identity, Multi-Tenancy & Authorization  
**Status**: Approved & Frozen Baseline  

---

## Executive Summary: Step 02 — Stakeholders, Personas & Roles

### 1. Executive Purpose & Governance Scope
The Stakeholders, Personas & Roles Docket translates Northbridge's multi-tiered talent acquisition and workforce mobilization operations into an authoritative identity, actor, and authorization model. In large-scale enterprise platforms, cross-tenant data leaks and operational breakdowns frequently occur when system boundaries are designed around informal user descriptions rather than formal, mathematically verified role structures.

This deliverable establishes the canonical identity and entitlement foundation under Phase 1 Discover (Gate G1). It introduces a single, authoritative role dictionary, profiles 12 comprehensive persona archetypes (`P-01` to `P-12`) spanning core human users, specialized external edge actors, and automated background daemons, and formalizes an exhaustive $12 \times 11$ module CRUD authorization matrix.

### 2. Key Accomplishments of Step 02
* **Single Authoritative Role Dictionary**: Eliminates terminology drift by defining twelve canonical roles (`RECRUITER`, `CANDIDATE`, `GIG_WORKER`, `EXECUTIVE`, `STAFFING_CONSULTANT`, `ACCOUNT_ADMIN`, `ACADEMIC_PARTNER`, `COMPLIANCE_OFFICER`, `SMB_EMPLOYER`, `STATUTORY_REGULATOR`, `SUPPORT_SPECIALIST`, `SYSTEM_DAEMON`).
* **Complete Persona Modeling (`P-01` to `P-12`)**: Every persona specifies operational scope, quantitative interaction frequencies (from Daily Continuous 150 actions/day to Sub-Second Automated continuous execution), mapped requirements (`REQ-01` to `REQ-29`), and database guardrails.
* **Specialized Enterprise Edge Actors**: Incorporates essential actors often neglected in standard designs:
  * **P-10: Elena — Statutory Data Protection Regulator & External Auditor** (`R---` on audit and consent registries).
  * **P-11: Tariq — Tier-2/3 Technical Support Specialist** (operational issue mitigation without PII visibility).
  * **P-12: Daemon — Automated Background Maintenance Cleaner** (sub-second partition rollover, session cleanup, and DPDP erasure).
* **Exhaustive $12 \times 11$ CRUD Entitlement Matrix**: 132 permission intersections across 11 platform subsystems, enforcing strict append-only invariants: `system_audit` and `wallet_billing` strictly ban in-place `UPDATE` and `DELETE` operations.

---

## 1. Single Canonical Role Vocabulary

To prevent role vocabulary drift, all specifications, requirements, features, permissions, and workflows reference this single canonical dictionary of twelve roles:

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

## 2. Enterprise Stakeholder Taxonomy (`STK-01` to `STK-10`)

| Stakeholder ID | Category | Stakeholder Description | Primary Strategic Responsibility |
| :--- | :--- | :--- | :--- |
| **STK-01** | **Executive Leadership** | Chief Human Resources Officers, VPs of Talent Acquisition | Platform adoption, organizational hiring velocity, commercial licensing ROI. |
| **STK-02** | **Corporate Recruitment** | In-house enterprise talent acquisition partners, sourcing leads | Job requisition management, candidate pipeline progression, offer extension. |
| **STK-03** | **Job Seekers & Talent** | Professional candidates, campus freshers, apprentice applicants | Profile curation, resume privacy control, job search, application tracking. |
| **STK-04** | **Contingent Workforce** | Independent contractors, gig workers, subject-matter experts | Trade showcase, milestone proposal submission, calendar availability. |
| **STK-05** | **Staffing Consultancies**| Third-party recruitment agencies, executive search firms | Split-commission candidate representation, candidate sourcing marketplace. |
| **STK-06** | **Academic Partners** | University career centers, vocational placement departments | Campus batch cohort management, verified credential verification. |
| **STK-07** | **System Administration**| Corporate IT tenant administrators, HR operations managers | Tenant seat allocation, branch hierarchies, user role provisioning. |
| **STK-08** | **Statutory Regulators** | Data protection authorities, labor compliance inspectors | Enforcement of DPDP Act 2023, GDPR Article 17 erasure, audit trail integrity. |
| **STK-09** | **Technical Operations** | Tier-2/3 technical helpdesk, support engineers | Operational troubleshooting, session unlock, payment webhook reconciliation. |
| **STK-10** | **System Daemons** | Automated cron workers, partition cleaners, queue processors | Scheduled partition rollover, asynchronous DPDP erasure, WAL streaming. |

---

## 3. Comprehensive Persona Profiles (`P-01` to `P-12`)

### Core Enterprise Personas

#### P-01: Asha — Corporate Senior Recruiter
* **Role Code**: `RECRUITER` | **Category**: Core Human
* **Operational Scope**: Enterprise Talent Acquisition for large multi-branch corporate accounts.
* **Frequency of Use**: Daily Continuous (50–150 operational actions per day).
* **Core Responsibilities**: Create and publish job requisitions, evaluate candidate application questionnaires, schedule interviews, and unlock full resume profiles.
* **Mapped Requirements**: `REQ-01`, `REQ-02`, `REQ-04`, `REQ-06`, `REQ-07`, `REQ-08`, `REQ-12`, `REQ-13`, `REQ-14`, `REQ-18`, `REQ-22`, `REQ-23`, `REQ-24`, `REQ-28`.
* **Primary Workflows**: `WF-02`, `WF-03`, `WF-04`.
* **Key Guardrail**: Restricted strictly to hiring `organisation_id` via PostgreSQL Row-Level Security (`RLS`).

#### P-02: Rohan — Mid-Level Software Engineer (Candidate)
* **Role Code**: `CANDIDATE` | **Category**: Core Human
* **Operational Scope**: Active and passive job seeker seeking full-time and contract opportunities.
* **Frequency of Use**: Weekly Interactive (5–15 portal interactions per week).
* **Core Responsibilities**: Maintain profile details, upload verified resumes, complete pre-qualification questionnaires, and configure employer block lists.
* **Mapped Requirements**: `REQ-01`, `REQ-02`, `REQ-06`, `REQ-07`, `REQ-10`, `REQ-12`, `REQ-14`, `REQ-23`, `REQ-26`, `REQ-27`, `REQ-28`, `REQ-29`.
* **Primary Workflows**: `WF-01`, `WF-03`.
* **Key Guardrail**: Anti-join privacy view completely hides profile from employers listed in `candidate_block_list`.

#### P-03: Kabir — Independent Cloud Solutions Architect (Gig Freelancer)
* **Role Code**: `GIG_WORKER` | **Category**: Core Human
* **Operational Scope**: Specialized independent consultant delivering milestone-based technical projects.
* **Frequency of Use**: Daily On-Demand (10–30 interactions during active contract proposals).
* **Core Responsibilities**: Publish trade specialties, define hourly and milestone rates, maintain calendar availability, and receive wallet payouts.
* **Mapped Requirements**: `REQ-01`, `REQ-02`, `REQ-04`, `REQ-06`, `REQ-12`, `REQ-15`, `REQ-17`, `REQ-20`.
* **Primary Workflows**: `WF-05`, `WF-07`.
* **Key Guardrail**: PostgreSQL `GiST` exclusion constraint prevents double-booking across overlapping contract dates.

#### P-04: Meera — VP of Talent Acquisition (Executive Leader)
* **Role Code**: `EXECUTIVE` | **Category**: Core Human
* **Operational Scope**: Strategic oversight of corporate workforce planning, time-to-hire velocity, and hiring spend.
* **Frequency of Use**: Weekly Strategic (1–3 dashboard review sessions per week).
* **Core Responsibilities**: Monitor hiring funnel conversion rates, review recruiter capacity utilization, and manage subscription tier investments.
* **Mapped Requirements**: `REQ-04`, `REQ-13`, `REQ-17`, `REQ-19`.
* **Primary Workflows**: `WF-06`, `WF-07`.
* **Key Guardrail**: Read-only analytical queries executed against aggregate reporting marts.

#### P-05: Dev — Staffing Agency Account Director (Third-Party Consultant)
* **Role Code**: `STAFFING_CONSULTANT` | **Category**: Core Human
* **Operational Scope**: Agency recruiter managing split-fee candidate representations across enterprise client requisitions.
* **Frequency of Use**: Daily Continuous (100+ sourcing queries and candidate submissions per day).
* **Core Responsibilities**: Source specialized talent for partner requisitions, submit candidates for bounty placements, and track placement fee distributions.
* **Mapped Requirements**: `REQ-02`, `REQ-07`, `REQ-08`, `REQ-14`, `REQ-18`, `REQ-24`.
* **Primary Workflows**: `WF-04`.
* **Key Guardrail**: Access restricted to client requisitions where agency has an active sourcing contract.

#### P-06: Nisha — Corporate IT Tenancy Administrator (Account Admin)
* **Role Code**: `ACCOUNT_ADMIN` | **Category**: Core Human
* **Operational Scope**: Enterprise tenant governance, branch organization hierarchy, and recruiter seat allocation.
* **Frequency of Use**: Weekly Administrative (5–10 configuration sessions per week).
* **Core Responsibilities**: Provision recruiter team accounts, assign corporate branch permissions, govern license seat quotas, and verify corporate tax identifiers.
* **Mapped Requirements**: `REQ-01`, `REQ-03`, `REQ-05`, `REQ-12`, `REQ-13`, `REQ-15`, `REQ-16`, `REQ-17`, `REQ-18`, `REQ-19`, `REQ-20`.
* **Primary Workflows**: `WF-02`, `WF-05`, `WF-06`, `WF-07`.
* **Key Guardrail**: Seat assignments blocked at database layer when exceeding `max_recruiter_seats`.

#### P-07: Prof. Verma — University Placement Officer (Academic Partner)
* **Role Code**: `ACADEMIC_PARTNER` | **Category**: Core Human
* **Operational Scope**: University career placement management, campus batch cohort management, and early-career drives.
* **Frequency of Use**: Seasonal Cohort (High-volume bursts during annual campus placement cycles).
* **Core Responsibilities**: Ingest verified campus graduate cohort lists, validate institutional graduation credentials, and coordinate campus interview drives.
* **Mapped Requirements**: `REQ-06`, `REQ-07`, `REQ-22`.
* **Primary Workflows**: `WF-02`, `WF-03`.
* **Key Guardrail**: Scope limited to candidate records matching associated educational institution ID.

#### P-08: Ira — Chief Data Privacy Officer (Compliance Auditor)
* **Role Code**: `COMPLIANCE_OFFICER` | **Category**: Core Human
* **Operational Scope**: Enterprise regulatory compliance, DPDP Act 2023 oversight, and statutory data retention audit.
* **Frequency of Use**: Monthly Audit (Periodic governance reviews and on-demand statutory investigations).
* **Core Responsibilities**: Inspect purpose-bound consent registers, audit column sensitivity classifications, and review automated erasure cascade logs.
* **Mapped Requirements**: `REQ-09`, `REQ-10`, `REQ-11`, `REQ-20`.
* **Primary Workflows**: `WF-01`, `WF-04`.
* **Key Guardrail**: Full read access to immutable audit events and DPDP consent registries.

#### P-09: Vikram — Startup Founder & Small Business Employer
* **Role Code**: `SMB_EMPLOYER` | **Category**: Core Human
* **Operational Scope**: Fast, flexible hiring for early-stage companies and specialized freelance project delivery.
* **Frequency of Use**: Monthly On-Demand (Triggered as business milestones arise).
* **Core Responsibilities**: Create immediate gig milestone awards, evaluate local talent proposals, and disburse wallet compensation upon milestone sign-off.
* **Mapped Requirements**: `REQ-04`, `REQ-15`, `REQ-17`.
* **Primary Workflows**: `WF-05`, `WF-07`.
* **Key Guardrail**: Pay-as-you-go wallet validation before gig contract execution.

### Specialized Enterprise Edge Actors

#### P-10 (Edge Actor): Elena — Statutory Data Protection Regulator & External Auditor
* **Role Code**: `STATUTORY_REGULATOR` | **Category**: Edge Human
* **Operational Scope**: Independent external statutory inspection under the DPDP Act 2023, GDPR, and ISO/IEC 27001.
* **Frequency of Use**: Quarterly Formal Audit / On-Demand Regulatory Inquiry.
* **Core Responsibilities**: Verify forensic non-repudiation of audit trails, inspect affirmative consent revocation timing, and validate cryptographic key shredding.
* **Mapped Requirements**: `REQ-09`, `REQ-10`, `REQ-11`, `REQ-20`, `REQ-25`.
* **Primary Workflows**: `WF-01`, `WF-07`.
* **Key Guardrail**: Zero direct mutation permissions (`SELECT` only on audit logs and consent registries); immutable triggers prevent any log tampering.

#### P-11 (Edge Actor): Tariq — Tier-2/3 Technical Platform Support Specialist
* **Role Code**: `SUPPORT_SPECIALIST` | **Category**: Edge Human
* **Operational Scope**: Escalated operational problem resolution, session lockout clearance, and webhook failure mitigation.
* **Frequency of Use**: Daily Operational (20–40 operational tickets resolved per day).
* **Core Responsibilities**: Investigate session conflict clashes, trace failed payment webhook deliveries, and assist recruiters with credential lockouts.
* **Mapped Requirements**: `REQ-12`, `REQ-16`, `REQ-21`.
* **Primary Workflows**: `WF-04`, `WF-07`.
* **Key Guardrail**: Cannot view cleartext candidate passwords or unmasked PII; actions captured in audit log with operator ID.

#### P-12 (Edge Actor): Daemon — Automated Background Maintenance & Retention Cleaner
* **Role Code**: `SYSTEM_DAEMON` | **Category**: Edge System
* **Operational Scope**: Automated, non-interactive platform maintenance, partition rotation, and queue execution.
* **Frequency of Use**: Sub-Second Continuous (Automated background daemon workers).
* **Core Responsibilities**: Rotate monthly audit partitions, purge expired session tokens, execute asynchronous DPDP erasure cascades, and monitor WAL replication lag.
* **Mapped Requirements**: `REQ-03`, `REQ-05`, `REQ-09`, `REQ-11`, `REQ-16`, `REQ-19`, `REQ-21`, `REQ-25`.
* **Primary Workflows**: `WF-01`, `WF-02`, `WF-03`, `WF-04`, `WF-05`, `WF-06`, `WF-07`.
* **Key Guardrail**: Executes under dedicated non-interactive service account (`app_user_id = 1`) with restricted schema permissions.

---

## 4. Full $12 \times 11$ Functional Module CRUD Entitlement Matrix

The following matrix formally defines the access entitlements for all 12 personas across all 11 platform subsystems (`C` = Create, `R` = Read, `U` = Update, `D` = Delete, `-` = Denied):

| Persona ID | Role Code | Identity & Auth | Org Tenancy | Job Req | Candidate Profile | Gig Market | Sourcing Screen | License Seats | Wallet Billing | Privacy Block | System Audit | Analytics Marts |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **P-01** | `RECRUITER` | `R---` | `R---` | `CRUD` | `R---` | `----` | `CRUD` | `R---` | `R---` | `----` | `----` | `R---` |
| **P-02** | `CANDIDATE` | `CRU-` | `R---` | `R---` | `CRUD` | `----` | `CR--` | `----` | `----` | `CRUD` | `----` | `----` |
| **P-03** | `GIG_WORKER` | `CRU-` | `R---` | `----` | `----` | `CRUD` | `----` | `----` | `R---` | `----` | `----` | `R---` |
| **P-04** | `EXECUTIVE` | `R---` | `R---` | `R---` | `----` | `----` | `R---` | `CRUD` | `CRU-` | `----` | `R---` | `CRUD` |
| **P-05** | `STAFFING_CONSULTANT`| `R---` | `R---` | `R---` | `R---` | `----` | `CRUD` | `----` | `R---` | `----` | `----` | `R---` |
| **P-06** | `ACCOUNT_ADMIN` | `CRUD` | `CRUD` | `R---` | `----` | `CRUD` | `R---` | `CRUD` | `CRU-` | `----` | `R---` | `R---` |
| **P-07** | `ACADEMIC_PARTNER` | `R---` | `R---` | `R---` | `CRUD` | `----` | `CR--` | `----` | `----` | `----` | `----` | `R---` |
| **P-08** | `COMPLIANCE_OFFICER` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` |
| **P-09** | `SMB_EMPLOYER` | `CRU-` | `CRUD` | `CRUD` | `R---` | `CRUD` | `CRUD` | `R---` | `CRU-` | `----` | `----` | `R---` |
| **P-10** | `STATUTORY_REGULATOR`| `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` | `R---` |
| **P-11** | `SUPPORT_SPECIALIST` | `R-U-` | `R---` | `R---` | `R---` | `R---` | `R---` | `R-U-` | `R-U-` | `----` | `R---` | `----` |
| **P-12** | `SYSTEM_DAEMON` | `R-U-` | `----` | `----` | `R-U-` | `----` | `----` | `R-U-` | `R-U-` | `----` | `CR--` | `CRU-` |

---

## 5. Security & Invariant Guardrails

1. **System Audit Trail Non-Repudiation**:
   - The `system_audit` column confirms that `P-08` (Compliance) and `P-10` (Regulator) have `R---` read-only access. Only `P-12` (System Daemon) can append (`C---`). **No actor in the entire system possesses Update (`U`) or Delete (`D`) privileges**, guaranteeing forensic non-repudiation.
2. **Double-Entry Wallet Immutability**:
   - The `wallet_billing` column allows authorized corporate entities (`P-04`, `P-06`, `P-09`) to post transactions (`CRU-`), but **Delete (`D`) is prohibited for all actors**. Financial corrections require compensating credit/debit ledger entries.
3. **Multi-Tenant Row-Level Security (RLS)**:
   - Recruiter requisition and application queries are automatically partitioned by session variable `app.current_org_id`, preventing any cross-tenant data leakage.
4. **Candidate Employer Privacy Shield**:
   - Candidate discovery queries automatically evaluate `candidate_block_list` via indexed anti-join views, ensuring that candidate profiles remain completely invisible to blocked employers and their subsidiaries.
5. **Single-Active-Session Concurrency Control**:
   - To protect commercial license seats, initiating a new authenticated session on a second device automatically invalidates existing active session tokens for that user account.

---

## 6. Discovery Boundaries & Next Stage Linkage

In strict accordance with Phase 1 Discover principles, **no database tables, DDL scripts, or SQL role definitions are executed in this document**.

This completes **Step 02: Stakeholders, Personas and Roles**. The established roles, persona profiles, and $12 \times 11$ authorization matrix provide the governance foundation for **Step 03: Feature Discovery (`c/`)**, where platform capabilities are mapped to these personas and prioritized.
