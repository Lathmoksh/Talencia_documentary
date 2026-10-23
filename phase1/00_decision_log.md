# Phase 1: Architectural Decision Log & Boundary Baseline
**Platform:** Talentra Enterprise Workforce Platform  
**Stage:** Phase 1 — Discover ("Understand Before You Model")  
**Scope:** Architecture Decision Records (ADRs), Policy Assumptions & Explicit System Boundaries  
**Status:** Baseline Established & Documented  

---

## 1. System Scope & Core Architecture Principles

Talentra is designed for Northbridge Workforce Systems to unify corporate full-time hiring, contingent gig labor procurement, and campus early-talent programs under a single multi-tenant data platform.

In Phase 1 Discover, **no database tables, schemas, or physical DDL are finalized**. Instead, this document records the foundational architectural decisions, boundary definitions, and policy assumptions that guide downstream modeling in Phase 2 and 3.

---

## 2. In-Scope vs. Explicit Out-of-Scope System Boundaries

To eliminate architectural ambiguity, the boundary between platform-owned responsibilities and external system delegations is strictly defined:

| Operational Subsystem | In-Scope (Platform Owned Responsibilities) | Out-of-Scope (External Delegated Boundary) |
| :--- | :--- | :--- |
| **Identity & Access** | User credentials, session lifecycles, multi-tenant role-based permissions, and device concurrency locking. | Live biometric verification, hardware token issuance, external OAuth2 identity provider operation. |
| **Candidate Sourcing** | Profile representation, parsed resume skill vector indexes, employer block-list filters, and application state machines. | External job board scraping; raw optical character recognition (OCR) binary file decoding. |
| **Gig Marketplace** | Worker trade categories, hourly rates, proposal management, milestone tracking, and contract schedule verification. | Physical on-site job supervision, vehicle or tool inspection, off-platform labor tribunal disputes. |
| **Billing & Finance** | Double-entry append-only credit ledger, subscription seat quotas, running balance synchronization, and download metering. | Direct credit card PAN/CVV collection and interchange routing (strictly delegated to PCI-DSS Level 1 payment gateways). |
| **Compliance & Audit** | DPDP Act 2023 purpose-bound consent logging, automated erasure cascades, data classification catalogs, and immutable event recording. | Direct governmental tax filing submissions; statutory courtroom litigation records. |

---

## 3. Architecture Decision Records (ADRs)

### ADR-01: Surrogate Identity Strategy vs. Natural Keys
* **Context**: High-scale talent platforms must support tens of millions of records across candidates, jobs, and applications with fast relational joins.
* **Decision**: Adopt surrogate keys across all core entities. Natural keys (such as email addresses or tax identifiers) are enforced via unique constraints but never used as foreign key join targets.
* **Rationale**: Natural keys mutate (e.g., user email changes, corporate legal re-registrations). Surrogate keys isolate relational integrity from business attribute mutations and optimize B-tree index traversal.

### ADR-02: Cryptographic Envelope & Blind Indexing for Sensitive PII
* **Context**: The Digital Personal Data Protection (DPDP) Act 2023 and GDPR mandate robust protection for personal phone numbers and national identity identifiers.
* **Decision**: Column-level encryption using AES-256-GCM with per-tenant Data Encryption Keys (DEKs). For deterministic exact-match search lookups, implement HMAC-SHA256 blind indexing with an isolated cryptographic pepper.
* **Rationale**: Plaintext storage creates unacceptable breach exposure. Full table decryption for queries introduces unscalable CPU bottlenecks. Blind indexing enables indexed exact-match equality queries without decrypting data rows.

### ADR-03: Multi-Tenant Isolation via Row-Level Security (RLS)
* **Context**: Corporate recruiters from competing organizations must operate within the same platform without any risk of cross-tenant pipeline data leakage.
* **Decision**: Enforce tenant isolation at the database kernel level using PostgreSQL Row-Level Security (`RLS`) tied to a verified session context (`app.current_org_id`).
* **Rationale**: Relying solely on application-layer software `WHERE` clauses is vulnerable to developer oversight. Kernel-level RLS guarantees that queries physically cannot return another tenant's candidate pipeline, even under application code defects.

### ADR-04: Concurrency & Temporal Exclusion in Gig Contracting
* **Context**: Freelance gig workers are booked across distinct milestone delivery intervals. High concurrency can result in double-booking the same worker for overlapping dates.
* **Decision**: Implement temporal non-overlapping exclusion constraints (`EXCLUDE USING gist`) on worker contract date intervals at the storage engine level.
* **Rationale**: Application-layer scheduling checks suffer from race conditions under high concurrent booking spikes. Database exclusion constraints make overlapping bookings mathematically impossible.

### ADR-05: Double-Entry Immutable Accounting for Corporate Wallets
* **Context**: Resume unlock metering, subscription credits, and gig milestone escrow require complete financial auditability with zero balance discrepancy.
* **Decision**: Implement an append-only double-entry ledger where every balance alteration requires paired debit and credit entries. Running balances are recalculated via automated database triggers. In-place `UPDATE` and `DELETE` queries on posted ledger rows are rejected.
* **Rationale**: Single-entry balance columns are vulnerable to tampering and concurrency drift. Double-entry ledgers guarantee non-repudiation, forensic traceability, and zero accounting variance ($0.00 balance discrepancy).

