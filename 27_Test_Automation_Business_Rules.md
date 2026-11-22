Milestone 27 — Test Automation: Business Rules

# Executive Summary & System Metadata

## Document Overview

This document defines the comprehensive specifications for Milestone 27 — Test Automation: Business Rules within the Talentra Enterprise Workforce & Talent Demand Management Platform. Positioned in Phase 4 (Build & Integrate) under the directive "Real Volume, Automate the Proof", Milestone 27 establishes the automated verification engine that programmatically validates every business logic constraint, state machine transition, and security boundary defined across Milestones 11, 14–21, and 24–26.

## Metadata Summary

| Metadata Field | Specification Details |
| :--- | :--- |
| Milestone Identifier | Milestone 27 — Test Automation: Business Rules |
| Phase / Step | Phase 4 — Build & Integrate (Test Step — "Real Volume, Automate the Proof") |
| Platform Target | Talentra Enterprise Workforce & Talent Demand Management Platform |
| Database Engine Baseline | PostgreSQL 16 Enterprise Baseline (Schema governance, identity, recruitment, gig, finance, consent) |
| Primary Goal | Automatically prove every business rule and 20 entity state transitions on every CI/CD commit without manual testing |
| Primary Deliverables | Test suite (tests/business_rules/), Rule Traceability Matrix parser (scripts/verify_br_coverage.py), Decision Table Generator (specs/decision_tables/) |
| CI/CD Exit Gate | 100% test coverage across all BR-001–BR-024 rules, 20 Entity FSMs, zero unmapped business requirements |




# Automated Business Rule Test Architecture & Rule Traceability

## 3-Layer Enforcement Test Pyramid Architecture

To ensure total system integrity, business rules are tested across three distinct architectural layers matching the platform enforcement model established in Milestone 11 Section 12.


```sql
+-------------------------------------------------------+
| Layer 3: Application Domain Service & API Policy      |
| FastAPI / Service Integration, AuthZ, HTTP Codes,     |
| Audit Event Emission (governance.system_audit_event)  |
+-------------------------------------------------------+
^
|
+-------------------------------------------------------+
| Layer 2: Transactional & Concurrency Race Tests       |
| Multi-threaded / Async parallel sessions, SELECT FOR  |
| UPDATE locking, GiST non-overlap, Seat/Balance Caps   |
+-------------------------------------------------------+
^
|
+-------------------------------------------------------+
| Layer 1: Database Storage & Trigger Enforcement       |
| Raw SQL via Pytest savepoints (psycopg / SQLAlchemy), |
| Hard DB Constraints, RLS Policies, Database Triggers   |
+-------------------------------------------------------+
Layer 1: Direct Database Storage & Trigger Enforcement Tests
```
Executes raw SQL INSERT, UPDATE, and DELETE operations using isolated PostgreSQL savepoints via psycopg and SQLAlchemy. These tests verify that database constraints (CHECK, UNIQUE, FOREIGN KEY), Row-Level Security (RLS) policies, and database triggers reject invalid states even if application services are completely bypassed.

### Layer 2: Transactional & Concurrency Race Tests

Utilizes asyncio.gather and multi-threaded test runners to simulate simultaneous, highly concurrent API interactions. This layer proves lock safety under load using SELECT FOR UPDATE on wallet balances (CTR-04), recruiter seat allocations (CTR-06), profile unlock credit deductions (CTR-07), and GiST spatio-temporal index locks for gig bookings (CTR-03).

### Layer 3: Application Domain Service & API Policy Tests

Executes FastAPI endpoint integration suites to confirm end-to-end actor authorization, response payloads, precise HTTP error codes (400 Bad Request, 402 Payment Required, 403 Forbidden, 409 Conflict), and correct audit log creation in governance.system_audit_event.



## Core Business Rule Automation Matrix

The following matrix maps all core platform rules (BR-001 through BR-024) to their upstream constraints, domain requirements, enforcement layer, and automated verification patterns.


