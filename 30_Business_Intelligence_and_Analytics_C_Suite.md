# Milestone 30 — Business Intelligence and Analytics (C-Suite)
**Platform:** Talentra Enterprise Workforce & Talent Demand Management Platform  
**Phase:** 5 — Insight  
**Lifecycle reference:** Talencia Global, Data-Driven Development Lifecycle, Version 1.0 (October 2026)  
**Upstream inputs:** Milestone 29 KPI catalogue; Milestone 26 Kimball star schema and DQ automation; Milestone 25 ingestion reconciliation; Milestones 21–28 physical model, integrations, scale data and automated proof  
**Primary output:** Executive dashboard specification, drill-down model, source-reconciled SQL/query catalogue and executive insight narrative

---

## 1. Purpose

Show leadership what Talentra's data can tell them. Build an executive dashboard that answers the top leadership questions, supports meaningful drill-downs, and provides an insight narrative grounded in measured data.

**Milestone 30 is complete when:** every displayed number reconciles to a query on source tables (or a documented analytical fact with proven OLTP parity); metric definitions match Milestone 29; filters and drill-downs preserve tenant/privacy controls; and the executive narrative distinguishes observed facts from interpretation.

## 2. Dashboard principles

1. **KPI catalogue is the contract.** Dashboard tiles use approved KPI IDs and versions; do not reimplement formulas independently.
2. **Reconciliation before presentation.** Every metric has a traceable query and a known source grain.
3. **Show context.** Display period, comparison period, sample size, last refresh and data-quality status.
4. **Separate outcomes from drivers.** Fill rate is an outcome; stage conversion and ageing are potential drivers.
5. **No misleading aggregation.** Do not average percentages across tenants without weighting; do not add distinct counts across overlapping periods.
6. **Privacy by design.** C-suite views use aggregate data. Candidate-level drill-down is restricted by role, tenant and purpose.
7. **Freshness is visible.** Show ingestion watermark/last successful refresh and stale-data warnings.
8. **No fabricated insight.** Anomaly flags and explanations must be evidence-based; causal claims require analysis.

## 3. Executive questions and dashboard layout

### 3.1 Top leadership questions

| Executive question | KPI / view | Primary drill-down |
|---|---|---|
| Are we fulfilling hiring demand? | Requisition fill rate, open requisition ageing, application-to-shortlist/offer conversion | Job category → organisation → requisition → stage |
| Where does the hiring funnel slow down? | Application volume, stage conversion, median/p90 duration in stage | Date → category → organisation → requisition → stage |
| Is candidate supply active and usable? | Candidate activation, profile completeness, application activity | Cohort → geography/skill where permitted → completeness band |
| Is the gig marketplace delivering? | Gig completion, utilisation, rating distribution, external handoff reconciliation | Period → requester/organisation → gig category → assignment |
| Is the platform commercially healthy? | Wallet debit/credit movement, credit use, subscription renewals/cancellations, seat utilisation | Period → organisation → transaction purpose |
| Can leadership trust the numbers? | Data quality score, ingestion reconciliation, OLTP/analytics parity, refresh freshness | Pipeline/batch → table → assertion → failure record |
| Are privacy and controls holding? | Privacy shielding compliance, audit exceptions and access violations | Period → tenant → control category; no unrestricted PII drill-down |

### 3.2 Suggested single-page executive layout

**Header**
- Reporting period and comparison period.
- Last successful ingestion / analytics refresh.
- Data-quality status and reconciliation status.
- Global filters: date range, hiring category, organisation segment and geography, subject to access policy.

**Row 1 — Outcome cards**
- Requisition fill rate (KPI-001).
- Application-to-offer conversion (KPI-003), only if the offer source history is proven.
- Gig completion rate (KPI-011).
- Net wallet movement (KPI-014).

**Row 2 — Hiring funnel**
- Applications by stage and period.
- Stage conversion rates.
- Median and p90 time in stage (KPI-005).
- Open requisition ageing (KPI-006).

**Row 3 — Supply and marketplace**
- Candidate profile completeness / activation (KPI-007/008).
- Gig completion and utilisation (KPI-011/012).
- Gig rating distribution with response count (KPI-013).

