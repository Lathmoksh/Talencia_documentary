# Milestone 18 — Business Rules and Data Constraints v2

**Phase:** 3 — Prove  
**Output:** Unified business/data rule catalogue v2 with IDs, ownership, enforcement points and planned tests

## 1. Purpose and exit criteria

Add the business policy layer on top of the data rules. Capture eligibility, policies, calculations, limits, approvals, and workflow decisions; map each rule to its enforcement point and test.

**Done when:** every business rule has a stable ID, owner, enforcement point and planned test; complex combinations are represented so no policy branch is overlooked.

## 2. Baseline and boundaries

Retain Step 11's `DR-001`–`DR-085` and `CTR-01`–`CTR-10` IDs. Step 18 adds business-rule IDs; do not rename or silently overwrite existing data rules. Align rules to the current requirements, workflow IDs, Step 08 transitions, Step 12 classifications, and refined schema.

Business rules must be derived from Talentra's documented scope, including candidate/recruiter access, organisation verification, requisition eligibility, application pipeline, consultant access, gig handoff, subscription/seat/quota/credit policy, financial transactions, privacy and audit. Mark any rule whose exact policy is not established by the source documents as **decision required**, rather than inventing a value.

## 3. Catalogue schema

| Field | Meaning |
|---|---|
| `BR-ID` | Stable identifier, e.g. `BR-001` |
| Rule name | Short business-readable title |
| Statement | Unambiguous condition and outcome |
| Domain / workflow | Owning domain and `WF-xx` |
| Owner | Business or technical owner |
| Inputs | Attributes/entities used |
| Preconditions | Conditions that must already hold |
| Enforcement | DB constraint, transaction/lock, domain service, access policy, async process or documented combination |
| Failure behavior | Reject, deny, queue, return state, or other explicit outcome |
| Data rules | Related `DR-###` / `CTR-##` |
| Lifecycle | Related entity transition(s) |
| Test IDs | Positive, negative and boundary tests |
| Classification | Data sensitivity / handling class |
| Status | Proposed, reviewed, approved, retired |

## 4. Rule discovery and mapping

For every policy:
1. Express it as a testable predicate or decision.
2. Identify its authoritative inputs and the transaction scope.
3. Identify enforcement that cannot be bypassed by another client.
4. Define deterministic failure behavior.
5. Link to relevant data rules and lifecycle transitions.
6. Define positive, negative and boundary tests.
7. Identify the policy owner and approval status.

Examples of policy areas (not a substitute for source-defined exact thresholds):
- Employer verification gates requisition publication.
- Recruiter actions are restricted to their own organisation's requisitions.
- Consultant access is limited to requisitions open to consultants.
- Candidate block lists and privacy controls suppress discovery/disclosure.
- Contact disclosure requires the documented unlock/credit path.
- Seat/device/quota/credit limits are enforced atomically.
- Gig availability and assignment windows cannot conflict where prohibited.
- Ledger transaction groups balance and are auditable.
- Consent and retention rules govern personal-data processing.

## 5. Decision tables

Represent interacting conditions with a complete decision table. Example structure:

| Verified organisation? | Requisition valid? | Actor authorized? | Consultant-open? | Expected result |
|---|---|---|---|---|
| Yes | Yes | Yes | N/A | Publish may proceed, subject to remaining rules |
| No | Yes | Yes | N/A | Reject publication |
| Yes | No | Yes | N/A | Reject publication |
| Yes | Yes | No | N/A | Deny |
| Yes | Yes | Yes | No | Consultant access denied |

This is an illustrative branch model; use approved source policy for exact behavior and extend rows to cover all combinations.

## 6. Acceptance checklist

- [ ] All rules have stable IDs and clear statements.
- [ ] Each rule has an owner and approval/status.
- [ ] Each rule maps to an enforcement point and planned test.
- [ ] Existing DR/CTR IDs remain traceable.
- [ ] Transition rules and business policy are linked.
- [ ] Decision tables cover combinations and boundary conditions.
- [ ] No undocumented limits, fees, thresholds or policy defaults were introduced.

## 7. Go deeper

Express complex rules as decision tables and check for missing combinations. Prefer deterministic, auditable outcomes over implicit behavior scattered across application code.