| Rule ID | Domain & Rule Name | Core Requirement & Logic | Target Entities & Schema Columns | Target Layer | Automated Test Pattern & Assertion |
| :--- | :--- | :--- | :--- | :--- | :--- |
| BR-001 | Requisition Publishing Guard | CTR-01 / DR-031WF-01 | Requiring organisation.verification_status = 'VERIFIED' before setting job_requisition.status to PUBLISHED. |  | Attempt API publish on UNVERIFIED org → Assert HTTP 403. Direct SQL DB update → Trigger raises exception ERR_ORG_NOT_VERIFIED. |
| BR-002 | Tenant Isolation & RLS | REQ-13 / DR-005WF-01 | All query contexts must enforce PostgreSQL RLS using current_setting('app.current_tenant_id'). |  | Set session tenant to Tenant A, query recruitment.job_requisition for Tenant B data → Assert 0 rows returned. |
| BR-003 | Agency Candidate Sourcing | CTR-02 / DR-047WF-02 | Vendors can submit candidates only to requisitions where visibility = 'AGENCY_OPEN' or explicit invitation exists. |  | Submit application from uninvited agency for PRIVATE requisition → Assert HTTP 403 Forbidden and zero DB record. |
| BR-004 | 180-Day Nomination Lockout | CTR-02 / DR-049WF-02 | Prevent re-nomination of a candidate for the same tenant within 180 days by another agency. |  | Agency A nominates Candidate X at Day 0. Agency B nominates Candidate X at Day 45 → Assert HTTP 409 Conflict. Agency B nominates at Day 181 → Assert HTTP 201 Created. |
| BR-005 | Anti-Join Privacy Shield | CTR-08 / DR-030WF-03 | Hide candidate direct contact details (email, phone) until explicit unlock credit is spent or accepted offer. |  | Fetch candidate profile as employer without unlock → Assert email and phone masked as ***@***.com and +XX-XXXXX. |
| BR-006 | Anti-Proxy Registration Guard | DR-012 / DR-028WF-03 | Candidate account creation requires strict uniqueness on national_id_hash and device fingerprint. |  | Insert candidate with existing national_id_hash → Assert DB unique_constraint_violation (idx_candidate_national_id_hash). |
| BR-007 | Contact Unlock Wallet Metering | CTR-07 / DR-073WF-04 | Unlocking candidate profile contact info deducts credits from finance.wallet_account. Rejects if balance < fee. |  | Concurrent requests to unlock profile with balance for 1 operation → Assert 1 succeeds (HTTP 200), 1 fails (HTTP 402 Payment Required), balance = 0. |
| BR-008 | Subscription Seat Ceiling | CTR-06 / DR-014WF-05 | Active tenant recruiter accounts cannot exceed subscription_licence.max_recruiter_seats. |  | Tenant has 5 max seats, 5 active accounts. Invite 6th user → Assert HTTP 409 Conflict. Direct DB status update to ACTIVE → DB trigger raises exception. |
| BR-009 | Concurrent Device Session Cap | DR-020 / DR-021WF-05 | A user cannot hold more than 3 active JWT session tokens simultaneously. |  | Log in 4 times on different devices → Assert oldest session token is revoked (is_active = FALSE in identity.user_session). |
| BR-010 | Gig Temporal Non-Overlap Guard | CTR-03 / DR-056WF-06 | A consultant cannot be booked for overlapping time windows (booking_period tstzrange) across active gig contracts. |  | Insert overlapping tstzrange for consultant → Assert DB GiST constraint violation exclusion_gig_schedule_overlap. |
| BR-011 | Gig Escrow Pre-Funding Guard | CTR-04 / DR-057WF-06 | Gig contract transition to ACTIVE requires 100% pre-funding in finance.escrow_hold. |  | Attempt state transition OFFERED → ACTIVE on unfunded gig contract → Assert HTTP 400 Bad Request (ERR_ESCROW_NOT_FUNDED). |
| BR-012 | 5-Day Auto-Approval Guard | DR-058 / DR-059WF-06 | Milestone review auto-approves if no employer action taken after 5 calendar days (120 hours). |  | Cron job execution on milestone in SUBMITTED state for > 120 hrs → Assert state transitions to APPROVED and escrow release triggered. |
| BR-013 | Double-Entry Zero-Variance | CTR-05 / DR-067WF-07 | Every ledger transaction entry group must have total debit_amount equal to total credit_amount. |  | Attempt DB insertion into finance.ledger_entry where SUM(debit) != SUM(credit) → Assert DB trigger trg_check_ledger_balance aborts. |
| BR-014 | Append-Only Ledger Immutability | CTR-05 / DR-068WF-07 | SQL UPDATE and DELETE statements are prohibited on finance.ledger_entry and finance.audit_log. |  | Execute UPDATE finance.ledger_entry SET amount = 0 → Assert DB Exception ERR_LEDGER_IMMUTABLE. Executed by superuser → Assert RLS/Trigger block. |
| BR-015 | Statutory Invoice Reconciliation | CTR-10 / DR-070WF-08 | Invoice tax breakdown (cgst, sgst, igst) must exactly match standard rates based on tenant state jurisdiction. |  | Post payment order with invalid GST breakdown → Assert HTTP 400 Bad Request (ERR_STATUTORY_TAX_MISMATCH). |
| BR-016 | Payment Webhook Idempotency | CTR-10 / DR-072WF-08 | Duplicate payment webhook events with identical idempotency_key must return cached status without re-executing ledger updates. |  | Post identical webhook payload twice → First returns HTTP 200 (Ledger written), second returns HTTP 200 (is_duplicate: true, Ledger un-updated). |
| BR-017 | DPDP Consent Gate Guard | CTR-09 / DR-075WF-09 | Candidates without active consent for DATA_PROCESSING cannot be indexed or made searchable. |  | Revoke DPDP consent → Query search API → Assert candidate excluded from results within active context. |
| BR-018 | Sub-2.0s Crypto DEK Shredding | CTR-09 / DR-080WF-09 | Account erasure request must destroy data encryption keys (DEK) in KMS within 2.0 seconds, rendering PII unrecoverable. |  | Call /api/v1/consent/erasure → Benchmark execution time (< 2.0s), verify DEK deletion in KMS, assert cipher text un-decryptable. |
| BR-019 | Tamper-Evident Audit Chain | DR-081 / DR-083WF-09 | Every system_audit_event entry must link to previous event via cryptographic hash (SHA-256). |  | Tamper with historical row in governance.system_audit_event → Run audit verifier → Assert failure detected at tampered record sequence. |
| BR-020 | Campus Placement 20-Student Min | DR-077WF-10 | Campus placement drives require a minimum of 20 verified student registrations before drive activation. |  | Transition drive state DRAFT → ACTIVE with 19 students → Assert HTTP 400 Bad Request (ERR_CAMPUS_MIN_COHORT_NOT_MET). |
| BR-021 | Interview Schedule Window Guard | DR-042WF-11 | Interview cannot be scheduled in the past or without confirmation from assigned panel members. |  | Post interview schedule with scheduled_time < NOW() → Assert HTTP 400. Post without panel confirmation → Assert state remains PENDING_CONFIRMATION. |
| BR-022 | Job Offer SLA Expiry Guard | DR-045WF-11 | Unaccepted job offers automatically transition to EXPIRED when expiry_timestamp is reached. |  | Trigger SLA check worker for offer where expiry_timestamp < NOW() → Assert offer status transitions to EXPIRED, seat reservation released. |
| BR-023 | Rate Card Compliance Guard | DR-052WF-12 | Contract bill rate must fall strictly between min_rate and max_rate of approved rate card for requested role. |  | Create contract with bill rate above max rate → Assert HTTP 422 Unprocessable Entity (ERR_RATE_CARD_OUT_OF_BOUNDS). |
| BR-024 | Multi-Tier Approval Chain Guard | DR-063WF-12 | Requisitions exceeding $100k budget require Tier-2 finance approval before state transitions to APPROVED. |  | Tier-1 approve $150k requisition → Assert state moves to PENDING_TIER_2_APPROVAL. Attempt publish → Assert HTTP 403 Forbidden. |




