# Milestone 21 — Baseline ER and Physical Model

**Phase:** 3 — Prove  
**Output:** Published ER Model v1, PostgreSQL DDL, indexes/constraints, migration v1 and clean-install evidence

## 1. Purpose and exit criteria

Freeze a proven baseline that the remaining lifecycle can build on. Publish the refined ER model and physical implementation, including indexes, partitioning decisions, constraints and versioned migrations.

**Done when:** DDL installs cleanly on an empty database and Test Suite v2 passes against it. This is a baseline, not a claim that the model will never change; later changes use the change log and migrations.

## 2. Inputs

- Redesigned ERL / ER Model v0.
- Milestones 13–20: volumetrics, reproducible data, test reports, coverage matrix, refinement decisions, rules v2 and dictionary v2.
- PostgreSQL 16 baseline specified by the discovery deliverables; verify actual project runtime/version.
- Project DDL and migration repository.

## 3. Physical model requirements

Document and implement:
- schema-qualified tables and naming conventions;
- PKs, FKs, uniqueness, nullability, check/domain constraints;
- FK delete/update behavior and indexes;
- indexes justified by workflow/query patterns;
- tenant boundary and row-level/access enforcement strategy;
- lifecycle enforcement and transaction/locking requirements;
- temporal exclusion constraints for protected gig booking windows where specified;
- financial ledger integrity and reconciliation strategy;
- privacy classification, masking/access boundary and audit strategy;
- partitioning decisions based on measured/estimated volume and retention;
- generated/default values, sequences, extensions and required privileges.

Do not add partitioning, indexes or triggers solely as decoration; record the workload or invariant they support. Where a rule spans rows/tables and cannot be represented by a simple constraint, document the authoritative enforcement mechanism and its concurrency behavior.

## 4. DDL and migration layout

A practical repository layout:

```text
database/
  er/
    talentra_er_v1.mmd
  ddl/
    001_extensions.sql
    010_schemas.sql
    020_reference_tables.sql
    030_identity_organisation.sql
    040_candidate_recruitment_application.sql
    050_gig_licensing_billing.sql
    060_engagement_governance_analytics.sql
    070_constraints_indexes.sql
  migrations/
    V1__baseline.sql
  tests/
    clean_install_check.sql
    schema_drift_check.sql
```

Adjust names and grouping to the existing repository. A baseline migration should be immutable after release; future schema changes receive new ordered migration files.

## 5. Clean-install and migration proof

1. Provision a fresh empty PostgreSQL database at the documented version.
2. Apply extensions and DDL/migrations in order.
3. Confirm all schemas, tables, constraints, indexes, triggers, functions and policies are created.
4. Run schema introspection and compare with Data Dictionary v2.
5. Load the Milestone 14 valid fixture.
6. Run Test Suite v2.
7. Verify negative tests fail for the expected reason.
8. Verify migration replay and documented rollback/forward-recovery strategy.
9. Capture command output, database version, commit hash and test report.

## 6. Baseline ER publication

The ER artifact should:
- represent the current physical/logical relationships with exact table and key names;
- be modular enough to read by domain, with an overall overview;
- show junction entities and cardinalities;
- reflect the refined schema—not a stale discovery draft;
- link to dictionary, rules and migration artifacts;
- carry version, date, change record and known limitations.

## 7. Acceptance checklist

- [ ] ER Model v1 published and aligned with the DDL.
- [ ] DDL runs on an empty database without manual fixes.
- [ ] Indexes, constraints, partitioning and migrations are documented.
- [ ] Dictionary drift check has zero unexplained differences.
- [ ] Valid sample dataset loads successfully.
- [ ] Test Suite v2 passes.
- [ ] Baseline version and known limitations are recorded.
- [ ] Future changes must use migration and decision/change logs.

## 8. Go deeper

Treat this as a proven baseline, not a final immutable design. Subsequent changes should be versioned, reviewed, tested against the suite and recorded in the change log.
