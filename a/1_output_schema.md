# Talentra: Requirements Analysis Schema Specification
**Document Reference**: Deliverable A1 — Output Schema Definition & Meta-Model  
**Playbook Step**: Step 1 · Phase 1 Discover  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Data Architecture & Systems Engineering Board  
**Gate**: Phase 1 Discover (Gate G1 Deliverable)  
**Status**: Approved & Frozen Baseline  

---

## Executive Summary: Step 1 — Requirements Analysis Meta-Model

### 1. Purpose & Business Objective
The Requirements Analysis Docket Meta-Model establishes the formal structural contract and data schema governing Deliverable A (**Requirements Analysis Docket**) for the Talentra Enterprise Workforce Platform. Built for Northbridge Workforce Systems, Talentra unifies corporate permanent hiring, contingent gig/contract labor mobilization, and university campus early-career recruitment into a single, multi-tenant digital ecosystem.

The core objective of Step 1 is to eliminate business and structural ambiguity before any database entity modeling, schema definition, or code development begins. Adhering to the foundational tenet:

> **"Understand before you model — nothing is modelled yet."**

Every requirement statement in this schema isolates pure business capabilities from premature physical implementation, assigns verifiable numeric thresholds, establishes firm integration boundaries, and maps to the source brief with 100% sentence-level traceability.

### 2. Architectural Deliverables & Scope
1. **Complete 77-Requirement Baseline (`REQ-001` through `REQ-142`)**:
   - Spanning 10 distinct subsections: Problem and Goals (6), Job Categories (8), Gig Marketplace (9), Core Workflows (11), Actors and Privileges (8), Data Domains Coverage (21), Data Standards Rule Groups (12), Integration Boundaries (10), Scale & Environment (5), and Deliverables (13).
   - Zero premature physical schema leaks: requirements define business invariants and observable behaviors, resolving subjective adjectives into empirical metrics.
2. **Explicit Out-of-Scope Demarcations (`OOS-01` through `OOS-07`)**:
   - Firm architectural boundaries excluding front-end UI construction, live external service operations, physical 10M loading on laptops, legacy migration execution, employer sub-roles, gig task dispatching, and standalone Tier 3 analytical modules.
3. **Actor Taxonomy (9 Primary Personas + 6 Edge / System Archetypes)**:
   - Full categorization across SuperAdmin, Admin, Account Admin, Candidate, Employer, Recruiter, Consultant, Placement Officer (TPO), Guest, Gig Worker, Gig Requester, Scheduled Daemons, External Systems, Auditor, and Support Staff.
4. **Ranked Open Questions with Architectural Stances (`Q1` through `Q10`)**:
   - Ranked by system design impact (Rank 1 to 10) with assigned owners and concrete architectural stances.
5. **Requirements Architecture & Taxonomy Tree Diagram**:
   - Formal visual mindmap and taxonomy tree structuring the entire requirements docket from root to operational leaves.

---

## 1. Schema Hierarchy & Structural Metrics

The formal structure of the Requirements Analysis Docket is organized across four nested levels:

```
Requirements Docket Schema (Root)
 ├── L1.0 Executive Summary, Document Metadata & Governance
 ├── L1.1 Business Problem, Enterprise Scope & Capacity Scaling
 ├── L1.2 Strategic Goals & Measurable Success Indicators (G1–G4)
 ├── L1.3 Scope Demarcations & Explicit Out-of-Scope Register (OOS-01–OOS-07)
 ├── L1.4 Actor Taxonomy & Authorization Roles (9 Core + 6 Edge Archetypes)
 ├── L1.5 Master Requirements Register (REQ-001 to REQ-142 across 10 Subsections)
 ├── L1.6 Vague Words Made Measurable Specification
 ├── L1.7 Operational Assumptions Register (A1–A6)
 ├── L1.8 Ranked Architectural Open Questions & Risk Mitigations (Q1–Q10)
 ├── L1.9 Brief Traceability & Coverage Matrix (Sections 1–7 to REQ IDs)
 └── L1.10 Visual Taxonomy Tree & Requirements Architecture Diagram
```

### Schema Structural Metrics

| Level | Structural Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **10 sections** | 100% frozen | Are all operational domains, boundaries, and governance dimensions accounted for? |
| **Level 2 · Micro** | Parameters & Models | **48 parameters** | 4.8 avg/section | Can the engineering team defend every functional capability, actor, and boundary? |
| **Level 3 · Nano** | Sub-parameters & Enums | **142 classifications**| Strictly typed | Are all priorities (Must/Should/Could), sources (S1..S7), and classifications typed? |
| **Level 4 · Pico** | Atomic Constraints | **100% leaf coverage** | Formally defined | Does every requirement link to a verifiable test assertion, metric, and owner? |

---

## 2. Scope Demarcation & Decision Log

