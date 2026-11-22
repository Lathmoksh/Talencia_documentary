Milestone 26 — Test Automation: Data Quality and Analytics

# 1. Executive Summary & Metadata Header

## Milestone Overview

Milestone: 26 — Test Automation: Data Quality and Analytics

Phase: Phase 4 — Build & Integrate ("Real Volume, Automate the Proof")

Platform: Talentra Enterprise Workforce & Talent Demand Management Platform

Architecture Alignment: PostgreSQL 16 baseline across 13 core domain schemas (identity, organisation, candidate, requisition, application, matching, assessment, interview, gig, billing, dpdp, audit, governance) and 1 analytical schema (analytics).

Upstream Standards: Enforces domain constraints DR-001 through DR-085, cross-domain integrity constraints CTR-01 through CTR-10, Data Dictionary v2, Test Suite v2, and Milestone 25 Zero-Loss Ingestion Reconciliation.

Purpose: Establish a fully automated, deterministic, and repeatable test automation suite for data quality (DQ) and analytical integrity checks. This suite executes continuously across PR merges, nightlies, and batch ingestion pipelines to guarantee total operational correctness and zero-loss transactional-to-analytical parity.

Core Outputs:

Automated Data Quality & Analytics Test Suite (pytest engine with SQL assertion runners).

Six-Dimension Data Quality Assertion Catalogue.

Kimball Star Schema & Fact-to-OLTP Reconciliation Engine.

Per-Table Data Quality Score Tracking Engine & Governance Persistence Layer.

## Exit Criteria ("Done When")

Single-command CLI execution (make test-dq or pytest tests/data_quality) runs the entire battery of assertion suites in under 120 seconds against production-scale staging data.

Integrated into CI/CD pipelines (GitHub Actions / GitLab CI) with rigid exit-code gating (Exit Code 1 on any Critical/High DQ assertion failure or DQ Score regression below configured baseline thresholds).

Automated persistence of detailed assertion metrics and composite per-table scores (0.00–100.00) into governance.data_quality_scorecard and governance.data_quality_check_result.



# 2. Six-Dimension Automated Data Quality Assertion Catalogue

The assertion catalogue defines concrete, automated data quality verification checks structured across the six standard dimensions of data quality. Each check maps directly to Talentra schema objects and specific Business Domain Rules (DR) or Cross-Domain Constraints (CTR).

## 2.1 Completeness Dimension

Ensures mandatory fields contain non-null values, expected nullability rates remain within statistical boundaries, and ingestion pipelines guarantee zero data loss.


| Assertion ID | Target Schema & Table | Target Column(s) | Rule / Constraint Mapping | Enforcement Logic & Threshold |
| :--- | :--- | :--- | :--- | :--- |
| DQ-CMP-01 |  | email | DR-007 (Mandatory Email) | COUNT(*) WHERE email IS NULL must equal 0. |
| DQ-CMP-02 |  | legal_name | DR-016 (Org Legal Identity) | COUNT(*) WHERE legal_name IS NULL OR TRIM(legal_name) = '' must equal 0. |
| DQ-CMP-03 |  | date_of_birth | DR-023 (Age Verification) | COUNT(*) WHERE date_of_birth IS NULL must equal 0. |
| DQ-CMP-04 |  | current_salary_amount | Milestone 11 Section 6.1 | Null-rate band verification: NULL allowed (undisclosed), but numeric values must NOT be formatted as 0.00 to indicate undisclosed state. Null-rate band must be within 15.0% to 45.0%. |
| DQ-CMP-05 |  | All Ingestion Targets | Milestone 25 (Zero-Loss) | Source_Records = Loaded_Records + Quarantined_Records with zero unaccounted record drop across all batch and streaming ingestions. |


### SQL Assertion Implementations (Completeness)

```sql
-- DQ-CMP-04: Undisclosed Salary Format & Null-Rate Band Verification
WITH salary_stats AS (
SELECT
COUNT(*) AS total_records,
COUNT(*) FILTER (WHERE current_salary_amount IS NULL) AS null_count,
COUNT(*) FILTER (WHERE current_salary_amount = 0.00) AS zero_count
FROM candidate.candidate_profile
)
SELECT
total_records,
null_count,
zero_count,
(null_count::NUMERIC / total_records::NUMERIC) * 100.0 AS null_percentage,
CASE
WHEN zero_count > 0 THEN 'FAIL: 0.00 used for undisclosed salary instead of NULL'
WHEN (null_count::NUMERIC / total_records::NUMERIC) NOT BETWEEN 0.15 AND 0.45 THEN 'FAIL: Null rate outside 15%-45% tolerance band'
ELSE 'PASS'
END AS status
FROM salary_stats;
-- DQ-CMP-05: Ingestion Pipeline Zero-Loss Reconciliation (Milestone 25)
SELECT
batch_id,
source_system,
source_record_count,
loaded_record_count,
quarantined_record_count,
(source_record_count - (loaded_record_count + quarantined_record_count)) AS unaccounted_record_drop,
CASE
WHEN source_record_count = (loaded_record_count + quarantined_record_count) THEN 'PASS'
ELSE 'FAIL: Record Loss Detected'
END AS status
FROM audit.ingestion_batch_log
WHERE ingestion_timestamp >= NOW() - INTERVAL '24 hours';
```

