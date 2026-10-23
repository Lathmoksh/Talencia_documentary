# Talentra — Requirement Analysis Docket
**Document Reference**: Deliverable A3 — System Scope, Boundary & Requirements Baseline  
**Step / Activity**: Step 01 — Requirement Analysis Docket  
**Platform**: Talentra Enterprise Workforce Platform  
**Architecture Domain**: Core Data Platform & Integration Boundaries  
**Status**: Approved & Frozen Baseline  

---

## Executive Summary: Step 01 — Requirement Analysis Docket

### 1. Executive Purpose & Context
Talentra is an enterprise-scale talent acquisition and workforce mobilization platform engineered for Northbridge Workforce Systems. It consolidates three traditionally fragmented employment sectors into a single, unified digital platform:
1. **Corporate Permanent Sourcing & Full-Time Recruitment**: Requisition pipelines, structured candidate assessments, and high-volume applicant tracking.
2. **Contingent Labor & Gig Marketplace**: Freelance trade categories, milestone-based bidding, calendar scheduling, and escrow settlement.
3. **Campus & Early-Career Programs**: University cohort onboarding, verified degree accreditation, and structured placement drives.

This docket represents **Step 01: Requirement Analysis Docket** under Phase 1 Discover (Gate G1). Its primary objective is to define the exact problem domain, establish firm system boundaries, formulate pure business requirements without premature database modeling, resolve all subjective ambiguities with numeric thresholds, and catalog foundational Architectural Decision Records (ADRs).

### 2. Key Accomplishments of Step 01
* **29 Pure Functional & Regulatory Requirements (`REQ-01` to `REQ-29`)**: Formulated across 6 core operational domains with 100% two-way traceability to authorized actors and MoSCoW priorities.
* **System Boundary Demarcations**: Five explicit boundary contracts delineating platform-owned capabilities from delegated third-party integrations (e.g. PCI-DSS Level 1 gateway tokenization, external Okta SSO, background check providers).
* **Ranked Architectural Questions (Q1 to Q5)**: Prioritized by architectural risk with verified solutions: recursive Common Table Expression (CTE) cycle checks, GiST temporal range exclusion, candidate anti-join privacy masking, double-entry wallet locking, and cryptographic key shredding for statutory DPDP erasure.
* **10 Architectural Decision Records (ADR-01 to ADR-10)**: Formalizing core invariants including engine-level multi-tenancy via PostgreSQL Row-Level Security (`RLS`), immutable append-only audit/ledger logs, HMAC-SHA256 blind indexing for encrypted PII, and interactive search latency budgets (`p95 <= 15.0 ms`).
* **7 Operational Policy Baselines**: Documenting confirmed institutional windows for agency exclusivity (180 days), application cooldown (90 days), assessment completion (72 hrs), offer expiry (7 days), and subscription grace periods (5 days).

---

## 1. Business Problem & Enterprise Scope

### 1.1 Legacy Fragmentation
Enterprise talent management at Northbridge currently suffers from severe operational and systemic fragmentation:
* **Siloed Systems**: Full-time recruitment, contingent labor, and campus drives operate on disconnected platforms, forcing duplicate profiles, disparate billing contracts, and zero visibility into total organizational talent capacity.
* **Commercial License Leakage**: Pervasive credential sharing among recruiters due to lack of device concurrency controls causes massive commercial seat revenue losses.
* **Candidate Privacy Exposure**: Current candidates are frequently discovered by their own employers on public job boards due to crude visibility toggles that fail to account for corporate subsidiaries and third-party staffing agencies.
* **Concurrency Conflicts in Contingent Labor**: Overlapping gig bookings cause contractor double-booking, milestone delivery disputes, and billing reconciliation nightmares.

