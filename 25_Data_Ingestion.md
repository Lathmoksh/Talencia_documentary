Milestone 25 — Data Ingestion Specification

# 1. Header Metadata & Executive Summary

Milestone: 25 — Data Ingestion

Phase: 4 — Build & Integrate (following Milestone 21 Physical Model, Milestone 22 Integration & Source Mapping, Milestone 23 Scale Generation, and Milestone 24 Data Seeding)

Platform: Talentra Enterprise Workforce & Talent Demand Management Platform

Target Engine: PostgreSQL 16 (Staging-Validate-Transform-Load Architecture, Transactional Checkpoints, Quarantine/DLQ Tables, Idempotent Upserts, Zero-Loss Count Reconciliation)

Outputs: Zero-Loss Validate-Transform-Load (VTL) Ingestion Pipeline Architecture, Quarantine & Rejection Reason Taxonomy, Automated Batch & Stream Reconciliation Report Engine, Re-Runnable Late & Corrected Record Resolution Protocol.

## Purpose & Exit Criteria

Milestone 25 establishes the production data ingestion framework for the Talentra Enterprise platform. Aligned directly with the PostgreSQL 16 baseline and the 13 domain schemas established in earlier architectural milestones, this specification governs how data flows into Talentra across batch feeds (INT-01 to INT-11) and real-time streaming webhooks.


The ingestion pipeline shifts traditional ETL paradigms to a Validate-Transform-Load (VTL) architecture. By enforcing syntactic, domain (DR-001 through DR-085), and cross-table (CTR-01 through CTR-10) validation prior to state modification, the engine guarantees complete zero-loss operational integrity.


The exit criteria ("Done When") for Milestone 25 are explicitly defined as:


Zero-Loss Data Preservation: Data is ingested across all 11 external integrations without dropping or silently altering a record.

Invariant Compliance: The mathematical accounting invariant Source_Count = Loaded_Count + Quarantined_Count holds at 100.00% precision across every batch run and streaming window.

Structured Rejection Handling: Every quarantined row is isolated in governance.ingestion_quarantine or governance.integration_dlq with a structured rejection reason code, diagnostic payload, and direct lineage to domain rules (DR/CTR).

Idempotent Re-Runnability: Every pipeline stage is re-runnable. Duplicate executions produce identical target states without duplicating records, breaking key constraints, or corrupting audit trails.

Late & Corrected Record Resolution: Late-arriving child records, out-of-order events, and upstream source corrections are processed deterministically via watermarks, transient staging, and SCD Type-2/Type-1 mechanics.



# 2. Zero-Loss Validate-Transform-Load (VTL) Pipeline Architecture

The VTL architecture executes in five deterministic stages to enforce zero-loss data handling. Raw data is captured, isolated, validated, cryptographically processed, and committed to target schemas in topological foreign-key order.


```sql
+-----------------------------------------------------------------------------------+
| STAGE 1: IMMUTABLE LANDING & MANIFEST REGISTRATION                                |
|---|
| - Register Batch in governance.ingestion_batch_run (Status: LANDED)               |
+-----------------------------------------------------------------------------------+
|
v
+-----------------------------------------------------------------------------------+
| STAGE 2: RAW STAGING ISOLATION                                                    |
| - Bulk Insert raw untyped strings/JSONB to staging.<domain>_raw                   |
| - Assign monotonic row_seq_num & compute raw_payload_hash                         |
+-----------------------------------------------------------------------------------+
|
v
+-----------------------------------------------------------------------------------+
| STAGE 3: DETERMINISTIC VALIDATION GATE                                            |
| - Syntax & Type Checks | Domain Rules (DR-001..085) | Cross-Table (CTR-01..10)    |
+-----------------------------------------------------------------------------------+
|                                           |
[ VALID RECORDS PASS ]                      [ INVALID RECORDS FAIL ]
|                                           |
v                                           v
+----------------------------------+        +---------------------------------------+
| STAGE 4: CANONICAL TRANSFORM     |        | STAGE 3B: QUARANTINE & DLQ ISOLATION  |
| & CRYPTOGRAPHIC HARDENING        |        | Write raw payload & error code to     |
| - E.164, Lowercase Trim, ISO 3166|        | governance.ingestion_quarantine       |
| - HMAC-SHA256 & AES-256-GCM      |        | and governance.integration_dlq        |
+----------------------------------+        +---------------------------------------+
|                                           |
v                                           v
+-----------------------------------------------------------------------------------+
| STAGE 5: IDEMPOTENT TARGET LOAD & ATOMIC RECONCILIATION COMMIT                    |
| - Upsert to Target Schema via Topological FK Order                                |
| - Evaluate Accounting Invariant: Source_Rows = Loaded_Rows + Quarantined_Rows     |
| - Commit Batch: Update status to RECONCILED (or HALTED_RECONCILIATION_MISMATCH)   |
+-----------------------------------------------------------------------------------+
Stage 1: Immutable Landing & Manifest Registration
```
The ingestion service intercepts incoming files or stream chunks. Prior to standard parsing, the service:


