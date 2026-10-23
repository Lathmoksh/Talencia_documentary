# Talentra — Stakeholders, Personas & Roles Docket
**Document Reference**: Deliverable B3 — Actor Modeling & Authorization Governance  
**Platform**: Talentra Enterprise Workforce Platform  
**Architecture Domain**: Identity, Multi-Tenancy & Authorization  
**Status**: Approved & Frozen for Implementation  

---

## 1. Executive Purpose & Governance Scope

This docket models the human, external, and automated actors who operate within the Talentra platform. It translates enterprise organizational taxonomies into actionable persona archetypes, access frequency profiles, CRUD entitlement matrices across 11 core subsystems, and physical database security guardrails.

In strict compliance with Phase 1 Discover specifications, this analysis incorporates core business actors alongside critical **edge actors** (statutory compliance auditors, technical support agents, and automated system maintenance daemons), ensuring zero unmapped requirements and complete role governance.

---

## 2. Enterprise Stakeholder Taxonomy (`STK-01` to `STK-10`)

| Stakeholder ID | Category | Stakeholder Description | Primary Strategic Responsibility |
| :--- | :--- | :--- | :--- |
| **STK-01** | **Executive Leadership** | Chief Human Resources Officers, VPs of Talent Acquisition | Platform adoption, organizational hiring velocity, commercial licensing ROI. |
| **STK-02** | **Corporate Recruitment** | In-house enterprise talent acquisition partners, sourcing leads | Job requisition management, candidate pipeline progression, offer extension. |
| **STK-03** | **Job Seekers & Talent** | Professional candidates, campus freshers, apprentice applicants | Profile curation, resume privacy control, job search, application tracking. |
| **STK-04** | **Contingent Workforce** | Independent contractors, gig workers, subject-matter experts | Trade showcase, milestone proposal submission, calendar availability. |
| **STK-05** | **Staffing Consultancies**| Third-party recruitment agencies, executive search firms | Split-commission candidate representation, candidate sourcing marketplace. |
| **STK-06** | **Academic Partners** | University career centers, vocational placement departments | Campus batch cohort management, verified credential verification. |
| **STK-07** | **System Administration**| Corporate IT tenant administrators, HR operations managers | Tenant seat allocation, branch hierarchies, user role provisioning. |
| **STK-08** | **Statutory Regulators** | Data protection authorities, labor compliance inspectors | Enforcement of DPDP Act 2023, GDPR Article 17 erasure, audit trail integrity. |
| **STK-09** | **Technical Operations** | Tier-2/3 technical helpdesk, support engineers | Operational troubleshooting, session unlock, payment webhook reconciliation. |
| **STK-10** | **System Daemons** | Automated cron workers, partition cleaners, queue processors | Scheduled partition rollover, asynchronous DPDP erasure, WAL streaming. |

---

## 3. Comprehensive Persona Profiles & Edge Actors (`P-01` to `P-12`)

Every persona below defines operational goals, interaction frequency, associated requirement IDs, and database guardrails:

### Core Enterprise Personas
* **P-01: Asha — Corporate Senior Recruiter**
  * **Role Code**: `RECRUITER` | **Frequency**: Daily Continuous (50–150 interactions/day)
  * **Goals**: Publish job openings, screen applications, schedule interviews, and unlock candidate resumes.
  * **Mapped Requirements**: `REQ-02`, `REQ-07`, `REQ-08`, `REQ-13`, `REQ-18`, `REQ-24`.
  * **Key Guardrail**: Restricted strictly to hiring `organisation_id` via PostgreSQL Row-Level Security (`RLS`).
* **P-02: Rohan — Mid-Level Software Engineer (Candidate)**
  * **Role Code**: `CANDIDATE` | **Frequency**: Weekly Interactive (5–15 interactions/week)
  * **Goals**: Build verified profile, upload resume, apply to curated requisitions, and block previous employers.
  * **Mapped Requirements**: `REQ-01`, `REQ-02`, `REQ-06`, `REQ-10`, `REQ-14`, `REQ-23`.
  * **Key Guardrail**: Anti-join privacy view completely hides profile from employers listed in `candidate_block_list`.