### 1.2 Enterprise Sizing & Workforce Classification
Talentra is engineered to support **8 discrete workforce categories** within a unified multi-tenant architecture:
1. `GIG_PROJECT`: Independent contractors and short-term project specialists.
2. `GENERAL_STAFFING`: Volume contingent and blue-collar labor.
3. `PROFESSIONAL_STAFFING`: White-collar technical and functional contract staffing.
4. `PERMANENT_FT`: Direct corporate full-time salaried hires.
5. `APPRENTICE`: Vocational trainees and structured apprenticeship programs.
6. `CAMPUS_FRESHER`: University campus placement candidates and new graduates.
7. `CONSULTANT_MARKETPLACE`: Highly specialized executive and strategic consultants.
8. `MANAGED_REMOTE`: Distributed remote teams managed under enterprise SLA contracts.

---

## 2. In-Scope vs. Explicit Out-of-Scope System Boundaries

To eliminate architectural ambiguity, the boundary between platform-owned capabilities and external system integrations is formally demarcated:

| Operational Subsystem | In-Scope (Platform Owned Responsibilities) | Out-of-Scope (External Delegated Boundary) |
| :--- | :--- | :--- |
| **Identity & Access** | User credentials, session lifecycles, multi-tenant role-based permissions, and device concurrency locking. | Live biometric verification, hardware token issuance, external OAuth2 identity provider operation. |
| **Candidate Sourcing** | Profile representation, parsed resume skill vector indexes, employer block-list filters, and application state machines. | External job board scraping; raw optical character recognition (OCR) binary file decoding. |
| **Gig Marketplace** | Worker trade categories, hourly rates, proposal management, milestone tracking, and contract schedule verification. | Physical on-site job supervision, vehicle or tool inspection, off-platform labor tribunal disputes. |
| **Billing & Finance** | Double-entry append-only credit ledger, subscription seat quotas, running balance synchronization, and download metering. | Direct credit card PAN/CVV collection and interchange routing (strictly delegated to PCI-DSS Level 1 payment gateways). |
| **Compliance & Audit** | DPDP Act 2023 purpose-bound consent logging, automated erasure cascades, data classification catalogs, and immutable event recording. | Direct governmental tax filing submissions; statutory courtroom litigation records. |

---

## 3. Assumptions & Ranked Architectural Questions

### 3.1 Foundational Architecture Assumptions
1. **Organizational Tenancy**: Every enterprise tenant operates under a legally registered entity with unique corporate identifiers.
2. **Global Temporal Normalization**: All business events, contracts, and audit entries are recorded in Coordinated Universal Time (`TIMESTAMP WITH TIME ZONE` in UTC).
3. **Financial & Forensic Immutability**: All financial balance movements and compliance audit entries are strictly append-only; in-place mutations and deletions are prohibited.

### 3.2 Ranked Architectural Open Questions (by System Impact)

| Rank | Architectural Question | Impact Level | Architectural Resolution & Mechanism |
| :---: | :--- | :---: | :--- |
| **Q1** | How to prevent circular ownership loops in conglomerate enterprise parent-subsidiary hierarchies? | **Critical** | Recursive Common Table Expression (CTE) cycle-detection check on corporate relationship trees guarded by transactional advisory locks. |
| **Q2** | How to guarantee gig workers cannot be double-booked across overlapping contracts during high concurrency? | **Critical** | PostgreSQL `GiST` temporal exclusion constraint (`EXCLUDE USING gist (worker_id WITH =, contract_validity_period WITH &&)`) rejecting overlapping booking windows at the database kernel level. |
| **Q3** | How to protect candidate privacy from current employers without degrading search query speed? | **High** | Materialized anti-join views combining candidate block lists with indexed recruiter organization IDs, executing within interactive latency targets. |
| **Q4** | How to maintain accurate corporate wallet balances during concurrent resume unlocks without race conditions? | **High** | Database row-level locking (`SELECT ... FOR UPDATE`) coupled with an append-only trigger that automatically calculates running balances from immutable ledger entries ($0.00 variance). |
| **Q5** | How to ensure statutory compliance with DPDP Act 2023 right to erasure while preserving forensic audit trails? | **Medium** | Cryptographic key shredding for tenant DEKs combined with candidate profile anonymization, leaving anonymized audit event IDs intact without personally identifiable data. |