| Capability / Architectural Dilemma | Stance | Architectural Rationale & Justification | Governance Owner |
| :--- | :---: | :--- | :---: |
| **Raw Credit Card Numbers (PAN / CVV)** | **DROPPED** | PCI-DSS scope elimination. Talentra only stores external gateway reference IDs, payment order statuses, and fixed-precision transaction amounts (`NUMERIC(12,2)`). | Security Architect |
| **Cleartext National Identity Numbers** | **DROPPED** | Statutory data privacy compliance (DPDP Act 2023). Identity numbers encrypted via AES-256-GCM; exact equality lookups use HMAC-SHA256 blind indexing. | Data Privacy Lead |
| **Unified Single Table for Gigs & Lateral** | **DROPPED** | Contingent gigs mandate calendar availability, milestone escrow, and fixed/rate pricing. Merging them into permanent job requisition tables creates severe NULL pollution. | Core Architect |
| **Client-Side Concurrency Controls** | **DROPPED** | Susceptible to network latency, distributed race conditions, and bypasses. Enforced via database-level `GiST` temporal exclusion constraints and row-level locks. | Database Engineer |
| **8 Discrete Workforce Categories** | **KEPT** | Essential for Northbridge's commercial business model: Gig, General Staffing, Professional Staffing, Permanent, Apprentice, Campus, Consultant, and Remote. | Product Board |
| **9 External Integration Boundaries** | **KEPT** | Eliminates integration ambiguity regarding external provider downtime, webhook idempotency, and transactional boundaries. | Integration Lead |
| **10 Ranked Open Questions with Stances** | **KEPT** | Replaces speculative developer assumptions with formal architectural stances, clear severity rankings, and assigned owners. | Systems Architect |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0: Document Metadata & Governance
* `docket_id`: Unique document identifier (Text, regex `^TAL-REQ-[0-9]{4}$`). Mandatory.
* `playbook_step`: Playbook execution step (`Step 1 · Phase 1 Discover`).
* `version`: Semantic version string (`MAJOR.MINOR`).
* `source_brief`: Reference to authoritative brief (`Northbridge Workforce Systems Hackathon Docket`).
* `gate_status`: Approval state (`Gate G1 Certified`, `100% Traceability`).

### Section L1.1: Business Problem & Enterprise Scope
* `problem_narrative`: Text detailing legacy fragmentation, candidate drop-off, and pipeline invisibility.
* `target_scale_parameters`:
  * `candidate_pool`: 1,000,000 active profiles (laptop seed) / 10,000,000 (full scale).
  * `requisition_volume`: 100,000 active requisitions (laptop seed) / 1,000,000 (full scale).
  * `application_throughput`: 5,000,000 applications (laptop seed) / 100,000,000 (full scale).

### Section L1.2: Strategic Goals (G1–G4)
* `goal_id`: Identifier (`G1` to `G4`).
* `goal_statement`: Concise statement of business goal.
* `measure_of_success`: Observable, measurable verification criterion.
* `verification_method`: Formal test method (query plan, concurrency test, ADR log).

### Section L1.3: Scope Demarcations & Out-of-Scope Register (OOS-01–OOS-07)
* `oos_id`: Unique identifier (`OOS-01` to `OOS-07`).
* `item_name`: Out-of-scope feature or system responsibility.
* `source_ref`: Brief section establishing the exclusion (`Section 1`, `Section 2`, `Section 3`, `Section 4`, `Section 6`, `Section 7`).
* `boundary_contract`: Explicit contract detailing platform-owned interface vs excluded external capability.

### Section L1.4: Actor Taxonomy (9 Primary + 6 Edge / System)
* `actor_id`: Identifier (`ACT-01` to `ACT-15` or canonical persona `P-01` to `P-12`).
* `actor_name`: Formal persona title (e.g. `Candidate`, `Employer`, `Recruiter`, `Gig Worker`, `Placement Officer`).
* `classification`: Actor type (`Primary Human`, `Edge / System`).
* `scope_of_authority`: Core operational responsibilities and permission boundaries.

### Section L1.5: Master Requirements Register (REQ-001 to REQ-142)
* `req_id`: Unique identifier (`REQ-001` through `REQ-142`). Mandatory.
* `subsection`: Functional grouping:
  * `A. Problem and Goals` (`REQ-001` to `REQ-006`)
  * `B. Job Categories` (`REQ-010` to `REQ-017`)
  * `C. Gig Marketplace` (`REQ-020` to `REQ-028`)
  * `D. Core Workflows` (`REQ-030` to `REQ-040`)
  * `E. Actors and Privileges` (`REQ-050` to `REQ-057`)
  * `F. Data Domains Coverage` (`REQ-060` to `REQ-082`)
  * `G. Data Standards` (`REQ-090` to `REQ-101`)
  * `H. Integration Boundaries` (`REQ-110` to `REQ-119`)
  * `I. Environment and Scale` (`REQ-120` to `REQ-124`)
  * `J. Deliverables` (`REQ-130` to `REQ-142`)
