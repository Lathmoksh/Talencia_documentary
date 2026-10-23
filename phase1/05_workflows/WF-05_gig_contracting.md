# WF-05: Freelance Gig Engagement, Conflict-Free Scheduling & Milestone Delivery
**Lifecycle Domain:** Gig Economy, Service Contracting & Milestone Delivery  
**Associated Features:** `F-13`, `F-14`, `F-15`  
**Participating Actors:** Freelance Professional (`P-03`), Account Administrator (`P-06`), SMB Client (`P-09`), System Daemon (`P-12`)  

---

## 1. Operational Specification (6-Parameter Tuple)

* **Trigger**: SMB Client or Project Manager identifies a verified Freelancer profile and initiates a milestone-based gig proposal, or Freelancer bids on a published project scope.
* **Steps**:
  1. Client drafts contract specifying deliverables, delivery target dates, hourly or fixed milestone pricing in ISO 4217 currency, and required trade skills.
  2. System checks Freelancer's calendar booking schedule for the proposed date range (`start_date <= end_date`); enforces conflict-free validation to ensure no overlapping confirmed bookings exist.
  3. Client accepts proposal terms and authorizes initial milestone funding; Account Administrator's corporate wallet or SMB client payment card locks required funds into escrow.
  4. Freelancer is notified of escrow guarantee and marks contract active; work commences.
  5. Freelancer uploads milestone deliverables (files, code repositories, documentation links) and clicks "Submit Milestone for Review".
  6. Client reviews submission within contractual review window (default 7 days); client either approves milestone or requests structured revisions.
  7. Upon client approval, system releases escrow funds to freelancer's available wallet balance; platform service fee deducted.
* **Actors**: SMB Client (`P-09`) defines requirements and approves deliverables; Freelance Professional (`P-03`) submits bids and executes work; Account Administrator (`P-06`) funds wallet balance; System Daemon (`P-12`) enforces calendar availability, auto-releases escrow on review timeout, and handles reminders.
* **Decisions**:
  - *Decision 1*: Does the proposed gig timeframe overlap with an existing accepted contract on the freelancer's calendar? (If Yes -> reject booking request with date conflict alert; If No -> proceed to contract formation).
  - *Decision 2*: Does client have sufficient cleared funds in corporate wallet or credit card to fund the milestone escrow? (If Yes -> lock escrow and activate contract; If No -> halt activation until funds deposited).
  - *Decision 3*: Does client approve deliverable within the 7-day review window? (If Yes -> trigger escrow release; If No -> after 7 days without revision request, auto-release escrow to freelancer).
* **Exceptions**:
  - `EXC-18`: Calendar date conflict on freelancer booking attempt (rejected with suggestion of open alternative slots).
  - `EXC-19`: Insufficient client wallet balance for milestone escrow (booking remains draft until funded).
  - `EXC-20`: Milestone deliverable rejected with requested revision (retry path: resets milestone to active rework status, up to maximum 3 revision cycles).
  - `EXC-21`: Formal project dispute lodged due to non-delivery or substandard output (cancel path: freezes escrow funds and routes to Support Specialist arbitration).
  - `EXC-35`: Mutual cancellation of contract prior to milestone commencement (refund path: locked escrow balance refunded back to client cleared wallet).
  - `EXC-36`: Client review window elapses after 7 days without revision request (timeout path: system auto-releases escrow payment to freelancer).
* **Outputs**: Formally executed gig contract, verified calendar schedule lock, completed milestone sign-off, and guaranteed payment transfer.

---

## 2. State Machine: Gig Contract & Milestone Lifecycle

```
[DRAFT_PROPOSAL] ──► [OFFER_SUBMITTED] ──► [ESCROW_FUNDED] ──► [WORK_IN_PROGRESS]
       │                    │                     │                     │
       │ (Discarded)        │ (Declined)          │ (Refunded)          ▼
       ▼                    ▼                     ▼             [MILESTONE_SUBMITTED]
  [CANCELLED]          [DECLINED]             [TERMINATED]              │
                                                                        ├──────────────┐
                                                                        ▼              ▼
                                                                [CLIENT_APPROVED] [REVISION_REQUESTED]
                                                                        │              │
                                                                        ▼              ▼
                                                                   [COMPLETED]   [WORK_IN_PROGRESS]
                                                                        │
                                                                        ▼ (In dispute)
                                                                    [DISPUTED]
```

| Origin State | Destination State | Triggering Condition | Guard Condition / Enforcement |
| :--- | :--- | :--- | :--- |
| `DRAFT_PROPOSAL` | `OFFER_SUBMITTED` | Client or Freelancer transmits terms | Start date <= End date; valid compensation |
| `OFFER_SUBMITTED` | `ESCROW_FUNDED` | Client deposits milestone funds | Escrow amount locked from client cleared balance |
| `OFFER_SUBMITTED` | `DECLINED` | Counterparty declines contract | Optional decline reason code recorded |
| `ESCROW_FUNDED` | `WORK_IN_PROGRESS` | Freelancer accepts and begins delivery | Conflict-free calendar check confirms zero overlaps |
| `WORK_IN_PROGRESS` | `MILESTONE_SUBMITTED` | Freelancer submits work artifacts | Mandatory deliverable attachment or URL provided |
| `MILESTONE_SUBMITTED`| `REVISION_REQUESTED`| Client requests changes within 7 days | Revision comments entered; revision count < 3 |
| `REVISION_REQUESTED` | `WORK_IN_PROGRESS` | Freelancer acknowledges feedback | Milestone returned to active rework |
| `MILESTONE_SUBMITTED`| `CLIENT_APPROVED` | Client clicks "Approve & Release" | Client affirms deliverable satisfaction |
| `MILESTONE_SUBMITTED`| `CLIENT_APPROVED` | 7-day review window expires without reply| System auto-release rule triggered |
| `CLIENT_APPROVED` | `COMPLETED` | System executes escrow payout transaction| Escrow cleared to freelancer wallet balance |
| `WORK_IN_PROGRESS` | `DISPUTED` | Either party files formal dispute | Escrow locked; arbiter assigned |
