# Deliverable Step 11: Data Rules and Constraints Discovery Catalogue

**Platform:** Talentra Enterprise Workforce & Talent Demand Management Platform  
**Document Reference:** Deliverable 11 — Comprehensive Data Integrity, Validation & Business Rules Catalogue  
**Target Engine:** PostgreSQL 16 (Check Constraints, GiST Temporal Indexing, RLS & Trigger Procedures)  
**Scope & Completeness:** 85 Master Data Rules (`DR-001`–`DR-085`), 10 Cross-Table Rules (`CTR-01`–`CTR-10`), 30 Test Mappings  
**Preceding Discovery Baselines:** Steps 06–10 (Entity, Attribute, Lifecycle, ER Model v0, Data Dictionary v1)  
**Compliance Alignment:** India DPDP Act 2023, ISO 3166/4217, Double-Entry Zero-Drift Financial Accounting  

---

## 1. Introduction and Scope

This document establishes the definitive **Data Rules and Constraints Catalogue** for the **Talentra Enterprise Workforce Platform**. Building upon the structural models defined in Steps 06 through 10, this deliverable operationalizes the boundary between valid and invalid data across the entire database architecture. By formalizing storage engine constraints, cross-table business invariants, regulatory privacy mandates, and concurrency protections, this catalogue ensures that corrupt, duplicate, contradictory, or unauthorized data is deterministically rejected before committing to disk.

### Key Architectural Objectives:
1. **Defensive Storage Engine Enforcement:** Ground critical invariants directly in PostgreSQL check constraints, unique indexes, and GiST temporal exclusion rather than trusting frontend application code.
2. **Cross-Table Integrity Hardening:** Formally specify dependencies linking multiple tables (e.g. unverified employers cannot publish jobs; contracts cannot be signed without funded escrow).
3. **Zero Financial Drift ($0.00 Variance):** Enforce strict double-entry balancing rules across corporate wallets and milestone escrows.
4. **Statutory Privacy Defensibility:** Codify DPDP Act 2023 consent validation, candidate anti-join privacy shields, and sub-second cryptographic DEK shredding.

---

## 2. Source Documents and Regulatory Baseline

The validation rules codified herein are derived directly from the project's discovery dockets:
* **Phase 1 Discover Core:** Business Requirements (`REQ-01` to `REQ-29`), NFR Register (`NFR-01` to `NFR-15`), and Canonical Actors (`P-01` to `P-12`).
* **Deliverable Step 07:** Physical data domains, length precisions, nullability justifications, and standard type specifications.
* **Deliverable Step 08:** 20 Finite State Machines (FSMs), prohibited lifecycle transitions, and temporal booking locks.
* **Deliverable Step 09:** Relational table structures, foreign key deletion actions (`RESTRICT` vs `CASCADE`), and junction designs.
* **Deliverable Step 10:** Data Dictionary v1 column definitions, workflow usage tags, and confidentiality classifications.

---

## 3. Constraint Discovery & Layered Enforcement Methodology

Validation rules are classified across five distinct architectural enforcement layers to avoid over-constraining the physical schema while guaranteeing absolute data integrity:

```
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│                         Talentra Tiered Validation & Enforcement Pyramid                      │
└───────────────────────────────────────────────┬───────────────────────────────────────────────┘
                                                │
      ┌─────────────────────────────────────────┴─────────────────────────────────────────┐
      ▼                                                                                   ▼
┌───────────────────────────┐                                               ┌───────────────────────────┐
│ 1. Database Storage Engine│ (PK, FK RESTRICT, NOT NULL, CHECK, GiST)      │ 2. Transaction / Lock Tier│ (Row Locks `FOR UPDATE`,
│    - Invariants defended  │                                               │    - High-concurrency     │  Serializable isolation)
│      regardless of caller │                                               │      balance deductions   │
└───────────────────────────┘                                               └───────────────────────────┘
      │                                                                                   │
      ▼                                                                                   ▼
┌───────────────────────────┐                                               ┌───────────────────────────┐
│ 3. Application Domain Tier│ (Multi-step business workflows, friendly      │ 4. Asynchronous Daemons   │ (Timeout auto-approval,
│    - NestJS / Go pipes &  │  HTTP 400/403/409 error payloads)             │    - Eventual consistency │  statutory DEK shredding,
│      domain validators    │                                               │      & background queues  │  batch quota resets)     │
└───────────────────────────┘                                               └───────────────────────────┘
```

---

## 4. Primary Key Constraints & Identity Architecture

Every table across the 13 domain schemas adheres to strict primary key standards:
1. **Surrogate Key Invariant:** Natural business keys (such as email, national ID, or tax registration number) are strictly forbidden as primary keys. All 81 transactional and operational tables utilize surrogate 128-bit UUID primary keys (`id UUID DEFAULT gen_random_uuid()`). This prevents enumerative crawling attacks (`REQ-03`), decouples relational keys from changeable business attributes, and enables multi-region distributed writes.
2. **Analytical Sequence Keys:** The 9 tables in the `analytics` dimensional star schema utilize 32-bit surrogate integer keys (`date_key`, `candidate_key`, `organisation_key`, `requisition_key`, `stage_key`) to maximize join performance and columnar compression.
3. **Non-Nullability & Permanent Immutability:** Primary keys are strictly non-nullable (`NOT NULL`) and immutable. Database triggers reject any `UPDATE` statement attempting to alter an existing primary key.

---

## 5. Foreign Key Constraints & Referential Defensibility

Foreign keys enforce strict referential actions to prevent dangling pointers and catastrophic data loss:
* **Mandatory Referential Actions (`ON DELETE RESTRICT`):** Applied to sovereign reference taxonomies (`master_data`), corporate accounts, and job postings. A parent record cannot be deleted while dependent records exist (e.g. `recruitment.job_requisition` cannot be dropped while child `application.job_application` records exist).
* **Cascading Dependent Children (`ON DELETE CASCADE`):** Restricted exclusively to tightly-coupled child tables that possess no operational meaning without the parent (e.g. `billing.invoice_item` cascading from `billing.invoice`, `candidate_education` cascading from `candidate_profile`, `thread_message` cascading from `message_thread`).
* **Explicit Indexing:** Every foreign key column is accompanied by an explicit B-tree index (`idx_<table_name>_<column_name>`) to ensure join performance and prevent full table locks during parent validation.

---

## 6. NOT NULL and UNIQUE Constraints Analysis

### 6.1 NOT NULL Enforcement Principles
In compliance with **Rule Group 5 (Nullability and Unknown Values)**, nullability is minimized across all domains. Mandatory attributes include explicit non-null constraints with documented justifications:
* **Monetary Values:** `min_salary_amount`, `max_salary_amount`, `agreed_amount`, `amount`, and `current_balance` are `NOT NULL`. A salary that is not disclosed is represented as `NULL` where allowed, never as `0.00` (which implies unpaid volunteer labor).
* **Booleans:** All boolean flags (`is_active`, `is_email_verified`, `is_primary`) are `NOT NULL DEFAULT TRUE/FALSE`. Tri-state booleans (`NULL`) are forbidden.

### 6.2 Master Uniqueness Matrix

