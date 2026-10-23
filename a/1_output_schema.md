# Talentra — Requirements Analysis Schema Specification
**Document Reference**: Deliverable A1 — Output Schema Definition & Meta-Model  
**Step / Activity**: Step 01 — Requirement Analysis Docket  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Data Architecture & Systems Engineering Board  
**Gate**: Phase 1 Discover (Gate G1 Deliverable)  
**Status**: Approved & Frozen Baseline  

---

## Executive Summary: Step 01 — Requirement Analysis Docket

### 1. Purpose & Business Objective
The Requirement Analysis Docket establishes the foundational engineering contract for the Talentra Enterprise Workforce Platform. Built for Northbridge Workforce Systems, Talentra unifies three historically fragmented labor models—permanent enterprise talent acquisition, contingent gig/contractor labor mobilization, and university campus early-career programs—into a unified, multi-tenant digital ecosystem.

The objective of Step 01 is to eliminate architectural and business ambiguity before any schema modeling or code execution begins. By isolating pure business requirements from premature physical implementation, establishing rigorous boundary demarcations, and assigning quantifiable numeric thresholds to every requirement, this docket ensures that subsequent architectural phases (Phases 2 through 4) build upon a mathematically verified and legally compliant foundation.

### 2. Key Architectural Deliverables & Scope
1. **29 Pure Functional & Regulatory Requirements (`REQ-01` to `REQ-29`)**:
   - Spans 6 critical operational domains: Core Platform Invariants (8), Domain Sourcing (6), Domain Gig (4), Billing & Monetization (3), Security & Privacy (5), and Infrastructure SLAs (3).
   - Zero implementation pollution: requirements state *what* business invariants must hold, resolving subjective adjectives ("fast", "scalable", "secure") with empirical metrics (e.g., E.164 phone regex, `NUMERIC(12,2)` precision, sub-10ms p95 search latency, ISO 4217 currency codes).
2. **System Boundary & Demarcation Register**:
   - Clear contract specifying platform-owned capabilities versus out-of-scope external integrations across Identity (Okta SSO delegation), Billing (PCI-DSS Level 1 gateway isolation), Candidate Verification (third-party background checks), and Job Sourcing.
3. **Ranked Architectural Questions & Risk Mitigations (Q1 to Q5)**:
   - Evaluated by risk impact (Critical to Medium) with concrete architectural resolutions: cyclic hierarchy recursion checks, temporal interval exclusion, candidate anti-join privacy masking, double-entry wallet locking, and cryptographic key shredding for statutory DPDP erasure.
4. **Foundational Architectural Decision Records (ADR-01 to ADR-10)**:
   - Formalizes architectural choices: engine-level multi-tenancy, immutable append-only audit/ledger logs, blind indexing for PII lookups, and transactional advisory locking.

---

## 1. Schema Hierarchy & Structural Metrics

This schema defines the formal structure required for the Requirement Analysis Docket across four nested levels:

```
Requirement Docket Schema (Root)
 ├── L1.0 Executive Summary, Document Metadata & Governance
 ├── L1.1 Business Problem, Enterprise Scope & Capacity Scaling
 ├── L1.2 In-Scope vs. Explicit Out-of-Scope System Boundaries
 ├── L1.3 Ranked Architectural Open Questions & Risk Mitigations (Q1–Q5)
 ├── L1.4 Master Functional Requirements Baseline (REQ-01 to REQ-29)
 ├── L1.5 Architectural Decision Records Register (ADR-01 to ADR-10)
 └── L1.6 Non-Functional Standards & Data Integrity Guardrails
```

### Schema Structural Metrics

| Level | Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **7 sections** | 100% frozen | Are all architectural domains, boundaries, and questions accounted for? |
| **Level 2 · Micro** | Parameters & Models | **32 parameters** | 4.6 avg/section | Can the engineering team defend every requirement, actor, and boundary? |
| **Level 3 · Nano** | Sub-parameters & Enums | **104 classifications** | Categorized & typed | Are all priority codes, sources, and ambiguity resolutions strictly typed? |
| **Level 4 · Pico** | Atomic Constraints | **100% leaf coverage** | Formally defined | Does every requirement link to a verifiable test assertion and data domain? |

---

## 2. Scope Demarcation & Decision Log