# Automated 20-Entity Finite State Machine (FSM) Transition Harness

The platform enforces strict state progression across 20 primary transactional entities. Milestone 27 provides a dynamic, parametric state machine test engine (tests/business_rules/test_fsm_engine.py) that systematically evaluates all potential state transitions.


```sql
+-----------------------------------------------------------------------------------+
|                        20 Core Platform State Machines                            |
+-------------------+--------------------+--------------------+---------------------+
| 1. user_account   | 6. job_interview   | 11. payment_order  | 16. candidate_claim |
| 2. organisation   | 7. job_offer       | 12. invoice        | 17. agency_contract |
| 3. vendor_profile | 8. gig_request     | 13. dpdp_consent   | 18. rate_card       |
| 4. job_requisition| 9. gig_contract    | 14. campus_drive   | 19. time_sheet      |
| 5. job_application| 10. gig_milestone  | 15. sub_licence    | 20. audit_session   |
+-------------------+--------------------+--------------------+---------------------+
FSM Parametric Test Strategy
```
For each entity state machine, the harness validates four operational categories:


Allowed Transitions: Verify (from_state, valid_event, guard_satisfied) -> to_state succeeds and automatically creates an immutable audit trace in recruitment.application_stage_history or governance.system_audit_event.

Prohibited Edge Transitions: Verify (from_state, invalid_to_state) is instantly rejected with an exception/error code.

