# Talentra — Requirement Analysis Docket
**Project**: Talentra Job Search & Demand Management Platform  
**Organization**: Northbridge Workforce Systems  
**Document**: Deliverable A3 — Project Requirement Baseline  
**Document Version**: 1.0 (Approved Baseline)  
**Target Database**: PostgreSQL 15+  

---

## 1. Executive Summary & Problem Context

Northbridge Workforce Systems currently maintains multiple disconnected legacy applications for candidate resumes, job requisitions, and recruitment histories. This legacy sprawl creates three major operational problems:
1. **Low Candidate Retention**: Candidates have no single dashboard to track their applications, verify interview stages, or manage their portfolio and gig availability.
2. **Pipeline Invisibility**: Corporate employers and recruitment consultants lack end-to-end visibility into hiring funnels, interview stages, and recruiter performance.
3. **Multi-Category Friction**: Modern staffing encompasses permanent hiring, contract staffing, campus drives, and short-term gig work. Forcing all of these into rigid full-time job models results in data corruption and poor reporting.

Talentra is designed as a unified PostgreSQL operational and analytical database supporting transactional hiring workflows and analytics at an enterprise scale of **10 million candidate profiles, 1 million job openings, and 100 million applications**.

---

## 2. Sizing Targets & Sizing Methodology

The platform database is designed to operate under two calibrated benchmark targets:

```
[ Laptop Benchmark Scale ]                   [ Full Production Horizon ]
1,000,000 Candidate Profiles        ───>     10,000,000 Candidate Profiles
  100,000 Job Requirements                    1,000,000 Job Requirements
5,000,000 Job Applications                  100,000,000 Job Applications
```

### Extrapolation & Performance Bottleneck Analysis
* **Working Set & Buffer Cache**: On a standard development machine (16 GB RAM, 8 CPU cores), the 5-million-row application dataset fits comfortably within PostgreSQL's `shared_buffers` and OS page cache.
* **Extrapolation to 100 Million Rows**: At full scale, the composite index on `(job_requirement_id, candidate_id, status)` will exceed available RAM. To prevent severe I/O degradation and disk swapping, the design mandates **range partitioning by month** on `job_application` and `system_audit_event`, ensuring active working sets remain in memory.

---

## 3. Supported Workforce Categories

Talentra natively models eight distinct workforce categories:
1. **Gig & Project-Based Work**: Primary revenue driver. Short-duration, milestone-priced or hourly rate-based. Features dedicated availability calendars, external fulfilment handoff, and bidirectional ratings.
2. **General Staffing**: High-volume blue and grey-collar contract roles.
3. **Professional Staffing**: White-collar IT and non-IT contract roles.
4. **Permanent Full-Time Roles**: Direct-hire corporate talent lifecycle.
5. **Apprentice Hiring**: Structured corporate and government apprentice training programs.
6. **Campus & Fresher Hiring**: Bulk hiring drives, college cohorts, and Placement Officer (TPO) interfaces.
7. **Consultant Marketplace**: Freelance recruitment agencies sourcing for approved employer requisitions.
8. **Managed Remote Workforce**: Geographically distributed managed technical teams.

---

## 4. External Integration Boundaries

Talentra references data from 9 external systems without owning their internal mechanics. Clear contracts govern each boundary:

| External Service | Data Ownership | Stored Locally vs Referenced | Outage Strategy | Duplicate Prevention (Idempotency) |
| :--- | :--- | :--- | :--- | :--- |
| **Payment Gateway** (Stripe/Razorpay) | External is source of truth | Stores transaction ID, status, order amount. **Never stores credit card PAN, CVV, or bank auth**. | Asynchronous retry; order marked `PENDING`; webhook reconciles. | Unique `idempotency_key` per checkout attempt. |
| **Identity Verification** (National ID/KYC) | External KYC vendor | Stores verification status (`VERIFIED`, `REJECTED`) and verification token. **No raw national identity numbers**. | Async queue; candidate flagged `ID_PENDING` with restricted actions. | Vendor transaction token stored in unique constraint. |
| **Company Reg & Tax** (MCA/GSTN) | External registry | Stores corporate registration number, tax entity type, verification timestamp. | Fallback to cached corporate profile if registry times out. | Company tax ID + country code unique constraint. |
| **Gig Fulfilment** | External fulfilment engine | Stores assignment handoff reference, delivery milestone status, and reconciled earnings. | Periodic reconciliation worker polls external status. | Handoff GUID stored in `gig_contract_handoff`. |
| **Legacy Systems** | Bidirectional sync (Talentra primary post-launch) | Initial migration source and delta sync. Conflict rule: Talentra timestamp wins over legacy. | Errors sent to dead-letter table; original record untouched. | Legacy source record ID stored as natural key. |
| **Messaging & Notifications** (Twilio/SendGrid) | External delivery gateway | Stores dispatch status (`SENT`, `BOUNCED`), template key, and timestamp. **No long-term message bodies**. | Exponential backoff retry; dead-letter after 3 attempts. | Batch dispatch ID + recipient ID unique key. |
| **Social Sharing** (LinkedIn, X) | External platforms | Outbound share events and timestamps only. | Fire-and-forget outbound link generation. | Event UUID logged. |
| **Mapping & Geocoding** (Google Maps/OSM) | External geo vendor | Normalized coordinates (latitude, longitude) and postal code. | Fallback to country/city centroid if geocoder is unreachable. | Geocache table keyed by normalized postal code. |
| **Market Salary & Reviews** | External benchmarks | Percentile aggregates (`p10`, `p50`, `p90`), source attribution, and refresh date. | Reads cached monthly snapshot if feed fails. | Role code + region code + year-month unique key. |

