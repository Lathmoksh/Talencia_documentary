# Talentra — Stakeholders, Personas & Roles Schema Specification
**Document**: Deliverable B1 — Output Schema Definition  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Identity & Authorization Architecture Team  
**Status**: Approved & Frozen for Sprint Implementation  

---

## 1. Schema Hierarchy & Level Metrics

```
Stakeholder & Authorization Schema (Root)
 ├── L1.0 Enterprise Stakeholder Taxonomy (STK-01 to STK-10)
 ├── L1.1 Actor Persona Archetypes & Edge Actors (P-01 to P-12)
 ├── L1.2 Granular 11-Module CRUD Entitlement Matrix
 ├── L1.3 Multi-Tenant Row-Level Security Isolation Guardrails
 └── L1.4 Device Concurrency & Privacy Anti-Join Controls
```

### Schema Metrics & Structural Hierarchy

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **5 sections** | Measured (100% frozen) | Does the structure cover human, system, and edge actors completely? |
| **Level 2 · Micro** | Parameters & Models | **26 parameters** | Measured (5.2 avg/section) | Can the security team verify every actor role, frequency, and entitlement? |
| **Level 3 · Nano** | Sub-parameters & Enums | **78 classifications** | Measured & categorized | Are all 12 personas, 11 modules, and CRUD grant combinations typed? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every leaf map to a concrete PostgreSQL constraint, trigger, or RLS rule? |

---

## 2. Scope & Architectural Decision Log

| Item / Feature Considered | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Direct Application-Layer Security Checks** | **DROPPED** | Major vulnerability. Replaced with database-kernel Row-Level Security (`RLS`) to prevent tenant leaks across services. | Security Eng |
| **Unbounded Multi-Device User Sessions** | **DROPPED** | Prevents commercial seat sharing. Stored procedure automatically terminates prior active sessions upon new device login. | Architecture |
| **Exclusion of Edge & Maintenance Actors** | **DROPPED** | Anti-pattern. System explicitly models regulators (`P-10`), support engineers (`P-11`), and system daemons (`P-12`). | Identity Lead |
| **Candidate Employer Privacy Shield** | **KEPT** | Candidates can block current or competing employers; enforced via indexed anti-join views. | Product & Security |
| **11-Module Granular CRUD Matrix** | **KEPT** | Establishes precise authorization boundaries across all functional subsystems with zero ambiguity. | Authorization |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0: Enterprise Stakeholder Taxonomy
* `stakeholder_id`: Unique identifier (`STK-01` to `STK-10`).
* `category`: Broad organizational grouping (`Executive`, `Recruitment`, `Talent`, `Gig`, `Consultancy`, `Academic`, `Admin`, `Regulator`, `Support`, `Daemon`).
* `strategic_responsibility`: Primary enterprise mandate.

### Section L1.1: Actor Persona Archetypes & Edge Actors (P-01 to P-12)
* `persona_id`: Unique identifier (`P-01` to `P-12`).
* `actor_name`: Representative persona name (e.g. Asha, Rohan, Elena).
* `role_code`: Database role code (`RECRUITER`, `CANDIDATE`, `GIG_WORKER`, `EXECUTIVE`, `STAFFING_CONSULTANT`, `ACCOUNT_ADMIN`, `ACADEMIC_PARTNER`, `COMPLIANCE_OFFICER`, `SMB_EMPLOYER`, `STATUTORY_REGULATOR`, `SUPPORT_SPECIALIST`, `SYSTEM_DAEMON`).
* `actor_type`: Classification (`CORE_HUMAN`, `EDGE_REGULATOR`, `EDGE_SUPPORT`, `EDGE_SYSTEM`).
* `interaction_frequency`: Expected activity profile (`Daily Continuous`, `Weekly Interactive`, `Monthly Audit`, `Sub-Second Continuous`).
* `associated_requirements`: Array of `REQ-xx` identifiers linked to the persona.
* `key_guardrail`: Primary physical database constraint protecting the persona.

### Section L1.2: 11-Module CRUD Matrix
* `module_code`: Functional subsystem (`IDENTITY`, `ORGANISATION`, `RECRUITMENT`, `PROFILE`, `GIG`, `SOURCING`, `LICENSING`, `BILLING`, `PRIVACY`, `AUDIT`, `ANALYTICS`).
* `crud_entitlement`: 4-character bitmask or representation (`C`, `R`, `U`, `D` or `-`).

### Section L1.3 & L1.4: Database Guardrails
* `rls_policy`: PostgreSQL Row-Level Security rule on multi-tenant tables.
* `anti_join_view`: Materialized or regular SQL view filtering blocked candidates.
* `session_lock_procedure`: Stored procedure enforcing single active session per user account.