**Row 4 — Commercial and operational trust**
- Debit/credit trend and credit consumption (KPI-014/015).
- Subscription renewal/cancellation and seat utilisation (KPI-016/021), only when lifecycle history is available.
- Ingestion reconciliation, DQ score and OLTP/analytics parity (KPI-017/018/019).
- Privacy shielding compliance (KPI-020).

**Footer**
- KPI definition version, refresh timestamp, data coverage, exclusions and links to governed drill-downs.

This is a specification, not a claim that a dashboard has already been implemented.

## 4. Analytical source model and lineage

### 4.1 Confirmed Milestone 26 star schema

Dimensions:
- `analytics.dim_candidate`
- `analytics.dim_organisation`
- `analytics.dim_requisition`
- `analytics.dim_date`
- `analytics.dim_stage`

Facts:
- `analytics.fact_application_event`
- `analytics.fact_billing_ledger`
- `analytics.fact_gig_performance`

The application-event fact is the primary source for funnel and stage-duration reporting. It contains surrogate keys to candidate, requisition, organisation, stage and event date, along with `duration_in_stage_hrs` and `is_terminal_state`. The billing fact supports debit/credit aggregation and reconciliation to `billing.wallet_ledger`. The gig fact supports gig performance measures. Use the deployed dictionary for exact columns not explicitly named here.

### 4.2 Required lineage map

| Dashboard area | Analytical source | OLTP / operational reconciliation source |
|---|---|---|
| Hiring funnel and stage duration | `analytics.fact_application_event` + `dim_stage`, `dim_date`, `dim_candidate`, `dim_requisition`, `dim_organisation` | Application/requisition lifecycle event tables from current DDL |
| Billing and wallet movement | `analytics.fact_billing_ledger` + `dim_date`, `dim_organisation` | `billing.wallet_ledger` (as used in Milestone 26 parity check) |
| Gig performance | `analytics.fact_gig_performance` + applicable dimensions | Gig assignment/contract, external handoff and rating source tables from current DDL |
| Candidate profile completeness | Candidate source profile or approved candidate dimension attribute | `candidate.candidate_profile` (Milestone 26 DQ checks) |
| Ingestion health | Governance ingestion batch/reconciliation records | Milestone 25 batch-run, quarantine and DLQ records |
| DQ score / test health | `governance.data_quality_scorecard`, `governance.data_quality_check_result` | Milestone 26 assertion execution records |
| Privacy / audit | Governance and audit control records | Exact audit/access event tables in current DDL |

If a desired measure has no fact, history or reliable source lineage, do not fabricate it in the dashboard. Create a model gap with a proposed fact/attribute and route it back to Phase 3.

## 5. Reconciliation requirements and query patterns

### 5.1 Application funnel reconciliation

The exact application event schema and status codes must be read from Data Dictionary v2. Reconciliation should compare the same event window, business keys, deduplication rules and terminal-state semantics between OLTP and the analytical fact.

Illustrative pattern (adapt column names to the deployed dictionary):

```sql
-- Compare daily application-event counts at the same grain.
-- Use the same event type, tenant scope, timezone and deduplication key
-- on both sides before treating the result as a parity assertion.
WITH oltp AS (
    SELECT DATE(event_at) AS event_date, COUNT(*) AS source_count
    FROM application.application_event
    WHERE event_at >= :from_ts AND event_at < :to_ts
    GROUP BY DATE(event_at)
),
mart AS (
    SELECT d.calendar_date AS event_date, COUNT(*) AS fact_count
    FROM analytics.fact_application_event f
    JOIN analytics.dim_date d ON d.date_key = f.event_date_key
    WHERE d.calendar_date >= :from_date AND d.calendar_date < :to_date
    GROUP BY d.calendar_date
)
SELECT COALESCE(o.event_date, m.event_date) AS event_date,
       COALESCE(o.source_count, 0) AS source_count,
       COALESCE(m.fact_count, 0) AS fact_count,
       COALESCE(o.source_count, 0) - COALESCE(m.fact_count, 0) AS variance
FROM oltp o
FULL OUTER JOIN mart m USING (event_date)
WHERE COALESCE(o.source_count, 0) <> COALESCE(m.fact_count, 0);
```

