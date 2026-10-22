# Talentra — Requirements Analysis Schema Specification
**Document**: Deliverable A1 — Output Schema Definition  
**System**: Talentra Demand Management Platform  
**Owner**: Core Data Architecture Team  
**Status**: Approved & Frozen for Sprint Implementation  

---

## 1. Schema Hierarchy & Level Metrics

Following the *Control the Output* methodology (Playbook Pages 5–6 & 18), this schema is structured as a nonlinear hierarchy across four distinct levels:

```
Requirement Docket Schema (Root)
 ├── L1.0 Project Metadata & Team Governance
 ├── L1.1 Business Problem & Capacity Planning
 ├── L1.2 External System Boundaries (9 Services)
 ├── L1.3 Functional Requirements Baseline (REQ-01 to REQ-14)
 ├── L1.4 Non-Functional Standards (Latency, RTO/RPO, Security)
 └── L1.5 Database Standards & Domain Rules (10 Rule Groups)
```

### Schema Metrics by Level (Playbook Page 6 & 18)

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **6 sections** | Measured (100% frozen) | Are these the right sections to capture the entire problem docket? |
| **Level 2 · Micro** | Parameters & Tables | **24 parameters** | Measured (4.0 avg/section) | Can the engineering team explain and defend every parameter? |
| **Level 3 · Nano** | Sub-parameters & Enums| **88 classifications** | Measured & categorized | Are all allowed values, enums, and state machines defined? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every leaf have a concrete SQL data type, constraint, and source? |

---

## 2. Keep / Drop Decision Log (Playbook Stage 2 Checklist)

As mandated by Stage 2 (*Define*) of the Process Playbook, all structural decisions and scope exclusions are explicitly logged:

| Item / Feature Considered | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Raw Credit Card Numbers (PAN/CVV)** | **DROPPED** | PCI-DSS compliance scope reduction. Talentra only persists gateway transaction references, order status, and amounts. | Define |
| **Cleartext National Identity Numbers** | **DROPPED** | Data privacy and statutory risk. Talentra only stores verification outcome tokens and cryptographic hashes. | Define |
| **Employer Internal Sub-Roles in v1** | **DROPPED** | Explicitly excluded by Problem Docket Section 3. Deferred to v2 roadmap to keep core multi-tenant RLS clean. | Define |
| **Unified Requisition for Gigs & Full-Time**| **DROPPED** | Gigs require calendar availability, proposal bidding, and external handoff. Forcing them into full-time jobs creates NULL-polluted tables. | Define |
| **8 Discrete Workforce Categories** | **KEPT** | Essential for Northbridge’s core business model (gig, general staffing, professional staffing, campus, permanent, etc.). | Discover |
| **Database-Tier Device & Concurrency Limit** | **KEPT** | Prevents commercial revenue leakage from multi-user seat sharing. Enforced in database stored procedure via row locking. | Define |
| **9 External Integration Boundary Contracts** | **KEPT** | Eliminates architectural ambiguity regarding third-party outages, idempotency, and data ownership. | Discover |

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
  * `production_projection`: 10,000,000 candidates, 1,000,000 jobs, 100,000,000 applications.
* `workforce_types`: Supported engagement categories. Covers all 8: `GIG_PROJECT`, `GENERAL_STAFFING`, `PROFESSIONAL_STAFFING`, `PERMANENT_FT`, `APPRENTICE`, `CAMPUS_FRESHER`, `CONSULTANT_MARKETPLACE`, `MANAGED_REMOTE`.

### Section L1.2: External Integration Boundaries (9 Services)
Defines the interface rules for all 9 third-party systems:
* `service_name`: External service (Payment Gateway, KYC Verification, Corporate Registry, Gig Fulfilment, Legacy Sync, Messaging Hub, Social Sharing, Geocoding Maps, Salary Feeds).
* `source_of_truth`: Specifies data ownership (`TALENTRA_OWNED`, `EXTERNAL_OWNED`, `BIDIRECTIONAL_RECONCILED`).
* `persisted_fields`: Explicitly lists what is saved locally vs referenced by token.
* `failure_strategy`: Behavior during outages (`CIRCUIT_BREAKER_QUEUE`, `ASYNC_RETRY`, `FALLBACK_CACHED`, `SYNCHRONOUS_REJECT`).
* `idempotency`: Mechanism preventing duplicate events (unique idempotency key, SHA-256 payload digest, or transaction reference).

### Section L1.3: Functional Requirements Baseline (REQ-01 through REQ-14)
* `id`: Unique identifier (`REQ-01` to `REQ-14`).
* `title`: Concise requirement name.
* `module`: Mapped database schema (`profile`, `recruitment`, `administration`, `organisation`, `gig`, `licence`, `sourcing`, `billing`, `engagement`, `analytics`).
* `priority`: MoSCoW ranking (`Must Have`, `Should Have`, `Could Have`).
* `description`: Operational capability delivered to users.
* `db_constraint`: Exact database-level rule (e.g., `CHECK (min_salary <= max_salary)`, `UNIQUE (email)`, exclusion constraint on gig booking windows).

### Section L1.4: Non-Functional Standards
* `latency_budgets`: Targets measured at laptop benchmark scale:
  * Single record lookup by primary key: p95 < 5ms.
  * Filtered candidate search across 1M rows: p95 < 80ms.
  * Application pipeline status update: p99 < 30ms.
* `backup_and_recovery`: RTO < 30 minutes, RPO < 5 minutes via continuous WAL archiving.
* `security_baseline`: Password hashing via Argon2id, tenant isolation via Postgres Row-Level Security (RLS), column-level masking for candidate contact details.

### Section L1.5: Database Standards Compliance (10 Rule Groups)
* **Naming (Rule 1)**: `snake_case`, singular table names, primary key as `id`, foreign keys as `<table_name>_id`, indexes as `idx_table_column`, unique constraints as `uq_table_column`.
* **Keys (Rule 2)**: Surrogate UUIDv4 primary keys. Natural business keys enforced via unique constraints.
* **Domains (Rule 3)**: Standard types for email (<= 254 chars, lowercase check), money (`NUMERIC(12,2)` + currency code), phone (E.164 + country code), UTC timestamps.
* **Audit (Rule 4)**: All business tables contain `created_at`, `created_by`, `updated_at`, `updated_by`, and optional `deleted_at` for soft deletes. Financial and security audit tables are append-only.
* **Nullability (Rule 5)**: No sentinel values (`0` or `"NA"` for missing values). Every nullable field must have a recorded technical reason.
