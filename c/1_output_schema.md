# Talentra — Feature Discovery Schema Specification
**Document Reference**: Deliverable C1 — Output Schema Definition & Meta-Model  
**Step / Activity**: Step 03 — Feature Discovery  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Product Architecture & Capability Engineering Board  
**Gate**: Phase 1 Discover (Gate G1 Deliverable)  
**Status**: Approved & Frozen Baseline  

---

## Executive Summary: Step 03 — Feature Discovery

### 1. Purpose & Business Objective
The Feature Discovery Specification establishes the formal functional capability baseline for the Talentra Enterprise Workforce Platform. In contemporary enterprise software engineering, premature system modeling often leads to feature bloat, unvalidated assumptions, and commercial misalignment against market competitors.

The objective of Step 03 is to articulate exactly *what* capabilities Talentra delivers, classify them via rigorous MoSCoW prioritization, link every single feature to verified business requirements (`REQ-01` to `REQ-29`), and demonstrate undeniable competitive superiority over legacy market leaders (LinkedIn Talent Solutions, InfoEdge Naukri, Monster Worldwide, and Upwork Enterprise).

### 2. Key Architectural Deliverables & Scope
1. **23 User-Facing Platform Features (`F-01` to `F-23`)**:
   - Structured across 7 strategic pillars: Identity & Authentication (1), Tenancy & Governance (2), Privacy & Compliance (2), Recruitment & Application Pipeline (5), Sourcing & Assessments (3), Licensing & Billing (4), Contingent Gig Labor (3), and Candidate Engagement & Discovery (3).
   - Every feature record provides an explicit `trace_note` documenting exactly how it fulfills its mapped requirements.
2. **MoSCoW Prioritization Governance**:
   - **17 Must-Have Features**: Foundational capabilities essential for Day-1 minimum viable platform operation.
   - **2 Should-Have Features**: High-value enhancements scheduled for early sprint inclusion (Tracked Referrals, Campus Batch Cohorts).
   - **4 Strategic Differentiators**: Unique commercial capabilities that distinguish Talentra from market competitors:
     - `F-03` Candidate Privacy Shield (anti-join employer masking).
     - `F-08` Consultant Sourcing Marketplace (agency split bounties with 180-day lock).
     - `F-11` Corporate Prepaid Wallet & Milestone Escrow (zero-variance double-entry accounting).
     - `F-14` Conflict-Free Freelance Calendar Booking (concurrency-safe temporal exclusion).
3. **15-Dimension Competitor Coverage Benchmark**:
   - Comprehensive comparative matrix evaluating LinkedIn, Naukri, Monster, and Upwork.
   - Provides concrete per-competitor verdicts (`Supported`, `Partial`, `Absent`), access verification dates (2026-10-23), live deep documentation links, and commercial impact justifications.

---

## 1. Schema Hierarchy & Structural Metrics

This schema defines the formal structure required for the Feature Discovery Docket across five nested levels:

```
Feature Discovery Schema (Root)
 ├── L1.0 Executive Summary & Strategic Architecture Pillars
 ├── L1.1 15-Dimension Competitive Coverage Benchmark & Market Gaps
 ├── L1.2 Master 23-Feature Modular Inventory (F-01 to F-23)
 ├── L1.3 MoSCoW Prioritization & Value Stratification Matrix
 └── L1.4 Feature-to-Requirement Traceability & Boundary Linkages
```

### Schema Structural Metrics

| Level | Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **5 sections** | 100% frozen | Does the inventory cover all core market needs and competitive differentiators? |
| **Level 2 · Micro** | Parameters & Models | **26 parameters** | 5.2 avg/section | Can the engineering and product teams trace every feature back to a business requirement? |
| **Level 3 · Nano** | Sub-parameters & Enums | **92 classifications** | Categorized & typed | Are all MoSCoW tiers, competitor verdicts, and category pillars typed? |
| **Level 4 · Pico** | Traceability Records | **23 trace notes** | 100% leaf coverage | Does every feature explicitly explain its satisfaction of mapped requirement IDs? |

---

## 2. Scope & Strategic Differentiation Decisions

| Capability Dimension | Decision | Architectural Rationale & Justification | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Siloed Gig vs. Full-Time Platforms** | **DROPPED** | Major legacy platform defect. Talentra unifies full-time hiring, contingent gigs, and campus cohorts under one corporate account. | Product Architecture |
| **Client-Side Freelance Conflict Checking** | **DROPPED** | Prone to network race conditions. Validated via temporal non-overlapping exclusion rules at the storage engine tier. | Lead Systems Architect |
| **Unsubstantiated Competitor Claims** | **DROPPED** | Anti-pattern. Every competitor comparison requires live deep links, access dates, and explicit commercial gap justifications. | Strategy Board |
| **Strict MoSCoW Prioritization** | **KEPT** | Eliminates sprint scope creep by categorizing 17 Must-Haves, 2 Should-Haves, and 4 high-impact Differentiators. | Technical Product Lead |
| **Explicit Requirement Trace Notes** | **KEPT** | Guarantees complete bidirectional transparency between functional features and pure business requirements. | QA Architecture |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0 & L1.1: Strategic Pillars & Competitive Benchmark
* `capability_area`: Evaluated platform capability dimension (15 total).
* `talentra_capability`: Formal statement of Talentra's operational implementation.
* `competitor_verdict`: Explicit evaluation code (`✓ Supported`, `Partial`, `✗ Absent`).
* `competitor_deep_link`: Direct HTTP URL to public documentation or product pricing.
* `access_date`: Verification timestamp (ISO date `2026-10-23`).
* `competitor_gap_argument`: Commercial and architectural justification of why competitors lack this capability and why that gap matters to enterprise clients.

### Section L1.2 & L1.3: Master 23-Feature Inventory (F-01 to F-23)
* `feature_id`: Unique identifier (`F-01` to `F-23`). Mandatory.
* `feature_title`: Canonical name of the platform capability.
* `category`: Strategic architectural pillar (`Identity`, `Tenancy`, `Privacy`, `Recruitment`, `Sourcing`, `Licensing`, `Billing`, `Gig`, `Governance`, `Engagement`).
* `moscow`: Priority tier (`Must-Have`, `Should-Have`, `Differentiator`).
* `mapped_reqs`: Comma-separated list of satisfied `REQ-xx` identifiers.
* `trace_note`: Explicit explanatory sentence detailing how the feature implements each mapped requirement.
* `user_description`: Plain-language narrative describing the end-user capability.