Calculates the cryptographic SHA-256 checksum of the source artifact.

Extracts or counts declared source records (source_row_count).

Determines high/low watermarks (source_watermark_start, source_watermark_end).

Inserts an execution row into governance.ingestion_batch_run with batch_status = 'LANDED'. If the SHA-256 checksum has already completed successfully, execution terminates immediately in an idempotent no-op state.

## Stage 2: Raw Staging Isolation

Data is streamed directly into unlogged, schema-isolated staging tables (staging.<domain>_raw).


All fields are ingested as untyped TEXT or raw JSONB structures.

No type casting, string trimming, or structural constraints are applied during Stage 2, eliminating row drop risks during raw load.

Every record is assigned a monotonic row_seq_num and a raw_payload_hash (SHA-256 of the unparsed line/object).

## Stage 3: Deterministic Validation Gate

A batch validation processor evaluates every row in staging.<domain>_raw against three distinct validation layers:


Syntax & Structural Validation: Verifies JSON parsing, string lengths, numeric formats, and mandatory null checks.

Domain Validation Rules (DR-001 to DR-085): Verifies domain-specific logic including lowercase email format (DR-007), E.164 phone format (DR-008), candidate age bounds (DR-023: minimum 18 years), salary range constraints (DR-032), and academic CGPA scale limits (DR-079: 0.00–10.00).

Cross-Table Rules (CTR-01 to CTR-10): Validates relational preconditions, such as verified organizational status (CTR-01) and temporal non-overlap via PostgreSQL GiST constraints (CTR-03).


Rows meeting all criteria are staged in staging.<domain>_clean. Rows failing any check bypass target insertion entirely and are written to governance.ingestion_quarantine with exact error codes, diagnostic attributes, and failed field pointers.

## Stage 4: Canonical Transformation & Cryptographic Hardening

Valid records in staging.<domain>_clean undergo standard normalization and cryptographic processing:


String Standardization: Lowercase trimming for email addresses and identifiers; whitespace normalization across free-text fields.

Code & Currency Mapping: Mapping country codes to ISO 3166-1 alpha-2, currency codes to ISO 4217, and scaling monetary values from minor fractional units to major ledger decimals.

Phone Standardization: Transformation to strict E.164 format.

Security & Privacy Hardening: Generating deterministic HMAC-SHA256 blind indexes for searchable PII fields and applying authenticated AES-256-GCM encryption using Data Encryption Keys (DEKs) for sensitive attributes (e.g., identity numbers, raw compensation values).

## Stage 5: Idempotent Target Load & Atomic Reconciliation Commit

Transformed records are loaded into target production schemas (identity, organization, talent, contract, finance, analytics) inside an explicit database transaction:


Topological Order: Writes execute in explicit foreign-key dependency order (e.g., organization.tenants -> identity.users -> talent.profiles -> contract.engagements).

Idempotent Upserts: Insert operations leverage ON CONFLICT (natural_key) DO UPDATE or DO NOTHING clauses guided by source_event_timestamp versioning.

Reconciliation Assertion: The engine counts target INSERT, UPDATE, and NOOP_SKIPPED rows, combining them into Loaded_Count. It queries Quarantined_Count for the current batch_run_id and checks the primary invariant:


$$\text{Source_Rows_Read} = \text{Loaded_Count} + \text{Quarantined_Count}$$


If the invariant matches, governance.ingestion_batch_run updates to RECONCILED and the transaction commits. If a discrepancy exists ($\Delta \neq 0$), the entire database transaction rolls back, and the batch transitions to HALTED_RECONCILIATION_MISMATCH.



