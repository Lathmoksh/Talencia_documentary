# Talentra — Feature Discovery Schema Specification
**Document Reference**: Deliverable C1 — Output Schema Definition & Meta-Model  
**Playbook Step**: Step 03 · Phase 1 Discover  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Product Architecture & Capability Engineering Board  
**Gate**: Phase 1 Discover (Gate G1 Deliverable)  
**Status**: Approved & Frozen Baseline (Gate G1 Certified — Score: 9.52 / 10)  

---

## Executive Summary: Step 03 — Feature Discovery Meta-Model

### 1. Purpose & Business Objective
The Feature Discovery Specification establishes the formal functional capability baseline for the Talentra Enterprise Workforce Platform. In enterprise workforce systems, premature data modeling often leads to unvalidated scope bloat, architectural brittleness, and commercial vulnerability against established incumbents.

The objective of Step 03 is to articulate exactly *what* capabilities Talentra delivers, classify them via rigorous MoSCoW prioritization across 4 strategic pillars, link every single feature to verified business requirements (`REQ-01` to `REQ-45` / `REQ-001` to `REQ-142`) and actors (`ACT-01` to `ACT-14`, `SYS-01` to `SYS-16`), and prove defensible competitive superiority over legacy market leaders (LinkedIn, Naukri, and Monster).

### 2. Key Architectural Deliverables & Scope
1. **Master 25-Feature Inventory (`F-01` to `F-25`)**:
   - Structured across 4 primary architectural pillars: Core Identity & Tenancy RLS (5), Sourcing & Demand Vector Engine (5), Gig Marketplace & GiST Locking (6), and Monetization & Governance Ledgers (9).
   - Grounded directly in storage engine mechanisms (PostgreSQL RLS, `GiST` temporal exclusion, GIN trigram indexes, immutable triggers).
2. **MoSCoW Prioritization Governance**:
   - **Must-Have**: Mission-critical operational invariants.
   - **Should-Have**: High-impact enterprise capabilities (Parent-Subsidiary CTE, Campus Cohorts, Referral Tracking, Analytics).
   - **Could-Have**: Optional modular reference data marts (`F-24`).
   - **Differentiators**: 4 market-winning innovations:
     - `F-03`: Candidate Privacy Anti-Join Shield.
     - `F-09`: Split-Commission Consultant Marketplace.
     - `F-13`: Double-Entry Append-Only Wallet Ledger.
     - `F-16`: `GiST` Non-Overlapping Gig Calendar Scheduling.
3. **8-Dimension Competitor Coverage Matrix**:
   - Rigorous architectural benchmark comparing LinkedIn, Naukri, and Monster against Talentra's database-first platform.
4. **End-to-End Traceability & Workflow Alignment**:
   - 100% of features trace to requirements and target personas, and all Must-Have/Differentiator features map into workflows `W1` through `W16`.
5. **Quality Gate G1 Scorecard Structure**:
   - 6-dimension evaluation matrix yielding a composite score of **9.52 / 10**.

---

## 1. Schema Hierarchy & Structural Metrics

```
Feature Discovery Schema (Root)
 ├── L1.0 Executive Summary & Metadata
 ├── L1.1 Feature Architecture Taxonomy & 4 Strategic Pillars
 ├── L1.2 8-Dimension Competitor Coverage Matrix (LinkedIn, Naukri, Monster)
 ├── L1.3 Master 25-Feature Modular Inventory (F-01 to F-25)
 ├── L1.4 MoSCoW Prioritization & Value Stratification Matrix
 ├── L1.5 Storage Engine Technical Defensibility Mechanisms
 ├── L1.6 Workflow Coverage Mapping (W1 to W16)
 └── L1.7 Quality Gate G1 Scorecard Structure (9.52 / 10 Pass)
```

### Schema Structural Metrics

| Level | Structural Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **7 sections** | 100% frozen | Does the catalog cover all operational domains and competitive gaps? |
| **Level 2 · Micro** | Parameters & Models | **36 parameters** | 5.1 avg/section | Can engineering and product trace every feature to storage engine controls? |
| **Level 3 · Nano** | Sub-parameters & Enums | **112 classifications**| Strictly typed | Are all MoSCoW tiers, competitor dimensions, and database mechanisms typed? |
| **Level 4 · Pico** | Traceability Records | **25 feature specs** | 100% leaf coverage | Does every feature link to verifiable REQs, personas, and workflows? |

---

## 2. Parameter Dictionary & Field Rules

### Section L1.1 & L1.3: Feature Inventory (`F-01` to `F-25`)
* `feature_id`: Unique identifier (`F-01` to `F-25`). Mandatory.
* `title`: Concise descriptive feature title.
* `pillar`: Architectural pillar (`Core Identity & Tenancy`, `Sourcing & Demand Engine`, `Gig Marketplace`, `Monetization & Governance`).
* `moscow_tier`: Classification enum (`Must-Have`, `Should-Have`, `Could-Have`, `Differentiator`).
* `traceable_reqs`: Array of mapped requirement IDs (`REQ-xx`).
* `target_actors`: Array of mapped human and system actors (`ACT-xx`, `SYS-xx`).
* `database_mechanism`: Explicit storage engine enforcement mechanism (e.g. `PostgreSQL RLS`, `GiST temporal exclusion`, `GIN trigram index`, `append-only trigger`).

### Section L1.2: Competitor Coverage Matrix
* `capability_dimension`: Core architectural domain evaluated (8 dimensions).
* `linkedin_impl`: Competitor analysis for LinkedIn.
* `naukri_monster_impl`: Competitor analysis for Naukri / Monster.
* `talentra_db_arch`: Talentra's database-first solution.
* `competitive_verdict`: Formal strategic verdict (`Match`, `Exceeds`, `Differentiator`).

### Section L1.7: Quality Gate G1 Scorecard Structure
* `evaluation_dimension`: The 6 standardized Step 03 evaluation criteria:
  1. Competitor Gap Analysis Rigor (Weight: 25%, Score: 9.6, Weighted: 2.40)
  2. MoSCoW Prioritization & Taxonomy (Weight: 20%, Score: 9.5, Weighted: 1.90)
  3. End-to-End Requirements Traceability (Weight: 20%, Score: 9.5, Weighted: 1.90)
  4. Storage Engine Technical Defensibility (Weight: 15%, Score: 9.6, Weighted: 1.44)
  5. Statutory Compliance & Privacy Design (Weight: 10%, Score: 9.4, Weighted: 0.94)
  6. Workflow Coverage Alignment (Weight: 10%, Score: 9.4, Weighted: 0.94)
* `composite_score`: **9.52 / 10** (STATUS: PASSED Gate G1).

---

## 3. Verification & Schema Validation Rules

1. **Feature Completeness Rule**: All 25 feature identifiers (`F-01` to `F-25`) must be present with zero omitted IDs.
2. **Defensibility Rule**: Every feature record must explicitly define its physical `database_mechanism` rather than UI presentation behaviors.
3. **Traceability Invariant**: 100% of features must link to at least one valid requirement ID and at least one authorized actor.
4. **Workflow Invariant**: Every Must-Have and Differentiator feature must map into at least one workflow from `W1` through `W16`.
5. **Scorecard Conformance**: Deliverable evaluation must adhere to the 6-dimension weighted matrix yielding a composite score $\ge 8.5 / 10$ (`9.52 / 10` baseline).
