# Talentra — Business Workflow Analysis Schema Specification
**Document**: Deliverable E1 — Output Schema Definition  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Workflow Architecture & Process Engineering Team  
**Status**: Approved & Frozen for Sprint Implementation  

---

## 1. Schema Hierarchy & Level Metrics

```
Workflow Analysis Schema (Root)
 ├── L1.0 Operational Lifecycle Governance & Master Inventory
 ├── L1.1 6-Parameter End-to-End Workflow Specifications (WF-01 to WF-07)
 ├── L1.2 State Transition Finite State Machines & Invariant Guardrails
 ├── L1.3 Decision Matrix & Authorization Gateways
 ├── L1.4 4-Category Exception Catalogue (Cancel, Refund, Retry, Timeout)
 ├── L1.5 Idempotency, Retry & Backoff Policies
 └── L1.6 20-Feature Traceability Verification (F-01 to F-20)
```

### Schema Metrics & Structural Hierarchy

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **7 sections** | Measured (100% frozen) | Do these workflows cover all lifecycles, states, and failure paths? |
| **Level 2 · Micro** | Parameters & Models | **28 parameters** | Measured (4.0 avg/section) | Can developers execute and audit every transition step and rollback? |
| **Level 3 · Nano** | Sub-parameters & Enums | **84 classifications** | Measured & categorized | Are all triggers, decision gates, and failure modes typed? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every workflow map to an executable SQL state machine and check trigger? |

---

## 2. Scope & Architectural Decision Log

| Item / Workflow Pattern | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Happy-Path-Only Modeling** | **DROPPED** | Major architectural defect. Workflows must explicitly specify Cancel, Refund, Retry, and Timeout failure branches. | Workflow Eng |
| **Application-Layer-Only Status Checks** | **DROPPED** | Fragile against race conditions. Finite state machine transitions are validated in database triggers and check constraints. | Database Lead |
| **6-Parameter Workflow Tuples** | **KEPT** | Standardizes workflow modeling across Trigger, Steps, Actors, Decisions, Exceptions, and Outputs. | Architecture |
| **4-Category Failure Modeling** | **KEPT** | Exhaustively covers Cancel, Refund, Retry, and Timeout operational paths. | Operations Lead |
| **Anti-Join Privacy Filtering (WF-01)** | **KEPT** | Automatically excludes blocked employers/competitors directly in candidate search queries without requiring client logic. | Security Lead |
| **GiST Concurrency Exclusion (WF-05)** | **KEPT** | Eliminates double-booking of gig workers during concurrent scheduling requests at the storage engine level. | Architecture |
| **Double-Entry Escrow Reconciliation (WF-07)**| **KEPT** | Guarantees that cancellations and milestone disputes always leave ledger credits and debits perfectly balanced ($0.00 variance). | Financial Lead |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0 & L1.1: 6-Parameter Workflow Tuples
* `workflow_code`: Unique identifier (`WF-01` to `WF-07`).
* `workflow_title`: Canonical name of the business lifecycle.
* `trigger`: Event initiating workflow (`PROFILE_REGISTERED`, `JOB_APPROVED`, `APPLICATION_SUBMITTED`, etc.).
* `steps`: Ordered list of procedural actions.
* `actors`: Authorized roles participating in the workflow.
* `decisions`: Boolean evaluation points branching execution.
* `exceptions`: Mapped failure codes (`EXC-01` to `EXC-08`).
* `outputs`: Resulting state and committed records.

### Section L1.2 & L1.3: State Machine Rules & Decision Gateways
* `entity_type`: State machine entity (`JOB_APPLICATION`, `GIG_CONTRACT`, `SUBSCRIPTION_LICENCE`, `WALLET_ESCROW`).
* `state_from` & `state_to`: Origin and destination operational statuses.
* `is_terminal`: Flag indicating terminal status (`HIRED`, `REJECTED`, `COMPLETED`, `CANCELLED`).

### Section L1.4: 4-Category Exception Catalogue (EXC-01 to EXC-08)
* `exception_code`: Unique reference (`EXC-01` to `EXC-08`).
* `failure_category`: Categorized under `CANCEL_PATH`, `REFUND_PATH`, `RETRY_PATH`, or `TIMEOUT_PATH`.
* `failure_condition`: Exact triggering fault mode.
* `mitigation_strategy`: Action taken (`ROLLBACK_TRANSACTION`, `COMPENSATING_CREDIT`, `EXPONENTIAL_RETRY`, `REVOKE_SESSION`).
* `final_state`: Resulting status of all impacted relational tables.

### Section L1.5 & L1.6: Retry Policies & 20-Feature Traceability
* `idempotency_key`: Deduplication token.
* `max_retry_limit`: Maximum automated attempts (default: 5).
* `feature_coverage`: Verification that all 20 features (`F-01` to `F-20`) execute in active operational workflows.