| Target Table | Unique Constraint Columns | Scope | Concrete Architectural Rationale |
| :--- | :--- | :---: | :--- |
| `identity.user_account` | `email` | Global | Normalized lowercase login username must identify a single principal (`REQ-01`). |
| `identity.user_account` | `phone_number` | Global | E.164 telecommunication phone number must identify a unique user (`REQ-02`). |
| `master_data.country` | `iso_alpha2_code` | Global | Standardized ISO 3166-1 alpha-2 sovereign identifier. |
| `master_data.currency` | `currency_code` | Global | Standardized ISO 4217 3-letter currency code. |
| `organisation.organisation` | `country_id, company_registration_number` | Composite | Company registration CIN/LLPIN is unique within each sovereign nation. |
| `organisation.organisation_tax_identifier` | `tax_id_blind_index` | Global | HMAC-SHA256 blind hash enables deterministic exact-match lookup queries (`REQ-20`). |
| `application.job_application` | `requisition_id, candidate_id` (Partial) | Conditional | A candidate cannot hold multiple active applications for the same job posting (`REQ-29`). |
| `gig.client_gig_worker_preference`| `organisation_id, worker_id` | Composite | Prevents duplicate favourite/blacklist relationship entries. |
| `billing.payment_gateway_event`| `gateway_event_id` | Global | Guarantees idempotent exactly-once processing of incoming PSP webhooks (`REQ-21`). |
| `governance.pii_encryption_key` | `user_id` | Global | Strict 1:1 mapping ensuring exactly one cryptographic DEK key per candidate (`REQ-10`). |
| `governance.system_audit_event` | `tamper_hash` | Global | Cryptographic SHA-256 HMAC hash chaining ensures tamper-evident audit trail (`REQ-09`). |

---

## 7. Storage Engine CHECK Constraints

The database storage engine enforces domain checks directly in table definitions:

### 7.1 Cross-Column Logical & Arithmetic Checks
* **Compensation Range:** `recruitment.job_requisition`: `CHECK (min_salary_amount >= 0.00 AND max_salary_amount >= min_salary_amount)`
* **Experience Range:** `recruitment.job_requisition`: `CHECK (min_experience_months >= 0 AND max_experience_months >= min_experience_months)`
* **Contractor Pricing:** `gig.gig_worker_profile`: `CHECK (hourly_rate_amount > 0.00 AND (daily_rate_amount IS NULL OR daily_rate_amount >= hourly_rate_amount))`
* **Invoice Arithmetic:** `billing.invoice`: `CHECK (total_amount = subtotal_amount + tax_amount AND total_amount >= 0.00)`
* **Line Item Arithmetic:** `billing.invoice_item`: `CHECK (total_price = quantity * unit_price AND quantity > 0)`
* **Wallet Non-Negative:** `billing.wallet_account`: `CHECK (current_balance >= 0.00 AND escrow_reserved_balance >= 0.00)`

### 7.2 Calendar & Temporal Bounds Checks
* **Education Tenure:** `candidate.candidate_education`: `CHECK (end_date IS NULL OR end_date >= start_date)`
* **Employment Tenure:** `candidate.candidate_work_experience`: `CHECK (end_date IS NULL OR end_date >= start_date)`
* **Interview Duration:** `application.job_interview`: `CHECK (scheduled_end_time > scheduled_start_time)`
* **Job Offer Validity:** `application.job_offer`: `CHECK (offer_validity_date >= CURRENT_DATE AND joining_date >= CURRENT_DATE)`
* **Requisition Deadline:** `recruitment.job_requisition`: `CHECK (application_deadline IS NULL OR application_deadline >= CURRENT_DATE)`

### 7.3 Quantitative Scoring Scales Checks
* **Interview Feedback:** `application.interview_feedback`: `CHECK (technical_score BETWEEN 1.0 AND 5.0 AND cultural_score BETWEEN 1.0 AND 5.0 AND overall_score BETWEEN 1.0 AND 5.0)`
* **Contractor Ratings:** `gig.gig_rating`: `CHECK (rating_score BETWEEN 1.00 AND 5.00 AND communication_score BETWEEN 1.00 AND 5.00 AND quality_score BETWEEN 1.00 AND 5.00)`
* **Profile Completeness:** `candidate.candidate_profile`: `CHECK (profile_completion_percentage BETWEEN 0.00 AND 100.00)`
* **University GPA:** `engagement.campus_student_member`: `CHECK (cumulative_gpa BETWEEN 0.00 AND 10.00)`

---

## 8. Domain Format & Regular Expression Validations

All string attributes conforming to standard domains are validated using POSIX regular expressions:
* **Email Format (`REQ-01`):** `CHECK (email ~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$')` (Case-normalized lowercase).
* **International E.164 Phone (`REQ-02`):** `CHECK (phone_number ~ '^\+[1-9][0-9]{1,14}$')` (Leading `+` followed by country dialing code and subscriber number).
* **Cryptographic Hash Digest (SHA-256):** `CHECK (tamper_hash ~ '^[a-f0-9]{64}$')` and `CHECK (session_token_hash ~ '^[a-f0-9]{64}$')` (Exact 64 hexadecimal characters).
* **ISO Country Codes:** `CHECK (iso_alpha2_code ~ '^[A-Z]{2}$')` and `CHECK (iso_alpha3_code ~ '^[A-Z]{3}$')` (Uppercase alphabetic).
* **ISO Currency Codes:** `CHECK (currency_code ~ '^[A-Z]{3}$')` (Uppercase alphabetic conforming to ISO 4217).

---

## 9. Platform Business Rules Catalog

The platform enforces business policies that govern cross-module actor behaviors:
1. **Company Recruiter Isolation (`REQ-13`):** A recruiter may only view, post, and act on job requisitions and candidate applications assigned to their own employer organization. Enforced via PostgreSQL Row-Level Security (RLS) filtering on `organisation_id`.
2. **Consultant Sourcing Openness Rule:** Staffing agency consultants may only source and nominate candidates for job requisitions where `open_to_consultants = TRUE`. Submissions on closed requisitions are blocked at the API gateway and database trigger layer.
3. **Candidate Anti-Join Privacy Shield Rule (`REQ-14`):** A candidate may explicitly block specific employers or recruiters. Blocked parties must never discover that candidate's profile, view resumes, or initiate contact.
4. **Anti-Proxy Registration Rule:** Recruiters and staffing consultants are strictly prohibited from creating candidate accounts or submitting applications on a candidate's behalf without affirmative consent (`P-01`, `WF-01`).
5. **Immutable Financial Book of Record (`REQ-17`):** Delete operations (`DELETE`) are globally revoked on `billing.wallet_ledger`. Corrective financial actions require paired compensatory journal entries.

---

## 10. Mandatory Cross-Table Constraints (CTR-01 to CTR-10)

Cross-table constraints govern dependencies linking multiple relational tables that cannot be satisfied by simple single-column check constraints:

