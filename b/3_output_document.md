# Talentra — Stakeholders, Personas & Roles
**Project**: Talentra Job Search & Demand Management Platform  
**Organization**: Northbridge Workforce Systems  
**Document**: Deliverable B3 — Actor Personas & Access Architecture  
**Document Version**: 1.0 (Approved Baseline)  
**Target Database**: PostgreSQL 15+  

---

## 1. Stakeholder Ecosystem Overview

Talentra operates at the intersection of job seekers, employers, independent recruiters, and educational institutions. The platform models stakeholders across three primary categories:

```
Demand Stakeholders           Talent Supply               Governance & Platform
├── Corporate Employers       ├── Job Candidates          ├── Super & Platform Admins
├── In-House Recruiters       ├── Freelance Gig Workers   ├── Account IT Admins
└── Sourcing Consultants      └── Campus Officers (TPOs)  └── Security Auditors
```

### Core Stakeholder Groups & Success Outcomes

| Stakeholder Group | Primary Goal / Success Outcome | Primary Database Schemas |
| :--- | :--- | :--- |
| **Job Candidates** | Accurate profiles, job matching, application status visibility, and robust privacy blocking. | `profile`, `recruitment`, `administration`, `engagement` |
| **Corporate Employers** | Verified company profile, posting requisitions, candidate screening, and pipeline tracking. | `organisation`, `recruitment`, `sourcing`, `billing`, `analytics` |
| **Corporate Recruiters** | Managing assigned requisitions, screening, outreach, and resume downloads within budget. | `organisation`, `recruitment`, `profile`, `billing` |
| **Sourcing Consultants** | Browsing open requisitions, submitting candidate shortlists, and tracking placement commissions. | `sourcing`, `recruitment`, `profile`, `billing` |
| **Gig Workers & Requesters**| Setting service availability, bidding on project gigs, tracking milestones, and rating requesters. | `gig`, `profile`, `billing`, `analytics` |
| **Placement Officers (TPOs)**| Managing student cohorts, tracking campus placement funnels, and institutional reporting. | `recruitment`, `profile`, `organisation`, `analytics` |
| **Account Administrators** | Provisioning recruiter seats, managing device session limits, and monitoring spend. | `organisation`, `licence`, `billing`, `administration` |
| **Platform Administrators** | System health, global master data (skills, locations), and dispute resolution. | All 11 Subsystems (Global Scope) |
| **Security & Financial Auditors**| Verifying append-only audit trails, PII compliance, and financial ledger reconciliations. | `administration`, `billing`, `licence` (Read-Only) |
| **System Integrations** | Webhook receivers, background queue consumers, SMS/email dispatches, and ETL jobs. | `billing`, `engagement`, `administration`, `gig` |

---

## 2. Representative Persona Archetypes

### P-01: Asha — Mid-Career Software Engineer (Candidate)
* **Role**: `CANDIDATE` | **Frequency**: Daily active during job search; weekly passive via alerts.
* **Core Workflows**:
  * Updates profile, skills, and portfolio projects; attaches multiple resume versions.
  * Searches requisitions with salary filters; tracks real-time application status (`APPLIED` $\rightarrow$ `INTERVIEW` $\rightarrow$ `OFFERED`).
  * Blocks current employer (`TechCorp India`) and aggressive agency headhunters.
* **Key Security Guardrail**: Blocked employers and recruiters can never view Asha's profile in search results or sourcing pools.

### P-02: Rohan — VP of Talent Acquisition (Employer / Client)
* **Role**: `EMPLOYER` | **Frequency**: Daily active.
* **Core Workflows**:
  * Registers corporate entity, submits GSTN/tax documents for verification, and sets up branch locations.
  * Publishes requisitions, attaches screening questionnaires, and reviews qualified candidates.
  * Enables consultant sourcing for niche engineering roles (`open_to_consultants = TRUE`).
* **Key Security Guardrail**: Rohan can only view and manage jobs belonging to his company. Multi-tenant Row-Level Security (`RLS`) isolates his organization's data.

### P-03: Meera — In-House Senior Recruiter (Recruiter)
* **Role**: `RECRUITER` | **Frequency**: Continuous throughout the day.
* **Core Workflows**:
  * Reviews applicant queues for assigned jobs; advances candidates through screening and interviews.
  * Searches talent pools, sends outreach messages, and downloads candidate contact details using company wallet credits.
* **Key Security Guardrails**:
  * Meera can only access requisitions assigned to her company.
  * Meera **cannot** register candidates on their behalf (candidates must register themselves).
  * Every resume download must record an immutable ledger deduction against her company's wallet.

### P-04: Kabir — Independent Tech Headhunter (Consultant)
* **Role**: `CONSULTANT` | **Frequency**: Weekly burst.
* **Core Workflows**:
  * Browses requisitions marked `open_to_consultants = TRUE`.
  * Submits sourcing requests to employers; upon employer approval, submits candidate shortlists.
  * Tracks commission payouts upon successful hiring.
