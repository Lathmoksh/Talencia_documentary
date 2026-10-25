# Talentra — Stakeholders, Personas & Roles Schema Specification
**Document Reference**: Deliverable B1 — Output Schema Definition & Meta-Model  
**Playbook Step**: Step 02 · Phase 1 Discover  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Identity & Authorization Architecture Board  
**Gate**: Phase 1 Discover (Gate G1 Deliverable)  
**Status**: Approved & Frozen Baseline (Gate G1 Certified — Score: 9.46 / 10)  

---

## Executive Summary: Step 02 — Stakeholders, Personas & Roles Meta-Model

### 1. Purpose & Business Objective
The Stakeholders, Personas & Roles Specification translates Northbridge Workforce Systems' multi-tiered talent acquisition and contingent labor ecosystem into a mathematically rigorous identity, actor, and authorization meta-model. In complex enterprise platforms, authorization vulnerabilities and workflow breakdowns stem from role vocabulary drift, vague actor descriptions, and the dangerous omission of operational "edge" and automated background daemons.

The objective of Step 02 is to establish an authoritative actor taxonomy and entitlement foundation that governs every requirement (`REQ-001` to `REQ-142` and `REQ-01` to `REQ-45`), feature, and workflow (`W1` to `W16`). By defining **14 Human Actors (`ACT-01` to `ACT-14`)**, **10 Stakeholder Groups (`STK-01` to `STK-10`)**, **11 Detailed Persona Profiles**, and **16 Dedicated System Daemons (`SYS-01` to `SYS-16`)**, this meta-model ensures 100% author traceability, eliminates dummy authors under Rule Group 5, and binds all permissions directly to database-level enforcement mechanisms (PostgreSQL RLS, `GiST` temporal exclusion, check constraints, and immutable ledger triggers).

### 2. Key Architectural Deliverables & Scope
1. **14 Human Actors (`ACT-01` to `ACT-14`) & 10 Stakeholder Categories (`STK-01` to `STK-10`)**:
   - Covers Supply-Side (Candidate, Gig Worker), Demand-Side (Employer, Recruiter, Consultant, Placement Officer), Platform Governance (Super Admin, System Admin, Account Admin, DPO, Auditor, Support Agent, Analyst), and Public (Guest).
2. **16 Dedicated System Service Accounts (`SYS-01` to `SYS-16`)**:
   - Explicit service accounts for scheduled jobs (Retention/DPDP Purge, Notification Dispatcher, Subscription Daemon, Session Sweeper, Legacy Sync, Gig Reconciliation, Analytics Refresh) and external boundary systems (PCI-DSS Gateway, Identity Verification, Tax Registry, Gig Fulfilment, etc.), guaranteeing zero-null `created_by` integrity.
3. **Master 11-Module CRUD+AX Entitlement Matrix**:
   - Formally maps actions (`C`, `R`, `U`, `D`, `A`, `X`) and scopes (`own`, `co`, `open`, `inst`, `pub`, `msk`, `agg`, `all`) across all 11 architecture modules, with strict immutability invariants banning `U` and `D` on ledger and audit tables.
4. **16 Operational Workflows & Negative Security Test Assertions (`W1` to `W16`)**:
   - Formulates negative security test cases and exact database-tier abort assertions for every workflow.
5. **15 Architectural Decision Records (`D-01` to `D-15`) & 8 Ranked Open Questions (`Q-01` to `Q-08`)**:
   - Grounding role conflict rules, dated recruiter mapping, break-glass masking, and sub-role extension paths.
6. **Embedded Visual Taxonomy Hierarchy Diagram**:
   - Incorporating high-resolution diagram `stakeholders_and_roles_taxonomy_tree.jpg` and accompanying Mermaid flowchart.

---

## 1. Schema Hierarchy & Structural Metrics

```
Stakeholder & Authorization Schema (Root)
 ├── L1.0 Executive Summary & Metadata
 ├── L1.1 Architectural Decision Log (D-01 to D-15)
 ├── L1.2 Human Actor Catalogue (ACT-01 to ACT-14) & Stakeholders (STK-01 to STK-10)
 ├── L1.3 System Daemons & Integration Service Accounts (SYS-01 to SYS-16)
 ├── L1.4 Persona Profiles & Step 29 KPI Seeds
 ├── L1.5 Master 11-Module CRUD+AX Entitlement Matrix
 ├── L1.6 Storage Engine Enforcement Mechanisms & Negative Security Tests (W1–W16)
 ├── L1.7 Sub-Roles Extension Path (Out-of-Scope Architecture)
 ├── L1.8 Ranked Open Questions & Mitigations (Q-01 to Q-08)
 ├── L1.9 Visual Stakeholder & Role Taxonomy Tree Diagram
 └── L1.10 Quality Gate G1 Scorecard Structure (9.46 / 10 Pass)
```