| Rule ID | Rule Name | Involved Tables | Exact Business Condition | Valid Scenario | Invalid Scenario | Enforcement Point | Error Rejection Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **CTR-01** | **Published Requisition Employer Verification Precondition** | `recruitment.job_requisition, organisation.organisation` | recruitment.job_requisition.publish_status = 'PUBLISHED' requires organisation.organisation.verification_status = 'VERIFIED' | Employer with verification_status = 'VERIFIED' publishes a job requisition. | Employer with verification_status = 'UNVERIFIED' attempts to publish a job requisition directly to marketplace. | Database Trigger / Application Service | Aborts transaction with HTTP 403 Forbidden (ORG_NOT_VERIFIED); requisition remains in DRAFT. |
| **CTR-02** | **Consultant Sourcing Requisition Openness Precondition** | `sourcing.consultant_authorization, recruitment.job_requisition` | Creating consultant_authorization requires recruitment.job_requisition.open_to_consultants = TRUE | Requisition with open_to_consultants = TRUE authorizes external staffing consultant. | Staffing consultant attempts to request sourcing on an internal-only requisition (open_to_consultants = FALSE). | Database Trigger | Aborts insert with SQL Exception (REQUISITION_NOT_OPEN_TO_CONSULTANTS). |
| **CTR-03** | **Gig Contract Schedule GiST Temporal Non-Overlap Exclusion** | `gig.gig_contract, gig.gig_worker_profile` | No two active contracts for the same worker_id can overlap in calendar time: EXCLUDE USING gist (worker_id WITH =, agreed_window WITH &&) | Contractor booked for Nov 1 to Nov 15; subsequent client books Nov 16 to Nov 30. | Client attempts to execute contract for Nov 10 to Nov 20 for contractor already booked Nov 1 to Nov 15. | Database Storage Engine (GiST Exclusion Index) | PostgreSQL aborts transaction with exclusion_violation (42P10 / 23P01); concurrent checkout rolls back. |
| **CTR-04** | **Gig Contract Signing Client Escrow Balance Precondition** | `gig.gig_contract, gig.gig_milestone, billing.wallet_account` | Transitioning gig_contract to 'SIGNED' requires client wallet spendable balance >= initial milestone escrow allocation | Client wallet has $5,000 spendable balance; Milestone 1 escrow requires $2,500. | Client wallet has $1,000 spendable balance; client attempts to sign contract with Milestone 1 escrow of $2,500. | Transaction (Row Lock + Trigger) | Aborts transition with HTTP 402 Payment Required (INSUFFICIENT_ESCROW_FUNDS); contract remains in DRAFT. |
| **CTR-05** | **Double-Entry Ledger Paired Balancing Zero Net Variance Invariant** | `billing.wallet_ledger, billing.wallet_account` | Every financial mutation must insert paired DEBIT and CREDIT entries with matching transaction_group_id where SUM(DEBIT) - SUM(CREDIT) = 0.00 | $2,500 escrow release inserts DEBIT $2,500 on Client Escrow Wallet and CREDIT $2,500 on Worker Operational Wallet. | A single DEBIT $2,500 is inserted without an equal and opposite CREDIT entry. | Database Trigger / Transaction Isolation | Transaction rolls back with fatal invariant error (LEDGER_IMBALANCE_NONZERO_VARIANCE). |
| **CTR-06** | **Enterprise Recruiter Seat Quota Ceiling Enforcement** | `organisation.recruiter_seat_assignment, licensing.subscription_licence, licensing.subscription_plan` | COUNT(active_seats where seat_status = 'ACTIVE') <= subscription_plan.max_recruiter_seats | Enterprise plan allows 25 seats; tenant administrator assigns 24th recruiter seat. | Tenant administrator attempts to provision 26th recruiter seat on a 25-seat license. | Database Trigger / Application Service | Aborts assignment with HTTP 403 Forbidden (SEAT_QUOTA_EXCEEDED); prompts tenant for license tier upgrade. |
| **CTR-07** | **Candidate Sourcing Contact Unlock Paid Metering Precondition** | `billing.profile_download_history, licensing.licence_entitlement_usage, billing.wallet_account` | Viewing unmasked candidate contact details requires active subscription quota > 0 OR spendable wallet balance >= unlock fee | Recruiter has 45 remaining monthly profile unlock credits; unlocks candidate profile. | Recruiter has 0 remaining unlock credits and $0.00 wallet balance; attempts to unmask candidate contact details. | Transaction (Row Lock + Trigger) | Aborts unmasking with HTTP 402 Payment Required (QUOTA_EXHAUSTED); candidate contact details remain masked. |
| **CTR-08** | **Direct In-App Recruiter-Candidate Message Thread Unlock Precondition** | `engagement.message_thread, billing.profile_download_history, candidate.candidate_block_list` | Creating message_thread requires verified profile_download_history unlock_receipt_id AND candidate has NOT blocked recruiter organisation | Recruiter holds verified unlock receipt; candidate privacy shield has no block rule; thread created. | Recruiter attempts to initiate in-app chat with candidate who added recruiter company to candidate_block_list. | Database Trigger / RLS Policy | Aborts with HTTP 403 Forbidden (CANDIDATE_PRIVACY_SHIELD_ACTIVE); message rejected. |
| **CTR-09** | **Statutory DPDP Right-to-be-Forgotten Cryptographic Shredding SLA** | `governance.dpdp_consent_record, governance.pii_encryption_key, candidate.candidate_profile` | dpdp_consent_record.status = 'REVOKED' triggers zeroing of pii_encryption_key.encrypted_dek within <= 2.0 seconds | Candidate clicks 'Withdraw Consent'; DEK is overwritten with zeroes; ciphertext permanently unrecoverable. | Consent is revoked but Data Encryption Key remains intact on disk. | Database Trigger + Daemon | Asynchronous worker validates zeroed DEK within 2.0s; alerts DPO if key shredding fails. |
| **CTR-10** | **Statutory Invoice Line Items Mathematical Reconciliation** | `billing.invoice, billing.invoice_item` | invoice.subtotal_amount = SUM(invoice_item.total_price) AND invoice.total_amount = invoice.subtotal_amount + invoice.tax_amount | Invoice with line items totaling $4,237.29 + $762.71 tax yields total_amount = $5,000.00. | Invoice total_amount is modified to $4,500.00 while line items sum to $5,000.00. | Database Check + Trigger | Aborts invoice finalization with mathematical reconciliation error (INVOICE_TOTAL_MISMATCH). |

---

## 11. Lifecycle-Dependent Constraints (Step 08 Alignment)

Entity state machines discovered in Step 08 dictate when records can be modified, transitioned, or locked:
1. **Terminal State Immutability Invariant:** Once an entity enters a terminal state (`DEACTIVATED`, `CLOSED`, `JOINED`, `FULFILLED`, `VOIDED`, `REVOKED`), the database rejects all normal business updates. For example, a `job_requisition` with `publish_status = 'CLOSED'` cannot be transitioned back to `PUBLISHED`.
2. **Pre-Requisite State Transitions:** Bypassing intermediate workflow states is prohibited. A `job_application` in `SUBMITTED` cannot transition directly to `OFFER_EXTENDED` without completing `SCREENING` and `INTERVIEWED` stages.
3. **Mandatory Rejection Justifications:** Any transition to a rejected state (e.g. `job_application` to `REJECTED`, `organisation` to `REJECTED`, `consultant_authorization` to `REJECTED`) mandates an accompanying non-empty `rejection_reason` string.
4. **Active Consent Precondition:** Recruiter messaging (`engagement.message_thread`) and resume downloads (`billing.profile_download_history`) require an affirmative `dpdp_consent_record.status = 'ACTIVE'`.