* **Key Security Guardrail**: Kabir cannot view applicant data or submit candidates until the employer explicitly marks his sourcing request as `ACCEPTED`.

### P-05: Dev — Full-Stack Cloud Freelancer (Gig Worker)
* **Role**: `CANDIDATE` (Sub-profile: `GIG_WORKER`) | **Frequency**: Weekly active.
* **Core Workflows**:
  * Maintains service offerings, fixed/hourly rate cards, and calendar availability windows.
  * Bids on project-based gig requests; receives external fulfilment handoff tokens.
  * Reviews reconciled earnings and rates project requesters.
* **Key Security Guardrail**: Dev cannot be booked for overlapping gig dates. Database GiST exclusion constraints prevent double-booking.

### P-06: Nisha — Enterprise IT Administrator (Account Admin)
* **Role**: `ACCOUNT_ADMIN` | **Frequency**: Weekly administrative.
* **Core Workflows**:
  * Provisions and deprovisions recruiter seats according to the company's subscription license.
  * Monitors active device sessions; revokes stale or unauthorized mobile logins.
  * Reviews monthly wallet consumption and invoice receipts.
* **Key Security Guardrail**: Cannot exceed license seat quotas or assign devices beyond `max_devices_per_user`.

### P-07: Prof. Verma — Training & Placement Officer (TPO)
* **Role**: `TPO` | **Frequency**: High-burst during placement season.
* **Core Workflows**:
  * Manages student rosters, verifies academic degrees, and creates college candidate cohorts.
  * Interfaces with campus hiring drives; monitors student interview conversion funnels.
* **Key Security Guardrail**: Scope is strictly restricted to students belonging to his verified educational institution.

### P-08: Ira — Internal Security & Compliance Auditor (Auditor)
* **Role**: `AUDITOR` | **Frequency**: Monthly audit reviews.
* **Core Workflows**:
  * Inspects system audit logs for unauthorized access attempts, privilege escalations, and PII exports.
  * Reconciles wallet transactions against payment gateway receipts.
* **Key Security Guardrail**: Read-only access across all schemas. Cannot update or delete records under any circumstance.

### P-09: Vikram — Global Platform Administrator (Super Admin)
* **Role**: `SUPER_ADMIN` | **Frequency**: Daily operations.
* **Core Workflows**:
  * Manages global master data (skill taxonomies, ISO countries, currencies).
  * Manages subscription plans, wallet pricing models, and system-wide feature flags.
  * Oversees database replication health, partitioning, and backup verification.
* **Key Security Guardrail**: All administrative actions are recorded in the append-only audit trail. Super admins cannot bypass financial ledger immutability triggers.

---

## 3. Subsystem Permission Matrix

| Database Module | Candidate | Employer | Recruiter | Consultant | Gig Worker | TPO | Account Admin | Super Admin | Auditor |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `master_data` | Read | Read | Read | Read | Read | Read | Read | CRUD | Read |
| `profile` (Core) | CRUD (Own) | Read (Public) | Read/Download | Read (Public) | CRUD (Own) | Read (Cohort) | Read (Company) | Read | Read |
| `recruitment` (Jobs) | Read (Public) | CRUD (Own) | CRUD (Assigned)| Read (Open Only) | Read (Public) | Read (Campus) | Read (Company) | CRUD | Read |
| `recruitment` (Apps) | CRU (Own) | Read/Update | Read/Update | Create (Sourced) | -- | Read (Cohort) | Read (Company) | Read | Read |
| `organisation` | Read (Public) | CRUD (Own) | Read (Company) | Read (Public) | Read (Public) | Read (Public) | CRUD (Own) | CRUD | Read |
| `administration` | Update (Consent) | -- | -- | -- | Update (Consent)| -- | CRUD (Company) | CRUD | Read |
| `gig` | -- | CRUD (Req) | -- | -- | CRUD (Worker) | -- | -- | CRUD | Read |
| `licence` | -- | Read (Company)| -- | -- | -- | -- | CRUD (Seats) | CRUD | Read |
| `sourcing` | -- | CRUD (Approvals)| Read (Outreach) | CRU (Approved) | -- | -- | Read (Company) | CRUD | Read |
| `billing` & Wallet | -- | Read (Invoices)| Read Balance | Read Balance | Read (Earnings)| -- | CRUD (Orders) | CRUD | Read |
| `engagement` | CRUD (Own) | CRUD (Own) | CRUD (Own) | CRUD (Own) | CRUD (Own) | CRUD (Own) | CRUD (Own) | CRUD | Read |
| `analytics` | -- | Read (Reports)| Read (Funnel) | Read (Stats) | Read (Stats) | Read (Reports) | Read (Reports) | CRUD | Read |