Guard Failure Validations: Verify (from_state, valid_event, guard_failed) is blocked when specific requirements are missing.

Terminal Immutability: Verify states designated as Terminal (DEACTIVATED, CLOSED, JOINED, FULFILLED, VOIDED, REVOKED) accept no further state mutations.



## Comprehensive 20-Entity FSM Matrix

The table below details all 20 state machines, their complete state set, valid transitions, key guards, and terminal states.


| Entity Name | Schema & Table | Complete State Set | Valid Allowed Transitions | Mandatory Guards / Preconditions | Terminal States |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1. User Account | identity.user_account | PENDING_VERIFICATION, ACTIVE, SUSPENDED, DEACTIVATED | PENDING → ACTIVEACTIVE → SUSPENDEDSUSPENDED → ACTIVEACTIVE → DEACTIVATED | Email verified (is_email_verified = TRUE), no active legal hold. | DEACTIVATED |
| 2. Organisation | identity.organisation | DRAFT, PENDING_VERIFICATION, VERIFIED, REJECTED, SUSPENDED | DRAFT → PENDINGPENDING → VERIFIEDPENDING → REJECTEDVERIFIED → SUSPENDED | Business tax ID validated, domain ownership verified. | REJECTED |
| 3. Vendor Profile | identity.vendor_profile | APPLIED, UNDER_REVIEW, APPROVED, REJECTED, TERMINATED | APPLIED → UNDER_REVIEWUNDER_REVIEW → APPROVEDUNDER_REVIEW → REJECTEDAPPROVED → TERMINATED | Master Services Agreement signed, compliance check passed. | TERMINATED, REJECTED |
| 4. Job Requisition | recruitment.job_requisition | DRAFT, PENDING_APPROVAL, APPROVED, PUBLISHED, FILLED, CANCELLED | DRAFT → PENDINGPENDING → APPROVEDAPPROVED → PUBLISHEDPUBLISHED → FILLEDPUBLISHED → CANCELLED | Hiring manager sign-off, wallet/budget pre-authorization, org status VERIFIED. | FILLED, CANCELLED |
| 5. Job Application (13 Stages) | recruitment.job_application | APPLIED, SCREENING, SHORTLISTED, ASSESSMENT, INTERVIEW_SCHEDULED, INTERVIEWED, OFFER_PENDING, OFFER_EXTENDED, OFFER_ACCEPTED, OFFER_DECLINED, JOINED, REJECTED, WITHDRAWN | Linear progression across 13 stages per DR-040 | Minimum assessment score met, interview score logged, rejection reason mandatory on drop. | JOINED, REJECTED, WITHDRAWN |
| 6. Job Interview | recruitment.job_interview | SCHEDULED, RESCHEDULED, COMPLETED, CANCELLED, NO_SHOW | SCHEDULED → RESCHEDULEDSCHEDULED → COMPLETEDSCHEDULED → CANCELLEDSCHEDULED → NO_SHOW | Calendar sync confirmed, interviewer assigned. | COMPLETED, CANCELLED, NO_SHOW |
| 7. Job Offer | recruitment.job_offer | DRAFT, PENDING_APPROVAL, APPROVED, EXTENDED, ACCEPTED, DECLINED, EXPIRED, RESCINDED | DRAFT → PENDINGPENDING → APPROVEDAPPROVED → EXTENDEDEXTENDED → ACCEPTEDEXTENDED → DECLINEDEXTENDED → EXPIRED | Candidate in OFFER_PENDING stage, compensation within rate card limits. | ACCEPTED, DECLINED, EXPIRED, RESCINDED |
| 8. Gig Request | gig.gig_request | DRAFT, OPEN, MATCHING, COMMITTED, CANCELLED | DRAFT → OPENOPEN → MATCHINGMATCHING → COMMITTEDOPEN → CANCELLED | Escrow estimate calculated, job requirements populated. | COMMITTED, CANCELLED |
| 9. Gig Contract | gig.gig_contract | DRAFT, OFFERED, ACTIVE, SUSPENDED, COMPLETED, TERMINATED | DRAFT → OFFEREDOFFERED → ACTIVEACTIVE → SUSPENDEDACTIVE → COMPLETEDACTIVE → TERMINATED | 100% Escrow funding verified in ledger (CTR-04), temporal non-overlap check passed. | COMPLETED, TERMINATED |
| 10. Gig Milestone | gig.gig_milestone | PLANNED, IN_PROGRESS, SUBMITTED, APPROVED, REJECTED, DISPUTED, PAID | PLANNED → IN_PROGRESSIN_PROGRESS → SUBMITTEDSUBMITTED → APPROVEDSUBMITTED → REJECTEDAPPROVED → PAID | Work deliverable uploaded, auto-approval timer (120h) active. | PAID |
| 11. Payment Order | finance.payment_order | CREATED, PROCESSING, SUCCESSFUL, FAILED, REFUNDED | CREATED → PROCESSINGPROCESSING → SUCCESSFULPROCESSING → FAILEDSUCCESSFUL → REFUNDED | Gateway transaction ID present, idempotency key locked. | SUCCESSFUL, REFUNDED |
| 12. Invoice | finance.invoice | DRAFT, ISSUED, PAID, OVERDUE, VOIDED | DRAFT → ISSUEDISSUED → PAIDISSUED → OVERDUEISSUED → VOIDED | Statutory tax calculation verified (CTR-10), ledger journal generated. | PAID, VOIDED |
| 13. DPDP Consent Record | consent.dpdp_consent | REQUESTED, GRANTED, REVOKED, EXPIRED | REQUESTED → GRANTEDGRANTED → REVOKEDGRANTED → EXPIRED | Explicit opt-in timestamp recorded, consent notice version attached. | REVOKED, EXPIRED |
| 14. Campus Drive | campus.placement_drive | DRAFT, SCHEDULED, ACTIVE, COMPLETED, CANCELLED | DRAFT → SCHEDULEDSCHEDULED → ACTIVEACTIVE → COMPLETEDSCHEDULED → CANCELLED | Minimum 20 verified student registrations linked (DR-077). | COMPLETED, CANCELLED |
| 15. Subscription Licence | finance.sub_licence | PROVISIONAL, ACTIVE, PAST_DUE, EXPIRED, CANCELLED | PROVISIONAL → ACTIVEACTIVE → PAST_DUEPAST_DUE → ACTIVEPAST_DUE → EXPIRED | Payment confirmation received, seat ceiling initialized. | EXPIRED, CANCELLED |
| 16. Candidate Claim | recruitment.candidate_claim | SUBMITTED, VERIFYING, CONFIRMED, DISPUTED, REJECTED | SUBMITTED → VERIFYINGVERIFYING → CONFIRMEDVERIFYING → DISPUTEDVERIFYING → REJECTED | Agency ownership proof validated, 180-day window check cleared. | CONFIRMED, REJECTED |
| 17. Agency Contract | recruitment.agency_contract | DRAFT, PENDING_SIGNATURE, ACTIVE, EXPIRED, TERMINATED | DRAFT → PENDINGPENDING → ACTIVEACTIVE → EXPIREDACTIVE → TERMINATED | Dual electronic signatures present, fee schedule attached. | EXPIRED, TERMINATED |
| 18. Rate Card | finance.rate_card | DRAFT, PENDING_APPROVAL, APPROVED, DEPRECATED | DRAFT → PENDINGPENDING → APPROVEDAPPROVED → DEPRECATED | Role skill taxonomy mapped, min_rate <= max_rate. | DEPRECATED |
| 19. Timesheet | gig.timesheet | DRAFT, SUBMITTED, APPROVED, REJECTED, PROCESSED | DRAFT → SUBMITTEDSUBMITTED → APPROVEDSUBMITTED → REJECTEDAPPROVED → PROCESSED | Total hours <= contract weekly maximum, activity log attached. | PROCESSED |
| 20. Audit Session | governance.audit_session | OPEN, ACTIVE, TERMINATED, EXPIRED | OPEN → ACTIVEACTIVE → TERMINATEDACTIVE → EXPIRED | Valid user token attached, IP range authorized. | TERMINATED, EXPIRED |