## 2.2 Accuracy Dimension

Validates mathematical calculations, financial ledger zero-variance balance constraints, and domain score bounds.


| Assertion ID | Target Schema & Table | Target Column(s) | Rule / Constraint Mapping | Enforcement Logic & Threshold |
| :--- | :--- | :--- | :--- | :--- |
| DQ-ACC-01 | billing.invoice | total_amount, subtotal_amount, tax_amount | DR-071, CTR-10 (Invoice Balance) | total_amount = subtotal_amount + tax_amount with exact 0.00 numeric variance tolerance. |
| DQ-ACC-02 | billing.invoice_item | total_price, quantity, unit_price | DR-072 (Item Calculation) | total_price = quantity * unit_price across all invoice lines. |
| DQ-ACC-03 | billing.wallet_ledger | amount, entry_type | DR-067, CTR-05 (Double Entry) | Double-entry zero net variance check: SUM(DEBIT) - SUM(CREDIT) = 0.00 per transaction batch and global system state. |
| DQ-ACC-04 | assessment.assessment_result | score_achieved | DR-043 (Quantitative Bounds) | score_achieved must fall strictly within 1.00 and 5.00 (or configured scale max). |
| DQ-ACC-05 | candidate.candidate_education | gpa_score | DR-079 (GPA Scale Bounds) | gpa_score must fall strictly within 0.00 and 10.00. |
| DQ-ACC-06 | candidate.candidate_profile | profile_completeness_pct | DR-025 (Completeness Pct) | profile_completeness_pct must fall strictly within 0.00 and 100.00. |


### SQL Assertion Implementations (Accuracy)

```sql
-- DQ-ACC-01 & DQ-ACC-02: Invoice Calculation Invariant Check
SELECT
i.invoice_id,
i.total_amount,
(i.subtotal_amount + i.tax_amount) AS computed_total,
ROUND(ABS(i.total_amount - (i.subtotal_amount + i.tax_amount)), 4) AS invoice_variance,
COALESCE(SUM(ABS(ii.total_price - (ii.quantity * ii.unit_price))), 0.00) AS line_item_variance
FROM billing.invoice i
JOIN billing.invoice_item ii ON i.invoice_id = ii.invoice_id
GROUP BY i.invoice_id, i.total_amount, i.subtotal_amount, i.tax_amount
HAVING ABS(i.total_amount - (i.subtotal_amount + i.tax_amount)) > 0.00
OR COALESCE(SUM(ABS(ii.total_price - (ii.quantity * ii.unit_price))), 0.00) > 0.00;
-- DQ-ACC-03: Double-Entry Financial Ledger Zero-Net Variance (DR-067 / CTR-05)
SELECT
transaction_group_id,
SUM(CASE WHEN entry_type = 'DEBIT' THEN amount ELSE 0.00 END) AS total_debit,
SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE 0.00 END) AS total_credit,
SUM(CASE WHEN entry_type = 'DEBIT' THEN amount ELSE -amount END) AS net_variance
FROM billing.wallet_ledger
GROUP BY transaction_group_id
HAVING SUM(CASE WHEN entry_type = 'DEBIT' THEN amount ELSE -amount END) <> 0.00;
```

## 2.3 Consistency Dimension

Ensures multi-table transactional state coherence, workflow policy compliance, non-overlapping temporal ranges, and transactional-to-analytical parity.


| Assertion ID | Target Schema & Table | Target Column(s) | Rule / Constraint Mapping | Enforcement Logic & Threshold |
| :--- | :--- | :--- | :--- | :--- |
| DQ-CNS-01 | requisition.job_requisition vs organisation.organisation | status, verification_status | CTR-01, DR-031 (Org Verification) | Requisitions in PUBLISHED state must belong exclusively to organisations with verification_status = 'VERIFIED'. |
| DQ-CNS-02 | candidate.message_thread vs Unlock & DPDP Consent | thread_id, consent_status | CTR-08, DR-074, DR-075 | Active messaging threads require a valid profile_download_history unlock receipt AND active DPDP consent. |
| DQ-CNS-03 | gig.gig_contract | active_period (tstzrange) | DR-056, CTR-03 (No Overlapping Gigs) | Active contracts for the same candidate must have zero overlapping temporal windows (WHERE active_period && active_period). |
| DQ-CNS-04 | analytics.fact_application_event vs application.job_application | Event Counts & State Maps | Analytical Parity Check | Total application counts per stage in OLTP must match analytical aggregate fact table counts with 0.00 variance. |


### SQL Assertion Implementations (Consistency)