* **P-03: Kabir — Senior Cloud Solutions Architect (Gig Freelancer)**
  * **Role Code**: `GIG_WORKER` | **Frequency**: Daily On-Demand (10–30 interactions/day)
  * **Goals**: Publish multi-rate trade profiles, maintain availability calendar, submit gig bids, and receive wallet payouts.
  * **Mapped Requirements**: `REQ-04`, `REQ-15`, `REQ-17`, `REQ-20`.
  * **Key Guardrail**: PostgreSQL `GiST` exclusion constraint prevents double-booking across overlapping contract dates.
* **P-04: Meera — VP of Talent Acquisition (Executive Leader)**
  * **Role Code**: `EXECUTIVE` | **Frequency**: Weekly Strategic (1–3 dashboard sessions/week)
  * **Goals**: Monitor time-to-hire velocity, recruitment pipeline funnels, and enterprise subscription seat usage.
  * **Mapped Requirements**: `REQ-04`, `REQ-14`, `REQ-19`, `REQ-24`.
  * **Key Guardrail**: Read-only analytical queries executed against aggregate reporting marts.
* **P-05: Dev — Staffing Agency Account Director (Consultant)**
  * **Role Code**: `STAFFING_CONSULTANT` | **Frequency**: Daily Continuous (100+ interactions/day)
  * **Goals**: Source candidates for partner client requisitions and track commission revenue splits.
  * **Mapped Requirements**: `REQ-04`, `REQ-08`, `REQ-18`, `REQ-24`.
  * **Key Guardrail**: Access restricted to client requisitions where agency has an active sourcing contract.
* **P-06: Nisha — Corporate IT Tenancy Administrator (Admin)**
  * **Role Code**: `ACCOUNT_ADMIN` | **Frequency**: Weekly Administrative (5–10 sessions/week)
  * **Goals**: Manage corporate branch locations, provision recruiter seats, and inspect tax identifiers.
  * **Mapped Requirements**: `REQ-13`, `REQ-16`, `REQ-19`, `REQ-20`.
  * **Key Guardrail**: Seat assignments blocked at database layer when exceeding `max_recruiter_seats`.
* **P-07: Prof. Verma — University Placement Officer (Campus Partner)**
  * **Role Code**: `ACADEMIC_PARTNER` | **Frequency**: Seasonal Cohort (High-volume bursts during placement cycles)
  * **Goals**: Ingest early-career campus cohorts, verify degree credentials, and coordinate campus hiring drives.
  * **Mapped Requirements**: `REQ-07`, `REQ-22`, `REQ-23`.
  * **Key Guardrail**: Scope limited to candidate records matching associated educational institution ID.
* **P-08: Ira — Chief Data Privacy Officer (Compliance Auditor)**
  * **Role Code**: `COMPLIANCE_OFFICER` | **Frequency**: Monthly Audit (Periodic formal verification)
  * **Goals**: Audit statutory consent records, review data classification policies, and monitor DPDP erasure requests.
  * **Mapped Requirements**: `REQ-09`, `REQ-10`, `REQ-11`, `REQ-20`.
  * **Key Guardrail**: Full read access to immutable `system_audit_event` and `dpdp_consent_record`.
* **P-09: Vikram — Startup Founder & Small Business Employer**
  * **Role Code**: `SMB_EMPLOYER` | **Frequency**: Monthly On-Demand (As hiring needs arise)
  * **Goals**: Post fast gig contracts, review local talent, and disburse milestone payments from corporate wallet.
  * **Mapped Requirements**: `REQ-04`, `REQ-15`, `REQ-17`.
  * **Key Guardrail**: Pay-as-you-go wallet validation before gig contract execution.

### Specialized Enterprise Edge Actors
* **P-10 (Edge Actor): Elena — Statutory Data Protection Regulator & External Auditor**
  * **Role Code**: `STATUTORY_REGULATOR` | **Frequency**: Quarterly Formal Audit / On-Demand Investigation
  * **Goals**: Verify platform compliance with DPDP Act 2023, GDPR Article 17, and tamper-proof forensic audit trails.
  * **Mapped Requirements**: `REQ-09`, `REQ-10`, `REQ-11`, `REQ-20`.
  * **Key Guardrail**: Zero direct mutation permissions (`SELECT` only on audit logs and consent registries); immutable triggers prevent any log tampering.
