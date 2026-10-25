# Talentra — Business Workflow Output Schema Specification
**Document Reference**: Deliverable E1 — Output Schema Definition & Meta-Model  
**Step / Activity**: Step 05 — Business Workflow Analysis  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Workflow Architecture & Process Engineering Review Board  
**Gate**: Phase 1 Discover (Gate G1 Exit Deliverable)  
**Status**: Approved & Frozen Baseline (Audit Score: 9.64 / 10)  

---

## Executive Summary: Step 05 — Business Workflow Analysis

### 1. Purpose & Business Objective
The Business Workflow Specification formalizes the dynamic operational lifecycles, state machine transitions, authorization barriers, and automated failure recovery routines for the Talentra Enterprise Workforce Platform. In enterprise workforce ecosystems, operational failures rarely stem from missing UI forms; they occur when unhandled edge cases, concurrent race conditions, and uncoordinated external network outages produce corrupted database states or financial drift.

The objective of Step 05 is to establish a rigorous, failure-resilient operational meta-model under Phase 1 Discover (Gate G1). Every business lifecycle is specified as an immutable 6-parameter operational tuple, and every operational failure condition is cataloged across four standardized recovery branches: **Cancel**, **Refund**, **Retry**, and **Timeout**.

### 2. Key Architectural Deliverables & Scope
1. **End-to-End Business Workflow Architecture**:
   - Organized across 4 foundational pillars: Supply Onboarding & Privacy Shield, Corporate Demand & Sourcing Funnel, Gig Marketplace & GiST Locking, and Monetization & Wallet Billing.
2. **Master 10-Workflow Inventory (`WF-01` to `WF-10`)**:
   - Covers candidate onboarding (`WF-01`), requisition lifecycle (`WF-02`), application pipeline (`WF-03`), talent sourcing (`WF-04`), gig scheduling (`WF-05`), consultant bounty (`WF-06`), subscription licensing (`WF-07`), double-entry wallet billing (`WF-08`), campus batch placement (`WF-09`), and DPDP cryptographic erasure (`WF-10`).
3. **Formal 6-Parameter Tuple Standard**:
   - Standardizes every workflow around:
     $$\{ \text{Trigger}, \text{Sequential Steps}, \text{Operating Actors}, \text{Decision Branching}, \text{Exceptions \& Failure Handling}, \text{Deterministic Outputs} \}$$
4. **4-Category Exception & Compensation Catalog (`EXC-01` to `EXC-10`)**:
   - Exhaustive operational coverage across Cancel Paths (`EXC-01`, `EXC-02`, `EXC-09`), Refund Paths (`EXC-03`, `EXC-04`, `EXC-10`), Retry Paths (`EXC-05`, `EXC-06`), and Timeout Paths (`EXC-07`, `EXC-08`).
5. **100% Feature-to-Workflow Alignment Matrix**:
   - Maps all 25 platform features (`F-01` to `F-25`) to operational workflows with concrete physical storage verification evidence. Zero orphaned features.
6. **Storage Engine Invariant Defensibility**:
   - Hardens workflows via PostgreSQL GiST exclusion (`EXCLUDE USING gist`), Row-Level Security (`RLS`), row-level locks (`SELECT FOR UPDATE`), and append-only triggers ($0.00 balance drift).

---

## 1. Schema Hierarchy & Structural Metrics

This schema defines the formal structure required for the Business Workflow Docket across five nested levels:

```
Business Workflow Schema (Root)
 ├── L1.0 Executive Scope & Formal Workflow Methodology
 ├── L1.1 End-to-End Business Workflow Architecture Diagram
 ├── L1.2 Master Operational Workflow Inventory (WF-01 to WF-10)
 ├── L1.3 Detailed 6-Parameter Tuple Specifications (Core Architectural Workflows)
 ├── L1.4 4-Category Exception, Failure & Compensation Catalogue (EXC-01 to EXC-10)
 ├── L1.5 Feature-to-Workflow Traceability Matrix (100% Coverage: F-01 to F-25)
 ├── L1.6 Storage Engine Invariant Defensibility & Statutory Privacy Lifecycle
 ├── L1.7 Quality Gate G1 Comprehensive Exit Scorecard (9.64 / 10 Exit Standard)
 └── L1.8 Phase 1 Discover Sign-Off & Phase 2 Transition Roadmap
```

### Schema Structural Metrics

| Level | Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **9 sections** | 100% frozen | Are all talent, gig, subscription, and financial lifecycles covered? |
| **Level 2 · Micro** | Operational Lifecycles | **10 workflows** | 6-tuple standardized | Are all workflows structured with triggers, steps, actors, decisions, exceptions, and outputs? |
| **Level 3 · Nano** | Failure & Compensation Cases| **10 critical EXCs** | 4-category partitioned | Are Cancel, Refund, Retry, and Timeout paths mapped with automated rollbacks? |
| **Level 4 · Pico** | Feature Verifications | **25 features** | 100% leaf coverage | Does every single feature appear in at least one operational workflow? |

---

## 2. Parameter Dictionary & Field Rules

### Section L1.2 & L1.3: 6-Parameter Tuple Fields
* `workflow_id`: Unique identifier (`WF-01` to `WF-10`). Mandatory.
* `trigger`: Event or human action initiating the operational lifecycle.
* `steps`: Ordered sequence of atomic operations and database state mutations.
* `actors`: Human personas (`ACT-01` to `ACT-14`) and system daemons (`SYS-01` to `SYS-16`) participating in execution.
* `decisions`: Gateway conditional branches determining execution routing.
* `exceptions`: Linked failure codes (`EXC-01` to `EXC-10`) defining rollback handling.
* `outputs`: Deterministic database state, audit receipts, and external notifications produced upon completion.

### Section L1.4: 4-Category Exception Catalog Fields
* `exception_id`: Unique identifier (`EXC-01` to `EXC-10`). Mandatory.
* `category`: Failure branch enum (`Cancel Path`, `Refund Path`, `Retry Path`, `Timeout Path`).
* `operational_condition`: Descriptive name of the error or failure condition.
* `triggering_context`: Operational state leading up to the failure.
* `mitigation_strategy`: Automated programmatic or database compensation routine.
* `terminal_state`: Non-repudiable database state following compensation.

### Section L1.5: Feature Traceability Fields
* `feature_id`: Feature identifier (`F-01` to `F-25`). Mandatory.
* `pillar`: Architecture category (`Identity`, `Tenancy`, `Sourcing`, `Monetization`, `Billing`, `Gig Market`, `Engagement`, `Governance`, `Analytics`).
* `priority`: MoSCoW tier (`Must-Have`, `Should-Have`, `Could-Have`, `Differentiator`).
* `mapped_workflows`: Array of workflow IDs operationalizing the feature.
* `verification_evidence`: Physical storage constraint, index, or stored trigger proving operational defensibility.