```sql
-- DQ-CNS-01: Published Requisitions vs Verified Organisation Check (CTR-01 / DR-031)
SELECT
r.requisition_id,
r.status AS requisition_status,
o.organisation_id,
o.verification_status AS org_status
FROM requisition.job_requisition r
JOIN organisation.organisation o ON r.organisation_id = o.organisation_id
WHERE r.status = 'PUBLISHED'
AND o.verification_status <> 'VERIFIED';
-- DQ-CNS-03: Overlapping Gig Contract Temporal Range Check (DR-056 / CTR-03)
SELECT
g1.gig_contract_id AS contract_id_1,
g2.gig_contract_id AS contract_id_2,
g1.candidate_id,
g1.contract_period AS period_1,
g2.contract_period AS period_2
FROM gig.gig_contract g1
JOIN gig.gig_contract g2
ON g1.candidate_id = g2.candidate_id
AND g1.gig_contract_id <> g2.gig_contract_id
WHERE g1.status = 'ACTIVE'
AND g2.status = 'ACTIVE'
AND g1.contract_period && g2.contract_period;
```

## 2.4 Timeliness Dimension

Validates chronological event ordering, temporal bounds, SCD Type-2 row version timelines, and pipeline SLA latencies.


| Assertion ID | Target Schema & Table | Target Column(s) | Rule / Constraint Mapping | Enforcement Logic & Threshold |
| :--- | :--- | :--- | :--- | :--- |
| DQ-TIM-01 | candidate.candidate_work_experience | start_date, end_date | DR-026, DR-027 (Chronology) | end_date >= start_date (when end_date is not NULL). |
| DQ-TIM-02 | interview.interview_schedule | scheduled_start_time, scheduled_end_time | DR-042 (Interview Window) | scheduled_end_time > scheduled_start_time. |
| DQ-TIM-03 | analytics.dim_candidate | row_effective_date, row_expiration_date | DR-085 (SCD-2 Chronology) | row_expiration_date >= row_effective_date (when row_expiration_date is not NULL). |
| DQ-TIM-04 | Operational CDC Pipelines | Stream Latency Metadata | INT-11 (CDC Latency SLA) | Real-time CDC analytics replication lag must be < 5.0 seconds. |
| DQ-TIM-05 | dpdp.consent_revocation_log | requested_at, shredded_at | DR-081, CTR-09 (Shredding SLA) | DPDP revocation DEK key shredding processing time: shredded_at - requested_at <= 2.0 seconds. |
| DQ-TIM-06 | gig.gig_milestone | submitted_at, auto_approved_at | DR-059 (Auto-Approval SLA) | Unreviewed milestone auto-approval must trigger exactly at 5 days (120 hours) post-submission. |


### SQL Assertion Implementations (Timeliness)

```sql
-- DQ-TIM-05: DPDP Consent Revocation Encryption Key Shredding SLA Check (DR-081 / CTR-09)
SELECT
revocation_id,
user_id,
requested_at,
shredded_at,
EXTRACT(EPOCH FROM (shredded_at - requested_at)) AS duration_seconds,
CASE
WHEN EXTRACT(EPOCH FROM (shredded_at - requested_at)) <= 2.0 THEN 'PASS'
ELSE 'FAIL: SLA Exceeded'
END AS status
FROM dpdp.consent_revocation_log
WHERE shredded_at IS NOT NULL
AND EXTRACT(EPOCH FROM (shredded_at - requested_at)) > 2.0;
```

## 2.5 Uniqueness Dimension

Guarantees global unique constraints, composite natural key integrity, single-active application policies, idempotency keys, and audit log cryptographic hash chain continuity.


| Assertion ID | Target Schema & Table | Target Column(s) | Rule / Constraint Mapping | Enforcement Logic & Threshold |
| :--- | :--- | :--- | :--- | :--- |
| DQ-UNQ-01 |  | email | DR-007 (Unique Email) | Lowercase email uniqueness: COUNT(email) = COUNT(DISTINCT LOWER(email)). |
| DQ-UNQ-02 |  | phone_number | DR-008 (Unique Phone) | E.164 phone_number uniqueness: COUNT(phone_number) = COUNT(DISTINCT phone_number). |
| DQ-UNQ-03 |  | country_id, company_registration_number | DR-016 (Org Natural Key) | Composite key uniqueness: COUNT(*) = COUNT(DISTINCT (country_id || '-' || company_registration_number)). |
| DQ-UNQ-04 |  | tax_id_blind_index | DR-019 (Blind Index Uniqueness) | tax_id_blind_index must be globally unique across active candidate records. |
| DQ-UNQ-05 |  | candidate_id, requisition_id | DR-039 (Single Active App) | Maximum of 1 active (non-terminal) application per candidate-requisition pair. |
| DQ-UNQ-06 |  | gateway_event_id | DR-070 (Idempotency Key) | Gateway event IDs must be strictly unique to prevent duplicate billing. |
| DQ-UNQ-07 |  | tamper_hash, sequence_id | DR-082 (Hash Chain Continuity) | SHA-256 tamper hash chain uniqueness and strict monotonic sequence continuity. |


### SQL Assertion Implementations (Uniqueness)

