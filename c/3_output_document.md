# Talentra — Feature Discovery & Competitive Analysis Docket
**Document Reference**: Deliverable C3 — Strategic Feature Inventory & Market Benchmarking  
**Platform**: Talentra Enterprise Workforce Platform  
**Architecture Domain**: Product Capabilities, Monetization & Differentiation  
**Status**: Approved & Frozen for Implementation  

---

## 1. Executive Purpose & Strategic Framing

This docket establishes the functional capability baseline for Talentra, synthesizing core market requirements, strategic differentiators, and competitive gap analyses against legacy industry leaders (LinkedIn Talent Solutions, InfoEdge Naukri, and Monster Worldwide).

In accordance with Phase 1 Discover specifications, all platform capabilities are inventoried into a structured 20-feature catalog classified by MoSCoW priority (**Must-Have**, **Should-Have**, **Differentiator**). Furthermore, this analysis articulates exactly what competitors lack and argues why those gaps matter commercially and architecturally.

---

## 2. Competitive Benchmarking Matrix & Architectural Gap Analysis

| Capability Dimension | Legacy Competitor Coverage | Talentra Implementation | What Competitors Lack & Why It Matters |
| :--- | :--- | :--- | :--- |
| **1. Dual-Track Workforce Model** | Siloed. LinkedIn focuses on corporate white-collar; Upwork/Fiverr on freelance gigs; legacy job boards on volume resume dumps. | **Unified Account & Shared Identity**: Supports full-time permanent, contract gig, and campus hiring under one multi-tenant organizational account. | Competitors force enterprise clients into separate platforms with disjointed billing and duplicate profiles. Talentra enables agile labor reallocation without data silos. |
| **2. Concurrency Conflict Prevention** | Absent. Relies on calendar UI syncing; prone to race conditions and double-booking during concurrent booking attempts. | **PostgreSQL GiST Non-Overlapping Exclusion Constraints**: Enforces `EXCLUDE USING gist` on worker contract intervals at the database kernel. | Application race conditions in competitor tools cause embarrassing double-booking disputes. Talentra mathematically guarantees temporal exclusivity at zero latency. |
| **3. Candidate Privacy Shield** | Basic. "Open to Work" visibility toggles hide profiles only from direct corporate recruiter seats of current employer. | **Automated Anti-Join Privacy Shield**: Candidates define explicit corporate entities in `candidate_block_list`, completely hidden via indexed anti-joins. | In competitor platforms, candidates risk exposure to parent companies, subsidiaries, or agency recruiters. Talentra provides total, verifiable confidentiality. |
| **4. In-Database Monetization Ledger** | Externalized. Billing is decoupled from transactional data, relying on delayed batch reconciliations and credit card billing. | **Double-Entry Append-Only Wallet Ledger**: High-frequency credit and debit accounting with automated running balance synchronization triggers. | Traditional batch reconciliation creates commercial leakage and credit disputes. Talentra guarantees sub-second balance consistency with $0.00 accounting variance. |
| **5. Resume Sourcing Quotas & Metering** | Opaque. Flat subscription packages with limited transparency on seat utilization and credit consumption. | **Atomic Metering & Download History**: Every unmasked resume download records an immutable receipt in `profile_download_history`. | Enterprise HR heads cannot audit which recruiter consumed resume download credits. Talentra provides immutable, per-download auditability. |
| **6. Multi-Tenant Engine Isolation** | Application-level. Most legacy platforms filter tenant data via software `WHERE` clauses in application code. | **PostgreSQL Engine-Level Row-Level Security (RLS)**: Enforces tenant isolation directly in the query planner via `app.current_org_id`. | A single developer oversight in application code can leak proprietary candidate pipelines. Talentra makes cross-tenant leakage physically impossible in SQL. |
| **7. Statutory Consent Management** | Retrofitted. Legacy platforms treat GDPR/DPDP as compliance checkboxes via cookie banners and bulk marketing consent. | **Purpose-Bound Consent Registry**: Explicit affirmative consent tracking with purpose codes, IP logging, and automated key-shredding erasure. | Regulators under DPDP Act 2023 impose massive fines for non-compliant consent processing. Talentra provides statutory compliance by design. |
| **8. Multi-Branch Seat Governance** | Permissive. Organizations freely share login credentials across team members due to lack of device session enforcement. | **Single-Active-Session Device Lock**: Stored procedure terminates previous session tokens upon new device login, enforcing paid seat caps. | Commercial revenue leakage from credential sharing costs platforms millions. Talentra protects enterprise licensing revenue at the database tier. |

---

## 3. Strategic Feature Inventory (`F-01` to `F-20`)

Every feature below defines operational scope, MoSCoW classification, mapped requirements, and physical database mechanisms:

### Pillar 1: Identity, Tenancy & Security
* **F-01: Zero-Trust Unified Authentication**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-01`, `REQ-12`.
  * **Scope**: Argon2id password hashing, E.164 phone normalization, canonical lowercase email uniqueness, and MFA tokens.
* **F-02: Fine-Grained 11-Module RBAC Matrix**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-13`.
  * **Scope**: Role-based access control across 11 modules; enforced via database role grants and session tokens.
* **F-03: Candidate Privacy Shield**
  * **Classification**: **Differentiator** | **Mapped REQs**: `REQ-14`.
  * **Scope**: Anti-join views hiding active candidate profiles from blocked employers and competitors.
* **F-04: Multi-Tenant Row-Level Security Isolation**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-13`.
  * **Scope**: PostgreSQL RLS policies filtering all requisition and candidate queries by session variable `app.current_org_id`.
* **F-05: Multi-Branch Location Hierarchy**
  * **Classification**: **Should-Have** | **Mapped REQs**: `REQ-05`, `REQ-13`.
  * **Scope**: Recursive parent-subsidiary enterprise organization structures with cycle detection triggers.

### Pillar 2: Sourcing, Screening & Assessment
* **F-06: Candidate Skill Vector Profile**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-06`, `REQ-24`.
  * **Scope**: Parsed resume skill extraction, GIN trigram indexing, and sub-10ms similarity searches across 1M profiles.
* **F-07: Structured Application Assessment Trees**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-07`, `REQ-08`.
  * **Scope**: Versioned questionnaires with weighted question scoring and automated candidate qualification benchmarks.
* **F-08: Consultant Sourcing Marketplace**
  * **Classification**: **Differentiator** | **Mapped REQs**: `REQ-04`, `REQ-17`.
  * **Scope**: Split-commission candidate representation allowing third-party agencies to submit talent for bounty fees.

### Pillar 3: Candidate Monetization & Enterprise Licensing
* **F-09: Resume Unlock Quota & Metering**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-18`.
  * **Scope**: Atomic resume contact unlock logging with automated monthly download credit deductions.
* **F-10: Tiered Enterprise Licensing**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-19`.
  * **Scope**: Enterprise subscription tiers (`ENTERPRISE`, `PRO`, `STARTER`) enforcing hard recruiter seat limits.

### Pillar 4: Financial Ledger & Billing
* **F-11: Double-Entry Immutable Wallet Ledger**
  * **Classification**: **Differentiator** | **Mapped REQs**: `REQ-04`, `REQ-17`.
  * **Scope**: Append-only transaction log (`CREDIT`/`DEBIT`) protected by exception triggers on update and delete.
* **F-12: Automated Running Balance Synchronization**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-17`.
  * **Scope**: Database trigger automatically recalculating `wallet_account.current_cleared_balance` from posted ledger rows.

### Pillar 5: Contingent Gig Marketplace
* **F-13: Gig Profile & Verified Trade Showcase**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-05`, `REQ-20`.
  * **Scope**: Independent freelancer profiles with multi-tier billing rates, ratings, and verified skill badges.
* **F-14: GiST Conflict-Free Contract Scheduling**
  * **Classification**: **Differentiator** | **Mapped REQs**: `REQ-15`.
  * **Scope**: PostgreSQL `GiST` exclusion constraint guaranteeing zero overlapping contract dates for active workers.
* **F-15: Milestone Escrow Governance**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-04`, `REQ-17`.
  * **Scope**: Escrow fund locking upon gig contract award and atomic release upon client milestone sign-off.

### Pillar 6: Compliance, Engagement & Analytics
* **F-16: Append-Only Compliance Audit Logging**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-09`, `REQ-11`.
  * **Scope**: Forensic logging of all critical mutations with pre/post JSONB snapshots, actor IDs, and client IP addresses.
* **F-17: DPDP 2023 Consent Lifecycle Management**
  * **Classification**: **Must-Have** | **Mapped REQs**: `REQ-10`.
  * **Scope**: Purpose-bound consent tracking with affirmative grant timestamps, revocation triggers, and key shredding.
* **F-18: Candidate Referral Program & Attribution**
  * **Classification**: **Should-Have** | **Mapped REQs**: `REQ-23`.
  * **Scope**: Alphanumeric referral code generation, application source attribution, and automated referral bonus payouts.
* **F-19: Campus Cohort Management**
  * **Classification**: **Should-Have** | **Mapped REQs**: `REQ-22`.
  * **Scope**: Bulk campus candidate ingestion, academic degree filters, and early-career placement drive pipelines.
* **F-20: Executive Recruitment Analytics Marts**
  * **Classification**: **Should-Have** | **Mapped REQs**: `REQ-24`.
  * **Scope**: High-performance aggregate reporting marts computing time-to-hire velocity and pipeline drop-off metrics.