# 3. Quarantine Storage Design & Rejection Reason Taxonomy

To guarantee zero silent data loss, non-compliant records are diverted into dedicated quarantine and dead-letter queue structures without disrupting valid record processing.

## Physical Database Schema Definition

l
-- Batch Run Execution & Manifest Tracking
CREATE TABLE governance.ingestion_batch_run (
batch_run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
integration_id VARCHAR(16) NOT NULL, -- Mapped to INT-01 through INT-11
source_system_name VARCHAR(64) NOT NULL,
file_name VARCHAR(256),
file_sha256 CHAR(64) NOT NULL,
source_row_count BIGINT NOT NULL,
loaded_row_count BIGINT DEFAULT 0,
quarantined_row_count BIGINT DEFAULT 0,
source_watermark_start TIMESTAMPTZ,
source_watermark_end TIMESTAMPTZ,
batch_status VARCHAR(32) NOT NULL DEFAULT 'LANDED',
started_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
completed_at TIMESTAMPTZ,
error_summary TEXT,
CONSTRAINT chk_batch_status CHECK (
batch_status IN (
'LANDED', 'STAGED', 'VALIDATED', 'TRANSFORMED',
'RECONCILED', 'HALTED_RECONCILIATION_MISMATCH', 'FAILED_FATAL'
)
)
);


CREATE INDEX idx_ingestion_batch_sha256 ON governance.ingestion_batch_run(file_sha256);
CREATE INDEX idx_ingestion_batch_status ON governance.ingestion_batch_run(batch_status);


-- Physical Quarantine Table for Isolated Bad Records
CREATE TABLE governance.ingestion_quarantine (
quarantine_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
batch_run_id UUID NOT NULL REFERENCES governance.ingestion_batch_run(batch_run_id) ON DELETE CASCADE,
integration_id VARCHAR(16) NOT NULL,
source_record_key VARCHAR(256),
source_row_number BIGINT NOT NULL,
raw_payload JSONB NOT NULL,
rejection_category VARCHAR(64) NOT NULL,
rejection_reason_code VARCHAR(64) NOT NULL,
linked_rule_id VARCHAR(32) NOT NULL, -- DR-### or CTR-##
diagnostic_detail JSONB NOT NULL,
quarantine_status VARCHAR(32) NOT NULL DEFAULT 'QUARANTINED',
quarantined_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
resolved_at TIMESTAMPTZ,
resolved_by_user_id UUID,
resolution_notes TEXT,
CONSTRAINT chk_quarantine_status CHECK (
quarantine_status IN ('QUARANTINED', 'CORRECTED_REPLAYED', 'DISMISSED_APPROVED')
)
);


CREATE INDEX idx_quarantine_batch_run ON governance.ingestion_quarantine(batch_run_id);
CREATE INDEX idx_quarantine_rule ON governance.ingestion_quarantine(linked_rule_id);
CREATE INDEX idx_quarantine_status ON governance.ingestion_quarantine(quarantine_status);
CREATE INDEX idx_quarantine_record_key ON governance.ingestion_quarantine(integration_id, source_record_key);