---

## 5. Functional Requirements Baseline

### REQ-01: Candidate Identity & Contact Normalization
* **Module**: `profile`, `administration` | **Priority**: Must Have
* **Description**: Normalized user accounts with canonical lowercase emails (RFC 5322) and international phone numbers in E.164 format.
* **Database Constraint**: `CHECK (email ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$')`, `UNIQUE (email)`.

### REQ-02: Comprehensive Candidate Profiles
* **Module**: `profile`, `master_data` | **Priority**: Must Have
* **Description**: Normalized records for education chronologies, work history, skill taxonomy with verified proficiencies, languages, projects, and multiple versioned resume attachments.
* **Database Constraint**: Child tables use `ON DELETE CASCADE` linked to candidate profile ID; soft-deletes at candidate root.

### REQ-03: Job Requisition Lifecycle Management
* **Module**: `recruitment` | **Priority**: Must Have
* **Description**: Requisition workflow tracking (`DRAFT`, `PUBLISHED`, `ON_HOLD`, `FILLED`, `CANCELLED`). Publication state enforces that start date precedes closing date and salary ranges are positive.
* **Database Constraint**: `CHECK (min_salary IS NULL OR max_salary IS NULL OR min_salary <= max_salary)`, `CHECK (closed_at IS NULL OR closed_at >= published_at)`.

### REQ-04: Structured Application Pipeline
* **Module**: `recruitment` | **Priority**: Must Have
* **Description**: State machine tracking applicant progression (`APPLIED` $\rightarrow$ `SHORTLISTED` $\rightarrow$ `ASSESSMENT` $\rightarrow$ `INTERVIEW` $\rightarrow$ `OFFERED` $\rightarrow$ `JOINED` / `REJECTED`). Every transition is recorded in an immutable history table.
* **Database Constraint**: Unique active application constraint: `UNIQUE (job_requirement_id, candidate_id) WHERE status NOT IN ('REJECTED', 'WITHDRAWN')`.

### REQ-05: Pre-Qualification Questionnaires
* **Module**: `recruitment` | **Priority**: Must Have
* **Description**: Employers can attach versioned screening questionnaires to job postings with typed questions (`SINGLE_SELECT`, `MULTI_SELECT`, `BOOLEAN`, `NUMERIC`, `TEXT`), knockout thresholds, and automatic scoring.
* **Database Constraint**: Candidate questionnaire responses link by foreign key to immutable questionnaire version IDs.

### REQ-06: Multi-Tenant Organisation & Recruiter Isolation
* **Module**: `organisation` | **Priority**: Must Have
* **Description**: Enterprise hierarchy supporting corporate parents, subsidiaries, and branches. Recruiters are mapped to a specific organisation and cannot view or act on other companies' jobs.
* **Database Constraint**: Enforced via PostgreSQL Row-Level Security (RLS): `organisation_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID`.

### REQ-07: Identity Governance, RBAC & Candidate Privacy Blocks
* **Module**: `administration` | **Priority**: Must Have
* **Description**: Role-based access control across all 9 platform actors. Candidate blocking table allows candidates to block specific employers, recruiters, or headhunters, completely hiding their profile from search pools.
* **Database Constraint**: Candidate search view uses an anti-join against `candidate_block_list`.

### REQ-08: Dedicated Gig Marketplace Subsystem
* **Module**: `gig` | **Priority**: Must Have
* **Description**: Project-based gig requests with fixed or hourly pricing, worker availability calendars, gig proposals, contracts, handoff tokens, and mutual ratings.
* **Database Constraint**: PostgreSQL GiST exclusion constraint prevents overlapping active contract dates for the same gig worker:
  `EXCLUDE USING gist (gig_worker_id WITH =, daterange(start_date, end_date, '[]') WITH &&) WHERE (contract_status = 'ACTIVE')`.

### REQ-09: Consultant Marketplace & Sourcing Lineage
* **Module**: `sourcing`, `recruitment` | **Priority**: Must Have
* **Description**: Independent recruiters can only view jobs flagged `open_to_consultants = TRUE`. Submitting candidates requires explicit employer acceptance of a sourcing request.
* **Database Constraint**: Foreign key trigger verifies `sourcing_request.status = 'ACCEPTED'` prior to candidate submission.

### REQ-10: Licences, Seats & Device Quota Management
* **Module**: `licence`, `administration` | **Priority**: Must Have
* **Description**: Subscriptions define maximum seats and maximum devices per user. Concurrent active sessions exceeding device limits are rejected at login.
* **Database Constraint**: Atomic row-level lock on active sessions (`FOR UPDATE`) inside login stored procedure.