**Important:** `application.application_event` and `event_at` above are illustrative placeholders unless present in the current deployed DDL. Replace them with the exact source table/column names; do not run this as-is without that verification.

### 5.2 Financial reconciliation

Milestone 26 explicitly defines an OLTP-to-analytics ledger parity check comparing daily debit and credit totals from `billing.wallet_ledger` with `analytics.fact_billing_ledger` joined to `analytics.dim_date`. The acceptance condition is zero debit and credit variance for each day in scope.

```sql
WITH oltp_ledger_summary AS (
    SELECT DATE(created_at) AS transaction_date,
           SUM(CASE WHEN entry_type = 'DEBIT' THEN amount ELSE 0.00 END) AS oltp_total_debit,
           SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE 0.00 END) AS oltp_total_credit
    FROM billing.wallet_ledger
    WHERE created_at >= :from_ts AND created_at < :to_ts
    GROUP BY DATE(created_at)
),
analytics_fact_summary AS (
    SELECT d.calendar_date AS transaction_date,
           SUM(f.debit_amount) AS fact_total_debit,
           SUM(f.credit_amount) AS fact_total_credit
    FROM analytics.fact_billing_ledger f
    JOIN analytics.dim_date d ON f.event_date_key = d.date_key
    WHERE d.calendar_date >= :from_date AND d.calendar_date < :to_date
    GROUP BY d.calendar_date
)
SELECT COALESCE(o.transaction_date, a.transaction_date) AS transaction_date,
       COALESCE(o.oltp_total_debit, 0.00) AS oltp_total_debit,
       COALESCE(a.fact_total_debit, 0.00) AS fact_total_debit,
       COALESCE(o.oltp_total_credit, 0.00) AS oltp_total_credit,
       COALESCE(a.fact_total_credit, 0.00) AS fact_total_credit,
       COALESCE(o.oltp_total_debit, 0.00) - COALESCE(a.fact_total_debit, 0.00) AS debit_variance,
       COALESCE(o.oltp_total_credit, 0.00) - COALESCE(a.fact_total_credit, 0.00) AS credit_variance
FROM oltp_ledger_summary o
FULL OUTER JOIN analytics_fact_summary a
  ON o.transaction_date = a.transaction_date
WHERE COALESCE(o.oltp_total_debit, 0.00) <> COALESCE(a.fact_total_debit, 0.00)
   OR COALESCE(o.oltp_total_credit, 0.00) <> COALESCE(a.fact_total_credit, 0.00);
```

This pattern follows the supplied Milestone 26 reconciliation logic. Ensure `:from_ts`, `:to_ts`, `:from_date`, and `:to_date` represent the same timezone-aware reporting interval.

### 5.3 Data quality and ingestion reconciliation

Display the Milestone 25 accounting invariant:

`source_record_count = loaded_record_count + quarantined_record_count`

A batch with a mismatch must be visibly marked failed/halted; do not present it as a successful refresh. Link the dashboard status to the batch ID, rejection reason and quarantine/DLQ counts.

### 5.4 Dashboard metric contract

For every tile/chart, store:
- `kpi_id`, `kpi_version`, query/semantic-model version;
- reporting grain and period;
- source fact/dimension and OLTP lineage;
- last successful refresh and source watermark;
- reconciliation status and variance;
- data-quality score/status;
- permitted filters and drill-down scope;
- owner and escalation path.

## 6. Drill-down and access design

- **C-suite:** aggregate organisation/period/category views; no direct candidate contact data by default.
- **Organisation administrator/employer:** own organisation and authorised subordinate scope only.
- **Recruiter:** requisitions assigned to their own company and permitted assignments only.
- **Consultant:** only requisitions open to consultants or explicitly invited, consistent with the project docket.
- **Placement Officer:** authorised campus cohorts and permitted student records; apply consent and privacy controls.
- **Candidate:** own profile and own application activity only.
- **Admin / DPO:** control dashboards with audited privileged access; sensitive values remain masked unless a documented purpose permits access.

