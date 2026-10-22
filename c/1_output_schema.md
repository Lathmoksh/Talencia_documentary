# Talentra — Feature Discovery Schema Specification
**Document**: Deliverable C1 — Output Schema Definition  
**System**: Talentra Demand Management Platform  
**Owner**: Product & Database Engineering  
**Status**: Approved Baseline  

---

## 1. Schema Hierarchy & Level Metrics

Following the *Control the Output* methodology (Playbook Pages 5–6 & 18), this schema organizes candidate platform features, competitive benchmarks, and physical database mappings into a 4-level nonlinear hierarchy:

```
Feature Discovery Schema (Root)
 ├── L1.0 Project Metadata & Governance
 ├── L1.1 Discovery Approach & MoSCoW Prioritization
 ├── L1.2 Feature Catalog (20 Functional Capabilities)
 ├── L1.3 Competitive Coverage Benchmark (LinkedIn, Naukri, Monster)
 ├── L1.4 Database Subsystem Mappings (11 PostgreSQL Schemas)
 └── L1.5 Quality Verification Scenarios (SQL Invariant Tests)
```

### Schema Metrics by Level (Playbook Page 6 & 18)

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **5 sections** | Measured (100% frozen) | Does the structure cover discovery, benchmarking, and database mapping? |
| **Level 2 · Micro** | Parameters & Models | **24 parameters** | Measured (4.8 avg/section) | Can the engineering team explain every feature, priority, and constraint? |
| **Level 3 · Nano** | Sub-parameters & Enums| **85 classifications** | Measured & categorized | Are all MoSCoW tags, competitor ratings, and table entities defined? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every feature map directly to relational tables and physical constraints? |

---

## 2. Keep / Drop Decision Log (Playbook Stage 2 Checklist)

As mandated by Stage 2 (*Define*) of the Process Playbook, all structural decisions and scope exclusions are explicitly logged:

| Item / Feature Considered | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Algorithmic Social Doom-Scrolling Feed**| **DROPPED** | Competitor pitfall. Algorithmic newsfeeds cause engagement distraction and balloon storage costs. Talentra focuses strictly on hiring pipeline throughput and structured technical Q&A. | Define |
| **Linear Unweighted Screening Questions** | **DROPPED** | Found in basic job portals. Inadequate for enterprise pre-qualification. Talentra implements versioned option trees with knockout rules and automated scoring. | Define |
| **Separate Blue-Collar & White-Collar Portals**| **DROPPED** | Competitor fragmentation (e.g. Naukri vs specialist boards). Talentra unifies all 8 workforce categories in a single relational schema. | Define |
| **20 Concrete Enterprise Features (F-01 to F-20)**| **KEPT** | Directly satisfies the workflows and data domains from Problem Docket Sections 2 and 4. | Discover |
| **3-Competitor Benchmarking Matrix** | **KEPT** | Directly fulfills Problem Docket Section 4 mandate to benchmark against LinkedIn, Naukri, and Monster. | Discover |
| **PostgreSQL GiST Non-Overlapping Gig Calendar**| **KEPT** | Prevents gig worker double-booking at the database engine tier via exclusion constraints. | Define |
| **Double-Entry Append-Only Wallet Ledger** | **KEPT** | Prevents financial tampering and dispute leakage. Reversals must reference original transaction IDs. | Define |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0: Project Metadata & Governance
* `document_id`: Unique identifier (`TAL-FEA-0001`). Required.
* `version`: Semantic version (`MAJOR.MINOR.PATCH`). Required.
* `author`: Product & database systems lead.
* `reviewer`: Senior database architect.
* `status`: Approval state (`Approved Baseline`).

### Section L1.1: Discovery Approach & Criteria
* `workflow_sources`: Workflows derived from Section 2 of the Hackathon Docket (Candidate profile building, screening questionnaires, consultant sourcing, gig bidding, wallet recharge).
* `prioritization_framework`: MoSCoW rules:
  * **Must Have**: Non-negotiable core transactional capabilities, security boundaries, and billing controls.
  * **Should Have**: Expected community, support ticketing, and referral growth features.
  * **Could Have**: Optional market salary benchmarks and administrative feature flags.

### Section L1.2: Feature Catalog (20 Capabilities)
* `id`: Feature key (`F-01` to `F-20`).
* `name`: Concise title (e.g., "Structured Screening Questionnaires").
* `description`: Operational capability delivered to users.
* `priority`: MoSCoW enum (`Must Have`, `Should Have`, `Could Have`).
* `target_actor`: Primary persona utilizing the feature (`Candidate`, `Employer`, `Recruiter`, `Consultant`, `Gig Worker`, `TPO`, `Admin`).
* `business_value`: Commercial or user retention impact (`Core Platform Liquidity`, `Monetization`, `Retention`, `Compliance`).
* `database_module`: Mapped schema (`profile`, `recruitment`, `organisation`, `gig`, `licence`, `billing`, `engagement`, `analytics`).

### Section L1.3: Competitive Coverage Benchmark
Direct comparison of candidate and employer data elements against three benchmark platforms:
* `capability`: Specific dimension being evaluated (Multi-Category Workforce, Pre-Qualification, Concurrency Enforcement, Financial Auditability, Candidate Privacy, Localization, Social Sprawl).
* `talentra_approach`: Talentra's database-backed capability.
* `linkedin_approach`: LinkedIn's documented capability.
* `naukri_approach`: Naukri's documented capability.
* `monster_approach`: Monster / Foundit's documented capability.
* `verdict`: Evaluation outcome (`Exceeds`, `Matches`, `Deliberately Diverges`).

### Section L1.4: Database Subsystem Mappings
Maps features directly to physical database objects:
* `module`: Relational schema name.
* `owned_features`: List of feature IDs implemented in this module.
* `tables`: Specific singular table names.
* `key_constraints`: Concrete SQL constraints enforcing business invariants (GiST date range exclusions, append-only triggers, unique composite indexes).

### Section L1.5: Acceptance Invariant Scenarios
Testable criteria verifying feature compliance at the database tier:
* `test_id`: Scenario key (`ACC-01` to `ACC-05`).
* `feature_id`: Related feature.
* `scenario`: Business rule being validated.
* `expected_db_invariant`: Exact SQL error or data state (`exclusion_violation`, automatic atomic status update, balance synchronization).
