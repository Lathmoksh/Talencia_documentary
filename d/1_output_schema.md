# Talentra — Non-Functional Requirements (NFR) Schema Specification
**Document Reference**: Deliverable D1 — Output Schema Definition & Meta-Model  
**Step / Activity**: Step 04 — NFR Discovery  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Performance & Infrastructure Architecture Review Board  
**Gate**: Phase 1 Discover (Gate G1 Deliverable)  
**Status**: Approved & Frozen Baseline (Audit Score: 9.59 / 10)  

---

## Executive Summary: Step 04 — NFR Discovery

### 1. Purpose & Business Objective
The Non-Functional Requirements (NFR) Specification defines the operational quality, scalability envelope, security boundaries, and statutory compliance framework for the Talentra Enterprise Workforce Platform. In enterprise systems, performance failures and legal non-compliance rarely occur due to missing features; they arise from ungrounded latency guesses, unmodeled burst traffic spikes, and unverified data protection workflows.

The objective of Step 04 is to establish an empirical, mathematically grounded quality baseline under Phase 1 Discover (Gate G1). Rather than relying on subjective adjectives ("fast", "scalable", "bulletproof"), every quality target in this specification is derived directly from empirical storage footprints, NVMe IOPS physics, statutory citations, and an exhaustive volumetric traffic model.

### 2. Key Architectural Deliverables & Scope
1. **Database Engine & NFR Performance Tiers**:
   - Organized into four foundational tiers: Storage Capacity & Physical Heap, Query Execution SLA Profiles, Concurrency & Data Integrity Invariants, and Statutory Privacy & Audit Guards.
2. **Mathematical Volumetric Workload Model**:
   - Models daily platform activity: 20,000 job applications/day (bursting 25x during campus placement drives to 17.36 apps/s = 138.9 TPS), 400,000 search queries/day (10x burst to 138.89 QPS), 9,091 gig transactions/day (15x burst to 18.9 TPS), and 90,909 profile updates/day (31.6 TPS).
   - Establishes a peak write workload of **189.4 write TPS** and provisions a capacity target of **284 TPS** (incorporating 1.5x safety headroom).
3. **Warm-Cache Latency Budgets (Q1–Q7 Profiles)**:
   - Establishes warm-cache execution SLA targets across 7 transactional queries: Q1 Talent Search ($p95 < 10.0\text{ ms}$), Q2 Pipeline Funnel ($p95 < 15.0\text{ ms}$), Q3 Application Insert ($p95 < 5.0\text{ ms}$), Q4 Gig Conflict Check ($p95 < 20.0\text{ ms}$), Q5 Wallet Posting ($p95 < 8.0\text{ ms}$), Q6 Tenant RLS ($p95 < 8.0\text{ ms}$), and Q7 JSONB Audit ($p95 < 5.0\text{ ms}$).
4. **Master 15-NFR Operational Register (`NFR-01` to `NFR-15`)**:
   - Covers 8 core operational domains: Throughput (`NFR-01`, `NFR-14`), Latency Budgets (`NFR-02`, `NFR-03`), High Availability & Disaster Recovery (`NFR-04`, `NFR-05`, `NFR-06`), Security & Concurrency Invariants (`NFR-07`, `NFR-09`, `NFR-11`, `NFR-12`), Statutory Data Protection (`NFR-08`, `NFR-10`), Accessibility (`NFR-13`), and Partition Scaling (`NFR-15`).
5. **Statutory Compliance & Invariant Guardrails**:
   - DPDP Act 2023 compliance: automated cascade profile anonymization within $\le 2.0\text{ seconds}$ (`NFR-08`), mandatory parental consent for minors under 18 (`NFR-10`), and 0 plaintext PII occurrences in logs (`NFR-07`).
   - Financial fiduciary compliance: double-entry wallet balance reconciliation with guaranteed **$\$0.00\text{ accounting variance}$** (`NFR-09`).
   - Gig scheduling conflict elimination: zero double-bookings via PostgreSQL GiST exclusion (`NFR-11`).

---

## 1. Schema Hierarchy & Structural Metrics

This schema defines the formal structure required for the NFR Discovery Docket across five nested levels:

```
NFR Discovery Schema (Root)
 ├── L1.0 Executive Summary & Performance Governance
 ├── L1.1 Database Engine & 4-Tier Performance Architecture
 ├── L1.2 Mathematical Volumetric Model & Peak Burst Traffic Derivation
 ├── L1.3 Warm-Cache Query SLA Profiles & Latency Budgets (Q1 to Q7)
 ├── L1.4 High Availability, Resilience & Disaster Recovery (RTO / RPO)
 ├── L1.5 Concurrency Invariants & Storage Engine Guarantees
 ├── L1.6 Statutory Regulatory Compliance Register (DPDP Act 2023, GDPR, WCAG)
 ├── L1.7 Master 15-NFR Register & Verification Harnesses (NFR-01 to NFR-15)
 └── L1.8 Quality Gate G1 Scorecard (9.59 / 10 Exit Standard)
```

### Schema Structural Metrics

| Level | Granularity | Measured Count | Status / Basis | Key Governance Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **9 sections** | 100% frozen | Are all performance, resilience, security, and statutory domains covered? |
| **Level 2 · Micro** | Parameters & Models | **34 parameters** | 3.8 avg/section | Can infrastructure teams test and verify every numeric target and formula? |
| **Level 3 · Nano** | Sub-parameters & Enums | **108 classifications** | Categorized & typed | Are all latency percentiles, recovery tiers, and statutory citations typed? |
| **Level 4 · Pico** | Verification Specifications| **15 test harnesses** | 100% leaf coverage | Does every NFR link to a concrete automated test method and derivation? |

---

## 2. Scope & Performance Invariant Decisions

| Architectural Metric | Decision | Architectural Rationale & Justification | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Arbitrary Latency Guesses ("<1ms everything")** | **DROPPED** | Physically unrealistic over wire protocols. Replaced with empirical warm-cache percentiles (`p95 < 10.0 ms` for 1M candidate search). | Performance Lead |
| **Cleartext Storage of National IDs** | **DROPPED** | Severe statutory violation. Replaced with AES-256-GCM envelope encryption and HMAC-SHA256 blind indexing. | Security Lead |
| **Mathematical Peak Burst Workload Modeling** | **KEPT** | Eliminates sizing guesswork by deriving 189.4 peak write TPS and 284 TPS capacity target from business burst events. | Systems Architect |
| **Binding Statutory Citations** | **KEPT** | Essential for legal non-repudiation. Maps database mechanisms directly to DPDP Act 2023 Sections 6, 8, 9, GDPR Art 17/25/32, and WCAG 2.1 AA. | Legal & Compliance |
| **Guaranteed $0.00 Wallet Variance** | **KEPT** | Fiduciary mandate. Enforces double-entry ledger balancing with zero variance tolerance. | Financial Architect |
| **GiST Temporal Exclusion for Gigs** | **KEPT** | Eliminates gig worker double-booking at the storage engine level. | Database Lead |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.1 & L1.2: Volumetric Model & Traffic Parameters
* `workload_domain`: Operational activity category (`Job Applications`, `Candidate Search`, `Gig Milestones`, `Profile Updates`).
* `baseline_daily_volume`: Standard daily transaction count.
* `peak_burst_multiplier`: Business burst factor (e.g. 25x for campus hiring, 15x for payroll, 10x for recruiter sourcing).
* `derived_peak_tps`: Calculated peak transaction rate per second.
* `provisioned_capacity_target`: Peak TPS multiplied by 1.5x safety headroom (284 TPS target).
* `record_geometry`: Calculated byte footprint per entity (`Candidate Profile`: 4.0 KB, `Job Application`: 1.024 KB).

### Section L1.3 & L1.4: Latency & Availability Parameters
* `query_id`: Unique identifier for core benchmark queries (`Q1` to `Q7`).
* `latency_sla`: Warm-cache execution percentiles (`p50`, `p95`, `p99`) measured in milliseconds.
* `annual_availability`: Service uptime percentage (Target: $\ge 99.95\%$, maximum 4.38 hours unplanned downtime/year).
* `rpo_target`: Recovery Point Objective (Target: $\le 1.0\text{ minute}$ via synchronous WAL streaming).
* `rto_target`: Recovery Time Objective (Target: $\le 15.0\text{ minutes}$ via automated standby promotion).

### Section L1.7: Master NFR Register (`NFR-01` to `NFR-15`)
* `nfr_id`: Unique identifier (`NFR-01` to `NFR-15`). Mandatory.
* `category`: Architectural category (`Throughput`, `Latency`, `Resilience`, `Security`, `Concurrency`, `Compliance`, `Accessibility`, `Scalability`).
* `metric_name`: Formal quality dimension name.
* `target_value`: Quantitative target threshold with unit.
* `test_method`: Concrete verification tool and harness (e.g. `pgbench`, `EXPLAIN (ANALYZE, BUFFERS)`, `axe-core`, partition pruning scripts).
* `architectural_derivation`: Mathematical and operational justification explaining how the target was calculated.