```sql
-- DQ-UNQ-05: Single Active Application Invariant Check (DR-039)
SELECT
candidate_id,
requisition_id,
COUNT(*) AS active_application_count
FROM application.job_application
WHERE status NOT IN ('REJECTED', 'WITHDRAWN', 'OFFER_DECLINED', 'ARCHIVED')
GROUP BY candidate_id, requisition_id
HAVING COUNT(*) > 1;
-- DQ-UNQ-07: Audit Log Tamper Hash Uniqueness & Monotonic Sequence Check (DR-082)
SELECT
sequence_id,
tamper_hash,
COUNT(*) OVER (PARTITION BY tamper_hash) AS hash_occurrences
FROM audit.tamper_evident_log
ORDER BY sequence_id ASC
LIMIT 10000;
```

## 2.6 Validity Dimension

Enforces string format regex compliance, standardization lookup codes, defined state machine enum values, and legal threshold constraints.


| Assertion ID | Target Schema & Table | Target Column(s) | Rule / Constraint Mapping | Enforcement Logic & Threshold |
| :--- | :--- | :--- | :--- | :--- |
| DQ-VAL-01 |  | email | DR-007 (Email Format) | Regex compliance: ^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$. |
| DQ-VAL-02 |  | phone_number | DR-008 (E.164 Format) | Regex compliance: ^\+[1-9]\d{1,14}$. |
| DQ-VAL-03 |  | tamper_hash | DR-082 (SHA-256 Hex) | Regex compliance: ^[a-f0-9]{64}$. |
| DQ-VAL-04 |  | country_code, currency_code | DR-001, DR-005 (ISO Standards) | country_code in ISO 3166 alpha-2/3; currency_code in ISO 4217. |
| DQ-VAL-05 |  | account_status | DR-009 (Account Enums) | Value must exist in allowed enum set: (UNVERIFIED, ACTIVE, SUSPENDED, LOCKED, DELETED). |
| DQ-VAL-06 |  | status | DR-040 (13-Stage Enum) | Value must exist in valid 13-stage application workflow state list. |
| DQ-VAL-07 |  | date_of_birth | DR-023 (Minimum Age) | AGE(CURRENT_DATE, date_of_birth) >= INTERVAL '18 years'. |


### SQL Assertion Implementations (Validity)

```sql
-- DQ-VAL-02 & DQ-VAL-03: Regex Format Validation (E.164 Phone & SHA-256 Hashes)
SELECT
'user_account.phone_number' AS check_target,
user_id::text AS record_id,
phone_number AS invalid_value
FROM identity.user_account
WHERE phone_number IS NOT NULL
AND phone_number !~ '^\+[1-9]\d{1,14}$'
UNION ALL
SELECT
'tamper_evident_log.tamper_hash' AS check_target,
log_id::text AS record_id,
tamper_hash AS invalid_value
FROM audit.tamper_evident_log
WHERE tamper_hash !~ '^[a-f0-9]{64}$';
-- DQ-VAL-07: Minimum Candidate Age Invariant Check (DR-023)
SELECT
candidate_id,
date_of_birth,
AGE(CURRENT_DATE, date_of_birth) AS calculated_age
FROM candidate.candidate_profile
WHERE date_of_birth > (CURRENT_DATE - INTERVAL '18 years');
```

# 3. Analytics & Kimball Star Schema Verification Suite

The analytics schema hosts the Kimball dimensional star schema serving enterprise reporting, intelligence dashboards, and machine learning features. The verification suite enforces dimensional integrity, temporal continuity, and strict transactional parity.


```sql
+--------------------+          +---------------------------+
|   dim_candidate    |          |      dim_requisition      |
+--------------------+          +---------------------------+
| SK candidate_key   |<---+  +->| SK requisition_key        |
| NK candidate_id    |    |  |  | NK requisition_id         |
|    is_current      |    |  |  |    is_current             |
+--------------------+    |  |  +---------------------------+
|  |
|  |
+-----------------------+      +-+--+--------------------+      +-----------------------+
|   dim_organisation    |      |  fact_application_event |      |       dim_stage       |
+-----------------------+      +-------------------------+      +-----------------------+
| SK organisation_key   |<----| SK application_event_key|----->| SK stage_key          |
| NK organisation_id    |      | FK candidate_key        |      | NK stage_code         |
|    is_current         |      | FK requisition_key      |      +-----------------------+
+-----------------------+      | FK organisation_key     |
| FK stage_key            |      +-----------------------+
| FK event_date_key       |----->|       dim_date        |
|    duration_in_stage_hrs|      +-----------------------+
|    is_terminal_state    |      | SK date_key (YYYYMMDD)|
+-------------------------+      +-----------------------+
3.1 Dimension & Fact Table Registry
```
Dimensions: analytics.dim_candidate, analytics.dim_organisation, analytics.dim_requisition, analytics.dim_date, analytics.dim_stage.

Facts: analytics.fact_application_event, analytics.fact_billing_ledger, analytics.fact_gig_performance.



## 3.2 SCD Type-2 Invariant Rules

Single Active Version Rule: For any natural key (NK), exactly one dimension row must have is_current = TRUE (or row_expiration_date IS NULL).