* **P-11 (Edge Actor): Tariq — Tier-2/3 Technical Platform Support Specialist**
  * **Role Code**: `SUPPORT_SPECIALIST` | **Frequency**: Daily Operational (20–40 ticket resolutions/day)
  * **Goals**: Resolve candidate login lockouts, diagnose session locking clashes, and investigate webhook payment failures.
  * **Mapped Requirements**: `REQ-12`, `REQ-16`, `REQ-21`.
  * **Key Guardrail**: Cannot view cleartext candidate passwords or unmasked PII; actions captured in audit log with operator ID.
* **P-12 (Edge Actor): Daemon — Automated Background Maintenance & Retention Cleaner**
  * **Role Code**: `SYSTEM_DAEMON` | **Frequency**: Sub-Second Continuous (Automated database worker)
  * **Goals**: Roll over monthly audit partitions, expire idle session tokens, and execute asynchronous DPDP erasure cascades.
  * **Mapped Requirements**: `REQ-09`, `REQ-10`, `REQ-16`, `REQ-25`.
  * **Key Guardrail**: Executes under dedicated non-interactive service account (`app_user_id = 1`) with restricted schema permissions.

---

## 4. 11-Module CRUD Entitlement Matrix

| Module / Schema | Candidate (`P-02`) | Recruiter (`P-01`) | Gig Worker (`P-03`) | Account Admin (`P-06`) | Compliance (`P-08`, `P-10`) | System Daemon (`P-12`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Identity & Accounts** | `CRU-` (Own) | `R--` (Assigned) | `CRU-` (Own) | `CRUD` (Tenant) | `R--` (Audit) | `R-U-` (Session cleanup) |
| **2. Organisation Tenancy** | `R--` (Public) | `R--` (Tenant) | `R--` (Public) | `CRUD` (Tenant) | `R--` (Audit) | `---` |
| **3. Job Requirements** | `R--` (Public) | `CRUD` (Tenant) | `---` | `R--` (Tenant) | `R--` (Audit) | `---` |
| **4. Candidate Profiles** | `CRUD` (Own) | `R--` (Unmasked) | `---` | `---` | `R--` (Audit) | `R-U-` (Anonymization) |
| **5. Gig Marketplace** | `---` | `---` | `CRUD` (Own) | `CRUD` (Client) | `R--` (Audit) | `---` |
| **6. Sourcing & Screening** | `CR--` (Apply) | `CRUD` (Tenant) | `---` | `R--` (Tenant) | `R--` (Audit) | `---` |
| **7. Licensing & Seats** | `---` | `R--` (Own seat)| `---` | `CRUD` (Tenant) | `R--` (Audit) | `R-U-` (Quota sync) |
| **8. Wallet & Billing** | `---` | `R--` (Spend) | `R--` (Payout) | `CRUD` (Tenant) | `R--` (Audit) | `---` (Trigger only) |
| **9. Privacy & Block Lists**| `CRUD` (Own) | `---` | `---` | `---` | `R--` (Audit) | `---` |
| **10. System Audit Log** | `---` | `---` | `---` | `---` | `R--` (Full log) | `C---` (Append-only) |
| **11. Analytics Marts** | `---` | `R--` (Funnel) | `R--` (Earnings)| `R--` (Tenant) | `R--` (Compliance)| `C-U-` (Aggregate refresh)|

---

## 5. Physical Database Security Guardrails

1. **Multi-Tenant Row-Level Security (RLS)**:
   ```sql
   CREATE POLICY recruiter_org_isolation ON recruitment.job_requirement
   FOR ALL TO application_user
   USING (organisation_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID);
   ```
2. **Candidate Privacy Anti-Join View**:
   ```sql
   CREATE VIEW profile.v_discoverable_candidates AS
   SELECT c.*
   FROM profile.candidate_profile c
   WHERE c.is_searchable = TRUE
     AND NOT EXISTS (
       SELECT 1 FROM administration.candidate_block_list b
       WHERE b.candidate_user_id = c.user_account_id
         AND b.blocked_entity_user_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID
     );
   ```
3. **Single-Active-Session Concurrency Lock**:
   Stored procedure `enforce_single_active_session(p_user_id, p_session_token)` invalidates all existing sessions for that user prior to issuing a new active token.
