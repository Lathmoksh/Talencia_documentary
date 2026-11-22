# Milestone 29 — KPI Discovery
**Platform:** Talentra Enterprise Workforce & Talent Demand Management Platform  
**Phase:** 5 — Insight  
**Lifecycle reference:** Talencia Global, Data-Driven Development Lifecycle, Version 1.0 (October 2026)  
**Upstream inputs:** Milestones 21–28; Data Dictionary v2; Phase 1 requirements/NFR register; Milestone 26 Kimball analytics model; Milestone 25 ingestion reconciliation  
**Primary output:** KPI catalogue with formulas, source tables, grain, target/baseline, owner, refresh cadence, persona, classification and traceability

---

## 1. Purpose

Define how Talentra measures success using data the platform actually holds. KPIs must be computable from the refined schema and analytical model, not invented as dashboard decoration. Define KPIs for each relevant persona, distinguish leading from lagging indicators, and connect operational measures to business outcomes.

**Milestone 29 is complete when:** every KPI has a precise definition, formula, source, grain, target or approved baseline method, owner and refresh cadence; every KPI can be computed from the current schema. Any missing data or unsupported KPI is recorded as a gap and routed back to Phase 3 (model/prove) rather than hidden with an estimate.

## 2. Platform and evidence boundaries

### 2.1 Confirmed platform context

Talentra is a job search and demand management platform supporting candidates, employers, recruiters, consultants, placement officers and administrators. Its scope includes general/professional/permanent staffing, apprentice and campus hiring, consultant sourcing, managed remote workforce requests, and a gig marketplace. The hackathon docket sets a 10-million-candidate scale objective and calls for an analytical star schema, dimensions, facts and aggregates for KPIs.

### 2.2 Confirmed analytical model from Milestone 26

Milestone 26 identifies these analytical dimensions:

- `analytics.dim_candidate`
- `analytics.dim_organisation`
- `analytics.dim_requisition`
- `analytics.dim_date`
- `analytics.dim_stage`

And these facts:

- `analytics.fact_application_event`
- `analytics.fact_billing_ledger`
- `analytics.fact_gig_performance`

The application-event fact includes candidate, requisition, organisation, stage and event-date keys, plus `duration_in_stage_hrs` and `is_terminal_state`. The billing fact supports debit/credit reconciliation by date and organisation. The gig fact supports gig performance analytics. Use the actual deployed Data Dictionary v2 and DDL as the final authority for column names.

### 2.3 Important limitation

The supplied lifecycle playbook defines the KPI catalogue structure but does not prescribe business target values. The supplied project materials also do not provide approved targets for every business outcome. Therefore:
- Do not fabricate targets, conversion goals, revenue goals or SLA values.
- Populate `target_value` only from an approved business decision or a cited Phase 1 NFR.
- Until approved, record `target_status = 'BASELINE_REQUIRED'` and calculate a measured baseline over an agreed observation window.
- A KPI that needs a field/fact not present in the refined schema is a Phase 3 gap.

## 3. KPI governance and identifier convention

Use stable IDs `KPI-001` onward. Keep IDs stable when definitions evolve; version the definition rather than recycling an ID.

Each catalogue entry must include:

| Field | Required meaning |
|---|---|
| KPI ID / version | Stable identity and definition version |
| Name | Concise business label |
| Persona | Candidate, employer, recruiter, consultant, placement officer, finance/admin, executive |
| Business question | Decision the KPI supports |
| Definition | Unambiguous inclusion/exclusion rules |
| Formula | Executable numerator, denominator, aggregation and time window |
| Unit | Count, %, currency, hours, days, rate |
| Leading / lagging | Early indicator or outcome indicator |
| Grain | Event, application, requisition, organisation, candidate, gig, day/month |
| Source | Exact fact/dimension and OLTP lineage |
| Filters | Status, tenant, geography, job type, date and privacy scope |
| Target / baseline | Approved target or baseline method/status |
| Owner | Accountable business owner and technical data steward |
| Refresh | Event-driven, hourly, daily, weekly or monthly |
| Classification | Public/Internal/Personal/Confidential-Sensitive as applicable |
| Quality gate | Reconciliation and data-quality assertions |
| Traceability | REQ/WF/BR/DR/CTR/NFR IDs and test IDs |
| Status | Proposed, validated, approved, retired |

