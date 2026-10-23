# Talentra — Feature Discovery Schema Specification
**Document**: Deliverable C1 — Output Schema Definition  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Product Architecture & Capability Engineering Team  
**Status**: Approved & Frozen for Sprint Implementation  

---

## 1. Schema Hierarchy & Level Metrics

```
Feature Discovery Schema (Root)
 ├── L1.0 Market Context & Competitive Benchmarking
 ├── L1.1 Competitor Gap Analysis (What Competitors Lack & Why It Matters)
 ├── L1.2 Modular Feature Inventory (F-01 to F-20 across 6 Pillars)
 ├── L1.3 MoSCoW Prioritization & Value Matrix
 └── L1.4 Physical Database Implementation Mechanisms
```

### Schema Metrics & Structural Hierarchy

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **5 sections** | Measured (100% frozen) | Do these features cover all market opportunities and competitive gaps? |
| **Level 2 · Micro** | Parameters & Models | **24 parameters** | Measured (4.8 avg/section) | Can the product and data teams build and defend every capability? |
| **Level 3 · Nano** | Sub-parameters & Enums | **76 classifications** | Measured & categorized | Are all MoSCoW tiers, competitor codes, and database mechanics typed? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every feature translate to an executable DDL table, view, or constraint? |

---

## 2. Scope & Architectural Decision Log

| Item / Feature Considered | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Siloed Gig vs Full-Time Database Architecture** | **DROPPED** | Major legacy platform defect. Talentra unifies all workforce categories under a single multi-tenant account structure. | Product Architecture |
| **Client-Side Conflict Checking for Gigs** | **DROPPED** | Prone to concurrency race conditions. Enforced via PostgreSQL `GiST` exclusion constraint at the storage engine. | Database Lead |
| **Competitor Gap Argumentation** | **KEPT** | Essential for commercial defensibility. Explicitly documents why LinkedIn, Naukri, and Monster fail at key capabilities. | Strategy Lead |
| **Strict MoSCoW Prioritization** | **KEPT** | Guarantees clear sprint boundaries: 13 Must-Haves, 4 Should-Haves, and 3 high-impact Differentiators. | Product Management |
| **In-Database Double-Entry Wallet Ledger** | **KEPT** | Eliminates external batch reconciliation discrepancies and ensures instant, verifiable balance auditing. | Financial Lead |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0 & L1.1: Market Context & Competitor Gap Analysis
* `dimension_name`: Evaluated capability dimension (e.g. Dual-Track Workforce, Concurrency Guard).
* `legacy_competitor_coverage`: Summary of competitor implementations (LinkedIn, Naukri, Monster).
* `talentra_implementation`: Concrete technical approach.
* `competitor_lack_argument`: Explicit architectural and commercial defense of why competitors lack this capability and why that gap matters.

### Section L1.2 & L1.3: Modular Feature Inventory & MoSCoW Classification
* `feature_id`: Unique identifier (`F-01` to `F-20`).
* `title`: Canonical feature title.
* `pillar`: Strategic category (`IDENTITY`, `SOURCING`, `MONETIZATION`, `BILLING`, `GIG`, `GOVERNANCE`).
* `moscow_priority`: Priority tier (`Must-Have`, `Should-Have`, `Differentiator`).
* `mapped_requirements`: Array of `REQ-xx` identifiers satisfied by this feature.
* `db_implementation_mechanism`: Physical PostgreSQL entity, constraint, or stored procedure.