### REQ-11: Subscriptions, Wallets & Financial Ledgers
* **Module**: `billing` | **Priority**: Must Have
* **Description**: Prepaid wallet credits for resume downloads and outreach. Wallet deductions, payments, invoices, and refunds are stored in an append-only ledger. Adjustments reference original transactions.
* **Database Constraint**: Database trigger blocks `UPDATE` and `DELETE` on `billing.wallet_ledger`.

### REQ-12: Omnichannel Engagement, Community & Support
* **Module**: `engagement` | **Priority**: Should Have
* **Description**: User notification preferences, quiet hours delivery rules, community discussion topics, reactions, support tickets, and referral rewards tracking.
* **Database Constraint**: Check constraints on notification channels (`EMAIL`, `SMS`, `PUSH`, `WHATSAPP`).

### REQ-13: Analytical Layer & Reporting Marts
* **Module**: `analytics` | **Priority**: Must Have
* **Description**: Star schema with SCD Type 2 dimensions, partitioned transactional facts (`fact_applications`, `fact_wallet_transactions`), and aggregated KPI marts (time-to-hire, funnel conversion).
* **Database Constraint**: Partitioning by date range (`PARTITION BY RANGE (created_at)`).

### REQ-14: Security, PII Protection & Data Lifecycle
* **Module**: `administration`, `profile` | **Priority**: Must Have
* **Description**: Classification of every column (Public, Internal, Personal, Sensitive). Sensitive credentials hashed with Argon2id. Audit log tables are append-only.
* **Database Constraint**: Revocation of `UPDATE` and `DELETE` privileges on audit tables for application database roles.

---

## 6. Architecture Decision Records (ADRs)

### ADR-01: Gig Marketplace Subsystem vs. Unified Requisitions
* **Decision**: Gig work is modeled in a separate `gig` schema rather than reusing `recruitment.job_requirement`.
* **Rationale**: Full-time recruitment follows multi-stage interview workflows and corporate requisitions. Gig work relies on immediate availability calendars, proposal bids, milestone deliveries, and external fulfilment engines. Merging them creates sparse, NULL-polluted tables and breaks constraint enforcement.
* **Trade-off**: Requires separate analytical facts, but preserves clean relational integrity and prevents schema coupling.

### ADR-02: Database-Tier Session and Device Concurrency
* **Decision**: Active device counts are enforced inside an atomic PostgreSQL stored procedure rather than application-layer cache.
* **Rationale**: Prevents race conditions during simultaneous logins from multiple devices, stopping commercial license sharing.

---

## 7. Quality Verification: 5-Branch Test Taxonomy

Test verification is structured across five core architectural branches to provide complete safety coverage:

```
Test Verification Graph
 ├── 1. Structure & Project Best Practices (Naming, keys, physical schema)
 ├── 2. Data Integrity & Data Quality (Formats, required fields, cascade rules)
 ├── 3. Business Rules & Behaviour (Pipelines, workflows, non-overlapping windows)
 ├── 4. Security, Privacy & Access (RLS isolation, candidate blocks, append-only triggers)
 └── 5. Non-Functional Requirements (Scale, buffer hit ratios, recovery RTO/RPO)
```

| Branch | Test ID | Description | Target Object | Verification Method | Expected Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Structure & Best Practices** | `TST-STR-01` | Validate singular table naming, surrogate PK `id`, and foreign key `<table_name>_id` conventions. | PostgreSQL `information_schema` | Schema catalog query inspection | 100% compliance; zero reserved keyword identifier collisions. |
| **2. Data Integrity & Quality** | `TST-INT-01` | Attempt inserting invalid email address or salary where `min_salary > max_salary`. | `users.account`, `recruitment.job_requirement` | SQL insert with invalid data | Database aborts with `CHECK constraint violation`. |
| **3. Business Rules & Behavior** | `TST-BIZ-01` | Candidate submits two concurrent active applications to the same job opening. | `recruitment.job_application` | Duplicate insert attempt | Aborts with `unique_violation` on active partial index. |
| **4. Security, Privacy & Access** | `TST-SEC-01` | Recruiter from Company A attempts `SELECT` on Company B's requisitions. | `recruitment.job_requirement` | Query with `app.current_org_id = Company_A` | Returns 0 rows. Row-Level Security silently filters tenant data. |
| **4. Security, Privacy & Access** | `TST-SEC-02` | Admin attempts `UPDATE` or `DELETE` on system audit log. | `audit.system_audit_event` | Direct DML statement | Aborts with trigger error: `Table is append-only`. |
| **5. Non-Functional & Scale** | `TST-NFR-01` | Benchmark lookup latency on 1M candidate profiles and verify RPO recovery from WAL archives. | `profile.candidate_profile` | Execution plan (`EXPLAIN ANALYZE`) & WAL replay log | Index scan lookup p95 < 5ms; point-in-time recovery completed in < 12 minutes. |
