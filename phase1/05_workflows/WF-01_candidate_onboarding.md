# WF-01: Candidate Onboarding, Privacy Shield & Consent Lifecycle
**Lifecycle Domain:** Identity, Privacy & Regulatory Compliance  
**Associated Features:** `F-01`, `F-03`, `F-06`, `F-17`  
**Participating Actors:** Candidate (`P-02`), Data Privacy Officer (`P-08`), Statutory Regulator (`P-10`), System Daemon (`P-12`)  

---

## 1. Operational Specification (6-Parameter Tuple)

* **Trigger**: Candidate accesses registration portal, accepts terms of service, and submits registration credentials with optional resume upload.
* **Steps**:
  1. System normalizes email to canonical lowercase and validates contact phone number against E.164 international standard (`^\+[1-9]\d{1,14}$`).
  2. System stores credentials using computationally expensive slow cryptographic transformations and provisions user account.
  3. Candidate uploads resume; background worker extracts semantic skill vectors and populates profile searchable index.
  4. Candidate configures employer block-list rules by selecting specific corporate organization IDs (e.g., current employer or competitor).
  5. System records affirmative purpose-bound consent in statutory consent register with client IP and timestamp.
  6. Candidate may later exercise statutory right to withdraw consent under the DPDP Act 2023.
* **Actors**: Candidate (`P-02`) initiates; Data Privacy Officer (`P-08`) audits; Statutory Regulator (`P-10`) inspects; System Daemon (`P-12`) executes asynchronous erasure.
* **Decisions**:
  - *Decision 1*: Is the candidate under 18 years of age based on submitted date of birth? (If Yes -> require verifiable parental consent token before profile activation; If No -> proceed directly).
  - *Decision 2*: Did candidate configure employer block-list entries? (If Yes -> activate indexed anti-join filter hiding candidate from designated organization IDs; If No -> profile visible to all authorized recruiters).
* **Exceptions**:
  - `EXC-01`: Email casing collision (detected by lowercase unique index; directs user to existing login page).
  - `EXC-02`: Invalid non-standard phone format (rejected with international formatting guidance).
  - `EXC-03`: Minor candidate registration without parental token (account placed in pending consent state).
  - `EXC-04`: Consent revocation trigger (initiates immediate cascade anonymization and cryptographic key shredding).
* **Outputs**: Activated candidate profile discoverable to all recruiters *except* blocked employers, with immutable consent audit receipt.

---

## 2. State Machine: Candidate Profile Lifecycle

```
[REGISTRATION_INITIATED] ──► [PENDING_VERIFICATION] ──► [ACTIVE_DISCOVERABLE]
          │                           │                         │
          │ (Age < 18)                │ (24h Token Timeout)      │ (Candidate Withdraws Consent)
          ▼                           ▼                         ▼
 [PENDING_PARENTAL_CONSENT]     [VERIFICATION_EXPIRED]     [ANONYMIZED_PURGED]
```

| Origin State | Destination State | Triggering Condition | Guard Condition / Enforcement |
| :--- | :--- | :--- | :--- |
| `REGISTRATION_INITIATED` | `PENDING_VERIFICATION` | Candidate submits email & password | Email normalized to lowercase; credentials cryptographically transformed |
| `REGISTRATION_INITIATED` | `PENDING_PARENTAL_CONSENT`| Date of birth indicates age < 18 | Mandatory parent/guardian contact and token verification flag |
| `PENDING_VERIFICATION` | `ACTIVE_DISCOVERABLE` | Candidate clicks verification link | Verification token valid within 24-hour validity window |
| `PENDING_VERIFICATION` | `VERIFICATION_EXPIRED` | 24 hours elapse without link click | Automatic token expiry; candidate requests fresh verification link |
| `ACTIVE_DISCOVERABLE` | `PRIVACY_RESTRICTED` | Candidate configures employer blocks | Employer IDs stored in block list; anti-join filters queries |
| `ACTIVE_DISCOVERABLE` | `ANONYMIZED_PURGED` | Candidate exercises DPDP erasure | Asynchronous worker shreds encryption key and anonymizes PII |