### Schema Structural Metrics

| Level | Structural Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **10 sections** | 100% frozen | Are all human, edge, system actors, and security mechanisms modeled? |
| **Level 2 · Micro** | Parameters & Models | **42 parameters** | 4.2 avg/section | Can security verify every persona profile, frequency, and entitlement? |
| **Level 3 · Nano** | Sub-parameters & Enums | **156 classifications**| Strictly typed | Are all 14 actors, 16 daemons, 11 modules, and 8 scopes typed? |
| **Level 4 · Pico** | Atomic Entitlements | **154 matrix cells** | Formally defined | Does every matrix cell map to a verified database permission rule? |

---

## 2. Parameter Dictionary & Field Rules

### Section L1.0 & L1.1: Governance & Decision Log (D-01 to D-15)
* `decision_id`: Unique identifier (`D-01` to `D-15`).
* `architectural_choice`: Concise title of approved decision.
* `defensible_rationale`: Business and technical justification explaining "why it is best".
* `alternative_rejected`: Explicit alternatives evaluated and discarded.
* `risk_and_mitigation`: Identified risk and concrete engineering mitigation.

### Section L1.2 & L1.3: Actor Catalogue & System Daemons
* `actor_id`: Identifier for human actors (`ACT-01` to `ACT-14`).
* `role_name`: Canonical role code (e.g. `Candidate`, `Gig Worker`, `Recruiter`, `Placement Officer`, `Super Admin`).
* `actor_class`: Classification (`Public`, `Supply Side`, `Demand Side`, `Intermediary`, `Institution`, `Platform Staff`).
* `daemon_id`: Identifier for automated/system accounts (`SYS-01` to `SYS-16`).
* `service_account_name`: Formal account name (e.g. `Retention & DPDP Purge Daemon`, `PCI-DSS Payment Gateway`).
* `boundary_constraint`: Explicit access boundary (e.g. `SECURITY DEFINER`, `no access to credentials`, `append-only`).

### Section L1.4: Persona Profiles & KPI Seeds
* `persona_name`: Humanized representative archetype (e.g. Priya Nair, Arjun Das, Rahul Mehta).
* `usage_frequency`: Quantitative usage expectation (e.g. `Daily Continuous (50–150/d)`, `Daily On-Demand (10–30/d)`).
* `operational_pain`: Verified pain point drawn from legacy system fragmentation.
* `kpi_seed`: Downstream success metric linked to Step 29 verification (e.g. `30-Day Return Rate`, `Time-to-Hire`).

### Section L1.5: Master 11-Module CRUD+AX Entitlement Matrix
* `module_code`: Functional subsystem (`Candidate Profile Core`, `Resume & Documents`, `Job Requisition`, `Questionnaires`, `Applications & Pipeline`, `Consultant Sourcing`, `Candidate Privacy Blocks`, `Gig Marketplace`, `Licensing & Seats`, `Wallet & Credits`, `Forensic Audit Log`).
* `action_set`: Subset of `{C, R, U, D, A, X}`.
* `scope_code`: Enum: `own`, `co`, `open`, `inst`, `pub`, `msk`, `agg`, `all`.

### Section L1.6: Storage Engine Enforcement & Negative Security Tests (W1 to W16)
* `workflow_id`: Workflow identifier (`W1` to `W16`).
* `negative_security_test`: Malicious or invalid transaction scenario.
* `expected_database_assertion`: Storage engine response (e.g. RLS 0 rows, check constraint violation, trigger exception).

### Section L1.9: Visual Taxonomy Hierarchy Diagram
* `image_path`: Relative path to graphic (`stakeholders_and_roles_taxonomy_tree.jpg`).
* `mermaid_source`: Executable Mermaid flowchart defining the 4-tier actor taxonomy.

### Section L1.10: Quality Gate G1 Scorecard Structure
* `evaluation_dimension`: The 6 standardized Gate G1 evaluation criteria.
* `weight`: Percentage weight (20%, 25%, 20%, 15%, 10%, 10%).
* `score`: Rating out of 10.
* `weighted_score`: Product of weight and score.
* `composite_score`: Total score (`9.46 / 10`).