## 4. Proposed KPI catalogue

The following are candidate definitions grounded in Talentra's documented workflows and supplied analytics facts. They are **proposed KPIs**, not approved business targets. Confirm exact physical columns and state values against Data Dictionary v2 before implementing.

| KPI ID | KPI / persona | Leading or lagging | Definition and formula | Grain / source | Target treatment |
|---|---|---|---|---|---|
| KPI-001 | Requisition fill rate — Employer / Executive | Lagging | Requisitions filled in period ÷ requisitions due to be filled in period × 100. Define cohort by expected fill date; do not divide by all historical requisitions. | Requisition-period; `analytics.dim_requisition`, `analytics.dim_date`, source requisition table | Baseline first; target approved by Talentra business owner |
| KPI-002 | Application-to-shortlist conversion — Recruiter / Employer | Leading | Distinct applications reaching shortlisted stage ÷ distinct eligible applications in same cohort × 100. | Requisition/application cohort; `analytics.fact_application_event`, `analytics.dim_stage`, `analytics.dim_date` | Baseline; segment by job family and organisation |
| KPI-003 | Application-to-offer conversion — Employer / Executive | Lagging | Distinct applications reaching offer stage ÷ distinct eligible applications in cohort × 100. | Application cohort; application-event fact and stage dimension | Baseline; define cohort window before target |
| KPI-004 | Offer acceptance rate — Employer / Executive | Lagging | Accepted offers ÷ offers issued with a resolved outcome × 100. Exclude pending offers from denominator; define expiry/cancellation handling. | Offer cohort; offer source entity and/or future approved offer fact | **Schema check:** current listed star facts do not explicitly include an offer fact; add a Phase 3 gap unless source tables support the required history |
| KPI-005 | Time in hiring stage — Recruiter / Employer | Leading | Median and p90 `duration_in_stage_hrs` for each stage, over applications whose stage interval is complete or validly observed. | Stage-event; `analytics.fact_application_event`, `analytics.dim_stage`, `analytics.dim_date` | Compare with approved service targets; otherwise baseline |
| KPI-006 | Requisition ageing — Recruiter / Employer | Leading | Current date minus publish/open date for open requisitions; report median, p90 and ageing buckets. | Requisition snapshot/day; requisition source and `analytics.dim_requisition` | Requires reliable publish/open date and snapshot strategy |
| KPI-007 | Candidate profile completeness — Candidate / Placement Officer | Leading | Average `profile_completeness_pct`; also report share above the agreed completeness threshold. | Candidate snapshot; `candidate.candidate_profile` (Milestone 26 DQ checks) | Threshold must be approved; report distribution, not only average |
| KPI-008 | Candidate activation — Candidate / Executive | Leading | Candidates completing a defined activation event (e.g., profile completed or first application) ÷ eligible newly registered candidates × 100 within a fixed window. | Candidate registration cohort; identity/candidate source events | **Schema check:** ensure event history and cohort dates exist; otherwise record model gap |
| KPI-009 | Application volume — Executive / Employer | Leading | Count of distinct application submissions by event date, job type and organisation. Deduplicate retries using canonical application identity. | Daily application event; `analytics.fact_application_event`, `analytics.dim_date`, `analytics.dim_requisition`, `analytics.dim_organisation` | Forecast/baseline, not a success target alone |
| KPI-010 | Organisation verification throughput — Admin | Leading | Count of organisations verified per period and median time from verification request to decision. | Organisation/verification event; organisation and KYB source tables | **Schema check:** decision timestamps/history required |
| KPI-011 | Gig completion rate — Gig requester / Executive | Lagging | Completed gig assignments ÷ accepted assignments whose planned end date has passed × 100. Exclude still-active assignments. | Gig assignment cohort; `analytics.fact_gig_performance` | Baseline; external fulfilment status is authoritative |
| KPI-012 | Gig worker utilisation — Gig worker / Marketplace Admin | Leading | Booked eligible gig hours ÷ available eligible gig hours × 100 over a defined period. Prevent double-counting overlapping intervals. | Worker-week/month; `analytics.fact_gig_performance` and availability source | Requires duration/availability fields at consistent grain |
| KPI-013 | Gig rating — Gig requester / Marketplace Admin | Lagging | Average rating and rating distribution for completed gigs, with response count and coverage rate. | Completed gig; `analytics.fact_gig_performance` or rating source | Show sample size; avoid ranking low-volume workers |
| KPI-014 | Net wallet movement — Finance / Executive | Lagging | Credits minus debits by transaction date and organisation; show gross debit and credit separately. | Organisation-day; `analytics.fact_billing_ledger`, `analytics.dim_organisation`, `analytics.dim_date` | Must reconcile exactly to OLTP ledger |
| KPI-015 | Credit consumption by purpose — Finance / Recruiter | Leading | Sum of debit amount grouped by approved transaction purpose and period. | Transaction-purpose/month; billing fact and source ledger | Requires purpose classification in source/fact |
| KPI-016 | Subscription renewal / cancellation — Finance / Executive | Lagging | Renewed subscriptions ÷ subscriptions eligible for renewal; cancellations separately ÷ active subscriptions at period start. | Subscription cohort; billing/subscription source entities | **Schema check:** subscription lifecycle fact/history required |
| KPI-017 | Ingestion reconciliation rate — Data Operations / Admin | Leading | Batches satisfying `source_count = loaded_count + quarantined_count` ÷ completed batches × 100. Also report count of halted/mismatched batches. | Batch; Milestone 25 ingestion batch log / governance reconciliation tables | Target is 100% accounting; zero unexplained records |
| KPI-018 | Data quality score — Data Governance / Executive | Leading | Per-table score and weighted platform score using the approved Milestone 26 scorecard weights. Never average without documented weighting. | Table-check/run; `governance.data_quality_scorecard`, `governance.data_quality_check_result` | Respect configured baseline and critical/high failure gates |
| KPI-019 | Analytics-to-OLTP ledger parity — Finance / Data Governance | Leading | Number and amount of daily debit/credit variances between `billing.wallet_ledger` and `analytics.fact_billing_ledger`. | Organisation/day or platform/day; OLTP ledger + billing fact + date dimension | Exact zero variance |
| KPI-020 | Candidate privacy shielding compliance — DPO / Admin | Leading | Unauthorized profile reads exposing direct contact data ÷ tested unauthorized reads; also count confirmed violations. | Access event; audit/access logs and candidate privacy model | Zero confirmed violations; requires auditable access events |
| KPI-021 | Recruiter seat utilisation — Organisation Admin | Leading | Active allocated recruiter seats ÷ licensed recruiter seat capacity × 100. | Organisation-day; licence/seat tables | Capacity is entitlement-derived; do not infer from user count |
| KPI-022 | Gig external handoff reconciliation — Marketplace Ops | Leading | Accepted gig assignments with a valid external handoff reference and reconciled external status ÷ accepted assignments requiring handoff. | Assignment; gig source and external integration status | Exact target/lag from Milestone 22 contract; surface stale handoffs |