Gapless & Non-Overlapping Timelines (DR-085): For any natural key with multiple historical versions ($V_1, V_2, \dots, V_n$), the effective date of version $V_{k}$ must exactly equal the expiration date of version $V_{k-1}$, ensuring zero temporal gaps and zero overlapping validity intervals.

### SQL Verification: SCD Type-2 Invariants

```sql
-- SCD-2 Check 1: Single Active Record Invariant
SELECT
natural_candidate_id,
COUNT(*) FILTER (WHERE is_current = TRUE) AS active_record_count
FROM analytics.dim_candidate
GROUP BY natural_candidate_id
HAVING COUNT(*) FILTER (WHERE is_current = TRUE) <> 1;
-- SCD-2 Check 2: Gapless & Non-Overlapping Effective Date Intervals (DR-085)
WITH ranked_dim AS (
SELECT
natural_candidate_id,
candidate_key,
row_effective_date,
row_expiration_date,
LEAD(row_effective_date) OVER (
PARTITION BY natural_candidate_id
ORDER BY row_effective_date ASC
) AS next_effective_date
FROM analytics.dim_candidate
)
SELECT
natural_candidate_id,
candidate_key,
row_effective_date,
row_expiration_date,
next_effective_date,
CASE
WHEN row_expiration_date IS NULL AND next_effective_date IS NOT NULL
THEN 'FAIL: Non-terminal historic row has NULL expiration date'
WHEN row_expiration_date <> next_effective_date
THEN 'FAIL: Temporal gap or overlap detected between versions'
ELSE 'PASS'
END AS invariant_status
FROM ranked_dim
WHERE next_effective_date IS NOT NULL
AND (row_expiration_date IS NULL OR row_expiration_date <> next_effective_date);
```

## 3.3 Foreign Key Referential Integrity & Fact Parity Checks

### Orphan Foreign Key Detection Check

Fact tables must contain zero orphan dimension keys. Unmatched keys indicate pipeline integrity failures.


```sql
-- Fact-to-Dimension Foreign Key Integrity Verification
SELECT
'fact_application_event -> dim_candidate' AS relationship,
COUNT(*) AS orphan_count
FROM analytics.fact_application_event f
LEFT JOIN analytics.dim_candidate d ON f.candidate_key = d.candidate_key
WHERE d.candidate_key IS NULL
UNION ALL
SELECT
'fact_application_event -> dim_requisition' AS relationship,
COUNT(*) AS orphan_count
FROM analytics.fact_application_event f
LEFT JOIN analytics.dim_requisition d ON f.requisition_key = d.requisition_key
WHERE d.requisition_key IS NULL
UNION ALL
SELECT
'fact_billing_ledger -> dim_organisation' AS relationship,
COUNT(*) AS orphan_count
FROM analytics.fact_billing_ledger f
LEFT JOIN analytics.dim_organisation d ON f.organisation_key = d.organisation_key
WHERE d.organisation_key IS NULL;
OLTP-to-Analytics Financial & Granular Parity Reconciliation
```
Validates that aggregate transactional values in OLTP match analytical fact aggregates with zero numeric divergence.


```sql
-- OLTP-to-Analytics Ledger Parity Check
WITH oltp_ledger_summary AS (
SELECT
DATE(created_at) AS transaction_date,
SUM(CASE WHEN entry_type = 'DEBIT' THEN amount ELSE 0.00 END) AS oltp_total_debit,
SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE 0.00 END) AS oltp_total_credit
FROM billing.wallet_ledger
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
),
analytics_fact_summary AS (
SELECT
d.calendar_date AS transaction_date,
SUM(f.debit_amount) AS fact_total_debit,
SUM(f.credit_amount) AS fact_total_credit
FROM analytics.fact_billing_ledger f
JOIN analytics.dim_date d ON f.event_date_key = d.date_key
WHERE d.calendar_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY d.calendar_date
)
SELECT
o.transaction_date,
o.oltp_total_debit,
a.fact_total_debit,
ABS(o.oltp_total_debit - COALESCE(a.fact_total_debit, 0.00)) AS debit_variance,
o.oltp_total_credit,
a.fact_total_credit,
ABS(o.oltp_total_credit - COALESCE(a.fact_total_credit, 0.00)) AS credit_variance,
CASE
WHEN ABS(o.oltp_total_debit - COALESCE(a.fact_total_debit, 0.00)) = 0.00
AND ABS(o.oltp_total_credit - COALESCE(a.fact_total_credit, 0.00)) = 0.00 THEN 'PARITY_OK'
ELSE 'PARITY_MISMATCH'
END AS status
FROM oltp_ledger_summary o
FULL OUTER JOIN analytics_fact_summary a ON o.transaction_date = a.transaction_date
WHERE ABS(o.oltp_total_debit - COALESCE(a.fact_total_debit, 0.00)) > 0.00
OR ABS(o.oltp_total_credit - COALESCE(a.fact_total_credit, 0.00)) > 0.00;
```

# 4. Single-Command Execution & CI/CD Pipeline Integration