```sql
### Rejection Reason Taxonomy Table
The taxonomy standardizes pipeline validation failures. Every failure is assigned a specific severity level, mapped to underlying system rules, and routed through automated or manual remediation protocols.
| Rejection Reason Code | Category | Severity | Linked DR / CTR Rules | Description & Diagnostic Criteria | Remediation Strategy | Resolution SLA |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `ERR_SYNTAX_PARSE` | Syntax | FATAL | Standard Spec | Row payload cannot be parsed as CSV, JSON, or XML. | Manual: Correct source file format or stream payload. | 4 Hours |
| `ERR_MISSING_REQUIRED` | Domain | HIGH | DR-001, DR-011 | Mandatory attribute (e.g., user primary key, email, legal name) is NULL or whitespace. | Manual: Request source field populate or operational override. | 8 Hours |
| `ERR_INVALID_ENUM_ISO` | Domain | MEDIUM | DR-004, DR-015 | Attribute contains an unmapped state, invalid ISO 3166 country code, or invalid ISO 4217 currency. | Automated: Fallback to lookup dictionary; missing codes trigger manual review. | 24 Hours |
| `ERR_RANGE_BOUND_DR` | Domain | HIGH | DR-023, DR-032, DR-079 | Value violates domain boundaries (e.g., Candidate age < 18, negative salary band, CGPA outside 0.00–10.00). | Manual: Source system operator must verify and issue corrected update. | 12 Hours |
| `ERR_FORMAT_EMAIL_PHONE` | Domain | MEDIUM | DR-007, DR-008 | Email fails RFC 5322 regex validation; phone number fails E.164 parsing. | Automated regex cleanup attempt; if invalid, route to Manual review. | 24 Hours |
| `ERR_ORPHAN_FK_LOOKUP` | Relational | HIGH | CTR-01, CTR-04 | Foreign key reference (e.g., tenant_id, organization_id, candidate_id) does not exist in target. | Automated retry after 15-min parent grace window; escalate to Manual if parent missing. | 2 Hours |
| `ERR_CTR_PRECONDITION` | Relational | HIGH | CTR-01, CTR-02, CTR-06 | Business precondition failed (e.g., Tenant organization state is not 'ACTIVE' or contract state invalid). | Manual: Tenant admin must activate parent entity. | 4 Hours |
| `ERR_GIST_OVERLAP_CONFLICT` | Temporal | CRITICAL | CTR-03 | Temporal assignment or rate card overlaps existing record within effective daterange via GiST constraint. | Manual: Adjust effective timestamps to eliminate overlap window. | 4 Hours |
| `ERR_STALE_EVENT_VERSION` | Idempotency | LOW | Standard Spec | Incoming record timestamp is older than currently persisted target `source_event_timestamp`. | Automated: Log as duplicate/stale state; flag as DISMISSED_APPROVED. | Immediate |
| `ERR_DPDP_CONSENT_MISSING` | Compliance | CRITICAL | DR-081 | PII ingestion attempted for candidate/employee without valid DPDP consent record on file. | Manual: Legal/HR team must confirm consent or purge record. | 2 Hours |
---
## 4. Mathematical Reconciliation Invariant & Automated Reconciliation Report
The pipeline enforces strict zero-loss operational state via mathematical verification routines executed at the end of each ingestion run.
### Formal Accounting Equations
#### 1. Primary Batch Invariant
For every batch or stream window, total source rows read must equal the sum of loaded rows and isolated quarantined rows:
$$\text{Source\_Rows\_Read} = \text{New\_Rows\_Inserted} + \text{Existing\_Rows\_Updated} + \text{Unchanged\_Rows\_Skipped} + \text{Quarantined\_Rows\_Isolated}$$
Where:
$$\text{Loaded\_Count} = \text{New\_Rows\_Inserted} + \text{Existing\_Rows\_Updated} + \text{Unchanged\_Rows\_Skipped}$$
$$\text{Source\_Rows\_Read} = \text{Loaded\_Count} + \text{Quarantined\_Rows\_Isolated}$$
$$\text{Unexplained\_Loss\_Delta} = \text{Source\_Rows\_Read} - (\text{Loaded\_Count} + \text{Quarantined\_Rows\_Isolated}) = 0.00$$
#### 2. Financial & Ledger Sub-Invariant
For monetary ingestion (e.g., Billing INT-04, Payment Escrow INT-05), absolute value monetary totals must balance across target balance and quarantine totals:
$$\sum \text{Monetary}_{\text{Source}} = \sum \text{Monetary}_{\text{Target\_Loaded}} + \sum \text{Monetary}_{\text{Quarantined}}$$
$$\text{Financial\_Drift\_Delta} = \left| \sum \text{Monetary}_{\text{Source}} - \left( \sum \text{Monetary}_{\text{Target\_Loaded}} + \sum \text{Monetary}_{\text{Quarantined}} \right) \right| = 0.0000$$
### Structured Ingestion Reconciliation Report Template
```
========================================================================================
TALENTRA ENTERPRISE DATA INGESTION RECONCILIATION REPORT

Batch Run ID           : 9f8c7b6a-5e4d-3c2b-1a0f-9e8d7c6b5a4f
Integration ID         : INT-01 (HRIS Employee Master Sync)
Source System          : Workday Enterprise HRIS
File Name / Stream ID  : hris_emp_delta_20260330_060000.csv
SHA-256 Digest         : e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
Execution Window       : 2026-03-30T06:00:00Z to 2026-03-30T06:02:14Z
Pipeline Execution Status: RECONCILED