### 4.1 Persona coverage

- **Candidate:** profile completeness, activation, application activity and application-stage progress where candidate-visible.
- **Employer:** requisition ageing, fill rate, shortlist/offer conversion, stage duration and gig fulfilment.
- **Recruiter:** assigned requisition pipeline, stage ageing, sourcing/application conversion and seat usage.
- **Consultant:** consultant-open requisition activity, nominations and accepted/declined outcomes. Add a KPI only when the source model records these events at the required grain.
- **Placement Officer (TPO):** campus cohort activation, application progression and outcomes. Use campus cohort identifiers and consent-aware reporting.
- **Finance/Admin:** wallet movement, credit use, subscription status, seat utilisation and reconciliation.
- **Executive:** hiring funnel, demand fulfilment, gig marketplace outcomes, revenue/ledger movement, platform quality and privacy/compliance indicators.

## 5. KPI tree

Build a hierarchy linking operational indicators to business outcomes. The following is a proposed logical tree; approve the causal relationships with business owners.

```text
Talentra business outcomes
├── Hiring demand fulfilled
│   ├── Requisition fill rate (KPI-001)
│   ├── Application-to-shortlist conversion (KPI-002)
│   ├── Application-to-offer conversion (KPI-003)
│   └── Time in stage / requisition ageing (KPI-005, KPI-006)
├── Candidate supply and engagement
│   ├── Profile completeness (KPI-007)
│   ├── Candidate activation (KPI-008)
│   └── Application volume (KPI-009)
├── Gig marketplace performance
│   ├── Completion rate (KPI-011)
│   ├── Worker utilisation (KPI-012)
│   ├── Rating and coverage (KPI-013)
│   └── External handoff reconciliation (KPI-022)
├── Commercial health
│   ├── Net wallet movement (KPI-014)
│   ├── Credit consumption (KPI-015)
│   ├── Subscription renewals/cancellations (KPI-016)
│   └── Seat utilisation (KPI-021)
└── Trust and platform reliability
    ├── Ingestion reconciliation (KPI-017)
    ├── Data quality score (KPI-018)
    ├── OLTP/analytics parity (KPI-019)
    └── Privacy shielding compliance (KPI-020)
```

