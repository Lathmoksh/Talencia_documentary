# Talentra — Business Workflow Analysis Schema Specification
**Document Reference**: Deliverable E1 — Output Schema Definition & Meta-Model  
**Step / Activity**: Step 05 — Business Workflow Analysis  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Workflow Architecture & Process Engineering Board  
**Gate**: Phase 1 Discover (Gate G1 Deliverable)  
**Status**: Approved & Frozen Baseline  

---

## Executive Summary: Step 05 — Business Workflow Analysis

### 1. Purpose & Business Objective
The Business Workflow Analysis Specification establishes the operational execution, finite state machine transitions, and exception recovery framework for the Talentra Enterprise Workforce Platform. In enterprise systems, catastrophic downtime and user frustration rarely stem from static requirement omissions; they occur during dynamic multi-party handoffs, unhandled edge-case failures, unrecoverable timeouts, and conflicting concurrent actions.

The objective of Step 05 is to model every business lifecycle across time under Phase 1 Discover (Gate G1). By standardizing on 6-parameter operational tuples `{ Trigger, Steps, Actors, Decisions, Exceptions, Outputs }`, mapping all 13 states of the hiring funnel, and exhaustively cataloging 36 exceptions across **Cancel**, **Refund**, **Retry**, and **Timeout** failure paths, this deliverable guarantees that the platform never encounters an unhandled operational state or financial drift.

### 2. Key Architectural Deliverables & Scope
1. **7 Master End-to-End Workflows (`WF-01` to `WF-07`)**:
   - `WF-01`: Candidate Onboarding, Skill Vector Extraction & Privacy Shield.
   - `WF-02`: Multi-Tenant Requisition Creation, Screening Setup & Publication.
   - `WF-03`: Job Application Pipeline, Versioned Assessment & 13-Stage Progression.
   - `WF-04`: Recruiter Talent Sourcing, Candidate Search & Contact Quota Metering.
   - `WF-05`: Contingent Gig Milestone Contracting, GiST Temporal Booking & Escrow Hold.
   - `WF-06`: Enterprise Subscription Licensing, Recruiter Seat Caps & Grace Periods.
   - `WF-07`: Corporate Wallet Settlement, Milestone Payout & Dispute Resolution.
2. **6-Parameter Operational Tuple Schema**:
   - Every workflow strictly conforms to the standardized tuple:
     - `Trigger`: Initiating domain event.
     - `Steps`: Ordered, deterministic procedural sequence.
     - `Actors`: Authorized human and automated participants (`P-01` to `P-12`).
     - `Decisions`: Explicit branching gateways evaluating business policies.
     - `Exceptions`: Explicit mapping to documented exception handlers.
     - `Outputs`: Resulting database entity states and audit receipts.
3. **Exhaustive 36-Exception Recovery Catalogue (`EXC-01` to `EXC-36`)**:
   - Complete 4-branch failure modeling:
     - **Cancel Paths (16 exceptions)**: Deterministic validation rejections, duplicate blocks, and policy aborts preserving system state.
     - **Refund Paths (5 exceptions)**: Financial reversions (`EXC-27`, `EXC-30`, `EXC-31`, `EXC-34`, `EXC-35`) restoring wallet balances or quota credits ($0.00 drift).
     - **Retry Paths (8 exceptions)**: Transient network timeouts, webhook deliveries, and assessment reconnects with exponential backoff.
     - **Timeout Paths (7 exceptions)**: Automated expiration daemons handling unverified emails (24h), assessment deadlines (72h), offer expiry (7d), grace periods (5d), and milestone reviews (7d).
4. **Finite State Machine Invariants**:
   - Application pipeline FSM (13 states from `APPLIED` through `HIRED` / `REJECTED`).
   - Strict append-only financial and audit ledger invariants ensuring non-repudiation.

---

## 1. Schema Hierarchy & Structural Metrics

This schema defines the formal structure required for the Business Workflow Docket across five nested levels:

```
Workflow Analysis Schema (Root)
 ├── L1.0 Executive Summary & Operational Lifecycle Governance
 ├── L1.1 Master Operational Inventory (WF-01 to WF-07)
 ├── L1.2 6-Parameter End-to-End Workflow Specifications
 ├── L1.3 Finite State Machine (FSM) Pipelines & Invariant Guardrails
 ├── L1.4 4-Category Exhaustive Exception Catalogue (EXC-01 to EXC-36)
 └── L1.5 Idempotency, Retry Backoff & Compensatory Rollback Protocols
```

### Schema Structural Metrics

| Level | Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **6 sections** | 100% frozen | Do workflows cover all platform lifecycles and failure scenarios? |
| **Level 2 · Micro** | Parameters & Models | **32 parameters** | 5.3 avg/section | Can developers execute every transition step, decision gate, and rollback? |
| **Level 3 · Nano** | Sub-parameters & Enums | **110 classifications** | Categorized & typed | Are all failure paths, event triggers, and state machine nodes typed? |
| **Level 4 · Pico** | Exception Handlers | **36 exceptions** | 100% leaf coverage | Does every exception map to a verified resolution, actor alert, and state impact? |

---

## 2. Scope & Operational Failure Decisions

| Operational Workflow Pattern | Decision | Architectural Rationale & Justification | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Happy-Path-Only Modeling** | **DROPPED** | Dangerous anti-pattern. Workflows must explicitly model Cancel, Refund, Retry, and Timeout failure branches. | Workflow Lead |
| **Application-Layer-Only Status Checks** | **DROPPED** | Fragile against race conditions. Finite state machine transitions are validated via database check constraints and triggers. | Database Architect |
| **6-Parameter Operational Tuples** | **KEPT** | Standardizes operational lifecycles across Trigger, Steps, Actors, Decisions, Exceptions, and Outputs. | Systems Architect |
| **Exhaustive 4-Branch Exception Modeling** | **KEPT** | Eliminates unhandled edge cases across Cancel (16), Refund (5), Retry (8), and Timeout (7). | QA Architecture |
| **Idempotency & Compensatory Rollbacks** | **KEPT** | Guarantees that payment webhooks and balance refunds never double-charge or create financial discrepancies. | Financial Lead |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.1 & L1.2: 6-Parameter Workflow Tuples
* `workflow_id`: Unique identifier (`WF-01` to `WF-07`). Mandatory.
* `workflow_title`: Canonical operational name.
* `primary_trigger`: Domain event initiating the workflow.
* `procedural_steps`: Ordered list of deterministic actions.
* `participating_actors`: Array of mapped persona codes (`P-01` to `P-12`).
* `decision_gateways`: Boolean evaluation gates directing flow.
* `mapped_exceptions`: Array of mapped `EXC-xx` identifiers.
* `terminal_outputs`: Resulting database entity states and audit event records.

### Section L1.4: 36-Exception Recovery Catalogue
* `exception_id`: Unique identifier (`EXC-01` to `EXC-36`). Mandatory.
* `workflow_id`: Associated parent workflow.
* `failure_branch`: Operational failure category (`CANCEL_PATH`, `REFUND_PATH`, `RETRY_PATH`, `TIMEOUT_PATH`).
* `trigger_condition`: Root-cause technical or business failure event.
* `resolution_action`: Automated or procedural recovery mechanism.
* `actor_notified`: Affected persona receiving notification alerts.
* `financial_or_state_impact`: Exact database and ledger state modification.