## Universal Pytest State-Machine Harness Pattern

The code block below highlights the core Python test implementation used to test all 20 entity state machines parameteristically against allowed, prohibited, and guarded transitions.


```sql
"""
Filename: tests/business_rules/test_fsm_engine.py
Purpose: Universal parametric state machine test engine for 20 platform entities.
"""
import pytest
import psycopg
from typing import Dict, Any, List
# Parametric matrix structure: (Entity, Initial State, Target State, Trigger Event, Guard Satisfied, Expected Result)
FSM_TRANSITION_CASES = [
# Entity: job_requisition (DR-031)
("job_requisition", "DRAFT", "PENDING_APPROVAL", "SUBMIT_FOR_APPROVAL", True, "PASS"),
("job_requisition", "PENDING_APPROVAL", "APPROVED", "APPROVE", True, "PASS"),
("job_requisition", "APPROVED", "PUBLISHED", "PUBLISH", True, "PASS"),
("job_requisition", "APPROVED", "PUBLISHED", "PUBLISH", False, "FAIL_GUARD"),  # Org unverified
("job_requisition", "DRAFT", "PUBLISHED", "PUBLISH", True, "FAIL_INVALID_EDGE"),  # Direct skip illegal
("job_requisition", "CANCELLED", "PUBLISHED", "REOPEN", True, "FAIL_TERMINAL"),  # Terminal immutable
# Entity: job_application (DR-040, 13-stage funnel)
("job_application", "APPLIED", "SCREENING", "ADVANCE", True, "PASS"),
("job_application", "INTERVIEWED", "OFFER_PENDING", "ADVANCE", True, "PASS"),
("job_application", "INTERVIEWED", "OFFER_EXTENDED", "EXTEND_OFFER", False, "FAIL_GUARD"),  # Missing approval
("job_application", "APPLIED", "JOINED", "BYPASS", True, "FAIL_INVALID_EDGE"),
# Entity: gig_contract (DR-057)
("gig_contract", "OFFERED", "ACTIVE", "ACTIVATE", True, "PASS"),  # Escrow funded
("gig_contract", "OFFERED", "ACTIVE", "ACTIVATE", False, "FAIL_GUARD"),  # Escrow missing
]
@pytest.mark.parametrize("entity,from_state,to_state,event,guard_ok,expected", FSM_TRANSITION_CASES)
def test_fsm_transitions(db_session, entity: str, from_state: str, to_state: str, event: str, guard_ok: bool, expected: str):
"""
Executes parametric FSM checks asserting valid transitions pass while invalid or un-guarded ones fail.
"""
harness = FSMTestHarness(db_session, entity=entity)
instance_id = harness.create_entity_in_state(from_state)
if expected == "PASS":
result = harness.trigger_transition(instance_id, event=event, target_state=to_state, mock_guard=guard_ok)
assert result.success is True
assert result.current_state == to_state
assert harness.verify_audit_log_written(instance_id, from_state, to_state)
elif expected == "FAIL_GUARD":
with pytest.raises(FSMGuardViolationException) as exc_info:
harness.trigger_transition(instance_id, event=event, target_state=to_state, mock_guard=False)
assert "ERR_GUARD_CONDITIONS_NOT_MET" in str(exc_info.value)
assert harness.get_current_state(instance_id) == from_state
elif expected == "FAIL_INVALID_EDGE":
with pytest.raises(FSMInvalidTransitionException) as exc_info:
harness.trigger_transition(instance_id, event=event, target_state=to_state, mock_guard=True)
assert "ERR_ILLEGAL_STATE_TRANSITION" in str(exc_info.value)
assert harness.get_current_state(instance_id) == from_state
elif expected == "FAIL_TERMINAL":
with pytest.raises(FSMTerminalStateImmutableException) as exc_info:
harness.trigger_transition(instance_id, event=event, target_state=to_state, mock_guard=True)
assert "ERR_TERMINAL_STATE_IMMUTABLE" in str(exc_info.value)
```

