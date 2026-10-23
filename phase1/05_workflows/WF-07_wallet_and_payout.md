# WF-07: Wallet Deposit, Double-Entry Escrow & Freelancer Payout Lifecycle
**Lifecycle Domain:** Financial Ledger, Escrow Settlement & Statutory Tax Compliance  
**Associated Features:** `F-11`, `F-12`, `F-15`, `F-21`, `F-23`  
**Participating Actors:** Freelance Professional (`P-03`), Corporate Executive (`P-04`), Account Administrator (`P-06`), SMB Client (`P-09`), Statutory Regulator (`P-10`), Support Specialist (`P-11`), System Daemon (`P-12`)  

---

## 1. Operational Specification (6-Parameter Tuple)

* **Trigger**: Client deposits funds into platform wallet, funds project milestone escrow, or Freelancer requests withdrawal of cleared earnings to external bank account.
* **Steps**:
  1. Client deposits funds into corporate prepaid wallet via bank transfer or credit card; system credits client wallet asset balance and records matching liability ledger entry.
  2. Client engages gig worker; funds corresponding to milestone value are moved from client cleared balance into locked escrow account.
  3. Strict double-entry ledger invariant is maintained across all transactions: total debits must exactly equal total credits ($\sum \text{Debits} = \sum \text{Credits}$), preventing any unaccounted balance drift.
  4. Upon verified milestone deliverable sign-off (or automated timeout release), system transfers funds from escrow account to Freelancer's cleared wallet balance, deducting platform service commission.
  5. Freelancer submits withdrawal payout request specifying verified bank account details (IBAN / routing number / IFSC).
  6. System checks statutory tax withholding thresholds (e.g., TDS under Income Tax Act or 1099-K compliance); system retains required statutory withholding, creates tax audit receipt for Statutory Regulator, and initiates payment gateway disbursement.
  7. Payment gateway dispatches external wire; webhook confirms successful disbursement to Freelancer's bank account.
* **Actors**: SMB Client (`P-09`) & Corporate Executive (`P-04`) fund deposits; Account Administrator (`P-06`) authorizes bank transfers; Freelance Professional (`P-03`) submits withdrawal requests; Statutory Regulator (`P-10`) inspects statutory tax withholding receipts; Support Specialist (`P-11`) handles settlement disputes; System Daemon (`P-12`) performs running balance reconciliation and idempotency checks.
* **Decisions**:
  - *Decision 1*: Does the client wallet contain sufficient cleared funds to lock the required milestone amount? (If Yes -> lock escrow; If No -> require deposit top-up).
  - *Decision 2*: Does the freelancer withdrawal amount exceed the mandatory statutory tax withholding threshold? (If Yes -> calculate and deduct statutory withholding, credit tax escrow account, and disburse net amount; If No -> disburse full requested amount).
  - *Decision 3*: Has payment gateway webhook returned confirmed settlement status? (If Yes -> mark withdrawal settled; If No -> poll gateway status with exponential backoff).
* **Exceptions**:
  - `EXC-26`: Double-entry ledger imbalance detected ($\sum \text{Debits} \neq \sum \text{Credits}$) immediately aborts database transaction.
  - `EXC-27`: Bank payout rejection due to invalid routing or account number (funds returned to freelancer cleared balance; alert sent to re-enter bank details).
  - `EXC-28`: Escrow freeze due to active contract dispute (funds immobilized until Support Specialist issues dispute resolution verdict).
  - `EXC-29`: Gateway disbursement webhook failure (queued for exponential retry with deduplication key).
  - `EXC-30`: Client requests refund of unallocated wallet balance deposit (refund path: system verifies funds are uncommitted and issues refund to original payment source).
* **Outputs**: Reconciled double-entry ledger entries, cleared escrow transfers, immutable tax compliance records, and verified bank payouts.

---

## 2. State Machine: Escrow & Withdrawal Transaction Lifecycle

```
[DEPOSIT_CONFIRMED] ──► [ESCROW_LOCKED] ──► [CLEARED_BALANCE] ──► [WITHDRAWAL_INITIATED]
         │                     │                    │                      │
         │ (Chargeback)        │ (Project Dispute)  │ (Admin Hold)         ▼
         ▼                     ▼                    ▼             [GATEWAY_DISPATCHED]
 [REFUND_PROCESSED]     [DISPUTED_FROZEN]    [WALLET_FROZEN]               │
                                                                   ┌───────┴───────┐
                                                                   ▼               ▼
                                                           [PAYOUT_SETTLED] [PAYOUT_FAILED]
```

| Origin State | Destination State | Triggering Condition | Guard Condition / Enforcement |
| :--- | :--- | :--- | :--- |
| `DEPOSIT_CONFIRMED` | `ESCROW_LOCKED` | Contract milestone initialized | Escrow amount <= Available cleared balance |
| `ESCROW_LOCKED` | `CLEARED_BALANCE` | Client approves deliverable | Double-entry journal balances; commission applied |
| `ESCROW_LOCKED` | `DISPUTED_FROZEN` | Formal contract dispute filed | Support Specialist assignment; escrow immobilized |
| `DISPUTED_FROZEN` | `CLEARED_BALANCE` | Arbiter resolves in favor of freelancer | Support Specialist enters binding decision |
| `DISPUTED_FROZEN` | `DEPOSIT_CONFIRMED`| Arbiter resolves in favor of client | Escrow funds refunded back to client wallet |
| `CLEARED_BALANCE` | `WITHDRAWAL_INITIATED`| Freelancer requests bank transfer | Withdrawal amount <= Available balance; bank verified |
| `WITHDRAWAL_INITIATED`| `GATEWAY_DISPATCHED`| System creates payout instruction | Tax withholding deducted; idempotency key generated |
| `GATEWAY_DISPATCHED`| `PAYOUT_SETTLED` | Gateway webhook confirms transfer | Gateway transaction reference recorded |
| `GATEWAY_DISPATCHED`| `PAYOUT_FAILED` | Gateway returns rejection code | Funds credited back to freelancer cleared balance |
| `DEPOSIT_CONFIRMED` | `REFUND_PROCESSED` | Client requests unallocated fund refund | Unallocated funds returned via original payment method |