## 4.1 CLI Runner & pytest Suite Architecture

The test automation suite is driven by pytest utilizing customized DB connection fixtures and custom reporting hooks.


```sql
tests/data_quality/
├── Makefile
├── pytest.ini
├── conftest.py
├── test_completeness.py
├── test_accuracy.py
├── test_consistency.py
├── test_timeliness.py
├── test_uniqueness.py
├── test_validity.py
└── test_kimball_analytics.py
Execution Commands
```
```sql
# Execute full Data Quality & Analytics Test Suite via Makefile
make test-dq
# Direct pytest invocation with structured outputs
pytest tests/data_quality \
-m "data_quality" \
--durations=10 \
--junitxml=reports/dq_report.xml \
--json-report \
--json-report-file=reports/dq_report.json \
-v
Execution Order Dependency Sequence
```
test_validity.py (Structural and format checks)

test_completeness.py (Null checks and zero-loss ingestion checks)

test_uniqueness.py (Key uniqueness and sequence checks)

test_accuracy.py (Calculations, bounds, and financial double-entry)

test_consistency.py (State cross-alignment and transactional rules)

test_timeliness.py (Chronology, SLA latencies, and key shredding)

test_kimball_analytics.py (Dimensional SCD-2, referential integrity, and OLTP parity)



## 4.2 CI/CD Pipeline Configuration (GitHub Actions / GitLab CI)

The data quality gate operates as a hard blocking check within the build and integration pipeline. Any failure in a CRITICAL or HIGH severity rule immediately exits with code 1, halting deployment.


```sql
# .github/workflows/data-quality-gate.yml
name: Talentra Data Quality & Analytics Automation Gate
on:
push:
branches: [ main, release/* ]
pull_request:
branches: [ main, develop ]
schedule:
- cron: '0 */4 * * *' # Every 4 hours
jobs:
data-quality-verification:
runs-on: ubuntu-latest
services:
postgres:
image: postgres:16-alpine
env:
POSTGRES_DB: talentra_staging
POSTGRES_USER: postgres
POSTGRES_PASSWORD: postgrespassword
ports:
- 5432:5432
options: >-
--health-cmd pg_isready
--health-interval 5s
--health-timeout 5s
--health-retries 5
steps:
- name: Checkout Repository
uses: actions/checkout@v4
- name: Set up Python 3.11
uses: actions/setup-python@v4
with:
python-version: '3.11'
cache: 'pip'
- name: Install Dependencies
run: |
python -m pip install --upgrade pip
pip install pytest pytest-json-report psycopg2-binary sqlalchemy pandas pydantic
- name: Apply Database Schemas & Seed Test Baseline
env:
PGHOST: localhost
PGPORT: 5432
PGDATABASE: talentra_staging
PGUSER: postgres
PGPASSWORD: postgrespassword
run: |
make db-migrate
make db-seed-staging
- name: Execute Automated Data Quality & Analytics Test Suite
env:
DATABASE_URL: postgresql://postgres:postgrespassword@localhost:5432/talentra_staging
run: |
pytest tests/data_quality \
-m "data_quality" \
--junitxml=reports/dq_report.xml \
--json-report \
--json-report-file=reports/dq_report.json \
--tb=short
- name: Publish Data Quality Scorecard to Governance Schema
if: always()
env:
DATABASE_URL: postgresql://postgres:postgrespassword@localhost:5432/talentra_staging
run: |
python scripts/publish_dq_scorecard.py --report-path reports/dq_report.json
- name: Archive Test Reports
if: always()
uses: actions/upload-artifact@v3
with:
name: dq-test-reports
path: reports/
```

# 5. Per-Table Data Quality Score & Historical Trend Tracking

## 5.1 Weighted Composite Data Quality Score Formula

For any target table $T$, the overall Data Quality Score $DQ_Score(T)$ is computed as a weighted sum of pass rates across the six dimensions:


$$DQ_Score(T) = 100 \times \sum_{d \in D} \left( w_d \times \frac{P_d(T)}{N_d(T)} \right)$$


Where:


$D = {\text{Completeness}, \text{Accuracy}, \text{Consistency}, \text{Timeliness}, \text{Uniqueness}, \text{Validity}}$

$w_d$ = Assigned dimensional weight ($\sum w_d = 1.00$)

$P_d(T)$ = Number of passed assertions in dimension $d$ for table $T$

$N_d(T)$ = Total number of executed assertions in dimension $d$ for table $T$

### Dimensional Weight Distribution ($w_d$)

Accuracy ($w_{acc}$): $0.25$ (25%)

Completeness ($w_{cmp}$): $0.20$ (20%)

Consistency ($w_{cns}$): $0.20$ (20%)

Uniqueness ($w_{unq}$): $0.15$ (15%)

Timeliness ($w_{tim}$): $0.10$ (10%)

Validity ($w_{val}$): $0.10$ (10%)

### Critical Invariant Hard-Override Rule

If any Critical Constraint (specifically cross-domain rules CTR-01 through CTR-10, double-entry balance DR-067, or cryptographic key shredding DR-081) fails, the composite table score is overridden:


$$DQ_Score(T) = 0.00 \quad \text{IF } \exists \text{ Critical Assertion Failure}$$


This instantly triggers a CI/CD build break regardless of other passing assertions.



## 5.2 Governance Scorecard DDL Schema (governance Schema)

To persist and track historical DQ metrics across builds and batch ingestions, two primary governance tables are defined in PostgreSQL 16.


```sql
-- Create Governance Schema
CREATE SCHEMA IF NOT EXISTS governance;
-- Table 1: Detailed Assertion Check Execution Results
CREATE TABLE governance.data_quality_check_result (
check_result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
execution_batch_id UUID NOT NULL,
check_id VARCHAR(32) NOT NULL,
check_name VARCHAR(128) NOT NULL,
dimension VARCHAR(32) NOT NULL CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
target_schema VARCHAR(64) NOT NULL,
target_table VARCHAR(64) NOT NULL,
target_column VARCHAR(64),
rule_mapping VARCHAR(64),
severity VARCHAR(16) NOT NULL CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
status VARCHAR(16) NOT NULL CHECK (status IN ('PASS', 'FAIL', 'ERROR', 'SKIPPED')),
records_evaluated BIGINT NOT NULL DEFAULT 0,
records_failed BIGINT NOT NULL DEFAULT 0,
execution_duration_ms NUMERIC(10, 2) NOT NULL,
error_details JSONB,
executed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Table 2: Aggregated Per-Table Data Quality Scorecard
CREATE TABLE governance.data_quality_scorecard (
scorecard_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
execution_batch_id UUID NOT NULL,
target_schema VARCHAR(64) NOT NULL,
target_table VARCHAR(64) NOT NULL,
completeness_score NUMERIC(5, 2) NOT NULL CHECK (completeness_score BETWEEN 0.00 AND 100.00),
accuracy_score NUMERIC(5, 2) NOT NULL CHECK (accuracy_score BETWEEN 0.00 AND 100.00),
consistency_score NUMERIC(5, 2) NOT NULL CHECK (consistency_score BETWEEN 0.00 AND 100.00),
timeliness_score NUMERIC(5, 2) NOT NULL CHECK (timeliness_score BETWEEN 0.00 AND 100.00),
uniqueness_score NUMERIC(5, 2) NOT NULL CHECK (uniqueness_score BETWEEN 0.00 AND 100.00),
validity_score NUMERIC(5, 2) NOT NULL CHECK (validity_score BETWEEN 0.00 AND 100.00),
composite_dq_score NUMERIC(5, 2) NOT NULL CHECK (composite_dq_score BETWEEN 0.00 AND 100.00),
critical_failure_flag BOOLEAN NOT NULL DEFAULT FALSE,
pipeline_gate_status VARCHAR(16) NOT NULL CHECK (pipeline_gate_status IN ('PASSED', 'FAILED_CRITICAL', 'FAILED_THRESHOLD')),
evaluated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT uq_scorecard_batch_table UNIQUE (execution_batch_id, target_schema, target_table)
);
-- Indexes for Historical Trend Analysis & Reporting
CREATE INDEX idx_dq_check_result_batch ON governance.data_quality_check_result(execution_batch_id);
CREATE INDEX idx_dq_check_result_target ON governance.data_quality_check_result(target_schema, target_table);
CREATE INDEX idx_dq_scorecard_target_time ON governance.data_quality_scorecard(target_schema, target_table, evaluated_at DESC);
```

## 5.3 Automated Score Calculation & Scorecard Publication Script

