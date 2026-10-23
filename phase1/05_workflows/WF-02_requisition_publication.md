# WF-02: Job Requisition Creation, Screening & Multi-Channel Publication
**Lifecycle Domain:** Corporate Recruitment & Academic Sourcing  
**Associated Features:** `F-02`, `F-04`, `F-05`, `F-19`, `F-20`, `F-21`  
**Participating Actors:** Recruiter (`P-01`), Account Administrator (`P-06`), Academic Partner (`P-07`), System Daemon (`P-12`)  

---

## 1. Operational Specification (6-Parameter Tuple)

* **Trigger**: Recruiter or Hiring Manager creates a draft requisition to fill an open role within an approved organizational department or university cohort drive.
* **Steps**:
  1. Recruiter specifies job title, department, branch office location hierarchy, employment type (full-time, contract, internship), and ISO 4217 numeric currency compensation band (`min_salary <= max_salary`).
  2. Recruiter configures mandatory screening questionnaire (e.g., minimum years of experience, mandatory certifications, work authorization status) and defines automated scoring pass thresholds.
  3. Requisition submitted for organizational approval if estimated compensation exceeds department budget threshold; Account Administrator reviews and approves.
  4. Recruiter selects publication target channels: platform public marketplace, external job board syndication, or targeted academic cohort drives (linking designated university campus partner programs).
  5. System publishes the job requisition, updates real-time search index, and broadcasts notifications to qualified academic placement cohorts.
  6. Recruiter monitors applicant funnel velocity and channel conversion analytics.
* **Actors**: Recruiter (`P-01`) drafts and publishes; Account Administrator (`P-06`) authorizes budget allocation; Academic Partner (`P-07`) coordinates university cohort participation; System Daemon (`P-12`) indexes and broadcasts.
* **Decisions**:
  - *Decision 1*: Does the proposed compensation band violate enterprise budget limits? (If Yes -> route to Account Administrator for budget approval; If No -> proceed directly to publication).
  - *Decision 2*: Is this requisition flagged for university campus placement? (If Yes -> link requisition to Academic Partner cohort pools and restrict visibility to validated campus candidate batches; If No -> syndicate to public search index).
* **Exceptions**:
  - `EXC-05`: Negative or inverted salary range (`min_salary > max_salary` or `min_salary < 0` rejected at validation).
  - `EXC-06`: Inactive or suspended organizational branch (publication blocked until branch status restored).
  - `EXC-07`: Enterprise requisition quota exhausted under current active license tier (notifies administrator to upgrade subscription).
  - `EXC-08`: Syndication webhook timeout or external board rejection (queued for exponential backoff retry).
  - `EXC-33`: Requisition approval pending budget sign-off for >14 days (timeout path: system daemon auto-archives stagnant draft requisition).
* **Outputs**: Live, indexed job requisition accepting candidate applications, with configured screening scoring engine and allocated hiring budget.

---

## 2. State Machine: Job Requisition Lifecycle

```
[DRAFT] ──► [PENDING_APPROVAL] ──► [APPROVED] ──► [PUBLISHED_ACTIVE] ──► [CLOSED_FILLED]
   │               │                                      │                    │
   │ (Discarded)   │ (Rejected)                           │ (Hire Completed)   │ (Archived)
   ▼               ▼                                      ▼                    ▼
[ARCHIVED]    [REJECTED_DRAFT]                       [ON_HOLD]             [HISTORICAL]
```

| Origin State | Destination State | Triggering Condition | Guard Condition / Enforcement |
| :--- | :--- | :--- | :--- |
| `DRAFT` | `PENDING_APPROVAL` | Recruiter submits requisition requiring budget sign-off | Department budget rules require approval if salary > tier threshold |
| `DRAFT` | `PUBLISHED_ACTIVE` | Recruiter publishes requisition within approved budget limit | Requisition quota check passes; valid salary band and skills |
| `PENDING_APPROVAL` | `APPROVED` | Account Administrator grants budget sign-off | Admin holds valid financial authorization permission |
| `PENDING_APPROVAL` | `REJECTED_DRAFT` | Account Administrator denies budget sign-off | Requires mandatory rejection rationale comment |
| `APPROVED` | `PUBLISHED_ACTIVE` | System launches automated publishing pipeline | Target search index updated; webhooks dispatched |
| `PUBLISHED_ACTIVE` | `ON_HOLD` | Hiring team pauses active candidate intake | Requisition hidden from public search; existing applications frozen |
| `ON_HOLD` | `PUBLISHED_ACTIVE` | Recruiter unpauses requisition | Requisition restored to public search index |
| `PUBLISHED_ACTIVE` | `CLOSED_FILLED` | Final candidate signs accepted offer | Target head-count fulfilled; pending applicants notified |
| `CLOSED_FILLED` | `HISTORICAL` | Requisition retained past 90 days of fill date | Read-only mode for audit and reporting compliance |