---

## 4. Master Requirements Baseline (`REQ-01` to `REQ-29`)

Every requirement below isolates pure business capabilities and replaces subjective qualifiers with measurable metrics:

| REQ ID | Requirement Statement | Architectural Source | Priority | Target Actors | Ambiguity Resolution & Numeric Threshold |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **REQ-01** | Canonical Email Normalization | Core Invariant | Must-Have | P-01, P-02, P-03, P-06 | Emails must be stored in lowercase canonical form (`CHECK (email = lower(email))`); max length 254 characters; whitespace rejected. |
| **REQ-02** | E.164 International Phone Standard | Core Invariant | Must-Have | P-01, P-02, P-03, P-05 | Contact phone numbers must strictly validate against E.164 regex (`^\+[1-9]\d{1,14}$`). Local un-prefixed numbers rejected. |
| **REQ-03** | Permanent Surrogate Identity | Core Invariant | Must-Have | P-06, P-12 | Primary keys must use surrogate UUIDv4 (`gen_random_uuid()`) to eliminate guessability and isolate relational integrity from business mutations. |
| **REQ-04** | Fixed-Precision Currency Financials | Core Invariant | Must-Have | P-01, P-03, P-04, P-09 | Currency amounts must use fixed-precision `NUMERIC(12,2)` paired with ISO 4217 3-letter currency code foreign keys. Floating-point strictly banned. |
| **REQ-05** | Standardized Lookup Catalog | Core Invariant | Must-Have | P-06, P-12 | Lookup tables mandate `id`, `code` (`^[a-z][a-z0-9_]*$`), `name`, `is_active`, and integer `sort_order` for administrative deprecation. |
| **REQ-06** | Multilingual Translation Fallback | Core Invariant | Must-Have | P-01, P-02, P-03, P-07 | Localized strings resolve in single indexed queries with automatic fallback to English (`en`) if localized key is missing. |
| **REQ-07** | Screening Questionnaire Trees | Domain Sourcing | Must-Have | P-01, P-02, P-05, P-07 | Requisitions support versioned questionnaires supporting Text, Single Choice, Multiple Choice, and Boolean with weighted scoring rules. |
| **REQ-08** | Dynamic Application Pre-Qualification | Domain Sourcing | Should-Have | P-01, P-05 | Custom application workflow forms link to questionnaire definitions through strict referential integrity. |
| **REQ-09** | Forensic Audit Trail Immutability | Core Security | Must-Have | P-08, P-10, P-12 | Audit log tables enforce append-only storage; database triggers abort all `UPDATE` and `DELETE` queries unconditionally. |
| **REQ-10** | DPDP 2023 Purpose-Bound Consent | Statutory Mandate | Must-Have | P-02, P-08, P-10 | Records affirmative consent grants, purpose codes, IP addresses, user agents, and explicit revocation timestamps. |
| **REQ-11** | Column-Level Data Sensitivity | Statutory Mandate | Must-Have | P-08, P-10, P-12 | All data attributes cataloged into 4 tiers (`PUBLIC`, `INTERNAL`, `CONFIDENTIAL`, `RESTRICTED`) with automated retention schedules. |
| **REQ-12** | Argon2id Credential Encryption | Core Security | Must-Have | P-01, P-02, P-03, P-06, P-11 | Passwords hashed using Argon2id with minimum 16-byte cryptographically secure salt. Plaintext prohibited. |
| **REQ-13** | Multi-Tenant Row-Level Security | Core Security | Must-Have | P-01, P-04, P-06 | Tenant tables enforce PostgreSQL RLS filtered by session variable `app.current_org_id`. |
| **REQ-14** | Candidate Privacy Shield | Core Security | Must-Have | P-01, P-02, P-05 | Candidate block list anti-joins prevent current employers and competitors from discovering active candidate profiles. |
| **REQ-15** | GiST Non-Overlapping Gig Scheduling | Domain Gig | Must-Have | P-03, P-06, P-09 | Enforces `EXCLUDE USING gist` on worker contract intervals, guaranteeing zero concurrent double-booking. |
| **REQ-16** | Single-Active-Session Concurrency | Core Security | Must-Have | P-06, P-11, P-12 | Stored procedure terminates prior device sessions upon new login, preventing commercial seat sharing. |
| **REQ-17** | Double-Entry Wallet Ledger | Domain Billing | Must-Have | P-03, P-04, P-06, P-09 | All financial movements record paired debit/credit ledger entries; running balances recalculated via trigger ($0.00 variance). |
| **REQ-18** | Resume Unlock Quota & Metering | Domain Sourcing | Must-Have | P-01, P-05, P-06 | Accessing candidate contact PII decrements monthly subscription download credits or debits wallet atomically with immutable receipts. |
| **REQ-19** | Tiered Subscription Seat Quotas | Domain Licensing | Must-Have | P-04, P-06, P-12 | Enforces hard cap on active recruiter seat assignments matching purchased tier allowance (`seat_count <= max_seats`). |
| **REQ-20** | National Identifier Blind Indexing | Core Security | Must-Have | P-03, P-06, P-08, P-10 | National tax IDs encrypted via AES-256-GCM; exact lookups executed via HMAC-SHA256 blind indexes without plaintext exposure. |
| **REQ-21** | Webhook Ingestion Idempotency | Integration | Must-Have | P-11, P-12 | Payment and background check webhooks enforce unique idempotency keys, dropping duplicate event deliveries. |
| **REQ-22** | Campus Cohort Management | Domain Sourcing | Should-Have | P-01, P-07 | Supports structured grouping of fresher talent by academic institution, degree specialization, and graduation year. |
| **REQ-23** | Candidate Referral Tracking | Engagement | Should-Have | P-01, P-02 | Assigns unique alphanumeric referral codes to track application origin and trigger automated bonus attributions. |
| **REQ-24** | Interactive Search Latency Budget | Performance SLA | Must-Have | P-01, P-05 | Candidate talent search across 1M profiles achieves warm-cache `p95 <= 15.0 ms` with GIN trigram indexes within a 50ms user budget. |
| **REQ-25** | Disaster Recovery RTO / RPO | Infrastructure | Must-Have | P-10, P-12 | Enforces Recovery Point Objective (RPO) < 1.0 minute and Recovery Time Objective (RTO) < 15.0 minutes via WAL streaming. |
| **REQ-26** | Faceted Candidate Job Search | Discovery | Must-Have | P-02 | Candidates discover and filter published jobs by salary band, location hierarchy, remote policy, and required skills. |
| **REQ-27** | Automated Candidate Job Alerts | Discovery | Must-Have | P-02 | Candidates subscribe to automated job alert criteria delivered via notification channels when matching positions are published. |
| **REQ-28** | Real-Time Recruiter Messaging | Engagement | Must-Have | P-01, P-02 | Secure in-app messaging channel for recruitment inquiries and interview coordination with configurable thread retention. |
| **REQ-29** | Transparent Application Journey | Engagement | Must-Have | P-02 | Candidates track their application journey in real time across all review milestones without exposing confidential internal scoring. |