## 6. Computability and source validation

For each KPI, implement a validation record with:
1. KPI ID and version.
2. SQL/query or governed semantic definition.
3. Exact source tables and columns from the current dictionary.
4. Declared grain and unique business key.
5. Time zone and period-boundary rule.
6. Deduplication and late-arriving-event behavior.
7. Null, unknown and excluded-state handling.
8. Tenant/privacy scope and permitted aggregation.
9. Reconciliation query and expected tolerance.
10. Test ID and evidence.

A KPI is not computable merely because a similarly named field exists. Its full numerator, denominator, cohort, history and exclusions must be reconstructible.

## 7. Target-setting method

1. Establish a representative baseline window (recommend 8–12 weeks where the data volume supports it; this is a proposed measurement window, not a source-mandated target).
2. Segment by hiring category, organisation size, geography and campus/gig channel where meaningful.
3. Inspect seasonality and outliers before setting targets.
4. Set targets with the accountable business owner; record effective date and approval.
5. Distinguish service-level thresholds (e.g., ingestion reconciliation) from business aspirations (e.g., fill rate).
6. Version targets so historical dashboard results are not silently rewritten.

## 8. Acceptance checklist

- [ ] KPI catalogue has stable IDs and definitions.
- [ ] Every KPI specifies persona, formula, source, grain, target/baseline, owner and refresh.
- [ ] Leading and lagging KPIs are distinguished.
- [ ] KPI tree links operational measures to outcomes.
- [ ] Every KPI is computable from the current schema or has an owned Phase 3 gap.
- [ ] OLTP-to-analytics parity and data-quality checks are linked.
- [ ] Privacy, tenant isolation and classification are applied to KPI access.
- [ ] Targets are approved, not fabricated.
- [ ] KPI definitions are version-controlled and tested.

## 9. Go deeper

Build a KPI tree linking operational metrics to business outcomes. For each branch, test whether the proposed leading indicator actually predicts the lagging outcome; retain the relationship as a hypothesis until validated with Talentra data.