# Decision-Table-Driven Test Generation

To eliminate manual test creation for complex rules, Milestone 27 introduces automated decision table testing. Standardized YAML decision tables define all inputs, boundary conditions, and expected outputs. A loader script parses these files to automatically inject parameterized test cases into pytest.

## Specification Format (specs/decision_tables/BR-001_BR-003.yaml)

```sql
decision_table:
rule_id: "BR-001 / BR-003"
name: "Requisition Publication & Vendor Agency Sourcing Guard"
description: "Validates conditions under which a job requisition can be published and agency candidates submitted."
inputs:
- name: "org_verification_status"
type: "enum"
values: ["VERIFIED", "UNVERIFIED", "REJECTED"]
- name: "recruiter_seat_available"
type: "boolean"
- name: "requisition_visibility"
type: "enum"
values: ["PUBLIC", "AGENCY_OPEN", "PRIVATE"]
- name: "agency_invited"
type: "boolean"
- name: "nomination_age_days"
type: "integer"
boundaries: [0, 179, 180, 181]
rules:
- id: "RULE_PUB_01"
conditions:
org_verification_status: "VERIFIED"
recruiter_seat_available: true
requisition_visibility: "PUBLIC"
agency_invited: false
nomination_age_days: 0
expected:
can_publish: true
can_submit_agency: false
http_status: 200
error_code: null
- id: "RULE_PUB_02_UNVERIFIED_ORG"
conditions:
org_verification_status: "UNVERIFIED"
recruiter_seat_available: true
requisition_visibility: "PUBLIC"
agency_invited: false
nomination_age_days: 0
expected:
can_publish: false
can_submit_agency: false
http_status: 403
error_code: "ERR_ORG_NOT_VERIFIED"
- id: "RULE_AGENCY_LOCKOUT_179"
conditions:
org_verification_status: "VERIFIED"
recruiter_seat_available: true
requisition_visibility: "AGENCY_OPEN"
agency_invited: true
nomination_age_days: 179
expected:
can_publish: true
can_submit_agency: false
http_status: 409
error_code: "ERR_NOMINATION_LOCKOUT_ACTIVE"
- id: "RULE_AGENCY_ALLOW_180"
conditions:
org_verification_status: "VERIFIED"
recruiter_seat_available: true
requisition_visibility: "AGENCY_OPEN"
agency_invited: true
nomination_age_days: 180
expected:
can_publish: true
can_submit_agency: true
http_status: 201
error_code: null
```

