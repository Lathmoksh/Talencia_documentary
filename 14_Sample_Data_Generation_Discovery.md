# Milestone 14 — Sample Data Generation (Discovery)

**Platform:** Talentra Enterprise Workforce & Talent Demand Management Platform  
**Phase:** 3 — Prove  
**Output:** Seeded, reproducible valid sample dataset; generator; golden query-answer catalogue; negative fixtures

## 1. Purpose and exit criteria

Generate a compact but representative dataset that exposes modeling defects before application code is built. It must obey the Step 07 attribute domains, Step 08 state machines, Step 09 relationships, Step 11 constraints, and Step 12 privacy classification.

**Done when:** every state, relationship, rule category and workflow can be exercised; generation is deterministic from a seed; valid and intentionally invalid records are kept separate.

## 2. Source and scope

The Talentra discovery baseline has 13 domain schemas and 90 logical entities. Sample data must represent the main workflows from the hackathon docket: registration/profile building, employer verification and requisition publishing, candidate applications and pipeline movement, sourcing, gig request/application/handoff, subscription/seat/credit use, wallet and payments, notifications, privacy, and audit.

Use the current repository's schema and naming. This deliverable defines generator behavior; it does not assert that all listed records already exist in the implementation.

## 3. Generator contract

Suggested interface:

```text
generate_sample_data(
  seed = 20261103,
  profile = "discovery",
  scale = "small",
  include_edge_cases = true,
  output = "sql|jsonl|csv"
)
```

The generator must:
- use a fixed seed and deterministic ID mapping;
- create parent rows before dependent rows, respecting FK ordering;
- generate valid defaults and required values from the dictionary;
- follow allowed lifecycle transitions and valid state combinations;
- keep tenant ownership coherent;
- use valid currency codes, timestamp zones, range boundaries, and enumerated values;
- avoid real personal data; use synthetic identities and non-routable/test contact values;
- generate distinct fixtures for negative tests (orphan FK, duplicate unique key, invalid enum, invalid range, unauthorized tenant, prohibited transition);
- support cleanup/reset or isolated test schema execution.

## 4. Dataset design

### 4.1 Minimum golden fixture

Include at least:
- multiple candidates with differing profile completeness, education, work history, skills and privacy preferences;
- multiple organisations across verification states, locations, recruiter assignments and tenant boundaries;
- requisitions in draft, published/open, paused/closed/filled or other states explicitly defined by the lifecycle document;
- applications at representative pipeline states, including terminal outcomes and guarded transitions;
- sourcing requests and consultant eligibility/open-to-consultant cases;
- gig workers, requests, availability intervals, accepted applications, assignment/handoff references, milestone or pricing cases as supported by the model;
- subscription plans, licences, seats, quota usage, orders, invoices, wallet and ledger cases;
- candidate block-list entries and profile-unlock receipts;
- consent, retention, key-registry and audit records;
- analytics dimension/fact rows at their intended grain.

### 4.2 Edge cases

Include exact boundaries and controlled exceptions:
- minimum/maximum permitted lengths and numeric values;
- nullable versus required attributes;
- duplicate candidates' skill associations and uniqueness boundaries;
- no-child and many-child relationships;
- date/time endpoints, adjacent non-overlapping gig windows, and overlapping windows;
- zero/one/multiple seats or devices at configured limits;
- salary undisclosed versus explicit zero, where permitted;
- missing consent, revoked consent, blocked employer, and contact details not unlocked;
- valid transition, forbidden transition, and concurrent competing update.

Do not invent state labels or limits: obtain them from Steps 07, 08 and 11 and the current DDL.

## 5. Golden answers

For each seeded scenario, record expected query results in `golden_queries.md` or test fixture metadata. Examples:
- candidate search excludes organisations in the candidate's block list;
- recruiter only sees requisitions belonging to the recruiter's organisation and permitted scope;
- only eligible/published requisitions are discoverable;
- a profile unlock creates one auditable receipt and applies the credit rule exactly once;
- a gig worker cannot be double-booked over an overlapping protected interval;
- a balanced ledger transaction nets to zero;
- lifecycle query returns only allowed transitions;
- analytics totals match source records at the defined fact grain.

Expected answers must be computed from the fixture and reviewed, not guessed.

## 6. Deliverables and acceptance

- [ ] Generator source, configuration and fixed seed.
- [ ] Valid sample dataset and schema reset/load instructions.
- [ ] Separate negative fixture set with expected rejection.
- [ ] Golden query catalogue with expected rows/aggregates.
- [ ] Coverage map from generated rows to states, relationships and rule IDs.
- [ ] No genuine personal data or secrets.
- [ ] Repeat run with same seed produces the same logical dataset.

## 7. Go deeper

Create a small golden dataset where every query answer is known in advance. Use it as a stable regression fixture; larger randomized datasets should not replace this trusted baseline.