---

## 12. Tiered Enforcement Strategy & Failure Handling

The table below formalizes the architectural layer responsible for each rule type and its expected failure handling:

| Enforcement Layer | Scope & Responsibilities | Concrete Technology & Mechanism | Failure & Exception Handling Pattern |
| :--- | :--- | :--- | :--- |
| **Database Storage Engine (Constraints, GiST, Triggers)** | Invariants that must NEVER be violated under any circumstance, regardless of client or internal service bug. | PostgreSQL CHECK constraints, UNIQUE btree indexes, GiST temporal exclusion, and AFTER INSERT/UPDATE triggers. | Immediate SQL Exception; rollback of current transaction. |
| **Transactional / Concurrency Layer (Row Locks)** | High-concurrency shared state prone to race conditions (wallet balances, seat quotas, checkout carts). | Row-level locks (`SELECT FOR UPDATE`) within ACID transactions (`SERIALIZABLE` or `READ COMMITTED`). | Transaction wait timeout or deadlock abort with client retry. |
| **Application Service Layer (Domain Logic)** | Complex pre-validation checks, multi-step business authorizations, and friendly error message formatting. | NestJS / Go domain services, validator pipes, and request middleware prior to database commit. | HTTP 400 Bad Request, 402 Payment Required, or 403 Forbidden with structured JSON error payload. |
| **Asynchronous Background Daemons** | Eventual consistency reconciliation, timeout enforcement, statutory archival, and external gateway synchronization. | Scheduled cron daemons, Kafka message consumers, and worker queues (e.g. 5-day auto-approval, annual DPDP expiry). | Exponential backoff retry with dead-letter queue (DLQ) and administrative alerting. |
| **External Gateway Integrations** | Boundary validation against third-party providers (payment gateways, identity verification bureaus). | Webhook HMAC signature verification, payload schema validation, and gateway event ID deduplication. | Rejection of malformed webhooks with HTTP 401 Unauthorized or HTTP 400 Bad Request. |

---

## 13. Duplicate Prevention & Idempotency Rules

To ensure data integrity under high concurrent loads, duplicate submissions and duplicate webhook processing are mitigated via three core patterns:
1. **Unique Operation Identifiers:** External PSP webhooks enforce a unique constraint on `billing.payment_gateway_event.gateway_event_id`. Duplicate incoming webhooks are caught at the database layer and handled idempotently via `ON CONFLICT (gateway_event_id) DO NOTHING`.
2. **Duplicate Application Lockout:** Candidates cannot apply twice to the same job opening. Enforced via a partial unique index on `application.job_application(requisition_id, candidate_id) WHERE (application_status NOT IN ('WITHDRAWN', 'REJECTED'))`.
3. **Schedule Double-Booking Prevention:** Gig workers cannot be booked simultaneously for overlapping contracts. Enforced via PostgreSQL `EXCLUDE USING gist (worker_id WITH =, agreed_window WITH &&)`.

---

## 14. Master Data Rules Catalogue (DR-001 to DR-085)

The master catalogue below assigns a permanent, stable rule ID to every documented constraint across the 13 domain modules:

| Rule ID | Rule Name | Rule Type | Affected Table(s) | Exact Constraint / Condition | Enforcement Point | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **DR-001** | **Country ISO Alpha-2 Format & Uniqueness** | Format / Unique | `master_data.country` | iso_alpha2_code ~ '^[A-Z]{2}$' AND is unique globally | Database (CHECK + UNIQUE) | **Critical** |
| **DR-002** | **Country International Dialing Prefix Format** | Format | `master_data.country` | phone_dialing_code ~ '^\+[0-9]{1,4}$' | Database (CHECK) | **High** |
| **DR-003** | **Administrative State Code Uniqueness within Country** | Composite Unique | `master_data.state` | UNIQUE(country_id, state_code) AND state_code ~ '^[A-Z0-9_-]{1,10}$' | Database (UNIQUE) | **High** |
| **DR-004** | **City Geographic Coordinates Bounding Box** | CHECK / Range | `master_data.city` | latitude BETWEEN -90.0 AND 90.0 AND longitude BETWEEN -180.0 AND 180.0 | Database (CHECK) | **High** |
| **DR-005** | **Sovereign Currency ISO 4217 Code & Decimal Precision** | Format / Range | `master_data.currency` | currency_code ~ '^[A-Z]{3}$' AND decimal_precision BETWEEN 0 AND 4 | Database (PK + CHECK) | **Critical** |
| **DR-006** | **Master Skill Code Standard Formatting** | Format / Unique | `master_data.skill` | skill_code ~ '^[A-Z0-9_]{2,50}$' AND is unique globally | Database (UNIQUE) | **Critical** |
| **DR-007** | **User Email Lowercase Normalization & Global Uniqueness** | Unique / Domain | `identity.user_account` | email = lower(email) AND email ~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$' AND is unique globally | Database (CHECK + UNIQUE) | **Critical** |
| **DR-008** | **Contact Phone Number E.164 Format & Global Uniqueness** | Format / Unique | `identity.user_account` | phone_number ~ '^\+[1-9][0-9]{1,14}$' AND is unique globally | Database (CHECK + UNIQUE) | **Critical** |
| **DR-009** | **User Account Lifecycle Allowed Enumerations** | CHECK / Status | `identity.user_account` | account_status IN ('PENDING_VERIFICATION','ACTIVE','SUSPENDED','LOCKED','DEACTIVATED') | Database (CHECK) | **Critical** |
| **DR-010** | **Consecutive Failed Login Attempts Non-Negative Threshold** | CHECK / Range | `identity.user_account` | failed_login_attempts >= 0 | Database (CHECK) | **High** |
| **DR-011** | **Account Lockout Window Integrity** | CHECK / Temporal | `identity.user_account` | locked_until IS NULL OR locked_until > CURRENT_TIMESTAMP | Database (CHECK) | **Critical** |
| **DR-012** | **Argon2id Password Cryptographic Hash Separation** | Security / 1:1 | `identity.user_credential` | password_hash ~ '^\$argon2id\$v=19\$' AND password_salt IS NOT NULL AND user_id is unique | Database (CHECK + UNIQUE) | **Critical** |
| **DR-013** | **User Role Grant Validity & Expiration Integrity** | CHECK / Temporal | `identity.user_role` | expires_at IS NULL OR expires_at > granted_at | Database (CHECK) | **High** |
| **DR-014** | **Concurrent Device Active Session Hard Cap** | Business / Cross-Table | `identity.user_active_session` | COUNT(active_sessions) <= subscription_plan.max_devices_per_user (Default <= 2) | Transaction (Trigger / Lock) | **Critical** |
| **DR-015** | **Corporate Account Status Allowed Enumerations** | CHECK / Status | `organisation.account` | account_status IN ('ACTIVE','DELINQUENT','SUSPENDED','TERMINATED') | Database (CHECK) | **Critical** |
| **DR-016** | **Company Statutory Registration Number Uniqueness within Country** | Composite Unique | `organisation.organisation` | UNIQUE(country_id, company_registration_number) | Database (UNIQUE) | **Critical** |
| **DR-017** | **Organisation Verification Status Integrity** | CHECK / Status | `organisation.organisation` | verification_status IN ('UNVERIFIED','UNDER_REVIEW','VERIFIED','REJECTED') | Database (CHECK) | **Critical** |
| **DR-018** | **Primary Headquarters Location Cardinality Constraint** | Business / Cross-Row | `organisation.organisation_location` | Exact 1 primary location per organisation: COUNT(is_primary = TRUE) = 1 | Database (Partial UNIQUE) | **High** |
| **DR-019** | **Tax Identifier AES-256 Ciphertext & HMAC Blind Index Uniqueness** | Security / Unique | `organisation.organisation_tax_identifier` | tax_id_blind_index ~ '^[a-f0-9]{64}$' AND is unique globally | Database (CHECK + UNIQUE) | **Critical** |
| **DR-020** | **Recruiter Seat Allocation Uniqueness & Quota Compliance** | Cross-Table / Unique | `organisation.recruiter_seat_assignment` | UNIQUE(organisation_id, user_id) AND allocated_seats <= max_recruiter_seats | Transaction (Trigger + UQ) | **Critical** |
| **DR-021** | **Organisation Hierarchy Self-Reference Acyclic Guard** | Integrity / Graph | `organisation.organisation_hierarchy` | parent_organisation_id <> child_organisation_id AND no circular loops | Database (CHECK + Trigger) | **Critical** |
| **DR-022** | **Candidate Profile 1:1 Identity Uniqueness** | Unique / 1:1 | `candidate.candidate_profile` | user_id is unique globally across candidate_profile | Database (UNIQUE) | **Critical** |
| **DR-023** | **Candidate Minimum Working Age Requirement** | CHECK / Temporal | `candidate.candidate_profile` | date_of_birth <= CURRENT_DATE - INTERVAL '18 years' | Database (CHECK) | **Critical** |
| **DR-024** | **Candidate Notice Period Non-Negative Days** | CHECK / Range | `candidate.candidate_profile` | notice_period_days >= 0 | Database (CHECK) | **Medium** |
| **DR-025** | **Candidate Profile Completeness Percentage Range** | CHECK / Range | `candidate.candidate_profile` | profile_completion_percentage BETWEEN 0.00 AND 100.00 | Database (CHECK) | **High** |
| **DR-026** | **Candidate Education Date Chronological Ordering** | CHECK / Temporal | `candidate.candidate_education` | end_date IS NULL OR end_date >= start_date | Database (CHECK) | **High** |
| **DR-027** | **Candidate Employment Experience Date Chronology & Current Job Invariant** | CHECK / Logical | `candidate.candidate_work_experience` | (end_date IS NULL OR end_date >= start_date) AND (is_current_job = FALSE OR end_date IS NULL) | Database (CHECK) | **High** |
| **DR-028** | **Candidate Skill Competency Proficiency Level & Experience** | CHECK / Range | `candidate.candidate_skill` | proficiency_level IN ('BEGINNER','INTERMEDIATE','ADVANCED','EXPERT') AND years_of_experience >= 0.0 | Database (CHECK) | **High** |
| **DR-029** | **Candidate Resume Document File Size & Format Restrictions** | CHECK / Domain | `candidate.candidate_resume` | file_format IN ('PDF','DOCX') AND file_size_bytes BETWEEN 1024 AND 10485760 | Database (CHECK) | **High** |
| **DR-030** | **Candidate Anti-Join Privacy Shield Target Requirement** | CHECK / Logical | `candidate.candidate_block_list` | blocked_organisation_id IS NOT NULL OR blocked_recruiter_user_id IS NOT NULL | Database (CHECK) | **Critical** |
| **DR-031** | **Job Requisition Published Organization Verification Precondition** | Cross-Table / Status | `recruitment.job_requisition` | publish_status = 'PUBLISHED' REQUIRES organisation.verification_status = 'VERIFIED' | Service / Trigger | **Critical** |
| **DR-032** | **Job Requisition Compensation Band Bounds** | CHECK / Range | `recruitment.job_requisition` | min_salary_amount >= 0.00 AND max_salary_amount >= min_salary_amount | Database (CHECK) | **Critical** |
| **DR-033** | **Job Requisition Experience Months Bounds** | CHECK / Range | `recruitment.job_requisition` | min_experience_months >= 0 AND max_experience_months >= min_experience_months | Database (CHECK) | **High** |
| **DR-034** | **Job Requisition Headcount Vacancies Positive Integer** | CHECK / Range | `recruitment.job_requisition` | vacancies_count > 0 | Database (CHECK) | **High** |
| **DR-035** | **Job Requisition Application Deadline Future Date Requirement** | CHECK / Temporal | `recruitment.job_requisition` | application_deadline IS NULL OR application_deadline >= CURRENT_DATE | Database (CHECK) | **High** |
| **DR-036** | **Screening Questionnaire 1:1 Requisition Attachment** | Unique / 1:1 | `recruitment.job_questionnaire` | requisition_id is unique across job_questionnaire | Database (UNIQUE) | **High** |
| **DR-037** | **Questionnaire Passing Score Percentage Range** | CHECK / Range | `recruitment.job_questionnaire` | passing_score_percentage BETWEEN 0.00 AND 100.00 | Database (CHECK) | **High** |
| **DR-038** | **Question Weight Points & Option Score Value Non-Negative** | CHECK / Range | `recruitment.questionnaire_question` | weight_points >= 0 AND question_option.score_value >= 0 | Database (CHECK) | **High** |
| **DR-039** | **Single Active Application Per Candidate Per Requisition** | Composite Unique | `application.job_application` | UNIQUE(requisition_id, candidate_id) WHERE (application_status NOT IN ('WITHDRAWN','REJECTED')) | Database (Partial UNIQUE) | **Critical** |
| **DR-040** | **13-Stage Hiring Funnel Status Allowed Enumerations** | CHECK / Status | `application.job_application` | application_status IN ('DRAFT','SUBMITTED','SCREENING','SHORTLISTED','INTERVIEW_SCHEDULED','INTERVIEWED','ASSESSMENT','OFFER_PENDING','OFFER_EXTENDED','OFFER_ACCEPTED','JOINED','REJECTED','WITHDRAWN') | Database (CHECK) | **Critical** |
| **DR-041** | **Application Stage History Append-Only Monotonicity** | Security / Immutability | `application.application_stage_history` | Records are append-only; transition_timestamp is immutable; no UPDATE or DELETE permitted | Database (Trigger / Rule) | **Critical** |
| **DR-042** | **Job Interview Scheduled Calendar Interval Ordering** | CHECK / Temporal | `application.job_interview` | scheduled_end_time > scheduled_start_time | Database (CHECK) | **Critical** |
| **DR-043** | **Interview Feedback Structured Scorecard Quantitative Scales** | CHECK / Range | `application.interview_feedback` | technical_score BETWEEN 1.0 AND 5.0 AND cultural_score BETWEEN 1.0 AND 5.0 AND overall_score BETWEEN 1.0 AND 5.0 | Database (CHECK) | **High** |
| **DR-044** | **Job Offer Positive Compensation Amount** | CHECK / Range | `application.job_offer` | offered_salary_amount > 0.00 | Database (CHECK) | **Critical** |
| **DR-045** | **Job Offer Validity & Joining Calendar Chronology** | CHECK / Temporal | `application.job_offer` | offer_validity_date >= CURRENT_DATE AND joining_date >= CURRENT_DATE | Database (CHECK) | **Critical** |
| **DR-046** | **Application Offer Extension Precondition** | Cross-Table / Status | `application.job_offer` | Extending offer requires application_status IN ('OFFER_PENDING', 'INTERVIEWED') | Service / Trigger | **Critical** |
| **DR-047** | **Consultant Requisition Openness Precondition** | Cross-Table / Business | `sourcing.consultant_authorization` | Creating authorization requires requisition.open_to_consultants = TRUE | Database (Trigger) | **Critical** |
| **DR-048** | **Staffing Agency Commission Rate Percentage Bounds** | CHECK / Range | `sourcing.consultant_authorization` | commission_rate_percentage BETWEEN 0.00 AND 100.00 | Database (CHECK) | **High** |
| **DR-049** | **Candidate Nomination Unique Agency Attribution Lockout** | Business / Temporal | `sourcing.candidate_nomination` | No duplicate nomination for same candidate and requisition within 180 days | Database (Trigger + Index) | **Critical** |
| **DR-050** | **Outreach Campaign Recipients and Deducted Credits Non-Negative** | CHECK / Range | `sourcing.outreach_campaign` | total_recipients_count >= 0 AND credits_deducted >= 0 | Database (CHECK) | **High** |
| **DR-051** | **Outreach Recipient Delivery Status Allowed Enumerations** | CHECK / Status | `sourcing.outreach_recipient` | delivery_status IN ('QUEUED','SENT','DELIVERED','OPENED','CLICKED','RESPONDED','BOUNCED','FAILED') | Database (CHECK) | **Medium** |
| **DR-052** | **Consultant User Account Type Integrity** | Cross-Table / Role | `sourcing.consultant_authorization` | consultant_user_id must possess user_account.user_type = 'CONSULTANT' | Database (Trigger) | **High** |
| **DR-053** | **Gig Worker Hourly and Daily Rate Positivity & Ordering** | CHECK / Range | `gig.gig_worker_profile` | hourly_rate_amount > 0.00 AND (daily_rate_amount IS NULL OR daily_rate_amount >= hourly_rate_amount) | Database (CHECK) | **Critical** |
| **DR-054** | **Gig Worker Average Rating Score Range** | CHECK / Range | `gig.gig_worker_profile` | average_rating_score BETWEEN 1.00 AND 5.00 | Database (CHECK) | **High** |
| **DR-055** | **Gig Request Budget Positivity & Booking Window Integrity** | CHECK / Range | `gig.gig_request` | budget_amount > 0.00 AND lower(booking_window) < upper(booking_window) | Database (CHECK) | **Critical** |
| **DR-056** | **PostgreSQL GiST Temporal Non-Overlap Booking Exclusion** | Exclusion / GiST | `gig.gig_contract` | EXCLUDE USING gist (worker_id WITH =, agreed_window WITH &&) WHERE (contract_status IN ('SIGNED','ACTIVE')) | Database (GiST Index) | **Critical** |
| **DR-057** | **Gig Contract Escrow Reservation Precondition** | Cross-Table / Financial | `gig.gig_contract` | Signing contract requires client wallet spendable balance >= initial milestone escrow | Transaction (Row Lock + Trigger) | **Critical** |
| **DR-058** | **Gig Milestone Escrow Allocation Consistency** | CHECK / Range | `gig.gig_milestone` | milestone_amount > 0.00 AND escrow_allocation_amount >= milestone_amount | Database (CHECK) | **Critical** |
| **DR-059** | **Milestone 5-Day Auto-Approval Inactivity Timeout** | Business / Lifecycle | `gig.gig_milestone` | CURRENT_TIMESTAMP >= submitted_at + INTERVAL '5 days' WITHOUT client review triggers automated approval | Background Daemon | **High** |
| **DR-060** | **Bilateral Review Rating Score Bounds** | CHECK / Range | `gig.gig_rating` | rating_score BETWEEN 1.00 AND 5.00 AND communication_score BETWEEN 1.00 AND 5.00 AND quality_score BETWEEN 1.00 AND 5.00 | Database (CHECK) | **High** |
| **DR-061** | **Subscription Plan Recruiter Seats & Devices Cap Bounds** | CHECK / Range | `licensing.subscription_plan` | max_recruiter_seats > 0 AND max_devices_per_user BETWEEN 1 AND 5 | Database (CHECK) | **Critical** |
| **DR-062** | **Subscription License Temporal Non-Overlap per Commercial Account** | Exclusion / Temporal | `licensing.subscription_licence` | No two active licenses can have overlapping validity_period for the same account_id | Database (GiST / Trigger) | **Critical** |
| **DR-063** | **Enterprise Allocated Recruiter Seats Hard Ceiling** | Cross-Table / Quota | `licensing.subscription_licence` | allocated_seats_count <= subscription_plan.max_recruiter_seats | Database (CHECK + Trigger) | **Critical** |
| **DR-064** | **Licence Entitlement Quota Consumption Non-Negative** | CHECK / Range | `licensing.licence_entitlement_usage` | allocated_quota >= 0 AND consumed_quota >= 0 | Database (CHECK) | **High** |
| **DR-065** | **Login Session Token Cryptographic Hash Uniqueness** | Security / Unique | `identity.user_active_session` | session_token_hash ~ '^[a-f0-9]{64}$' AND is unique globally | Database (UNIQUE) | **Critical** |
| **DR-066** | **Wallet Balances Strict Non-Negative Invariant** | CHECK / Range | `billing.wallet_account` | current_balance >= 0.00 AND escrow_reserved_balance >= 0.00 | Database (CHECK) | **Critical** |
| **DR-067** | **Double-Entry Ledger Paired Balancing Zero Net Variance ($0.00)** | Business / Accounting | `billing.wallet_ledger` | SUM(DEBIT) - SUM(CREDIT) = 0.00 for every transaction_group_id | Database (Trigger / Transaction) | **Critical** |
| **DR-068** | **Wallet Ledger Append-Only Immutability Invariant** | Security / Immutability | `billing.wallet_ledger` | No UPDATE or DELETE operations permitted; corrections require paired reversal entries | Database (Trigger / Rule) | **Critical** |
| **DR-069** | **Payment Order Positive Gross Value & Currency Pairing** | CHECK / Range | `billing.payment_order` | amount > 0.00 AND currency_code matches ISO 4217 | Database (CHECK) | **Critical** |
| **DR-070** | **Payment Gateway Webhook Inbound Idempotency Key Uniqueness** | Security / Unique | `billing.payment_gateway_event` | gateway_event_id is unique globally across payment_gateway_event | Database (UNIQUE) | **Critical** |
| **DR-071** | **Statutory Invoice Mathematical Total Equality** | CHECK / Logical | `billing.invoice` | total_amount = subtotal_amount + tax_amount AND total_amount >= 0.00 | Database (CHECK) | **Critical** |
| **DR-072** | **Statutory Invoice Item Extended Price Equality** | CHECK / Logical | `billing.invoice_item` | total_price = quantity * unit_price AND quantity > 0 | Database (CHECK) | **High** |
| **DR-073** | **Candidate Contact Unlock Paid Quota Verification Precondition** | Cross-Table / Billing | `billing.profile_download_history` | Unlock requires employer active license quota > 0 OR spendable wallet balance >= unlock fee | Transaction (Row Lock + Trigger) | **Critical** |
| **DR-074** | **Recruiter-Candidate Direct Message Thread Unlock Precondition** | Cross-Table / Security | `engagement.message_thread` | Creating message thread requires verified billing.profile_download_history unlock_receipt_id | Database (FK + Trigger) | **Critical** |
| **DR-075** | **Message Thread Active DPDP Consent Precondition** | Cross-Table / Privacy | `engagement.message_thread` | Message transmission requires candidate active affirmative consent (status = 'ACTIVE') | Service / Trigger | **Critical** |
| **DR-076** | **Candidate Cryptographic Referral Token Uniqueness** | Security / Unique | `engagement.candidate_referral_link` | unique_referral_token is unique globally | Database (UNIQUE) | **High** |
| **DR-077** | **University Campus Placement Minimum Enrollment Cohort Guard** | Business / Quota | `engagement.campus_placement_cohort` | Launching drive (status = 'ACTIVE') requires minimum 20 verified student profiles enrolled | Service / Trigger | **High** |
| **DR-078** | **University Student Roll Number Uniqueness within Placement Cohort** | Composite Unique | `engagement.campus_student_member` | UNIQUE(cohort_id, university_roll_number) | Database (UNIQUE) | **High** |
| **DR-079** | **Student Cumulative Grade Point Average Scale Bounds** | CHECK / Range | `engagement.campus_student_member` | cumulative_gpa BETWEEN 0.00 AND 10.00 | Database (CHECK) | **High** |
| **DR-080** | **Affirmative DPDP Consent Logging Non-Repudiation Precondition** | Security / Compliance | `governance.dpdp_consent_record` | Logging consent requires granted_ip_address NOT NULL AND consent_purpose NOT NULL | Database (CHECK) | **Critical** |
| **DR-081** | **DPDP Consent Revocation Sub-Second DEK Key Shredding SLA** | Regulatory / Privacy | `governance.pii_encryption_key` | Consent status = 'REVOKED' triggers DEK overwrite with zeroes within <= 2.0 seconds | Database (Trigger + Daemon) | **Critical** |
| **DR-082** | **Tamper-Evident SHA-256 Audit Chaining Hash Uniqueness** | Security / Integrity | `governance.system_audit_event` | tamper_hash ~ '^[a-f0-9]{64}$' AND is unique globally | Database (CHECK + UNIQUE) | **Critical** |
| **DR-083** | **System Audit Trail Append-Only Immutability Invariant** | Security / Immutability | `governance.system_audit_event` | Application users cannot update or delete audit events; table is append-only | Database (Grant / Rule) | **Critical** |
| **DR-084** | **Statutory Data Retention Policy Duration Positivity** | CHECK / Range | `governance.data_retention_policy` | retention_duration_days > 0 | Database (CHECK) | **High** |
| **DR-085** | **Kimball Dimensional Star Schema SCD Type 2 Temporal Ordering** | CHECK / Temporal | `analytics.dim_candidate` | row_expiration_date >= row_effective_date | Database (CHECK) | **Critical** |