## Automated Decision Table Pytest Loader (tests/business_rules/decision_table_loader.py)

The loader below automatically dynamically generates pytest test cases directly from the YAML specs.


```sql
"""
Filename: tests/business_rules/decision_table_loader.py
Purpose: Dynamically load YAML decision tables and generate parameterized pytest cases.
"""
import os
import yaml
import pytest
from typing import List, Dict, Any
def load_decision_table(file_path: str) -> Dict[str, Any]:
with open(file_path, "r") as f:
return yaml.safe_load(f)
def generate_test_cases(table_dir: str):
cases = []
for root, _, files in os.walk(table_dir):
for file in files:
if file.endswith(".yaml") or file.endswith(".yml"):
table_path = os.path.join(root, file)
data = load_decision_table(table_path)
rule_id = data["decision_table"]["rule_id"]
for test_rule in data["decision_table"]["rules"]:
cases.append((
rule_id,
test_rule["id"],
test_rule["conditions"],
test_rule["expected"]
))
return cases
DECISION_TABLE_CASES = generate_test_cases("specs/decision_tables/")
@pytest.mark.rule_dt
@pytest.mark.parametrize("rule_id,case_id,conditions,expected", DECISION_TABLE_CASES)
def test_decision_table_rule(api_client, db_session, rule_id: str, case_id: str, conditions: Dict[str, Any], expected: Dict[str, Any]):
"""
Executes dynamically generated tests from decision table specifications.
"""
# Setup test state based on condition values
context = setup_test_context(db_session, conditions)
# Execute API or service call
response = api_client.post("/api/v1/requisitions/publish_and_submit", json={
"org_id": context.org_id,
"req_id": context.req_id,
"candidate_id": context.candidate_id,
"nomination_days": conditions.get("nomination_age_days", 0)
})
# Assert HTTP outcome and application error code
assert response.status_code == expected["http_status"], f"Failed case {case_id} in {rule_id}"
if expected["error_code"]:
assert response.json()["detail"]["code"] == expected["error_code"]
else:
assert response.json()["status"] == "SUCCESS"
```

# CI/CD Traceability Gate & Coverage Enforcement

To prevent unverified business logic from being merged into production branches, Milestone 27 establishes a strict CI/CD gate script (scripts/verify_br_coverage.py).

## Verification Script Execution Architecture

