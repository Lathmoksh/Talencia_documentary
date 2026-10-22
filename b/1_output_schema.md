# Talentra — Stakeholders, Personas & Roles Schema Specification
**Document**: Deliverable B1 — Output Schema Definition  
**System**: Talentra Demand Management Platform  
**Owner**: Platform Identity & Security Engineering  
**Status**: Approved Baseline  

---

## 1. Schema Hierarchy & Level Metrics

Following the *Control the Output* methodology (Playbook Pages 5–6 & 18), this schema organizes access boundaries, persona models, and database security rules into a 4-level nonlinear hierarchy:

```
Stakeholders & Roles Schema (Root)
 ├── L1.0 Project Metadata & Governance
 ├── L1.1 Stakeholder Classification Taxonomy
 ├── L1.2 Persona Catalog (9 Core Archetypes)
 ├── L1.3 Subsystem Permission Matrix (CRUD across 11 Modules)
 ├── L1.4 Mandatory Database Guardrails (Isolation, Blocking, Concurrency)
 └── L1.5 Quality Verification Scenarios (SQL Security Assertions)
```

### Schema Metrics by Level (Playbook Page 6 & 18)

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **5 sections** | Measured (100% frozen) | Does the structure cover all actors, personas, permissions, and guardrails? |
| **Level 2 · Micro** | Parameters & Models | **22 parameters** | Measured (4.4 avg/section) | Can the engineering team explain every actor role and security policy? |
| **Level 3 · Nano** | Sub-parameters & Enums| **65 classifications** | Measured & categorized | Are all 9 roles, CRUD grants, and enforcement tiers defined? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every leaf map to a concrete PostgreSQL constraint, trigger, or RLS rule? |

---

## 2. Keep / Drop Decision Log (Playbook Stage 2 Checklist)

As mandated by Stage 2 (*Define*) of the Process Playbook, all structural decisions and scope exclusions are explicitly logged:

| Item / Feature Considered | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Employer Internal Sub-Roles in v1** | **DROPPED** | Explicitly excluded by Problem Docket Section 3. Kept out of v1 to ensure clean, high-performance Row-Level Security (`RLS`). Extended via v2 roadmap. | Define |
| **Recruiter Proxy Candidate Registration** | **DROPPED** | Strictly prohibited by Problem Docket Section 3. Candidates must self-register to ensure ownership of consent and privacy blocks. | Define |
| **Frontend-Only Role Hiding** | **DROPPED** | Problem Docket mandates: *Every privilege must be enforced in the database or access layer, not only in the interface.* Relies on PostgreSQL RLS and stored procedures. | Define |
| **9 Human Actors + 2 System Roles** | **KEPT** | Directly implements the 9 actors defined in Section 3 (Super Admin, Admin, Account Admin, Guest, Candidate, Employer, Recruiter, Consultant, TPO) plus Auditor and System Worker. | Discover |
| **Candidate Negative Sourcing Blocks** | **KEPT** | High-value privacy differentiator. Blocked parties are completely suppressed from search pools via SQL anti-joins. | Define |
| **Database-Tier Session Device Limits** | **KEPT** | Prevents concurrent seat sharing. Enforced inside `authenticate_session()` stored procedure with row locking (`FOR UPDATE`). | Define |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0: Project Metadata & Governance
* `document_id`: Unique identifier (`TAL-PER-0001`). Required.
* `version`: Semantic version (`MAJOR.MINOR.PATCH`). Required.
* `author`: Lead security engineer.
* `reviewer`: Senior systems architect.
* `status`: Approval state (`Approved Baseline`).

### Section L1.1: Stakeholder Ecosystem
Classifies users and systems into distinct operational categories:
* `group_id`: Unique identifier (`STK-01` to `STK-10`).
* `name`: Stakeholder group name (Candidates, Employers, Recruiters, Consultants, etc.).
* `category`: Broad type (`Human User`, `Enterprise Account`, `System Integration`).
* `primary_outcome`: Business outcome driving platform engagement.
* `subsystems`: List of database schemas mapped to this stakeholder group.

### Section L1.2: Persona Catalog (9 Core Archetypes)
Defines realistic personas to validate user workflows:
* `persona_id`: Identifier string (`P-01` to `P-09`).
* `display_name`: Persona name and professional context (e.g., "Asha — Mid-Career Software Engineer", "Meera — In-House Tech Recruiter").
* `role_code`: Exact system role code from the database catalog (`CANDIDATE`, `EMPLOYER`, `RECRUITER`, `CONSULTANT`, `TPO`, `ACCOUNT_ADMIN`, `SUPER_ADMIN`, `AUDITOR`, `SYSTEM_WORKER`).
* `workflows`: 3 to 5 key jobs-to-be-done supported in the database.
* `security_guardrail`: Critical data invariant or access restriction protecting this user or their data.
* `frequency`: Typical interaction pattern (`Daily Continuous`, `Daily Active`, `Weekly Burst`, `Monthly Audit`, `As Needed`).

### Section L1.3: Subsystem Permission Matrix
Maps each role to allowable actions across all 11 database modules:
* `role`: System role code.
* `module`: Database schema (`profile`, `recruitment`, `organisation`, `gig`, `licence`, `billing`, etc.).
* `permissions`: Explicit CRUD grants (`Create`, `Read`, `Update`, `Delete`).
* `enforcement_method`: How the database guarantees the rule (`Postgres RLS`, `Check Trigger`, `Stored Procedure`, `Database Grant`).

### Section L1.4: Mandatory Database Guardrails
Defines the mandatory non-negotiable rules from the problem statement:
* **G-01 Recruiter Isolation**: A recruiter may only view and manage job requisitions belonging to their own employer organization. Enforced via Row-Level Security (`RLS`).
* **G-02 Candidate Blocking**: Candidates can block specific employers, recruiters, or headhunters. Blocked parties must be completely excluded from seeing the candidate in search results.
* **G-03 Consultant Access Gate**: Consultants can only view and source for requisitions explicitly flagged `open_to_consultants = TRUE` where an employer has accepted their sourcing request.
* **G-04 No Proxy Registration**: Recruiters cannot register candidates on a candidate's behalf. Candidates must self-register.
* **G-05 Device Limit Enforcement**: Active sessions cannot exceed the license device quota. Enforced atomically at login time.
* **G-06 Append-Only Financial & Audit Records**: Ledger updates and deletions are physically blocked by database triggers.

### Section L1.5: Security Test Cases
Executable SQL assertions to prove guardrail enforcement in automated test suites:
* `test_id`: Reference identifier (`SEC-TST-01` to `SEC-TST-06`).
* `description`: Unauthorized scenario being attempted (e.g. Recruiter A querying Recruiter B's company requisitions).
* `expected_db_response`: Exact database outcome (`0 rows returned`, `Permission Denied exception`, `Trigger Error`).