SOURCE VS TARGET COUNT BREAKDOWN



# Metric Name                                       Row Count              Percentage

Source Rows Read (Declared / Extracted)          125,000                 100.0000%


New Target Rows Inserted                       98,420                  78.7360%

Existing Target Rows Updated                   22,150                  17.7200%

Unchanged Target Rows (Idempotent No-Op)        3,930                   3.1440%
TOTAL LOADED COUNT                               124,500                  99.6000%


Quarantined Rows Isolated                            500                   0.4000%
TOTAL ACCOUNTED COUNT (Loaded + Quarantined)     125,000                 100.0000%
UNEXPLAINED LOSS DELTA                                 0                   0.0000%


QUARANTINE BREAKDOWN BY REJECTION CODE & DOMAIN RULE



# Reason Code             Rule ID    Category    Count   % Batch   Remediation Path

# ERR_FORMAT_EMAIL_PHONE  DR-007     Domain        210   0.1680%   Auto-Regex / Manual HR
ERR_RANGE_BOUND_DR      DR-023     Domain        145   0.1160%   Manual Source Update
ERR_ORPHAN_FK_LOOKUP    CTR-01     Relational    115   0.0920%   Grace Window / Manual
ERR_DPDP_CONSENT_MISS   DR-081     Compliance     30   0.0240%   Legal Manual Opt-In

TOTAL QUARANTINED ISOLATED                       500   0.4000%


LATE & CORRECTED RECORD DISPOSITION SUMMARY



# Category                                          Row Count   Disposition State

Late-Arriving Parent Dependencies Resolved              85   Promoted from Quarantine
SCD Type-2 Active Dimension Rows Closed (DR-085)     1,420   Historical Version Expired
SCD Type-2 New Dimension Versions Opened (DR-085)    1,420   Current Version Active
Replayed Quarantine Records Processed                  115   Marked CORRECTED_REPLAYED


MONETARY & LEDGER RECONCILIATION SUMMARY (INT-04 / INT-05)



# Ledger Category                Source Amount (USD)   Loaded + Quarantined (USD)   Delta

Total Processing Value          $14,250,800.00        $14,250,800.00              $0.00


Target Accounts Loaded      $14,198,300.00        $14,198,300.00              $0.00

Isolated in Quarantine           $52,500.00            $52,500.00              $0.00




FINANCIAL BALANCE VERDICT       BALANCED (0.0000 Drift)

# ========================================================================================
5. AUTOMATED GATE VERDICT: [ PASS ]

Invariant Equation Verification: 125,000 (Source) == 124,500 (Loaded) + 500 (Quarantine)
Database Transaction Status    : COMMITTED
Report Signed Off By Automation Engine at 2026-03-30T06:02:14.812Z

