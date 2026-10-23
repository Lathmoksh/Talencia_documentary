# WF-03: Candidate Application Pipeline & Selection Lifecycle
**Lifecycle Domain:** Applicant Funnel Progression & Hiring Decisions  
**Associated Features:** `F-05`, `F-07`, `F-18`, `F-19`, `F-20`, `F-22`, `F-23`  
**Participating Actors:** Recruiter (`P-01`), Candidate (`P-02`), Academic Partner (`P-07`), System Daemon (`P-12`)  

---

## 1. Operational Specification (6-Parameter Tuple)

* **Trigger**: Candidate submits an application for a published job requisition, either directly, through an academic campus cohort, or via an attribution-tracked employee referral link.
* **Steps**:
  1. System checks candidate profile against requisition prerequisites; evaluates answers to automated screening questionnaire.
  2. If screening score meets pass threshold, application transitions to active review queue; referral attribution recorded if referral code present.
  3. Recruiter reviews application dossier, evaluates resume, and shortlists candidate for technical assessment.
  4. System dispatches time-bound technical assessment link (with strict 72-hour completion window).
  5. Upon successful assessment score, recruiter schedules structured interview panel; automated calendar invitations dispatched.
  6. Hiring committee extends formal offer letter with compensation details and 7-day expiration deadline.
  7. Candidate signs offer letter; application transitions to hired state, closing open requisition headcount if target reached.
* **Actors**: Candidate (`P-02`) submits application and attends interviews; Recruiter (`P-01`) evaluates and advances stages; Academic Partner (`P-07`) monitors campus batch applicant progress; System Daemon (`P-12`) enforces timeouts and sends notifications.
* **Decisions**:
  - *Decision 1*: Did candidate fail the mandatory screening questionnaire threshold? (If Yes -> automatically reject with respectful templated notice; If No -> route to recruiter review queue).
  - *Decision 2*: Did candidate complete the technical assessment before the 72-hour deadline? (If Yes -> score submission and notify recruiter; If No -> transition to `ASSESSMENT_TIMEOUT`).
  - *Decision 3*: Did candidate accept the formal employment offer before the expiration date? (If Yes -> mark as `HIRED` and initiate onboarding; If No -> transition to `OFFER_EXPIRED`).
* **Exceptions**:
  - `EXC-09`: Duplicate application submission for the same requisition within 90 days (rejected; existing record highlighted).
  - `EXC-10`: Candidate assessment session disconnection or technical failure (triggers retry token issuance upon review).
  - `EXC-11`: Assessment window timeout (asynchronous daemon transitions status to `ASSESSMENT_TIMEOUT`).
  - `EXC-12`: Formal offer expiry (asynchronous daemon transitions status to `OFFER_EXPIRED` after 7 days).
  - `EXC-13`: Candidate voluntary withdrawal at any pre-hire stage (application immediately transitions to `WITHDRAWN`).
* **Outputs**: Fully tracked application journey with milestone timestamps, candidate scorecards, audit trail, and finalized hire record.

---

## 2. Complete State Machine: 13-State Pipeline

```
                              [SUBMITTED]
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
              [UNDER_REVIEW]                 [REJECTED]
                    │
                    ▼
              [SHORTLISTED]
                    │
                    ▼
          [TECHNICAL_ASSESSMENT] ──────► [ASSESSMENT_TIMEOUT]
                    │
                    ▼
           [INTERVIEW_SCHEDULED]
                    │
                    ▼
             [OFFER_EXTENDED]
                    │
       ┌────────────┼────────────┐
       ▼            ▼            ▼
[OFFER_ACCEPTED] [OFFER_DECLINED] [OFFER_EXPIRED]
       │
       ▼
    [HIRED]

(At any pre-hire stage: Candidate may trigger ──► [WITHDRAWN])
```

| Origin State | Destination State | Triggering Condition | Guard Condition / Enforcement |
| :--- | :--- | :--- | :--- |
| `SUBMITTED` | `UNDER_REVIEW` | Application passes screening questionnaire | Score >= Requisition pass threshold |
| `SUBMITTED` | `REJECTED` | Screening questionnaire score below threshold | Automated evaluation rule |
| `UNDER_REVIEW` | `SHORTLISTED` | Recruiter reviews profile and approves | Recruiter role permission verified |
| `UNDER_REVIEW` | `REJECTED` | Recruiter rejects application after review | Rejection reason documented |
| `SHORTLISTED` | `TECHNICAL_ASSESSMENT` | Recruiter initiates assessment invitation | Assessment template assigned with 72h window |
| `TECHNICAL_ASSESSMENT` | `INTERVIEW_SCHEDULED` | Candidate completes test with passing score | Automated score >= assessment threshold |
| `TECHNICAL_ASSESSMENT` | `ASSESSMENT_TIMEOUT` | 72 hours elapse without completion | Daemon executes automatic timeout transition |
| `TECHNICAL_ASSESSMENT` | `REJECTED` | Test completed but score below passing mark | Recruiter confirms assessment evaluation |
| `INTERVIEW_SCHEDULED` | `OFFER_EXTENDED` | Interview panel submits positive evaluation | Offer compensation approved by budget admin |
| `INTERVIEW_SCHEDULED` | `REJECTED` | Interview panel submits negative evaluation | Recruiter archives candidate with feedback |
| `OFFER_EXTENDED` | `OFFER_ACCEPTED` | Candidate executes digital acceptance | Accepted prior to offer expiration timestamp |
| `OFFER_EXTENDED` | `OFFER_DECLINED` | Candidate explicitly declines offer | Candidate provides optional reason code |
| `OFFER_EXTENDED` | `OFFER_EXPIRED` | Offer window elapses (default 7 days) | Daemon expires offer token automatically |
| `OFFER_ACCEPTED` | `HIRED` | Background check clears and start date logged | Requisition available opening decremented |
| *ANY (pre-hire)* | `WITHDRAWN` | Candidate clicks "Withdraw Application" | Irrevocable withdrawal flag recorded |