---

## 5. Architectural Decision Records (ADRs)

* **ADR-01: Surrogate Identity Strategy vs. Natural Keys**: Adopt surrogate UUIDv4 keys across all core entities. Natural keys (email, tax ID) enforced via unique constraints but never used as foreign keys.
* **ADR-02: Cryptographic Envelope & Blind Indexing for Sensitive PII**: Column-level encryption via AES-256-GCM with per-tenant DEKs; HMAC-SHA256 blind indexing for deterministic exact-match search lookups.
* **ADR-03: Multi-Tenant Isolation via Row-Level Security (RLS)**: Enforces tenant isolation at the database kernel level using PostgreSQL RLS tied to `app.current_org_id`, preventing application-level data leaks.
* **ADR-04: Concurrency & Temporal Exclusion in Gig Contracting**: Enforces temporal non-overlapping exclusion constraints (`EXCLUDE USING gist`) on worker contract date intervals at the storage engine level.
* **ADR-05: Double-Entry Immutable Accounting for Corporate Wallets**: Financial movements managed via append-only debit/credit ledgers with trigger-calculated running balances ($0.00 variance).
* **ADR-06: PCI-DSS Level 1 Boundary Tokenization**: Zero persistence of Primary Account Numbers (PAN) or CVVs; credit card processing delegated to PCI-DSS Level 1 gateways.
* **ADR-07: Statutory Erasure via Cryptographic Key Shredding**: Two-tier erasure model: PII wiped and candidate keys shredded immediately, while anonymized transaction IDs remain for audit compliance.
* **ADR-08: Query Latency Specification & Measurement Boundary**: Clarifies preliminary "sub-millisecond" text as internal in-memory index traversal; establishes formal interactive SQL execution target of `p95 <= 15.0 ms` across 1M records.
* **ADR-09: Reconciliation of Statutory DPDP Erasure vs. 7-Year Financial Retention**: Candidate PII purged immediately upon consent revocation (search indexes within 2.0s); financial ledgers retained pseudonymously for statutory 7-year retention period under DPDP Section 8(7).
* **ADR-10: Candidate Consent Revocation Impact on Unlocked Recruiter Contacts**: Candidate privacy rights are sovereign; upon revocation, contact PII is masked immediately, and if revocation occurs within 30 days of unlock, one unlock credit is automatically refunded to the recruiter (`EXC-31`).