Use the database/access-layer controls defined in the model (including tenant isolation/RLS where implemented). Dashboard filters are not a security boundary. Aggregate small cohorts carefully to avoid re-identification.

## 7. Insight narrative format

The executive narrative should be generated for each reporting period using this structure:

1. **What changed:** KPI value, comparison period, absolute/relative change and sample size.
2. **Where it changed:** category, organisation segment, geography or stage breakdown.
3. **Likely driver:** supporting leading indicators (e.g., stage duration or requisition ageing).
4. **Confidence and caveats:** data coverage, DQ score, late data, exclusions and sample size.
5. **Action / owner:** specific decision, responsible owner and review date.
6. **Follow-up measure:** KPI ID and date when impact will be evaluated.

Do not state that one factor caused another based only on correlation. Label causal explanations as hypotheses until validated.

## 8. Anomaly flags, trend explanations and what-if views

### 8.1 Anomaly flags

- Start with transparent rules: period-over-period change, deviation from rolling median, unusual stage backlog, ingestion lag, DQ score regression and OLTP/mart variance.
- Record the comparison window, threshold, affected grain and triggering rows.
- Tune thresholds on historical data; do not silently hard-code arbitrary business thresholds.
- Suppress or qualify alerts when the underlying data-quality or freshness gate fails.

### 8.2 Trend explanations

Explain trends using KPI tree relationships and drill-down evidence. Example: a lower fill rate may coincide with higher requisition ageing and longer time in a specific stage. Present the relationship and evidence; do not assert causation without a validated analysis.

### 8.3 What-if views

Provide scenario controls only for supported variables, such as:
- change in application volume;
- change in stage conversion assumption;
- change in time-in-stage assumption;
- change in gig availability/utilisation assumption;
- change in credit consumption or seat utilisation.

Show assumptions, formula, baseline, scenario result and sensitivity. What-if outputs are simulations, not actual results or approved forecasts.

## 9. Performance, refresh and reliability

- Follow the Milestone 28 NFR-05 dashboard rollup target: analytical star-schema dashboard rollups p95 < 500 ms under the specified Year 3 benchmark context.
- Do not claim the target is met until the automated NFR suite has executed and produced evidence.
- Prefer pre-aggregations/materialized views only when their refresh, lineage and reconciliation are documented.
- Show data freshness and stale status. Milestone 22 INT-11 specifies continuous export with less than 5 seconds lag for its relevant outbound stream; do not assume this is the refresh SLA for every dashboard.
- Schedule refreshes according to KPI ownership and source update characteristics; record each KPI's approved refresh cadence in Milestone 29.
- Ensure dashboard queries use governed indexes/partitions and are benchmarked at documented scale tiers.

## 10. Acceptance checklist

- [ ] Executive dashboard answers the leadership questions in Section 3.
- [ ] Every tile/chart maps to an approved KPI ID and version.
- [ ] Every number reconciles to source tables or a proven fact with OLTP parity.
- [ ] Application, billing and gig metrics use correct grain and deduplication.
- [ ] Ingestion, data-quality and freshness status are visible.
- [ ] Drill-downs enforce tenant, role, consent and privacy rules.
- [ ] Executive narrative distinguishes facts, hypotheses and actions.
- [ ] Anomaly flags have documented thresholds and evidence.
- [ ] What-if views disclose assumptions and are labelled simulations.
- [ ] Dashboard rollups are benchmarked against NFR-05; no unverified performance claim.
- [ ] All unresolved source/model gaps are assigned and routed back to Phase 3.

## 11. Phase 5 exit — G5: Insight validated

Phase 5 is complete only when:
- every KPI is computable from the schema, or its gap has been sent back to Phase 3 and resolved;
- every dashboard number reconciles with its source;
- the executive dashboard and insight narrative are reviewed by the relevant business owners;
- access controls and privacy boundaries are verified;
- data freshness and quality caveats are visible.

## 12. Go deeper

Add anomaly flags, trend explanations and what-if views. Use actual historical Talentra data to validate alert thresholds and scenario assumptions, and clearly separate observed facts from modelled outcomes.