| Candidate Feature / Capability | Decision | Architectural Rationale & Justification | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Raw Credit Card Numbers (PAN / CVV)** | **DROPPED** | PCI-DSS scope elimination. Talentra only persists gateway reference IDs, order statuses, and fixed-precision transaction amounts. | Core Architecture |
| **Cleartext National Identity Numbers** | **DROPPED** | Statutory data privacy mandate. Replaced with AES-256-GCM encryption and HMAC-SHA256 blind indexing for deterministic equality lookups. | Security Eng |
| **Unified Single Table for Gigs & Full-Time**| **DROPPED** | Gigs mandate calendar scheduling, bid proposals, and milestone escrow. Forcing them into full-time requisition entities creates NULL-polluted models. | Domain Lead |
| **Client-Side Concurrency Locking** | **DROPPED** | Unreliable across distributed clients; susceptible to network race conditions. Enforced via database-level temporal exclusions and transaction locks. | Database Architect |
| **8 Discrete Workforce Categories** | **KEPT** | Essential for Northbridge's commercial market model (Gig, Staffing, Professional, Permanent, Campus, Apprentice, Consultant, Remote). | Product Board |
| **9 External Integration Boundary Contracts** | **KEPT** | Eliminates integration ambiguity regarding external provider downtime, webhook idempotency, and transactional boundaries. | Integration Eng |
| **Ranked Open Questions with Concrete Resolutions**| **KEPT** | Replaces speculative assumptions with mathematical cycle detection, GiST temporal non-overlap, and anti-join shielding. | Systems Architect |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0: Executive Summary & Governance
* `docket_id`: Unique document identifier (Text, regex `^TAL-REQ-[0-9]{4}$`). Mandatory.
* `version`: Semantic version string (`MAJOR.MINOR.PATCH`).
* `status`: Approval state (`Draft`, `In Review`, `Approved`, `Frozen`).
* `authors`: Principal Data Architect, Lead Systems Engineer.
* `governance_board`: Enterprise Architecture Review Board (EARB).

### Section L1.1: Business Problem & Capacity Scaling
* `problem_statement`: Narrative explaining legacy platform fragmentation, candidate leakage, and siloed labor billing.
* `supported_workforce_types`: Array of 8 discrete labor categories (`GIG_PROJECT`, `GENERAL_STAFFING`, `PROFESSIONAL_STAFFING`, `PERMANENT_FT`, `APPRENTICE`, `CAMPUS_FRESHER`, `CONSULTANT_MARKETPLACE`, `MANAGED_REMOTE`).
* `target_scale_parameters`:
  * `candidate_pool_baseline`: 1,000,000 active profiles (laptop baseline) / 50,000,000 (production horizon).
  * `requisition_volume`: 100,000 active requisitions (baseline) / 5,000,000 (production horizon).
  * `application_throughput`: 5,000,000 applications (baseline) / 100,000,000 (production horizon).

### Section L1.2: System Boundaries & Demarcations
* `domain_name`: Operational system domain (`Identity`, `Sourcing`, `Gig Marketplace`, `Billing`, `Compliance`).
* `in_scope_responsibilities`: Explicitly platform-owned business logic and data states.
* `out_of_scope_boundary`: Delegated external capabilities with explicit handoff contracts.

### Section L1.3: Ranked Architectural Open Questions
* `question_id`: Identifier (`Q1` to `Q5`).
* `question_statement`: Core architectural dilemma or edge condition.
* `impact_level`: Severity rating (`Critical`, `High`, `Medium`).
* `architectural_resolution`: Specific architectural mechanism resolving the uncertainty.

### Section L1.4: Master Functional Requirements Baseline (REQ-01 to REQ-29)
* `req_id`: Unique identifier (`REQ-01` to `REQ-29`). Mandatory.
* `domain`: Functional domain category (`Core Invariant`, `Domain Sourcing`, `Domain Gig`, `Billing & Licensing`, `Security & Privacy`, `Infrastructure SLA`).
* `requirement_statement`: Concise statement of business capability without implementation leaks.
* `moscow_priority`: Classification (`Must-Have`, `Should-Have`, `Could-Have`).
* `target_actors`: Array of authorized personas interacting with this capability.
* `ambiguity_resolution`: Concrete metric, standard, or constraint replacing subjective qualifiers.

### Section L1.5: Architectural Decision Records (ADR-01 to ADR-10)
* `adr_id`: Unique identifier (`ADR-01` to `ADR-10`).
* `title`: Architecture design decision title.
* `context_and_problem`: Business or technical trigger necessitating a definitive architectural stance.
* `decision`: Concrete choice made by the architecture board.
* `consequences`: Trade-offs, operational implications, and downstream constraints.