```sql
### PostgreSQL Verification Procedure
The following stored procedure verifies the mathematical invariant prior to batch completion. If a mismatch occurs, it logs the error and raises an exception to force a transaction rollback.
```sql
CREATE OR REPLACE PROCEDURE governance.sp_verify_and_commit_ingestion_batch(
p_batch_run_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
v_source_count BIGINT;
v_loaded_count BIGINT;
v_quarantined_count BIGINT;
v_calculated_total BIGINT;
v_delta BIGINT;
BEGIN
-- 1. Fetch official counts from the batch record
SELECT source_row_count, loaded_row_count
INTO v_source_count, v_loaded_count
FROM governance.ingestion_batch_run
WHERE batch_run_id = p_batch_run_id;
IF NOT FOUND THEN
RAISE EXCEPTION 'Ingestion Batch Run ID % not found.', p_batch_run_id;
END IF;
-- 2. Compute physical quarantined row count
SELECT COUNT(*)
INTO v_quarantined_count
FROM governance.ingestion_quarantine
WHERE batch_run_id = p_batch_run_id;
-- 3. Calculate mathematical invariant
v_calculated_total := v_loaded_count + v_quarantined_count;
v_delta := v_source_count - v_calculated_total;
-- 4. Evaluate Invariant
IF v_delta = 0 THEN
-- Invariant Holds: Update status to RECONCILED
UPDATE governance.ingestion_batch_run
SET quarantined_row_count = v_quarantined_count,
batch_status = 'RECONCILED',
completed_at = clock_timestamp()
WHERE batch_run_id = p_batch_run_id;
RAISE NOTICE 'Batch % successfully reconciled. Source: %, Loaded: %, Quarantined: %',
p_batch_run_id, v_source_count, v_loaded_count, v_quarantined_count;
ELSE
-- Invariant Violation: Update status to HALTED and abort transaction
UPDATE governance.ingestion_batch_run
SET quarantined_row_count = v_quarantined_count,
batch_status = 'HALTED_RECONCILIATION_MISMATCH',
error_summary = format('Zero-Loss Invariant Violated! Source: %s, Calculated (Loaded %s + Quarantine %s): %s. Mismatch Delta: %s',
v_source_count, v_loaded_count, v_quarantined_count, v_calculated_total, v_delta),
completed_at = clock_timestamp()
WHERE batch_run_id = p_batch_run_id;
RAISE EXCEPTION 'INGESTION HALTED: Batch % failed zero-loss invariant check. Delta = %',
p_batch_run_id, v_delta;
END IF;
END;
$$;
```

# 5. Re-Runnability, Late-Arriving Data & Corrected Record Resolution Protocol

The pipeline provides deterministic mechanisms to safely handle re-executed batches, out-of-order events, and corrected upstream data feeds.

## 5.1 Batch & Stream Re-Runnability

File-Level Deduplication: Upon landing a batch file, the engine checks its SHA-256 hash against historical runs in governance.ingestion_batch_run.

If a run with the exact same hash exists in status RECONCILED, the engine skips reprocessing and logs an idempotent no-op.

If a run exists with --replay-quarantine specified, the engine isolates and re-evaluates only rows currently in governance.ingestion_quarantine for that batch_run_id.

Idempotent Target Upserts: Target schema load statements use deterministic natural business keys alongside explicit timestamp guards to safely prevent duplicate records:


```sql
INSERT INTO talent.profiles (
tenant_id, candidate_id, email, phone_e164, full_name, source_event_timestamp
)
SELECT
tenant_id, candidate_id, email, phone_e164, full_name, source_event_timestamp
FROM staging.talent_clean
ON CONFLICT (tenant_id, candidate_id) DO UPDATE
SET
email = EXCLUDED.email,
phone_e164 = EXCLUDED.phone_e164,
full_name = EXCLUDED.full_name,
source_event_timestamp = EXCLUDED.source_event_timestamp,
updated_at = clock_timestamp()
WHERE talent.profiles.source_event_timestamp <= EXCLUDED.source_event_timestamp
AND talent.profiles IS DISTINCT FROM EXCLUDED;
```
Append-Only Financial Ledgers: In accordance with DR-041, DR-068, and DR-083, accounting, audit, and billing tables prohibit in-place updates. Upserts use ON CONFLICT (transaction_id) DO NOTHING to preserve audit records while maintaining idempotency.

## 5.2 Late-Arriving Record Handling

Watermarks & Grace Windows: Streams and batch interfaces evaluate incoming record timestamps against current watermark tracking thresholds.

Late records within defined operational grace windows (e.g., Campus SIS roster edits INT-09, timesheet edits submitted within 5 days per DR-059) process automatically.

Records exceeding domain SLA thresholds are flagged for manual operational sign-off before entering production tables.

Transient Pending-Parent Staging: If a child record arrives before its parent entity (e.g., student roster row arriving prior to campus cohort setup, or time entry prior to engagement creation), the pipeline holds the record in a transient staging queue (staging.pending_parent_holding).

Staged child records hold for up to a configurable window (15 minutes for real-time streams; 1 batch cycle for bulk files).

If the parent entity arrives within the window, the child record is re-queued and processed.

If the parent fails to land before window expiration, the child record moves to governance.ingestion_quarantine with error code ERR_ORPHAN_FK_LOOKUP and linked rule CTR-01.

Terminal Finite State Machine (FSM) Protection: Records attempting to modify entities already in terminal states (e.g., JOINED, CLOSED, VOIDED, REVOKED) bypass direct updates. Instead of being silently ignored, they are routed to governance.ingestion_quarantine under rejection code ERR_FSM_TERMINAL_STATE_LOCKED for administrative audit.

## 5.3 Corrected Record & Quarantine Replay Lifecycle

When an upstream source sends corrected data, or an operator corrects an entry in quarantine, updates follow defined propagation pathways based on target storage type:

### Operational Schema Updates (SCD Type-1 with Audit Logging)

For operational tables (identity, organization, talent, contract), field corrections update current state in-place while generating a structured entry in governance.system_audit_event per DR-082. This entry logs the execution context, prior state, updated state, and updating user ID.

### Analytics Dimension Updates (SCD Type-2 Dimensional Tracking)

In compliance with DR-085, updates to analytical dimensions (analytics.dim_candidate, analytics.dim_organization) maintain point-in-time history using Slowly Changing Dimension (SCD) Type-2 mechanics:


```sql
-- Step 1: Expire current active dimension record
UPDATE analytics.dim_candidate
SET row_expiration_date = EXCLUDED.source_event_timestamp - INTERVAL '1 millisecond',
is_current = FALSE
FROM staging.talent_clean EXCLUDED
WHERE analytics.dim_candidate.candidate_id = EXCLUDED.candidate_id
AND analytics.dim_candidate.is_current = TRUE
AND analytics.dim_candidate.source_event_timestamp < EXCLUDED.source_event_timestamp;
-- Step 2: Insert new current version dimension record
INSERT INTO analytics.dim_candidate (
candidate_id, email, full_name, cgpa_value,
row_effective_date, row_expiration_date, is_current, source_event_timestamp
)
SELECT
candidate_id, email, full_name, cgpa_value,
source_event_timestamp AS row_effective_date,
'9999-12-31 23:59:59'::TIMESTAMPTZ AS row_expiration_date,
TRUE AS is_current,
source_event_timestamp
FROM staging.talent_clean;
Quarantine Remediation & Replay Lifecycle
```
Source/Operator Correction: Records in quarantine can be resolved by ingesting an updated upstream source file or manually editing raw payloads via the administrative console.

Re-Validation Stage: Corrected records are re-submitted to Stage 3 Validation Gates under a --replay-quarantine execution invocation.

Target Promotion & Audit Update: Upon passing validation, the record is promoted to production target schemas, and its entry in governance.ingestion_quarantine transitions to:

quarantine_status = 'CORRECTED_REPLAYED'

resolved_at = clock_timestamp()

resolved_by_user_id = <operator_uuid>

Historical Reconciliation Protection: Upstream corrections create explicit trace lines in quarantine logs without altering historical run statistics, preserving historical auditability.



# 6. Acceptance Checklist & Sign-Off Criteria

To achieve full milestone sign-off, implementation teams must satisfy all criteria listed below.


| Item | Requirement Category | Verification Criteria | Status | Sign-Off |
| :--- | :--- | :--- | :--- | :--- |
| 01 | Zero Silent Drop Guarantee | Ingestion testing across INT-01 through INT-11 confirms 0 dropped, missing, or unacknowledged rows across 1,000,000+ synthetic payloads. |  | Person |
| 02 | Invariant Enforcement | sp_verify_and_commit_ingestion_batch halts execution and rolls back transaction whenever Source != Loaded + Quarantined. |  | Person |
| 03 | Quarantine Traceability | 100% of quarantined records populate rejection_reason_code, linked_rule_id (DR/CTR), and structural diagnostic_detail JSONB. |  | Person |
| 04 | Idempotency Verification | Dual execution of identical source file digests produces identical target row states without creating primary/unique key violations or duplicate records. |  | Person |
| 05 | Parent Grace Holding | Dependent child records arriving prior to parent reference records stage in holding queue for up to 15 minutes before executing quarantine fallback. |  | Person |
| 06 | Terminal FSM Protection | Updates directed at entities in terminal FSM states (CLOSED, VOIDED, JOINED) quarantine automatically under ERR_FSM_TERMINAL_STATE_LOCKED. |  | Person |
| 07 | SCD Type-2 Audit Logging | Dimension changes update active versions in analytics per DR-085, and generate corresponding audit events in governance.system_audit_event per DR-082. |  | Person |
| 08 | Cryptographic Hardening | Sensitive target attributes correctly process through HMAC-SHA256 blind indexing and AES-256-GCM field encryption prior to target storage. |  | Person |




## Specification Approval Sign-Off

Lead Data Architect: Person
Date: Date


Head of Enterprise Engineering: Person
Date: Date
