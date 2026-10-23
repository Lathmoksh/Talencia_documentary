# WF-06: Enterprise Tier Subscription, Seat Licensing & Session Concurrency
**Lifecycle Domain:** Monetization, Subscription Management & License Enforcement  
**Associated Features:** `F-10`, `F-21`, `F-22`  
**Participating Actors:** Corporate Executive (`P-04`), Account Administrator (`P-06`), System Daemon (`P-12`)  

---

## 1. Operational Specification (6-Parameter Tuple)

* **Trigger**: Corporate Executive or Account Administrator selects an enterprise subscription plan (Starter, Professional, Enterprise) to license platform recruitment tools and seat capacity.
* **Steps**:
  1. Administrator selects plan tier, billing frequency (monthly or annual), and specifies required recruiter seat quota.
  2. System initiates idempotent payment checkout session through payment gateway with unique idempotency key; gateway returns confirmed webhook event.
  3. System activates organization subscription, allocates monthly resume unlock quota, and provisions seat allocation pool.
  4. Account Administrator assigns recruiter licenses to specific staff user IDs up to the purchased tier limit (`active_seats <= purchased_seats`).
  5. When any assigned recruiter logs into the platform, system validates active seat assignment and enforces single-active-device session concurrency: any preexisting active session token for that recruiter is terminated immediately with an audit log entry.
  6. Recurring billing processed at billing cycle end; if card transaction fails, organization enters a 5-day grace period with administrative alerts.
  7. If unresolved after grace period, account transitions to restricted status: recruiter seat logins are suspended while data is retained read-only.
* **Actors**: Corporate Executive (`P-04`) authorizes contractual subscription; Account Administrator (`P-06`) provisions licenses and manages payment credentials; System Daemon (`P-12`) processes recurring renewals, enforces seat caps, and invalidates concurrent device sessions.
* **Decisions**:
  - *Decision 1*: Does the count of assigned recruiters exceed the purchased tier seat cap? (If Yes -> block seat assignment until additional licenses are purchased; If No -> grant recruiter seat privileges).
  - *Decision 2*: Does a recruiter attempt login while an existing session token is active on another device? (If Yes -> revoke older session token, record device switch event, and establish new active session; If No -> grant access).
  - *Decision 3*: Did recurring renewal payment succeed upon invoice due date? (If Yes -> replenish monthly quota and extend validity period; If No -> enter 5-day grace period).
* **Exceptions**:
  - `EXC-22`: Seat allocation overflow attempt (`assigned_seats > max_seats` blocked at administrative console).
  - `EXC-23`: Gateway recurring payment card decline (triggers automated email to billing admin and initiates retry schedule: day 1, day 3, day 5).
  - `EXC-24`: Idempotency collision on renewal webhook (gateway duplicates ignored; transaction processed exactly once).
  - `EXC-25`: Grace period expiration without payment (subscription suspended; recruiter write permissions revoked).
  - `EXC-34`: Accidental duplicate seat package purchase or cancellation within 48h cooling-off window (refund path: gateway refund credit issued and unallocated seats revoked).
* **Outputs**: Provisioned enterprise subscription with enforceable seat quotas, single-device session integrity, and predictable recurring invoicing.

---

## 2. State Machine: Enterprise Subscription Lifecycle

```
[TRIAL_EVALUATION] ──► [ACTIVE_PAID] ──► [OVERDUE_GRACE_PERIOD] ──► [RESTRICTED_SUSPENDED]
        │                     │                      │                           │
        │ (Expired)           │ (Voluntary Cancel)   │ (Payment Cleared)         │ (Terminated)
        ▼                     ▼                      ▼                           ▼
[TRIAL_EXPIRED]       [CANCELLED_PENDING]       [ACTIVE_PAID]            [TERMINATED_PURGED]
```

| Origin State | Destination State | Triggering Condition | Guard Condition / Enforcement |
| :--- | :--- | :--- | :--- |
| `TRIAL_EVALUATION` | `ACTIVE_PAID` | Admin executes payment checkout | Gateway confirms valid payment authorization |
| `TRIAL_EVALUATION` | `TRIAL_EXPIRED` | 14-day trial period elapses | Daemon revokes premium tool access |
| `ACTIVE_PAID` | `OVERDUE_GRACE_PERIOD`| Renewal payment transaction declines | 5-day grace period timer initiated |
| `OVERDUE_GRACE_PERIOD`| `ACTIVE_PAID` | Admin updates card and payment succeeds | Gateway confirms cleared settlement |
| `OVERDUE_GRACE_PERIOD`| `RESTRICTED_SUSPENDED`| 5-day grace period expires unpaid | Recruiter write permissions suspended |
| `ACTIVE_PAID` | `CANCELLED_PENDING` | Admin submits subscription cancellation | Plan remains active until current billing cycle end |
| `CANCELLED_PENDING` | `TERMINATED_PURGED`| Billing cycle completes after cancel | Profile downgraded to free tier; seats released |
| `RESTRICTED_SUSPENDED`| `ACTIVE_PAID` | Outstanding balance settled | Reactivates seats and restores full capabilities |