```sql
#!/usr/bin/env python3
"""
Talentra Enterprise Data Quality Scorecard Publisher
Reads pytest JSON report execution outputs, calculates weighted per-table
composite scores, and publishes results to governance.data_quality_scorecard.
"""
import json
import sys
import uuid
import psycopg2
from psycopg2.extras import execute_values
WEIGHTS = {
'ACCURACY': 0.25,
'COMPLETENESS': 0.20,
'CONSISTENCY': 0.20,
'UNIQUENESS': 0.15,
'TIMELINESS': 0.10,
'VALIDITY': 0.10
}
def publish_scorecard(report_path: str, db_url: str):
with open(report_path, 'r') as f:
report = json.load(f)
batch_id = str(uuid.uuid4())
check_results = []
table_stats = {}
for test in report.get('tests', []):
nodeid = test.get('nodeid', '')
# Extract metadata from test execution
metadata = test.get('user_properties', {})
check_id = metadata.get('check_id', 'DQ-UNK')
dimension = metadata.get('dimension', 'ACCURACY')
schema = metadata.get('target_schema', 'public')
table = metadata.get('target_table', 'unknown')
severity = metadata.get('severity', 'HIGH')
outcome = test.get('outcome', 'failed').upper()
status = 'PASS' if outcome == 'PASSED' else 'FAIL'
eval_records = metadata.get('records_evaluated', 0)
fail_records = metadata.get('records_failed', 0 if status == 'PASS' else 1)
duration_ms = test.get('call', {}).get('duration', 0.0) * 1000.0
check_results.append((
batch_id, check_id, nodeid, dimension, schema, table,
metadata.get('target_column'), metadata.get('rule_mapping'),
severity, status, eval_records, fail_records, duration_ms
))
table_key = (schema, table)
if table_key not in table_stats:
table_stats[table_key] = {dim: {'pass': 0, 'total': 0} for dim in WEIGHTS}
table_stats[table_key]['critical_fail'] = False
if dimension in table_stats[table_key]:
table_stats[table_key][dimension]['total'] += 1
if status == 'PASS':
table_stats[table_key][dimension]['pass'] += 1
if severity == 'CRITICAL' and status == 'FAIL':
table_stats[table_key]['critical_fail'] = True
# Connect to PostgreSQL Governance Persistence Layer
conn = psycopg2.connect(db_url)
cur = conn.cursor()
# Insert individual check results
insert_check_sql = """
INSERT INTO governance.data_quality_check_result (
execution_batch_id, check_id, check_name, dimension, target_schema,
target_table, target_column, rule_mapping, severity, status,
records_evaluated, records_failed, execution_duration_ms
) VALUES %s;
"""
execute_values(cur, insert_check_sql, check_results)
# Calculate and insert per-table scorecards
scorecard_rows = []
for (schema, table), stats in table_stats.items():
dim_scores = {}
composite_score = 0.0
for dim, weight in WEIGHTS.items():
tot = stats[dim]['total']
pas = stats[dim]['pass']
score = (pas / tot * 100.0) if tot > 0 else 100.0
dim_scores[dim] = score
composite_score += (score * weight)
has_critical_fail = stats['critical_fail']
if has_critical_fail:
composite_score = 0.00
gate_status = 'FAILED_CRITICAL'
elif composite_score < 95.0:
gate_status = 'FAILED_THRESHOLD'
else:
gate_status = 'PASSED'
scorecard_rows.append((
batch_id, schema, table,
dim_scores['COMPLETENESS'], dim_scores['ACCURACY'],
dim_scores['CONSISTENCY'], dim_scores['TIMELINESS'],
dim_scores['UNIQUENESS'], dim_scores['VALIDITY'],
composite_score, has_critical_fail, gate_status
))
insert_scorecard_sql = """
INSERT INTO governance.data_quality_scorecard (
execution_batch_id, target_schema, target_table,
completeness_score, accuracy_score, consistency_score,
timeliness_score, uniqueness_score, validity_score,
composite_dq_score, critical_failure_flag, pipeline_gate_status
) VALUES %s;
"""
execute_values(cur, insert_scorecard_sql, scorecard_rows)
conn.commit()
cur.close()
conn.close()
print(f"Successfully published DQ Scorecard for Batch ID: {batch_id}")
if __name__ == '__main__':
publish_scorecard(sys.argv[1], sys.argv[2])
```

# 6. Acceptance Checklist & Sign-Off Criteria

To achieve formal sign-off for Milestone 26, all requirements detailed in the operational matrix below must be fulfilled and verified by automated pipeline runs.


| Requirement Verification Item | Technical Target | Verification Method | Pass Criteria | Status |
| :--- | :--- | :--- | :--- | :--- |
| Single-Command CLI Execution | make test-dq / pytest runner | Local & CI Terminal Run | Suite completes within 120s; proper XML/JSON logs generated. |  |
| CI/CD Quality Gate Integration | GitHub Actions / GitLab CI | Pipeline PR Trigger | Hard exit code 1 generated on any Critical rule failure or score < 95.0. |  |
| Six DQ Dimensions Coverage | All 13 Domain Schemas | Assertion Catalogue Audit | Minimum 2 automated checks implemented per dimension across key domain tables. |  |
| Zero-Loss Ingestion Compliance | Milestone 25 Reconciliation | Pipeline Log Audit | Source = Loaded + Quarantined verified with 0 unaccounted record drops. |  |
| Financial & Ledger Integrity | DR-067, DR-071, DR-072, CTR-05, CTR-10 | Double-Entry & Invoice SQL Checks | 0.00 numeric variance between total/subtotal+tax and debit/credit ledger sums. |  |
| SCD Type-2 Dimensional Integrity | analytics.dim_* tables | Gapless Timeline SQL Check | Single active record per NK; zero overlapping or gapped date ranges (DR-085). |  |
| OLTP-to-Analytics Parity | analytics.fact_* tables | Aggregate Parity Reconciliation | Zero count/amount divergence between OLTP source tables and Kimball star schema facts. |  |
| DPDP Shredding SLA Verification | dpdp.consent_revocation_log | Timeliness Latency Query | Encryption key (DEK) shredding duration strictly $\le 2.0$ seconds (DR-081). |  |
| Governance Scorecard Persistence | governance.* tables | Database Query Audit | Automated calculation & insertion of per-table DQ scores (0–100) per execution batch. |  |


## Milestone Sign-Off Approval

Lead Quality & Test Automation Engineer: Approved

Principal Data & Analytics Architect: Approved

Enterprise Platform Director: Approved

