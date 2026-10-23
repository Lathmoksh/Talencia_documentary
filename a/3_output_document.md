# Talentra — Requirement Analysis Docket
**Document Reference**: Deliverable A3 — System Scope, Boundary & Requirements Baseline  
**Platform**: Talentra Enterprise Workforce Platform  
**Architecture Domain**: Core Data Platform & Integration Boundaries  
**Status**: Approved & Frozen for Implementation  

---

## 1. Executive Purpose & Context

Talentra is an enterprise-scale talent acquisition and workforce mobilization platform designed for Northbridge Workforce Systems. It unifies professional permanent hiring, contingent gig labor procurement, and campus early-career programs into a multi-tenant, high-throughput PostgreSQL architecture.

This docket defines the formal requirements baseline, external integration contracts, open architectural questions, and data governance policies. Every requirement is uniquely indexed, assigned an engineering priority, linked to authorized actors, and accompanied by strict ambiguity resolutions that replace subjective adjectives with concrete mathematical and physical database thresholds.

---

## 2. In-Scope vs. Explicit Out-of-Scope Boundaries

| Operational Domain | In-Scope (Platform Owned) | Out-of-Scope (External Boundary) |
| :--- | :--- | :--- |
| **Identity & Authentication** | User credentials hashed with Argon2id, session token tracking, multi-tenant RBAC assignments, device concurrency locks. | Live biometric capture, hardware key provisioning (delegated to enterprise SSO / Okta). |
| **Candidate Sourcing** | Anonymized search indexes, parsed resume skill vectors, candidate profile visibility toggles, employer block lists. | External job scraping from third-party boards; resume file OCR (processed via external text extraction microservice). |
| **Gig Marketplace** | Worker trade categories, hourly rates, proposal submissions, GiST non-overlapping contract scheduling, milestone statuses. | Physical on-site job supervision, vehicle or tool inspection, off-platform labor disputes. |
| **Billing & Finance** | Double-entry append-only wallet ledger, running balance reconciliation, subscription seat caps, download credit tracking. | Credit card PAN/CVV storage, direct banking interchange (delegated to PCI-DSS Level 1 payment gateways). |
| **Compliance & Audit** | DPDP Act 2023 consent capture, GDPR erasure cascade, immutable pre/post JSONB mutation logging, data classification tiers. | Legal tribunal filings, government tax filing generation. |

---

## 3. Assumptions & Ranked Architectural Questions

### 3.1 Foundational Engineering Assumptions
1. **Organizational Identity**: Every corporate tenant operates under a legally registered national identifier (e.g., GSTIN, MCA, EIN, SEC) stored with cryptographic blind indexing.
2. **Global Temporal Normalization**: All business events, contract schedules, and audit entries are recorded in Coordinated Universal Time (`TIMESTAMP WITH TIME ZONE` in UTC).
3. **Financial Immutability**: Financial transactions and ledger postings are strictly append-only. Ledger errors cannot be altered in place; they require compensating debit/credit entries.

### 3.2 Ranked Open Questions (by Architectural Impact)

| Rank | Architectural Question | Impact Level | Architectural Resolution & Physical Mechanism |
| :---: | :--- | :---: | :--- |
| **Q1** | How to prevent circular ownership loops in conglomerate enterprise parent-subsidiary hierarchies? | **Critical** | Recursive Common Table Expression (CTE) cycle-detection trigger on `organisation.organisation_relationship` guarded by PostgreSQL transactional advisory locks (`pg_advisory_xact_lock`). |
| **Q2** | How to guarantee gig workers cannot be double-booked across overlapping contracts during high concurrency? | **Critical** | PostgreSQL `GiST` temporal exclusion constraint (`EXCLUDE USING gist (worker_id WITH =, contract_validity_period WITH &&)`) rejecting overlapping booking windows at the database kernel level. |
| **Q3** | How to protect candidate privacy from current employers without degrading search query speed? | **High** | Materialized anti-join views combining `administration.candidate_block_list` with indexed recruiter organization IDs, executing in sub-millisecond latency. |
| **Q4** | How to maintain accurate corporate wallet balances during concurrent resume unlocks without race conditions? | **High** | Database-level row-level locking (`SELECT ... FOR UPDATE`) coupled with an append-only trigger that automatically re-sums running balances from immutable ledger entries. |
| **Q5** | How to ensure statutory compliance with DPDP Act 2023 right to erasure while preserving forensic audit trails? | **Medium** | Cryptographic key shredding for tenant DEKs combined with candidate profile anonymization, leaving anonymized audit event IDs intact without personally identifiable data. |

---

## 4. Master Requirements Docket (`REQ-01` to `REQ-25`)

Every requirement below resolves common ambiguities by binding implementation to measurable metrics:

| REQ ID | Requirement Statement | Architectural Source | Priority | Target Actor(s) | Ambiguity Resolution & Numeric Threshold |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **REQ-01** | Canonical Identity Normalization | Core Invariant | Must-Have | Candidate, User | Email must be stored in lowercase canonical form (`CHECK (email = lower(email))`); max length 254 chars; rejects whitespace. |
| **REQ-02** | E.164 International Phone Standard | Core Invariant | Must-Have | Candidate, Recruiter | Phone numbers must follow E.164 standard (`^\+[1-9]\d{1,14}$`). Rejects local un-prefixed numbers. |
| **REQ-03** | Primary Key Standard | Core Invariant | Must-Have | System | Primary keys use surrogate UUIDv4 (`gen_random_uuid()`) to eliminate guessability and enable distributed generation. |
| **REQ-04** | Fixed-Precision Financials | Core Invariant | Must-Have | Recruiter, Admin | Currency values use `NUMERIC(12,2)` with ISO 4217 currency code foreign keys. Floating-point types strictly prohibited. |
| **REQ-05** | Standardized Lookup Catalog | Core Invariant | Must-Have | System | Lookup tables mandate `id`, `code` (`^[a-z][a-z0-9_]*$`), `name`, `is_active`, and integer `sort_order`. |
| **REQ-06** | Multilingual Translation Fallback | Core Invariant | Must-Have | Candidate, Recruiter | UI localized strings resolve in a single indexed query with automatic fallback to English (`en`) if localized key is missing. |
| **REQ-07** | Screening Questionnaire Trees | Domain Sourcing | Must-Have | Recruiter, Candidate | Requisitions attach versioned questionnaires supporting Text, Single Choice, Multiple Choice, and Boolean with scoring rules. |
| **REQ-08** | Dynamic Application Templates | Domain Sourcing | Should-Have | Recruiter | Custom application workflows link to questionnaire definitions through strict foreign key referential integrity. |
| **REQ-09** | Forensic Audit Trail Immutability | Core Security | Must-Have | Auditor, System | Audit tables enforce append-only storage; database triggers abort all `UPDATE` and `DELETE` queries unconditionally. |
| **REQ-10** | DPDP 2023 Purpose-Bound Consent | Statutory Mandate | Must-Have | Candidate, Auditor | Records affirmative consent grants, purpose codes, IP addresses, user agents, and explicit revocation timestamps. |
| **REQ-11** | Column-Level Data Sensitivity | Statutory Mandate | Must-Have | Auditor, Security | All columns cataloged into 4 tiers (`PUBLIC`, `INTERNAL`, `CONFIDENTIAL`, `RESTRICTED`) with automated retention policies. |
| **REQ-12** | Argon2id Credential Encryption | Core Security | Must-Have | System | Passwords hashed using Argon2id with minimum 16-byte cryptographically secure salt. Plaintext prohibited. |
| **REQ-13** | Multi-Tenant Row-Level Security | Core Security | Must-Have | Recruiter, Admin | Tenant tables enforce PostgreSQL RLS filtered by session variable `app.current_org_id`. |
| **REQ-14** | Candidate Privacy Shield | Core Security | Must-Have | Candidate, Recruiter | Candidate block list anti-joins prevent current employers from discovering active candidate profiles. |
| **REQ-15** | GiST Non-Overlapping Gig Scheduling | Domain Gig | Must-Have | Gig Worker, Client | Enforces `EXCLUDE USING gist` on worker contract intervals, guaranteeing zero concurrent double-booking. |
| **REQ-16** | Single-Active-Session Concurrency | Core Security | Must-Have | Security, Admin | Stored procedure terminates prior device sessions upon new login, preventing commercial seat sharing. |
| **REQ-17** | Double-Entry Wallet Ledger | Domain Billing | Must-Have | Client, Gig Worker | All financial movements record paired debit/credit ledger entries; running balances recalculated via trigger ($0.00 variance). |
| **REQ-18** | Resume Unlock Quota & Metering | Domain Sourcing | Must-Have | Recruiter | Accessing candidate PII decrements monthly subscription download credits or debits wallet credits atomically. |
| **REQ-19** | Tiered Subscription Seat Quotas | Domain Licensing | Must-Have | Account Admin | Enforces hard cap on active recruiter seat assignments matching purchased tier allowance (`seat_count <= max_seats`). |
| **REQ-20** | National Identifier Blind Indexing | Core Security | Must-Have | Security, System | National tax IDs encrypted via AES-256-GCM; exact lookups executed via HMAC-SHA256 blind indexes without plaintext exposure. |
| **REQ-21** | Webhook Ingestion Idempotency | Integration | Must-Have | System | Payment and background check webhooks enforce unique idempotency keys, dropping duplicate event deliveries. |
| **REQ-22** | Campus Cohort Management | Domain Sourcing | Should-Have | Recruiter, Campus Fresher | Supports structured grouping of fresher talent by academic institution, degree specialization, and graduation year. |
| **REQ-23** | Candidate Referral Tracking | Engagement | Should-Have | Candidate, Recruiter | Assigns unique alphanumeric referral codes to track application origin and trigger automated bonus attributions. |
| **REQ-24** | Sub-Millisecond Search Latency | Performance SLA | Must-Have | Recruiter | Candidate profile search across 1,000,000 records achieves warm-cache p95 latency under 10.0 ms via GIN trigram indexes. |
| **REQ-25** | Disaster Recovery RTO/RPO | Infrastructure | Must-Have | System Admin | Enforces Recovery Point Objective (RPO) < 1.0 minute and Recovery Time Objective (RTO) < 15.0 minutes via WAL streaming. |

---

## 5. Architectural Decision Records (ADRs)

- **ADR-01: Engine-Level Multi-Tenancy via PostgreSQL Row-Level Security (RLS)**: Enforces tenant data isolation at the storage engine level rather than relying on application `WHERE` clauses, preventing data leaks.
- **ADR-02: GiST Temporal Exclusion for Gig Workforce Booking**: Prevents scheduling collisions at the database layer using geometric spatial/range operators, eliminating application race conditions.
- **ADR-03: Double-Entry Immutable Financial Ledger**: All wallet balance modifications require an explicit entry in `billing.wallet_ledger`, maintaining mathematical proof of financial integrity.
- **ADR-04: Cryptographic Blind Indexing for Sensitive Identifiers**: Allows deterministic equality queries on encrypted PII columns (phone, tax ID) using HMAC-SHA256 without decrypting database tables.
- **ADR-05: Append-Only Immutable Compliance Auditing**: Forensically valid tracking of all critical system mutations via JSONB before/after snapshots protected by exception triggers.
