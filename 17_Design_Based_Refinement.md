# Milestone 17 — Design-Based Refinement

**Phase:** 3 — Prove  
**Output:** Refined logical model, change log with rationale, rerun Test Suite v1 evidence

## 1. Purpose and exit criteria

Close defects discovered by Milestones 15 and 16. Make deliberate model changes—add, split, merge or remove entities/attributes/relationships—only when evidence shows the current design fails a rule or workflow.

**Done when:** all gaps are closed or explicitly deferred with a reason, owner and impact; Test Suite v1 is rerun after every material change; the change log explains the decision.

## 2. Inputs

- Current ER Model v0 / redesigned ERL.
- Step 07 attribute discovery and Step 08 state machines.
- Step 11 data rule catalogue.
- Milestone 14 golden dataset.
- Milestone 15 data integrity test report.
- Milestone 16 workflow coverage matrix.
- Existing repository DDL/schema and migrations.

## 3. Refinement process

1. Create a defect record with a reproducible fixture, workflow, rule ID and expected/actual result.
2. Identify whether the issue is a data-model defect, rule-enforcement gap, workflow gap, performance issue, or documentation drift.
3. Form at least two viable designs for high-impact decisions.
4. Compare integrity, normalization, query complexity, write cost, privacy, auditability, migration risk and future extensibility.
5. Select a design and record the trade-off.
6. Update ER model, dictionary, rules, workflow matrix, generator and tests together.
7. Re-run relevant positive and negative tests; then run the complete Test Suite v1 regression.
8. Record migration/backfill and compatibility implications.

## 4. Decision record template

```markdown
### DEC-### — <short decision>

- **Problem / evidence:** defect, test ID, workflow and rule IDs
- **Options considered:** A / B (at least two for material design choices)
- **Decision:** selected option
- **Rationale:** integrity, normalization, workload, privacy and maintainability
- **Consequences:** schema/API/reporting/migration implications
- **Rejected option and reason:**
- **Owner / date / status:**
- **Tests rerun:** IDs and result
```

## 5. Change log format

| Change ID | Object | Before | After | Triggering gap/test | Rationale | Impact | Tests rerun | Status |
|---|---|---|---|---|---|---|---|---|

Avoid speculative changes. If a table/column is added, explain the business fact it represents and why existing structures cannot model it cleanly. If removed, show that no requirement, workflow, rule, or reporting grain depends on it.

## 6. Acceptance checklist

- [ ] Every P1/P2 gap from workflow and data testing is resolved or formally deferred.
- [ ] No unresolved integrity regression.
- [ ] Model and schema are in sync.
- [ ] Dictionary, rules and workflow matrix updated.
- [ ] Generator and golden answers updated.
- [ ] Test Suite v1 passes after changes.
- [ ] Design alternatives and decision rationale are recorded.

## 7. Go deeper

Compare two designs for the hardest area—likely lifecycle, gig temporal booking, tenant/privacy boundary, or financial ledger—and record the choice based on explicit criteria rather than preference.