```sql
CI/CD Pipeline
|
v
+---------------------------------------+
|  Extract Catalog Rules (BR-001..024)   |
|  from specs/catalogue/BR_CATALOG.json |
+---------------------------------------+
|
v
+---------------------------------------+
|  Parse Test AST for @pytest.mark.rule |
|  Decorators across tests/ Directory   |
+---------------------------------------+
|
v
+---------------------------------------+
|  Evaluate Coverage & Rule Trace Matrix|
+---------------------------------------+
|
+------------------+------------------+
|                                     |
Coverage < 100%                       Coverage == 100%
|                                     |
v                                     v
+-----------------------+             +-----------------------+
|   Exit Code 1 (FAIL)  |             |   Exit Code 0 (PASS)  |
|  Block GitHub Action  |             | Proceed to Deployment |
+-----------------------+             +-----------------------+
Script Source Code (scripts/verify_br_coverage.py)
```
```sql
#!/usr/bin/env python3
"""
Filename: scripts/verify_br_coverage.py
Purpose: Audit test suite AST to ensure 100% coverage of Milestone 18 Business Rule Catalogue.
"""
import ast
import os
import sys
import json
from typing import Set, Dict
CATALOG_PATH = "specs/catalogue/BR_CATALOG.json"
TESTS_DIR = "tests/business_rules"
def load_catalog_rules() -> Set[str]:
with open(CATALOG_PATH, "r") as f:
data = json.load(f)
return set(data["rules"].keys())  # Returns {"BR-001", "BR-002", ..., "BR-024"}
def parse_decorated_rules(directory: str) -> Dict[str, Set[str]]:
covered_rules = {}
for root, _, files in os.walk(directory):
for file in files:
if file.endswith(".py"):
path = os.path.join(root, file)
with open(path, "r") as f:
tree = ast.parse(f.read(), filename=path)
for node in ast.walk(tree):
if isinstance(node, ast.FunctionDef):
for decorator in node.decorator_list:
if isinstance(decorator, ast.Call):
if getattr(decorator.func, "id", None) == "rule" or \
(isinstance(decorator.func, ast.Attribute) and decorator.func.attr == "rule"):
for arg in decorator.args:
if isinstance(arg, ast.Constant):
rule_id = arg.value
covered_rules.setdefault(rule_id, set()).add(f"{file}::{node.name}")
return covered_rules
def main():
catalog_rules = load_catalog_rules()
covered_map = parse_decorated_rules(TESTS_DIR)
covered_rules = set(covered_map.keys())
missing_rules = catalog_rules - covered_rules
print("==================================================")
print("      TALENTRA BUSINESS RULE COVERAGE REPORT      ")
print("==================================================")
print(f"Total Catalogue Rules Enforced : {len(catalog_rules)}")
print(f"Automated Covered Rules        : {len(covered_rules)}")
print(f"Missing / Unmapped Rules       : {len(missing_rules)}")
print("--------------------------------------------------")
if missing_rules:
print("ERROR: CI/CD Pipeline Failed! The following rules lack automated tests:")
for rule in sorted(missing_rules):
print(f"  - [MISSING]: {rule}")
sys.exit(1)
else:
print("SUCCESS: 100% Business Rule Automation Verified. CI Gate Passed!")
sys.exit(0)
if __name__ == "__main__":
main()
```

# Acceptance Checklist & Sign-Off Criteria

## Verification Matrix

| Requirement Area | Acceptance Condition | Status | Verified By |
| :--- | :--- | :--- | :--- |
| Catalog Coverage | Every business rule (BR-001 through BR-024) from Milestone 18 has at least one mapped pytest suite using @pytest.mark.rule("BR-###"). |  | Automated CI Gate (verify_br_coverage.py) |
| 20 Entity FSMs | All 20 system entity state machines pass automated parametric validation testing allowed, prohibited, and guarded state transitions. |  | FSM Test Engine (test_fsm_engine.py) |
| Concurrency Locks | Multi-threaded race condition tests confirm lock integrity for wallet balance deductions, seat ceilings, and non-overlapping GiST schedules under concurrent load. |  | Layer 2 Async Suite (test_concurrency.py) |
| Decision Table Engine | Automated YAML decision-table generator executes boundary tests (lower-1, boundary, upper+1) with zero missing condition paths. |  | Loader Engine (decision_table_loader.py) |
| DB Constraint Hardening | Direct SQL insertion tests confirm RLS, foreign keys, and DB triggers fail cleanly when bypass attempts occur at Layer 1. |  | Database Layer Suite (test_db_constraints.py) |
| Audit Trace Immutability | Cryptographic hash chaining on governance.system_audit_event verified tamper-evident under raw DB update attempts. |  | Security Audit Engine (test_audit_chain.py) |




## Key Takeaway

Milestone 27 shifts the platform from manual quality assurance to continuous, automated mathematical proof. Every state transition, balance deduction, concurrency guard, and privacy constraint is automatically verified on every code commit, ensuring software stability across the entire Talentra platform ecosystem.