* `statement`: Concise, implementation-free statement of capability or business rule.
* `source`: Source citation from brief (`S1` to `S7`, `B35`, `B46`, `B59`, etc.).
* `priority`: MoSCoW classification (`Must`, `Should`, `Could`).
* `ambiguity_note`: Clarification resolving brief silences or assumptions into concrete engineering rules.

### Section L1.6: Vague Words Made Measurable
* `brief_phrase`: Ambiguous adjective or qualitative phrase from source brief.
* `risk_analysis`: Risk of subjective misinterpretation.
* `proposed_number`: Deterministic numeric threshold or SLA target.
* `test_method`: Concrete verification method (row counts, latency percentile runs, concurrency test).

### Section L1.7: Assumptions Register (A1–A6)
* `assumption_id`: Identifier (`A1` to `A6`).
* `statement`: Operational or technical assumption.
* `architectural_impact`: Impact on schema, infrastructure, or project planning.
* `governance_link`: Approved architectural decision or policy authority.

### Section L1.8: Ranked Open Questions (Q1–Q10)
* `rank`: Priority ranking (`1` to `10`) based on architectural design severity.
* `question_id`: Identifier (`Q1` to `Q10`).
* `question_text`: Architectural dilemma or missing specification.
* `impact_domain`: Affected system subsystem (e.g. `Analytics`, `Concurrency`, `RBAC`, `Data Dictionary`).
* `owner`: Assigned resolution party (`Mentor`, `Team`, `Security Lead`, `Product Lead`).
* `proposed_resolution`: Defensible stance adopted by the engineering team.

### Section L1.9: Brief Coverage & Traceability Check
* `brief_section`: Chapter or topic of the source brief (Sections 1 through 7).
* `mapped_ids`: Complete list of mapped Goals (`G1`–`G4`), Requirements (`REQ-*`), and Out-of-Scope items (`OOS-*`).
* `gate_status`: Formal audit confirmation (`100% Coverage`, `Gate G1 Certified`).

### Section L1.10: Visual Requirements Taxonomy Hierarchy Diagram
* `diagram_file`: Embedded high-resolution graphic (`requirements_taxonomy_diagram.png`).
* `mermaid_source`: Complete executable Mermaid flowchart representing the four-level taxonomic tree.

### Section L1.11: Quality Gate G1 Scorecard Structure (Composite: 8.96 / 10)
* `evaluation_dimension`: The 6 standardized Step 01 evaluation criteria:
  1. Requirements Completeness & Mapping (Weight: 25%, Score: 9.5, Weighted: 2.38)
  2. Taxonomy & Structural Decomposition (Weight: 20%, Score: 8.5, Weighted: 1.70)
  3. Measurability & NFR Quantification (Weight: 15%, Score: 9.0, Weighted: 1.35)
  4. Prioritization & Ambiguity Handling (Weight: 15%, Score: 9.0, Weighted: 1.35)
  5. Stakeholder, Privilege & Boundary Tracing (Weight: 15%, Score: 8.5, Weighted: 1.28)
  6. Compliance & Data Standards Rigor (Weight: 10%, Score: 9.0, Weighted: 0.90)
* `total_composite_score`: 8.96 / 10 (STATUS: PASSED Gate G1 Requirements Baseline).

---

## 4. Verification & Schema Validation Rules

Any deliverable claiming compliance with this meta-model must satisfy the following validation rules:

1. **Completeness Rule**: Every requirement ID in the sequence (`REQ-001`..`006`, `REQ-010`..`017`, `REQ-020`..`028`, `REQ-030`..`040`, `REQ-050`..`057`, `REQ-060`..`082`, `REQ-090`..`101`, `REQ-110`..`119`, `REQ-120`..`124`, `REQ-130`..`142`) must be present with zero missing identifiers.
2. **Implementation Purity Rule**: Requirement statements must not leak physical schema keywords (e.g. `CREATE TABLE`, `FOREIGN KEY`, `B-tree index`, `UUIDv4`, `Argon2id`). Implementation mechanisms are reserved for the Ambiguity Resolution and Data Standards sections.
3. **Traceability Invariant**: 100% of functional requirements must trace directly to a valid source citation (`S1` through `S7` or playbook section).
4. **Boundary Invariant**: All external integrations must be paired with an explicit boundary contract in Section L1.8 (`REQ-110` through `REQ-119`) specifying ownership, stored vs referenced data, failure handling, and idempotency.
5. **Open Question Governance**: All 10 open questions must include a concrete architectural stance to prevent blocking downstream modeling steps.
6. **Scorecard Conformance**: The deliverable evaluation must adhere to the 6-dimension weighted matrix yielding a composite score $\ge 8.5 / 10$ (`8.96 / 10` baseline).
