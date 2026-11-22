# Milestone 13 — Data Volumetrics and Distribution Profile

**Platform:** Talentra Enterprise Workforce & Talent Demand Management Platform  
**Phase:** 3 — Prove  
**Status:** Planning baseline; validate against the deployed schema and workload  
**Inputs:** `talentra_redesigned_erl.md`; Steps 07–12; Hackathon Docket; Data-Driven Development Lifecycle Playbook  
**Output:** Volumetric and distribution sheet, growth assumptions, cardinality/null/skew profile, and reproducible sizing model

## 1. Purpose and exit criteria

Estimate how Talentra's generated data should behave at launch, year 1, and year 3. Uniform row counts are not realistic: candidates, job requisitions, applications, audit events, messages, and ledger entries have different growth and skew patterns.

**Done when:** every modeled table has a row-volume estimate and distribution assumptions; assumptions are explained; hot/peak/burst patterns are documented; estimates can be regenerated from the assumptions.

## 2. Model scope and baseline

The discovery baseline describes 13 domain schemas and 90 logical tables, with 893 columns in the Step 10 dictionary. The core platform covers identity, organisations, candidate profiles, recruitment, applications, sourcing, gig work, licensing, billing, engagement, governance, master data, and analytics. The hackathon docket names a scale target of 10 million candidate profiles and expects both OLTP and analytics design.

Use the authoritative schema/table inventory from the current repository when producing the final table-by-table sheet. Do not silently treat estimates below as measured production facts.

## 3. Volumetric assumptions

| Population / workload | Launch | Year 1 | Year 3 | Distribution notes |
|---|---:|---:|---:|---|
| Candidate profiles | 100,000 | 1,000,000 | 10,000,000 | Long-tail geography, skills and experience; profile completeness is uneven |
| Organisations | 2,000 | 20,000 | 100,000 | Tenant sizes are highly skewed; a small enterprise cohort owns many requisitions |
| Job requisitions | 10,000 | 100,000 | 1,000,000 | Open/closed mix varies by hiring season and industry |
| Applications | 250,000 | 5,000,000 | 100,000,000 | Highly skewed by requisition; popular roles receive disproportionate volume |
| Application events/history | 1,000,000 | 15,000,000 | 100,000,000+ | Append-heavy; event count can exceed application count substantially |
| Candidate skills associations | 1,000,000 | 15,000,000 | 150,000,000 | Candidate skill count follows a right-skewed distribution |
| Profile download history | 50,000 | 2,000,000 | 20,000,000 | Credit-gated action; concentrated among active recruiters |
| Audit events | 500,000 | 10,000,000 | 100,000,000+ | Append-only; bursty around admin, billing and hiring operations |
| Messaging records | 100,000 | 5,000,000 | 50,000,000 | Conversation activity is power-law / long-tail |
| Wallet/ledger entries | 100,000 | 3,000,000 | 30,000,000 | Financial writes require append-only integrity and reconciliation |
| Gig availability / assignments | 10,000 | 500,000 | 10,000,000 | Time-window density and overlap attempts matter more than uniform counts |
| Analytics fact rows | 500,000 | 20,000,000 | 200,000,000 | Depends on event retention, aggregation grain and refresh strategy |

**Important:** These are explicit test-planning scenarios, not promises or measured forecasts. Replace or tune them using stakeholder estimates, repository seed data, and workload evidence. Keep a separate per-table worksheet with `schema.table`, launch/year-1/year-3 rows, growth rate, distinct counts, null rate, skew assumption, retention, and rationale.

## 4. Distribution profile to model

- **Cardinality:** distinct candidates, organisations, requisitions, skills, currencies, statuses, and tenant IDs.
- **Null rates:** optional profile attributes, salary disclosure, secondary contact details, optional education/work-history details, and optional gig metadata.
- **Skew:** popular skills, high-volume employers, requisitions with unusually high application counts, recruiter activity, and geographic concentration.
- **Temporal shape:** weekday/weekend, hiring-season peaks, month-end billing, campaign bursts, and event retention.
- **Relationship density:** candidate-to-skill, requisition-to-application, organisation-to-recruiter, gig-to-milestone, wallet-to-ledger, and application-to-event cardinalities.
- **Invalid-data distribution:** include deliberately invalid values only in the negative-test fixture, never in the valid golden dataset.

## 5. Capacity-estimation method

For each table:

1. Record source row count or declared scenario count.
2. Estimate row width from the current schema (including variable-length fields as a range).
3. Estimate heap/table bytes as `row_count × average_row_width`; separately estimate indexes, TOAST/large objects, WAL, replicas, and retained history.
4. State assumptions for index selectivity and access patterns.
5. Calculate growth at launch, year 1, and year 3; include peak-day and burst multipliers.
6. Mark assumptions as **measured**, **stakeholder-provided**, or **planning assumption**.

A precise disk figure is not claimed until the schema, representative values, indexes, and PostgreSQL version are measured.

## 6. Outputs and acceptance checklist

- [ ] Inventory covers every table in the current ER/DDL.
- [ ] Launch, year-1, and year-3 volumes are recorded for every table.
- [ ] Cardinality, null rate, skew and growth rationale are documented.
- [ ] Peak season, peak day and burst assumptions are included.
- [ ] Data retention and append-only history are accounted for.
- [ ] Sizing assumptions are traceable to a source or explicitly labeled.
- [ ] Generated sample data can be configured from this profile.

## 7. Go deeper

Model seasonality and burst traffic explicitly: simulate a peak hiring campaign, a large enterprise tenant, a popular requisition, and a billing/event burst. Compare expected and observed distribution after running the generator; record deviations and update the assumptions rather than forcing uniform data.