---

## 6. Operational Policy Assumptions & Confirmation Register

| Policy Area | Assumed Baseline Value | Architectural Owner | Confirm With / Authority | Business Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Agency Exclusivity** | 180 Calendar Days | Head of Talent Partnerships | Legal & Agency Brokerage Committee | Standard industry placement protection preventing enterprise clients from bypassing agency split bounties. |
| **Application Cooldown** | 90 Calendar Days | VP of Recruitment Operations | Enterprise Talent Acquisition Leads | Prevents automated resume spam while allowing candidates to re-apply after skill upgrades or new hiring cycles. |
| **Assessment Window** | 72 Hours | Director of Assessment Products | Technical Hiring Advisory Group | Balances candidate scheduling accommodation with enterprise hiring pipeline velocity. |
| **Offer Expiry Window** | 7 Calendar Days | Enterprise HR Operations Lead | Corporate Compensation & Legal Teams | Prevents requisition opening stagnation and allows hiring managers to extend offers to secondary candidates. |
| **Email Verification** | 24 Hours | Lead Security Architect | Identity & Security Operations | Limits the attack surface and exposure window for dormant verification tokens. |
| **Subscription Grace** | 5 Calendar Days | Head of Billing Operations | Enterprise Finance & Accounts Receivable | Accommodates transient corporate credit card processing failures before recruiter write access suspension. |
| **Milestone Review** | 7 Calendar Days | Marketplace Operations Director | Contingent Labor Guild | Prevents client review inertia; triggers automated escrow release to freelancer upon expiration. |

---

## 7. Discovery Phase Boundaries & Next Stage Linkage

In strict accordance with Phase 1 Discover principles ("Understand Before You Model"), **no physical database tables, relational schemas, or DDL scripts are defined in this document**.

This completes **Step 01: Requirement Analysis Docket**. The established requirements, system boundaries, and architectural decisions form the direct input to **Step 02: Stakeholders, Personas and Roles (`b/`)**, where these requirements are mapped to specific human and edge actor archetypes.