---

## 15. Positive and Negative Test Scenarios (Verification Suite)

The test suite below maps key validation rules to concrete positive (valid accepted data) and negative (invalid rejected data) test scenarios:

| Test ID | Rule ID | Scenario Description | Tested Input / Data Payload | Expected System Result | Test Category |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-V-01** | **DR-007** | Candidate Register with Valid Lowercase Email | `user@enterprise.com` | Accepted; row inserted in user_account | **Positive (Format)** |
| **TC-V-02** | **DR-008** | Candidate Register with Valid E.164 Phone | `+14155552671` | Accepted; E.164 regex matches | **Positive (Format)** |
| **TC-V-03** | **DR-032** | Create Job Requisition with Valid Salary Bands | `min_salary = 150000.00, max_salary = 180000.00` | Accepted; min <= max and min >= 0 | **Positive (Range)** |
| **TC-V-04** | **DR-056** | Book Gig Worker for Non-Overlapping Calendar Window | `Worker booked Nov 1-15; next booking Nov 16-30` | Accepted; GiST exclusion index verifies no overlap | **Positive (Temporal)** |
| **TC-V-05** | **DR-067** | Execute Double-Entry Escrow Disbursement | `DEBIT $2,400 Escrow, CREDIT $2,400 Worker` | Accepted; net variance is exactly $0.00 | **Positive (Accounting)** |
| **TC-V-06** | **DR-070** | Process Valid Inbound Payment Gateway Webhook | `New webhook event_id = 'evt_1N87abc' with valid HMAC` | Accepted; credited wallet; logged receipt | **Positive (Idempotency)** |
| **TC-V-07** | **DR-023** | Candidate Profile with Age >= 18 Years | `date_of_birth = '1998-05-12' (28 years old)` | Accepted; satisfies age check constraint | **Positive (CHECK)** |
| **TC-V-08** | **DR-045** | Extend Corporate Job Offer with Future Dates | `validity = +15 days, joining = +30 days` | Accepted; chronological order verified | **Positive (Temporal)** |
| **TC-V-09** | **DR-078** | Enroll Student with Unique Roll Number in Cohort | `Cohort 1 enrolls student '23CS1092'` | Accepted; composite unique passes | **Positive (Unique)** |
| **TC-V-10** | **DR-081** | Candidate Revokes DPDP Sourcing Consent | `Candidate clicks withdraw; DEK zeroed` | Accepted; sub-second DEK shredding executed | **Positive (Privacy)** |
| **TC-V-11** | **DR-007** | Attempt Account Registration with Uppercase Email | `User.NAME@Enterprise.COM` | Rejected by check constraint (email must be lower) | **Negative (Format)** |
| **TC-V-12** | **DR-007** | Attempt Duplicate Email Registration | `Existing user email submitted again` | Rejected by unique constraint (23505 unique_violation) | **Negative (Unique)** |
| **TC-V-13** | **DR-008** | Attempt Invalid Contact Phone Format | `14155552671 (Missing leading + sign)` | Rejected by E.164 check constraint | **Negative (Format)** |
| **TC-V-14** | **DR-023** | Attempt Underage Candidate Registration (< 18) | `date_of_birth = CURRENT_DATE - 16 years` | Rejected by age check constraint (date_of_birth <= now - 18y) | **Negative (CHECK)** |
| **TC-V-15** | **DR-032** | Requisition with Inverted Salary Bands | `min_salary = 200000.00, max_salary = 150000.00` | Rejected by check constraint (max_salary >= min_salary) | **Negative (Range)** |
| **TC-V-16** | **DR-035** | Requisition with Expired Application Deadline | `application_deadline = '2020-01-01'` | Rejected by check constraint (deadline >= CURRENT_DATE) | **Negative (Temporal)** |
| **TC-V-17** | **DR-039** | Duplicate Application on Same Requisition | `Candidate submits second application while first is ACTIVE` | Rejected by partial unique constraint | **Negative (Duplicate)** |
| **TC-V-18** | **DR-056** | Concurrent Gig Booking with Overlapping Schedule | `Worker booked Nov 1-15; new client books Nov 10-20` | Rejected by GiST exclusion constraint (exclusion_violation) | **Negative (GiST)** |
| **TC-V-19** | **DR-066** | Attempt Overdrawing Wallet Account Balance | `Debit $5,000 on wallet with current_balance = $3,000` | Rejected by check constraint (current_balance >= 0.00) | **Negative (Range)** |
| **TC-V-20** | **DR-067** | Unbalanced Single-Sided Ledger Entry Attempt | `Insert DEBIT $1,000 with net variance <> $0.00` | Rejected by trigger (LEDGER_IMBALANCE_NONZERO_VARIANCE) | **Negative (Accounting)** |
| **TC-V-21** | **DR-068** | Attempting UPDATE on Wallet Ledger Row | `UPDATE billing.wallet_ledger SET amount = 500 WHERE id = ...` | Rejected by rule/trigger (APPEND_ONLY_TABLE_MODIFICATION_FORBIDDEN) | **Negative (Immutability)** |
| **TC-V-22** | **DR-070** | Duplicate Delivery of Payment Webhook | `Resend identical webhook with event_id = 'evt_1N87abc'` | Ignored gracefully via ON CONFLICT DO NOTHING (idempotent) | **Negative (Idempotency)** |
| **TC-V-23** | **DR-071** | Invoice Total Mismatched with Subtotal and Tax | `subtotal = $1,000, tax = $180, total_amount = $1,100` | Rejected by check constraint (total = subtotal + tax) | **Negative (CHECK)** |
| **TC-V-24** | **CTR-01** | Unverified Employer Attempts Job Publication | `Employer verification_status = 'UNVERIFIED' publishes job` | Rejected with HTTP 403 Forbidden (ORG_NOT_VERIFIED) | **Negative (Cross-Table)** |
| **TC-V-25** | **CTR-02** | Consultant Requests Sourcing on Closed Job | `open_to_consultants = FALSE, consultant applies` | Rejected by trigger (REQUISITION_NOT_OPEN_TO_CONSULTANTS) | **Negative (Cross-Table)** |
| **TC-V-26** | **CTR-04** | Sign Contract with Insufficient Wallet Escrow | `Milestone escrow $2,500; wallet spendable balance $500` | Rejected with HTTP 402 (INSUFFICIENT_ESCROW_FUNDS) | **Negative (Cross-Table)** |
| **TC-V-27** | **CTR-06** | Allocate Recruiter Seat Over Subscription Limit | `Plan limit 25 seats; administrator assigns 26th seat` | Rejected with HTTP 403 Forbidden (SEAT_QUOTA_EXCEEDED) | **Negative (Cross-Table)** |
| **TC-V-28** | **CTR-08** | Recruiter Initiates Chat with Blocked Candidate | `Candidate has active block rule against recruiter company` | Rejected with HTTP 403 (CANDIDATE_PRIVACY_SHIELD_ACTIVE) | **Negative (Cross-Table)** |
| **TC-V-29** | **DR-078** | Duplicate Student Roll Number in Same Cohort | `Roll '23CS1092' enrolled twice in same cohort_id` | Rejected by composite unique constraint | **Negative (Unique)** |
| **TC-V-30** | **DR-083** | Malicious DBA Attempts to DELETE Audit Event | `DELETE FROM governance.system_audit_event WHERE id = ...` | Rejected by permission/trigger (AUDIT_TRAIL_IS_IMMUTABLE) | **Negative (Immutability)** |