---

## 4. Mandatory Database Guardrails

The database architecture enforces the rules from Section 3 of the Problem Docket at the database tier:

### G-01: Recruiter Tenant Isolation
* **Requirement**: Recruiters may only view and act on job requisitions belonging to their own company.
* **Implementation**: PostgreSQL Row-Level Security (`RLS`) policy:
  ```sql
  ALTER TABLE recruitment.job_requirement ENABLE ROW LEVEL SECURITY;
  CREATE POLICY recruiter_org_isolation ON recruitment.job_requirement
  FOR ALL TO recruiter_role
  USING (organisation_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID);
  ```

### G-02: Candidate Privacy & Negative Sourcing Blocks
* **Requirement**: When a candidate blocks an employer or recruiter, that blocked party must never see the candidate in search results or talent shortlists.
* **Implementation**: Candidate directory search view uses an anti-join against `candidate_block_list`:
  ```sql
  CREATE VIEW profile.vw_searchable_candidate AS
  SELECT c.* FROM profile.candidate_profile c
  WHERE c.is_searchable = TRUE
    AND c.user_id NOT IN (
      SELECT b.candidate_user_id FROM administration.candidate_block_list b
      WHERE b.blocked_organisation_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID
         OR b.blocked_user_id = NULLIF(current_setting('app.current_user_id', true), '')::UUID
    );
  ```

### G-03: Consultant Requisition Gate
* **Requirement**: Consultants can only access requisitions that are open to consultants and have an accepted sourcing request.
* **Implementation**: Database RLS policy on `job_requirement` requires `open_to_consultants = TRUE` and an existing record in `sourcing.sourcing_request` where `status = 'ACCEPTED'`.

### G-04: Prohibition of Proxy Registration
* **Requirement**: Recruiters cannot register candidates on a candidate's behalf.
* **Implementation**: Database role grants explicitly omit `INSERT` privileges on `profile.candidate_profile` for the recruiter database role.

### G-05: Concurrent Device & Session Limit
* **Requirement**: A user cannot hold more active sessions than their license device limit (`max_devices_per_user`).
* **Implementation**: `administration.authenticate_session()` stored procedure locks active session rows (`FOR UPDATE`) inside the login transaction, aborting if the active count meets or exceeds the license quota.

### G-06: Append-Only Audit & Financial Records
* **Requirement**: Audit logs and financial wallet ledgers are strictly append-only.
* **Implementation**: Database triggers immediately raise exceptions on any `UPDATE` or `DELETE` attempt.

---

## 5. Quality Verification: Access & Security Test Taxonomy

Access and persona security verification is structured across five core engineering branches:

```
Access & Security Test Graph
 ├── 1. Structure & Project Best Practices (Role catalogs, system flags, surrogate keys)
 ├── 2. Data Integrity & Data Quality (Effective dates, email regex, unique mappings)
 ├── 3. Business Rules & Behaviour (Consultant sourcing gating, proxy registration bar)
 ├── 4. Security, Privacy & Access (RLS isolation, negative block suppression, device limits)
 └── 5. Non-Functional Requirements & Resilience (Concurrent login race condition locks)
```

| Branch | Test ID | Description | Target Object | Verification Method | Expected Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Structure & Best Practices** | `SEC-STR-01` | Verify that roles and permissions use surrogate PKs and unique code constraints. | `administration.role`, `administration.user_role` | SQL DDL inspection | Primary key is UUID; unique constraint on role code. |
| **2. Data Integrity & Quality** | `SEC-INT-01` | Insert recruiter mapping with `end_date < start_date`. | `organisation.organisation_recruiter_mapping` | Invalid SQL date insert | Aborts with `CHECK constraint violation`. |
| **3. Business Rules & Behavior** | `SEC-BIZ-01` | Recruiter attempts direct `INSERT INTO profile.candidate_profile`. | `profile.candidate_profile` | SQL insert as recruiter role | Aborts with `permission denied for table candidate_profile`. |
| **3. Business Rules & Behavior** | `SEC-BIZ-02` | Consultant attempts submitting candidate to job with `open_to_consultants = FALSE`. | `sourcing.sourcing_candidate_submission` | Gated submission query | Aborts with foreign key / authorization violation. |
| **4. Security, Privacy & Access** | `SEC-ACC-01` | Recruiter queries candidate search view for candidate who blocked their organisation. | `profile.vw_searchable_candidate` | Search query with recruiter context | Candidate row completely omitted from result set. |
| **5. Non-Functional & Resilience** | `SEC-NFR-01` | Simulate 5 simultaneous login attempts for user with `max_devices_per_user = 2`. | `administration.authenticate_session()` | Concurrent thread execution | Exactly 2 succeed; 3 reject with `Device Limit Exceeded` via row lock serialization. |
