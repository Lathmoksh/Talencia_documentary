# Talentra — Requirements Analysis Schema Specification
**Document**: Deliverable A1 — Output Schema Definition  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Data Architecture Team  
**Status**: Approved & Frozen for Sprint Implementation  

---

## 1. Schema Hierarchy & Level Metrics

This schema is structured as an architectural hierarchy across four distinct levels:

```
Requirement Docket Schema (Root)
 ├── L1.0 Project Metadata & Team Governance
 ├── L1.1 Business Problem & Capacity Planning
 ├── L1.2 In-Scope vs Explicit Out-of-Scope System Boundaries
 ├── L1.3 Ranked Architectural Open Questions & Risk Mitigations
 ├── L1.4 Functional Requirements Baseline (REQ-01 to REQ-25)
 ├── L1.5 Non-Functional Standards (Latency Budgets, RTO/RPO, Cryptography)
 └── L1.6 Database Standards Compliance (10 Rule Groups)
```

### Schema Metrics & Structural Hierarchy

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **7 sections** | Measured (100% frozen) | Are all architectural domains, boundaries, and questions accounted for? |
| **Level 2 · Micro** | Parameters & Models | **28 parameters** | Measured (4.0 avg/section) | Can the engineering team explain every requirement, actor, and boundary? |
| **Level 3 · Nano** | Sub-parameters & Enums | **92 classifications** | Measured & categorized | Are all priority codes, sources, and ambiguity resolutions typed? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every leaf map to a concrete SQL data type, constraint, and check rule? |

---

## 2. Scope & Architectural Decision Log

| Item / Feature Considered | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Raw Credit Card Numbers (PAN/CVV)** | **DROPPED** | PCI-DSS scope elimination. Talentra only persists gateway transaction references, order status, and amounts. | Architecture |
| **Cleartext National Identity Numbers** | **DROPPED** | Statutory data privacy compliance. Replaced with AES-256-GCM encryption and HMAC-SHA256 blind indexing for equality lookups. | Security Eng |
| **Employer Internal Sub-Roles in v1** | **DROPPED** | Excluded in initial baseline to keep multi-tenant RLS clean and performant; scheduled for v2 roadmap. | Architecture |
| **Unified Requisition for Gigs & Full-Time**| **DROPPED** | Gigs require calendar availability, proposal bidding, and milestone payouts. Forcing them into full-time jobs creates NULL-polluted tables. | Architecture |
| **8 Discrete Workforce Categories** | **KEPT** | Essential for Northbridge's core business model (gig, general staffing, professional staffing, campus, permanent, etc.). | Requirements |
| **Database-Tier Device & Concurrency Limit** | **KEPT** | Prevents commercial seat sharing. Enforced in database stored procedure via session locking. | Security Eng |
| **9 External Integration Boundary Contracts** | **KEPT** | Eliminates architectural ambiguity regarding third-party outages, idempotency, and data ownership. | Integration Eng |
| **Ranked Open Questions with Concrete Resolutions**| **KEPT** | Replaces vague assumptions with mathematical CTE cycle prevention, GiST non-overlap constraints, and anti-joins. | Architecture |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0: Project Metadata & Governance
* `docket_id`: Unique document reference (Text, regex `^TAL-REQ-[0-9]{4}$`). Required.
* `version`: Semantic version string (`MAJOR.MINOR.PATCH`). Required.
* `author`: Name and role of the technical author.
* `reviewer`: Name and role of the reviewing senior architect.
* `status`: Document approval state (`Draft`, `In Review`, `Approved`, `Superseded`).

### Section L1.1: Business Problem & Capacity Planning
* `problem_summary`: Description of legacy system fragmentation, candidate drop-off, and pipeline invisibility. Max 2,000 characters.
* `target_scale`: Structured capacity metrics:
  * `laptop_benchmark`: 1,000,000 candidate profiles, 100,000 job openings, 5,000,000 applications.
  * `production_projection`: 10,000,000 to 50,000,000 candidates, 1,000,000 to 5,000,000 jobs, 50,000,000 to 100,000,000 applications.
* `workforce_types`: Supported engagement categories. Covers all 8: `GIG_PROJECT`, `GENERAL_STAFFING`, `PROFESSIONAL_STAFFING`, `PERMANENT_FT`, `APPRENTICE`, `CAMPUS_FRESHER`, `CONSULTANT_MARKETPLACE`, `MANAGED_REMOTE`.

### Section L1.2: In-Scope vs Out-of-Scope System Boundaries
* `domain_name`: Operational domain name.
* `in_scope_responsibilities`: Explicit platform capabilities.
* `out_of_scope_boundary`: Clear demarcation of delegated external functionality.

### Section L1.3: Ranked Architectural Open Questions
* `question_rank`: Relative design priority (`Q1` to `Q5`).
* `architectural_question`: Detailed technical uncertainty.
* `impact_level`: Severity rating (`Critical`, `High`, `Medium`).
* `architectural_resolution`: Physical database solution (e.g. recursive CTE cycle checks, GiST exclusion constraints).

### Section L1.4: Functional Requirements Baseline (REQ-01 through REQ-25)
* `req_id`: Unique identifier (`REQ-01` to `REQ-25`).
* `statement`: Concise operational capability.
* `architectural_source`: Provenance category (`Core Invariant`, `Domain Sourcing`, `Domain Gig`, `Core Security`, `Statutory Mandate`, `Performance SLA`, `Infrastructure`).
* `priority`: MoSCoW ranking (`Must-Have`, `Should-Have`, `Could-Have`).
* `target_actors`: Array of authorized user roles (`Candidate`, `Recruiter`, `Admin`, `Gig Worker`, `Auditor`, `System`).
* `ambiguity_resolution`: Concrete numerical metric or constraint replacing subjective adjectives.

### Section L1.5: Non-Functional Standards
* `latency_budgets`: Warm-cache targets at 1M profile scale:
  * Single record lookup by PK: p95 < 0.20 ms.
  * Filtered candidate search with privacy guard: p95 < 10.0 ms.
  * Application submission with questionnaire: p95 < 5.0 ms.
* `backup_and_recovery`: RTO < 15 minutes, RPO < 1 minute via continuous WAL archiving and synchronous standby streaming.
* `security_baseline`: Password hashing via Argon2id, tenant isolation via PostgreSQL Row-Level Security (RLS), column-level encryption for sensitive PII.

### Section L1.6: Database Standards Compliance (10 Rule Groups)
* **Naming**: `snake_case`, singular table names, primary key as `id`, foreign keys as `<table_name>_id`.
* **Keys**: Surrogate UUIDv4 primary keys. Natural business keys enforced via unique constraints.
* **Domains**: Standard types for email (canonical lowercase), money (`NUMERIC(12,2)` + currency code), phone (E.164 standard), UTC timestamps.
* **Audit**: All business tables contain `created_at`, `created_by`, `updated_at`, `updated_by`, and soft-delete column `deleted_at`.
* **Nullability**: No arbitrary sentinels (`0` or `"NA"` for missing values). Nullable columns require documented justification.