---

## 16. Open Questions & Architectural Alignment

The following ranked open questions represent constraint edge cases requiring stakeholder validation before physical database creation:

| Question ID | Architectural Domain | Open Ambiguity Statement | Stated Working Recommendation | Impact on Physical DDL |
| :--- | :--- | :--- | :--- | :--- |
| **Q1** | `gig.gig_contract` | Under the GiST temporal exclusion constraint, should the database allow overlapping bookings if the contracts specify non-overlapping daily working hours? | Recommendation: Keep GiST exclusion coarse-grained to `tstzrange` calendar date windows for Step 11; introduce hourly sub-slot exclusions in Phase 3 if hourly consulting demand requires it. | GiST index predicate definition. |
| **Q2** | `application.job_application` | If a candidate is rejected on a requisition, how long must they wait before submitting a fresh application for that same role? | Recommendation: Enforce a 90-day cooldown period via partial unique index `WHERE (applied_at >= now() - INTERVAL '90 days')`. | Partial index condition. |
| **Q3** | `billing.wallet_ledger` | In the event of a payment gateway chargeback/dispute, should the wallet balance be allowed to drop into negative numbers temporarily? | Recommendation: Maintain `current_balance >= 0.00` check constraint; record chargeback liabilities in a dedicated dispute sub-ledger to prevent database constraint exceptions. | Maintains non-negative balance invariant. |

