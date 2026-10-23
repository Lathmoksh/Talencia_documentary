# Talentra: Enterprise Workforce & Talent Marketplace Platform
## Phase 1: Discover — Canonical Requirements, Actors, Features & Workflows

---

## 1. Executive Summary

**Talentra** is an enterprise talent acquisition and workforce mobilization platform engineered to unify permanent lateral hiring, contingent gig labor contracting, and university graduate cohort drives within a single multi-tenant ecosystem.

This repository encapsulates the canonical, single-source-of-truth deliverables for **Phase 1: Discover (Steps 01 through 05)**, fully aligned with the principle: **"Understand before you model — nothing is modelled yet."** 

All physical data definitions, database schemas, and ER diagrams have been parked in [`phase2_draft/`](phase2_draft/) for upcoming implementation phases. The [`phase1/`](phase1/) directory contains pure business requirements, single-source actor vocabularies, user-facing feature mappings, end-to-end workflow specifications, and automated verification suites.

---

## 2. Directory Structure

```
talencia2/
├── README.md                           # Master system overview and discovery documentation
├── phase1/                             # Pure Phase 1 Discover Single-Source-of-Truth
│   ├── 00_decision_log.md              # Architectural decisions (ADR-01..10) & policy assumptions register
│   ├── 01_requirements.csv             # 29 pure business requirements (REQ-01..29) with status column
│   ├── 02_actors.md                    # Single canonical vocabulary across 12 personas (P-01..12)
│   ├── role_permission.csv             # Exhaustive 12-persona x 11-module CRUD authorization matrix
│   ├── 03_features.csv                 # 23 user-facing features (F-01..23) with trace_note column
│   ├── 04_nfr_register.csv             # 14 measurable NFRs with metrics, targets & derivations
│   ├── brief_extract.md                # Reconstructed reference extract for BRIEF-SEC-*. citations
│   ├── competitor_matrix.csv           # 15 capabilities benchmarked with per-competitor verdicts & deep links
│   ├── volumetric_model.py             # Workload modeling script deriving throughput & capacity targets
│   ├── volumetric_model.csv            # Sizing model output (189.4 TPS peak write load, 284 TPS capacity target)
│   ├── g1_check.py                     # Primary automated Gate 1 structural verification harness (7 checks)
│   ├── g1_extra_checks.py              # Secondary automated Gate 1 reference, substance & sync checker
│   └── 05_workflows/                   # End-to-end lifecycle workflows (6-parameter tuples)
│       ├── WF-01_candidate_onboarding.md
│       ├── WF-02_requisition_publication.md
│       ├── WF-03_application_pipeline.md
│       ├── WF-04_sourcing_and_unlock.md
│       ├── WF-05_gig_contracting.md
│       ├── WF-06_subscription_licensing.md
│       ├── WF-07_wallet_and_payout.md
│       └── exceptions.csv              # 36 failure paths (CANCEL, REFUND, RETRY, TIMEOUT)
├── phase2_draft/                       # Parked physical DDL schemas & ERDs for subsequent phases
│   ├── README.md                       # Warning notice & known pre-model draft defects list
│   ├── a_schema_design.sql & a_er_diagram.png
│   ├── b_schema_design.sql & b_er_diagram.png
│   ├── c_schema_design.sql & c_er_diagram.png
│   ├── d_schema_design.sql & d_er_diagram.png
│   └── e_schema_design.sql & e_er_diagram.png
└── archive/                            # Superseded legacy documents (Folders a through e)
    └── README.md                       # Superseded artifacts notice
```

---

## 3. Discovery Core Artifacts

### 3.1 Business Requirements ([`phase1/01_requirements.csv`](phase1/01_requirements.csv))
29 atomic business requirements (`REQ-01` to `REQ-29`) stating business needs rather than implementation solutions:
- **Columns**: `REQ-id`, `statement`, `brief_ref`, `priority`, `actors`, `open_question`, `status`.
- Requirements `REQ-01` to `REQ-25` trace to brief clauses detailed in [`phase1/brief_extract.md`](phase1/brief_extract.md).
- Requirements `REQ-26` to `REQ-29` represent candidate-side capabilities (Faceted Search, Job Alerts, Direct Messaging, and Application Journey Tracking) introduced from competitive discovery (`COMP-DISC-*`).
- Zero physical implementation solution leaks (no physical database engine terms, hashing algorithms, or internal locking mechanics in requirements statements).

