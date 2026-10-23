# Talentra — Stakeholders, Personas & Roles Schema Specification
**Document Reference**: Deliverable B1 — Output Schema Definition & Meta-Model  
**Step / Activity**: Step 02 — Stakeholders, Personas and Roles  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Identity & Authorization Architecture Board  
**Gate**: Phase 1 Discover (Gate G1 Deliverable)  
**Status**: Approved & Frozen Baseline  

---

## Executive Summary: Step 02 — Stakeholders, Personas & Roles

### 1. Purpose & Business Objective
The Stakeholders, Personas & Roles Specification translates Northbridge's multi-tier workforce ecosystem into a mathematically rigorous identity and authorization meta-model. In complex enterprise platforms, authorization vulnerabilities and workflow breakdowns stem from role vocabulary drift, vague actor descriptions, and the dangerous omission of operational "edge" actors.

The objective of Step 02 is to establish a single, canonical role vocabulary that governs every requirement (`REQ-01` to `REQ-29`), feature (`F-01` to `F-23`), and workflow (`WF-01` to `WF-07`). By defining 12 distinct persona archetypes (`P-01` to `P-12`) with explicit interaction frequencies, mapping them to an exhaustive 11-module CRUD matrix, and formalizing immutable audit and ledger invariants, this deliverable ensures zero unauthorized access and complete forensic traceability.

### 2. Key Architectural Deliverables & Scope
1. **Single Canonical Role Vocabulary**:
   - Exactly twelve standardized role codes (`RECRUITER`, `CANDIDATE`, `GIG_WORKER`, `EXECUTIVE`, `STAFFING_CONSULTANT`, `ACCOUNT_ADMIN`, `ACADEMIC_PARTNER`, `COMPLIANCE_OFFICER`, `SMB_EMPLOYER`, `STATUTORY_REGULATOR`, `SUPPORT_SPECIALIST`, `SYSTEM_DAEMON`).
2. **Comprehensive Persona Archetypes (`P-01` to `P-12`)**:
   - Covers 9 core human enterprise actors alongside 3 essential edge actors:
     - `P-10` Statutory Regulator: External DPDP Act 2023 / GDPR auditor (`R---` on audit/consent logs).
     - `P-11` Technical Support Specialist: Tier-2/3 operations engineer handling session lockouts and webhook failures without PII visibility.
     - `P-12` Automated System Maintenance Daemon: Sub-second background worker managing partition rollover, DPDP erasure cascades, and session expiration.
3. **Exhaustive $12 \times 11$ Role-Permission Matrix**:
   - 132 cell evaluations spanning 11 functional modules: Identity & Auth, Organisation Tenancy, Job Requirements, Candidate Profiles, Gig Marketplace, Sourcing & Screening, Licensing & Seats, Wallet & Billing, Privacy Blocklist, System Audit, and Analytics Marts.
   - Enforces core security invariants: `system_audit` and `wallet_billing` strictly prohibit in-place updates or deletions (`U` and `D` are banned on financial ledger and audit records).
4. **Interaction Frequency Profiles**:
   - Quantitative activity expectations ranging from Daily Continuous (50–150 actions/day) down to Quarterly Formal Regulatory Audits and Sub-Second Automated Background Daemon runs.

---

## 1. Schema Hierarchy & Structural Metrics

This schema defines the formal structure required for the Stakeholder & Persona Docket across four nested levels:

```
Stakeholder & Authorization Schema (Root)
 ├── L1.0 Executive Summary & Canonical Role Vocabulary
 ├── L1.1 Enterprise Stakeholder Taxonomy (STK-01 to STK-10)
 ├── L1.2 Persona Archetypes & Edge Actor Profiles (P-01 to P-12)
 ├── L1.3 Full 12x11 Functional Module CRUD Entitlement Matrix
 └── L1.4 Physical Database Security Guardrails & Invariants
```

### Schema Structural Metrics

| Level | Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **5 sections** | 100% frozen | Does the architecture model all human, edge, and automated actors? |
| **Level 2 · Micro** | Parameters & Models | **28 parameters** | 5.6 avg/section | Can security verify every persona profile, frequency, and entitlement? |
| **Level 3 · Nano** | Sub-parameters & Enums | **96 classifications** | Categorized & typed | Are all 12 roles, 11 modules, and CRUD grant combinations typed? |
| **Level 4 · Pico** | Atomic Entitlements | **132 matrix cells** | Formally defined | Does every matrix cell map to a verified database permission rule? |

---

## 2. Scope & Security Invariant Decisions

| Architectural Capability | Decision | Architectural Rationale & Justification | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Application-Layer-Only Authorization** | **DROPPED** | Major enterprise vulnerability. Software `WHERE` clauses fail under developer error. Replaced with database-kernel Row-Level Security (`RLS`). | Security Eng |
| **Unbounded Multi-Device User Sessions** | **DROPPED** | Prevents commercial seat sharing. Stored procedures automatically invalidate previous session tokens upon new device login. | Architecture |
| **Exclusion of Edge & Maintenance Actors** | **DROPPED** | Critical anti-pattern. System explicitly models regulators (`P-10`), support engineers (`P-11`), and system daemons (`P-12`). | Identity Lead |
| **Candidate Employer Privacy Shield** | **KEPT** | Candidates can block current or competing employers; enforced via indexed anti-join views. | Product & Security |
| **Strict Append-Only Ledger & Audit Invariants** | **KEPT** | Eliminates financial fraud and audit tampering by prohibiting `UPDATE` and `DELETE` on ledger and audit entities. | Financial Lead |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0 & L1.1: Canonical Role Vocabulary & Stakeholders
* `role_code`: Unique standardized role string (Enum: `RECRUITER`, `CANDIDATE`, `GIG_WORKER`, `EXECUTIVE`, `STAFFING_CONSULTANT`, `ACCOUNT_ADMIN`, `ACADEMIC_PARTNER`, `COMPLIANCE_OFFICER`, `SMB_EMPLOYER`, `STATUTORY_REGULATOR`, `SUPPORT_SPECIALIST`, `SYSTEM_DAEMON`).
* `stakeholder_id`: Unique identifier (`STK-01` to `STK-10`).
* `stakeholder_category`: Enterprise grouping (`Executive Leadership`, `Corporate Recruitment`, `Job Seekers`, `Contingent Workforce`, etc.).

### Section L1.2: Persona Archetypes & Edge Actors (`P-01` to `P-12`)
* `persona_id`: Unique identifier (`P-01` to `P-12`). Mandatory.
* `persona_name`: Representative persona archetype (e.g. Asha, Rohan, Elena).
* `actor_type`: Classification (`Core Human`, `Edge Human`, `Edge System`).
* `interaction_frequency`: Quantitative activity metric (e.g. Daily Continuous, Weekly Strategic, Sub-Second Continuous).
* `mapped_requirements`: Array of `REQ-xx` identifiers satisfied by or affecting this persona.
* `key_guardrail`: Primary physical database constraint protecting the persona's operational boundary.

### Section L1.3: $12 \times 11$ Module CRUD Matrix
* `module_code`: Functional platform subsystem (`IDENTITY`, `ORGANISATION`, `RECRUITMENT`, `PROFILE`, `GIG`, `SOURCING`, `LICENSING`, `BILLING`, `PRIVACY`, `AUDIT`, `ANALYTICS`).
* `crud_grant`: 4-character entitlement string (`C` = Create, `R` = Read, `U` = Update, `D` = Delete, `-` = Denied).