---

## 17. Step 11 Data Rules Discovery Completion Checklist

| Verification Audit Item | Target Standard | Observed Specification Status | Verdict |
| :--- | :--- | :--- | :---: |
| **1. Comprehensive Rule Identification** | All 13 modules covered with stable rule IDs | **85 Master Data Rules (`DR-001`–`DR-085`)** documented across all tables. | **PASSED (100%)** |
| **2. Constraint Categorization** | PK, FK, NOT NULL, UNIQUE, CHECK, Regex covered | Sections 4, 5, 6, 7, and 8 systematically detail all constraint archetypes. | **PASSED (100%)** |
| **3. Mandatory Cross-Table Rules** | Section 10 dedicated cross-table table | **10 Cross-Table Rules (`CTR-01`–`CTR-10`)** specified with valid/invalid scenarios. | **PASSED (100%)** |
| **4. Lifecycle Integration** | State machine alignment from Step 08 | Section 11 formalizes terminal state immutability and valid transition preconditions. | **PASSED (100%)** |
| **5. Tiered Enforcement Strategy** | Database vs Application vs Transaction layers | Section 12 establishes explicit layer mappings, rationales, and failure handling. | **PASSED (100%)** |
| **6. Duplicate & Idempotency Rules** | Idempotency keys and anti-duplicate guards | Section 13 details webhook deduplication, partial indexes, and GiST locks. | **PASSED (100%)** |
| **7. Verification Test Suite** | Positive and Negative test cases mapped | Section 15 details **30 test scenarios (10 positive + 20 negative edge cases)**. | **PASSED (100%)** |
| **8. Pure Discovery Standard** | No premature SQL DDL scripts or code | Document defines pure logical rules, constraints, and conditions without premature DDL. | **PASSED (100%)** |

---

**Sign-off Status:** Complete, defensive, and ready for Physical PostgreSQL DDL Generation (Step 12).