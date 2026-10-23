# WF-04: Candidate Sourcing, Agency Marketplace & Resume Contact Unlocking
**Lifecycle Domain:** Sourcing Intelligence, Agency Representation & Monetization  
**Associated Features:** `F-06`, `F-08`, `F-09`, `F-16`  
**Participating Actors:** Recruiter (`P-01`), Staffing Consultant (`P-05`), Data Privacy Officer (`P-08`), Support Specialist (`P-11`), System Daemon (`P-12`)  

---

## 1. Operational Specification (6-Parameter Tuple)

* **Trigger**: Recruiter searches active talent database for specialized skills, or Staffing Consultant presents an exclusive represented candidate for an enterprise opening.
* **Steps**:
  1. Recruiter executes query using boolean keywords, skill tags, experience ranges, and geographic radius.
  2. Search engine applies mandatory anti-join privacy filter to exclude any candidates who have placed the recruiter's employer on their block list.
  3. Recruiter views anonymized profile previews (displaying skills, redacted work experience, and educational background, but masking email, phone, and full name).
  4. Recruiter initiates "Unlock Contact" action; system verifies recruiter's organization has available monthly resume unlock quota or sufficient prepaid wallet credits.
  5. System debits one unlock quota credit or charges wallet, grants authorized contact access for that candidate to the organization while candidate consent remains active, and logs immutable audit record. If the candidate subsequently withdraws consent under the DPDP Act, contact details are masked across all recruiter views immediately, and if withdrawal occurs within 30 days of unlock, the organization's unlock credit is refunded automatically (ADR-10).
  6. If candidate was submitted via Staffing Consultant marketplace (`F-08`), representation agreement locks ownership for 180 days; upon successful hire, platform escrow reserves split placement bounty for the agency.
  7. In the event of dual-agency representation disputes, Support Specialist arbitrates based on verifiable timestamped candidate consent evidence.
* **Actors**: Recruiter (`P-01`) searches and unlocks; Staffing Consultant (`P-05`) submits candidates and claims placement fees; Data Privacy Officer (`P-08`) audits contact access; Support Specialist (`P-11`) arbitrates agency representation disputes; System Daemon (`P-12`) enforces quota limits and resets monthly allotments.
* **Decisions**:
  - *Decision 1*: Does candidate have an active privacy shield blocking the querying organization? (If Yes -> profile omitted entirely from search result set; If No -> anonymized snippet included).
  - *Decision 2*: Does recruiter's organization hold active unlock quota or positive wallet balance? (If Yes -> execute unlock and reveal contact information; If No -> present quota purchase modal).
  - *Decision 3*: Is candidate already represented by another staffing consultant for this enterprise requisition? (If Yes -> reject submission with duplicate representation notification; If No -> establish 180-day agency exclusivity).
* **Exceptions**:
  - `EXC-14`: Quota exhaustion on contact unlock attempt (notifies recruiter to purchase top-up credits or upgrade subscription).
  - `EXC-15`: Redundant unlock attempt on previously unlocked candidate (system returns existing cached contact details without double-charging).
  - `EXC-16`: Conflicting agency representation claim (escalated to Support Specialist for arbitration).
  - `EXC-17`: Contact access audit failure (logs security alert to Data Privacy Officer).
  - `EXC-31`: Unlocked candidate exercises DPDP consent revocation within 30 days of unlock (refund path: system refunds one unlock credit back to organization quota pool; contact masked).
  - `EXC-32`: Transient gateway network timeout on external phone/email verification dispatch (retry path: enqueued for idempotent exponential backoff retry).
* **Outputs**: Full candidate contact information revealed to recruiter, quota deducted, permanent authorization record stored, and agency attribution locked.

---

## 2. State Machine: Resume Contact Unlock & Agency Representation

```
[MASKED_PROFILE_DISCOVERED] ──► [UNLOCK_REQUESTED] ──► [FUNDS/QUOTA_VERIFIED] ──► [CONTACT_REVEALED]
             │                          │                       │
             │ (Blocked Employer)       │ (Insufficient Quota)   │ (Agency Dispute)
             ▼                          ▼                       ▼
    [SILENTLY_FILTERED]         [TOPUP_REQUIRED]        [DISPUTE_ARBITRATION]
```

| Origin State | Destination State | Triggering Condition | Guard Condition / Enforcement |
| :--- | :--- | :--- | :--- |
| `MASKED_PROFILE_DISCOVERED` | `UNLOCK_REQUESTED` | Recruiter clicks "Unlock Contact Details" | Candidate not blocked by privacy shield |
| `UNLOCK_REQUESTED` | `FUNDS/QUOTA_VERIFIED` | System verifies organization balance | Monthly credits > 0 OR wallet balance >= unlock fee |
| `UNLOCK_REQUESTED` | `TOPUP_REQUIRED` | Insufficient credits and insufficient funds | Balance check fails; notify admin to replenish wallet |
| `FUNDS/QUOTA_VERIFIED` | `CONTACT_REVEALED` | Atomic debit transaction completes | Deduct 1 credit; log audit record; expose PII |
| `REPRESENTATION_PROPOSED` | `AGENCY_LOCKED` | Consultant submits candidate with consent | Candidate not submitted to requisition in past 180 days |
| `REPRESENTATION_PROPOSED` | `DISPUTE_ARBITRATION` | Dual agency claims submitted within 48h | Support Specialist reviews signed representation letters |
| `DISPUTE_ARBITRATION` | `AGENCY_LOCKED` | Arbiter resolves in favor of primary agency | Arbiter records formal resolution note |
