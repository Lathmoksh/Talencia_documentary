# Milestone 19 — Data Dictionary v2

**Phase:** 3 — Prove  
**Output:** Refined-model data dictionary, generated or schema-derived, with rule IDs, classification and volumetrics

## 1. Purpose and exit criteria

Bring the dictionary into line with the refined schema after Milestone 17 and business rules in Milestone 18. It must be a reliable bridge between business semantics, physical schema, governance and testing.

**Done when:** a validation script reports zero unexplained drift between the dictionary and deployed schema; each applicable column has classification, rule references and volumetric context.

## 2. Source baseline

Step 10 documents the original 90 logical tables / 893 columns across 13 schemas. These counts are the historical baseline, not a guarantee that the refined physical schema still has exactly those totals. Regenerate counts from the current DDL/database and record any intentional difference.

Use Step 12 for privacy/classification and retention metadata; Step 11 and Milestone 18 for rule references; Milestone 13 for volumes; Milestone 17 for change history.

## 3. Required dictionary fields

| Field | Description |
|---|---|
| Schema / table / column | Exact physical identifier |
| Business name / definition | Meaning in Talentra's domain |
| Data type | Actual database type and precision |
| Nullable | Actual nullability and rationale |
| Default / generated expression | Exact schema behavior |
| PK / FK / unique / check | Constraints and target/action |
| Index | Relevant index and purpose |
| Domain / allowed values | Enum/check/reference domain |
| Rule IDs | `DR-###`, `CTR-##`, `BR-###`, transition IDs |
| Workflow IDs | `WF-xx` usage |
| Classification | Public / Internal / Personal / Confidential-Sensitive as defined by Step 12 |
| Access / masking | Role/tenant visibility and display treatment |
| Retention | Approved period or policy reference |
| Volumetrics | Estimated row count, growth and distribution context |
| Source / decision | Discovery document or decision record |
| Change status | Added, changed, retained, deprecated |

## 4. Generation and drift validation

Preferred workflow:
1. Introspect the target PostgreSQL schema (`information_schema`, `pg_catalog`, constraints, indexes, defaults and comments).
2. Generate physical facts from the database, not manually copied descriptions.
3. Merge reviewed business definitions, rule IDs, workflow mapping, classification and retention metadata from a controlled source file.
4. Compare generated schema facts against the checked-in dictionary.
5. Fail CI on unexplained differences in tables, columns, types, nullability, defaults, keys, constraints or indexes.
6. Report intentional exceptions with a linked decision/migration ID.

Illustrative drift checks:
- dictionary column absent from schema;
- schema column missing from dictionary;
- data type or nullability mismatch;
- missing/changed PK, FK, unique/check constraint;
- dictionary classification or rule mapping absent;
- volumetric sheet does not contain a current table.

## 5. Acceptance checklist

- [ ] Dictionary matches refined model and current schema.
- [ ] Rule IDs and workflow IDs are mapped where applicable.
- [ ] Privacy classification and retention are populated from approved Step 12 decisions.
- [ ] Volumetrics are linked to Milestone 13 assumptions.
- [ ] Generation and validation steps are documented and repeatable.
- [ ] Drift check reports zero unexplained mismatches.
- [ ] Schema-count differences from the 90/893 baseline are explained.

## 6. Go deeper

Generate physical dictionary fields directly from the database so that types, constraints and indexes cannot drift. Keep business meaning and privacy metadata in a reviewable source of truth, then validate its linkage to the physical schema.
