# Milestone 15 — Test Suite v1: Data Integrity

**Phase:** 3 — Prove  
**Test stage:** Data-only integrity, before application implementation  
**Output:** Executable tests, expected outcomes, rule IDs, and reproducible report

## 1. Purpose and completion condition

Prove that the relational model rejects malformed data and accepts valid data. Test primary/foreign keys, orphan prevention, uniqueness, nullability, formats, domains, ranges, and referential actions.

**Done when:** every data rule has at least one positive and one negative test; invalid records are rejected (not merely omitted); test outcomes are linked to rule IDs.

## 2. Source baseline

Use Step 11's `DR-001`–`DR-085` and `CTR-01`–`CTR-10` catalogue, Step 07 attribute domains, Step 09 relationship definitions, and Step 10 dictionary. Confirm exact rule descriptions and names from the source files before mapping tests. Do not fabricate or renumber source rules.

## 3. Test categories

| Category | Positive test | Negative test | Expected result |
|---|---|---|---|
| Primary key | Insert valid unique ID | Null or duplicate ID | Constraint rejection |
| Foreign key | Insert child with existing parent | Insert orphan child | FK rejection |
| Uniqueness | Insert distinct valid business key | Duplicate key in defined scope | Unique violation |
| Requiredness | Populate required attribute | Omit required value | NOT NULL rejection |
| Domain / format | Valid ISO code, email/phone format, enum | Invalid or malformed value | Check/domain rejection or documented validation layer |
| Numeric / date range | Value exactly inside permitted boundary | Below/above boundary | Check rejection |
| Referential action | Exercise declared RESTRICT/CASCADE/SET NULL behavior | Delete parent against incompatible action | Exact declared action |
| Composite uniqueness | Different permitted version/tenant pair | Duplicate composite key | Unique rejection |
| Temporal constraint | Adjacent/non-overlapping intervals | Overlapping protected interval | Exclusion constraint rejection |
| Financial invariant | Balanced debit/credit group | Unbalanced group | Transaction rejected / invariant failure |
| Privacy rule | Authorized scoped read | Blocked or unconsented disclosure | Denied / excluded |

## 4. Test-case schema

Each test record should include:

```yaml
test_id: TC-DATA-###
rule_id: DR-### | CTR-##
purpose: concise assertion
fixture: fixture name
setup: deterministic prerequisite
action: insert/update/delete/query
expected: accept | reject | return exact result
actual: populated by runner
status: pass | fail | blocked
evidence: output/log reference
```

Keep this shape as an illustrative contract; adapt it to the team's existing test runner.

## 5. Required assertions

- Every source rule is represented in the mapping inventory.
- Positive and negative cases exist for every rule where both semantics apply.
- Referential actions match the ER model.
- The schema does not rely solely on UI validation for core invariants.
- Tests run against an empty disposable database after migrations/DDL.
- Negative tests assert the correct failure class/constraint, not just any error.
- Seed and test runs are deterministic.

## 6. Test execution and reporting

1. Create a clean test database.
2. Apply the current schema/migrations.
3. Load valid fixtures.
4. Run positive assertions.
5. Run each negative case in an isolated transaction/savepoint so one failure does not contaminate later cases.
6. Capture SQLSTATE, constraint name, result rows and elapsed time where relevant.
7. Produce summary by rule ID: covered / positive / negative / pass / fail / blocked.
8. File each uncovered or failed assertion as a refinement item for Milestone 17.

## 7. Go deeper

For every important rule, demonstrate that an invalid row is rejected at the enforcement point. A passing happy-path insert alone is not proof of integrity.