### ADR-06: PCI-DSS Level 1 Boundary Tokenization
* **Context**: Enterprise recruitment software must process subscription fees and wallet top-ups without incurring catastrophic credit card compliance burdens.
* **Decision**: Zero persistence of Primary Account Numbers (PAN), CVVs, or magnetic stripe data. All card collection is handled via external gateway tokenization (Stripe/Razorpay), with Talentra storing only opaque gateway customer tokens and transaction references.
* **Rationale**: Eliminates PCI-DSS Level 1 audit overhead while guaranteeing total cardholder privacy.

### ADR-07: Statutory Erasure via Cryptographic Key Shredding
* **Context**: DPDP Act 2023 (Section 8) and GDPR (Article 17) mandate personal data erasure upon candidate consent revocation, while financial regulations mandate 7-year audit retention.
* **Decision**: Implement a two-tier erasure model: PII attributes are wiped and per-candidate cryptographic keys are shredded, while anonymized transaction and audit event IDs remain in immutable history logs.
* **Rationale**: Satisfies the candidate's statutory right to be forgotten while fulfilling mandatory statutory accounting and security audit compliance.

### ADR-08: Query Latency Specification & Measurement Boundary (REQ-24 vs NFR-02)
* **Context**: Preliminary brief notes referenced "sub-millisecond search", whereas physical database benchmarking indicates realistic query response times across 1M records with RLS filters and anti-joins require up to 15.0 ms.
* **Decision**: We interpret "sub-millisecond" as referring strictly to internal in-memory index traversal or cache lookups. For the formal engineering specification, `REQ-24` and `NFR-02` are reconciled to state an interactive database execution target of `p95 <= 15.0 ms` (warm cache) across 1M candidate profiles, fitting within an end-to-end user SLA budget of 50.0 ms.
* **Rationale**: An end-to-end relational SQL query involving index scanning, multi-tenant RLS checks, and employer block anti-joins cannot physically execute over wire protocols in `< 1.0 ms`. Aligning the requirement to `<= 15.0 ms` creates a rigorous, measurable, and achievable engineering target.

### ADR-09: Reconciliation of Statutory DPDP Erasure vs. 7-Year Financial & Audit Retention
* **Context**: Digital Personal Data Protection (DPDP) Act 2023 Section 8 mandates immediate cessation of personal data processing upon consent withdrawal. Concurrently, the Income Tax Act 1961 (Section 44AA) and Companies Act 2013 (Section 128) mandate 7 to 8 years retention of books of account and audit trails.
* **Decision**: Adopt a dual-lifecycle compliance model backed by DPDP Section 8(7) legal obligation exemptions:
  1. *Immediate Erasure*: Candidate PII (names, contact numbers, email addresses, resume files, skill tags) is wiped immediately upon consent withdrawal. Search index entries are purged within `<= 2.0 seconds` (`NFR-10`), and cryptographic Data Encryption Keys (DEKs) are shredded.
  2. *Retained Financial & Security Ledgers*: Financial ledger transactions (`WF-07`) and security audit logs (`F-16`) are retained in pseudonymized form (cryptographically detached surrogate IDs with shredded encryption keys) for the statutory 7-year retention period, after which they are permanently purged.
* **Rationale**: Harmonizes candidate privacy sovereignty with non-negotiable statutory accounting and anti-fraud regulations without legal breach.

### ADR-10: Candidate Consent Revocation Impact on Unlocked Recruiter Contacts
* **Context**: In `WF-04`, recruiters pay quota credits or wallet balance to unlock candidate contact details. A potential conflict arises if a candidate subsequently exercises their DPDP right to withdraw consent and purge their profile (`WF-01`).
* **Decision**: Candidate statutory privacy rights are sovereign and override commercial access. Upon candidate consent withdrawal:
  1. The candidate profile and contact details are masked across all recruiter views immediately.
  2. The organization that unlocked the contact receives an automated notification stating the candidate has withdrawn from the platform.
  3. *Commercial Fairness Guarantee*: If consent revocation occurs within 30 days of the unlock transaction, the platform automatically refunds one unlock quota credit back to the organization's monthly credit pool (`EXC-31`).
* **Rationale**: Preserves 100% statutory DPDP compliance while protecting corporate clients against commercial loss from premature candidate withdrawals.

---

## 4. Operational Policy Assumptions & Confirmation Register

The following operational timeframes and business limits are established as Phase 1 baseline assumptions:

| Policy Area | Assumed Baseline Value | Architectural Owner | Confirm With / Authority | Business Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Agency Exclusivity** | 180 Calendar Days | Head of Talent Partnerships | Legal & Agency Brokerage Committee | Standard industry placement protection preventing enterprise clients from bypassing agency split bounties. |
| **Application Cooldown** | 90 Calendar Days | VP of Recruitment Operations | Enterprise Talent Acquisition Leads | Prevents automated resume spam while allowing candidates to re-apply after skill upgrades or new hiring cycles. |
| **Assessment Window** | 72 Hours | Director of Assessment Products | Technical Hiring Advisory Group | Balances candidate scheduling accommodation with enterprise hiring pipeline velocity. |
| **Offer Expiry Window** | 7 Calendar Days | Enterprise HR Operations Lead | Corporate Compensation & Legal Teams | Prevents requisition opening stagnation and allows hiring managers to extend offers to secondary candidates. |
| **Email Verification** | 24 Hours | Lead Security Architect | Identity & Security Operations | Limits the attack surface and exposure window for dormant verification tokens. |
| **Subscription Grace** | 5 Calendar Days | Head of Billing Operations | Enterprise Finance & Accounts Receivable | Accommodates transient corporate credit card processing failures before recruiter write access suspension. |
| **Milestone Review** | 7 Calendar Days | Marketplace Operations Director | Contingent Labor Guild | Prevents client review inertia; triggers automated escrow release to freelancer upon expiration. |