### 3.2 Canonical Actors & Role Permissions ([`phase1/02_actors.md`](phase1/02_actors.md) & [`phase1/role_permission.csv`](phase1/role_permission.csv))
- **12 Canonical Personas**:
  - `P-01`: Recruiter / Talent Acquisition Specialist (`RECRUITER`)
  - `P-02`: Job Seeker / Professional Candidate (`CANDIDATE`)
  - `P-03`: Freelance Professional / Contingent Gig Worker (`GIG_WORKER`)
  - `P-04`: Corporate Executive / Business Owner (`EXECUTIVE`)
  - `P-05`: External Staffing Consultant (`STAFFING_CONSULTANT`)
  - `P-06`: Account Administrator / Billing Owner (`ACCOUNT_ADMIN`)
  - `P-07`: University Placement Officer / Academic Partner (`ACADEMIC_PARTNER`)
  - `P-08`: Data Privacy Officer / Compliance Officer (`COMPLIANCE_OFFICER`)
  - `P-09`: SMB Client / Project Manager (`SMB_EMPLOYER`)
  - `P-10`: Statutory Auditor / Regulatory Authority (`STATUTORY_REGULATOR`)
  - `P-11`: Support Specialist / Platform Arbiter (`SUPPORT_SPECIALIST`)
  - `P-12`: System Automation Engine (`SYSTEM_DAEMON`)
- **Enforced Security Invariants**:
  - `system_audit` is strictly append-only: Compliance Officer (`P-08`) and Auditors inspect logs read-only (`R---`), while System Daemon records operational events (`CR--`). No update or delete operations are permitted.
  - `wallet_billing` enforces double-entry ledger invariants: Delete operations (`D`) are globally forbidden across all human and administrative roles.

### 3.3 User-Facing Features ([`phase1/03_features.csv`](phase1/03_features.csv))
23 user-facing features (`F-01` to `F-23`) prioritized using MoSCoW methodology, each accompanied by an explicit `trace_note` documenting the exact architectural and functional rationale connecting the feature to its mapped business requirements.

### 3.4 Operational Workflows ([`phase1/05_workflows/`](phase1/05_workflows/))
7 end-to-end lifecycle workflows defined via 6-parameter tuples (*Trigger, Steps, Actors, Decisions, Exceptions, Outputs*) with explicit state machines:
- **WF-01**: Candidate Onboarding, Privacy Shield & Consent Lifecycle
- **WF-02**: Job Requisition Publishing, Screening & Multi-Channel Syndication
- **WF-03**: Candidate Application Pipeline (Complete 13-stage progression from `SUBMITTED` through `HIRED` / `WITHDRAWN`)
- **WF-04**: Candidate Sourcing, Agency Marketplace & Resume Contact Unlocking (Includes 30-day DPDP withdrawal credit refund)
- **WF-05**: Freelance Gig Engagement, Conflict-Free Scheduling & Milestone Delivery
- **WF-06**: Enterprise Subscription, Recruiter Seat Caps & Concurrency Protection
- **WF-07**: Wallet Deposit, Double-Entry Escrow & Freelancer Bank Payout
- **`exceptions.csv`**: 36 concrete exception paths covering all 4 failure categories (`CANCEL_PATH`, `REFUND_PATH`, `RETRY_PATH`, `TIMEOUT_PATH`) across all workflows.

### 3.5 Volumetric Capacity Model ([`phase1/volumetric_model.py`](phase1/volumetric_model.py))
Mathematical workload derivations generated in [`phase1/volumetric_model.csv`](phase1/volumetric_model.csv):
- **Job Applications**: 5,000,000 annual applications across 250 business days; 8 database writes per application; 25x seasonal burst factor yielding **138.9 application write TPS**.
- **Contingent Gig Milestones**: 200,000 monthly milestones across 22 days; 4 ledger writes per milestone; 15x payroll burst factor yielding **18.9 financial write TPS**.
- **Profile Updates & Consent**: 1,000,000 candidates averaging 2 updates/month (90,909 updates/day); 10x burst factor yielding **31.6 profile write TPS**.
- **Candidate Talent Search**: 10,000 recruiters executing 40 searches/day; 10x burst factor yielding **138.9 search queries/sec (QPS)**.
- **Total Peak Write Workload**: Sum of application (138.9) + gig ledger (18.9) + profile writes (31.6) = **189.4 peak write TPS**.
- **Designed Storage/Engine Capacity**: 189.4 TPS $\times$ 1.5 safety headroom multiplier = **284 TPS capacity target**.

---

## 4. Verification Harnesses & Quality Status

Phase 1 provides two automated verification suites located in `phase1/`:

```bash
# 1. Primary structural & traceability verification (7 checks):
python phase1/g1_check.py

# 2. Reference integrity, substance, non-circular NFR & persona-sync checker:
python phase1/g1_extra_checks.py
```

### Current Quality Status
**Pre-checks pass; awaiting formal reviewer sign-off.**

### Gate 1 Review Log

| Date | Reviewer | Role | Review Scope / Focus | Status / Verdict |
| :--- | :--- | :--- | :--- | :--- |
| 2026-10-23 | Senior Architecture Reviewer | Peer Reviewer | Structural gate review, reference substance, NFR non-circularity, persona sync & deep-link audit | Pre-checks pass; formal audit pending |
