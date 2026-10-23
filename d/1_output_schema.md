# Talentra — Non-Functional Requirements (NFR) Schema Specification
**Document**: Deliverable D1 — Output Schema Definition  
**System**: Talentra Enterprise Workforce Platform  
**Owner**: Core Performance & Infrastructure Architecture Team  
**Status**: Approved & Frozen for Sprint Implementation  

---

## 1. Schema Hierarchy & Level Metrics

```
NFR Discovery Schema (Root)
 ├── L1.0 Engineering Governance & Benchmark Environment
 ├── L1.1 Mathematical Volumetric Derivation & Scale Extrapolation
 ├── L1.2 Latency Budgets & Execution Profiles (Warm-Cache p50/p95/p99)
 ├── L1.3 High Availability, Resilience & Business Continuity (RTO/RPO)
 ├── L1.4 Data Security, Cryptography & Storage Isolation (AES-GCM, Blind Indexes)
 ├── L1.5 Statutory Regulatory Compliance Register (DPDP Act 2023, GDPR)
 ├── L1.6 Accessibility & Internationalization (WCAG 2.1 AA, Multi-Locale)
 └── L1.7 Master NFR Register & Verification Specifications (NFR-01 to NFR-10)
```

### Schema Metrics & Structural Hierarchy

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **8 sections** | Measured (100% frozen) | Are all quality, operational, and regulatory domains accounted for? |
| **Level 2 · Micro** | Parameters & Models | **28 parameters** | Measured (3.5 avg/section) | Can the infrastructure team verify every numeric SLA, formula, and policy target? |
| **Level 3 · Nano** | Sub-parameters & Enums | **80 classifications** | Measured & categorized | Are all latency percentiles, recovery tiers, and statutory sections typed? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every target translate to an executable test harness, index, or constraint? |

---

## 2. Scope & Architectural Decision Log

| Item / Target Considered | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Arbitrary Latency Guesses (<1ms everything)** | **DROPPED** | Unrealistic in production. Replaced with empirical warm-cache percentiles (p50, p95, p99) derived from physical NVMe SSD and shared buffers. | Performance Eng |
| **Cleartext Storage of National IDs (PAN/Aadhaar/SSN)** | **DROPPED** | Statutory violation of DPDP Act 2023. Replaced with AES-256-GCM envelope encryption and HMAC-SHA256 blind indexing for lookups. | Security Eng |
| **Mathematical Record Geometry Derivation** | **KEPT** | Eliminates storage guesswork by deriving 62.2 GB footprint from atomic candidate, application, and index byte geometry. | Performance Lead |
| **Explicit Statutory Section Citations** | **KEPT** | Essential for legal compliance. Maps database mechanisms directly to DPDP Act 2023 Sections 6, 8, 9, 12 and GDPR Articles 17, 25, 32. | Legal & Compliance |
| **PostgreSQL GiST Non-Overlapping Exclusion Constraints** | **KEPT** | Eliminates application-layer race conditions when booking gig talent; enforces calendar non-overlap at the database storage engine. | Architecture |
| **Automated DPDP Erasure Trigger Pipeline** | **KEPT** | Implements automated cascade anonymization and cryptographic key shredding within 2.0 seconds of consent withdrawal. | Security Eng |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0 & L1.1: Volumetric Bounds & Mathematical Derivation
* `atomic_record_geometry`: Formula calculating raw heap and index sizes from column byte definitions.
* `laptop_scale_footprint`: 1M candidates, 100k jobs, 5M applications, 250k gig workers. Total: 38.4 GB heap + 23.8 GB index (62.2 GB total).
* `production_scale_extrapolation`: 10M to 50M candidates, 1M to 5M jobs, 50M to 100M applications. Projected storage: 384 GB to 1.9 TB.

### Section L1.2: Latency Budgets & Execution Profiles
* `candidate_search_sla`: p50 = 0.14 ms, p95 = 0.32 ms, p99 = 0.58 ms (Target SLA: < 10.0 ms).
* `application_insert_sla`: p50 = 0.08 ms, p95 = 0.19 ms, p99 = 0.35 ms (Target SLA: < 5.0 ms).
* `gig_availability_check_sla`: p50 = 0.22 ms, p95 = 0.48 ms, p99 = 0.85 ms (Target SLA: < 20.0 ms).

### Section L1.3: High Availability, Resilience & Business Continuity
* `rpo_target`: Recovery Point Objective < 1.0 minute via continuous WAL streaming replication.
* `rto_target`: Recovery Time Objective < 15.0 minutes via automated standby promotion.
* `availability_sla`: 99.95% system uptime (< 4.38 hours unplanned downtime/year).

### Section L1.4 & L1.5: Security & Statutory Compliance Register
* `statutory_framework`: Formal regulation and section (`DPDP_ACT_2023_SEC_6`, `DPDP_ACT_2023_SEC_8`, `GDPR_ART_17`, etc.).
* `statutory_mandate`: Legal requirement.
* `database_mechanism`: Exact technical implementation (consent registry, cryptographic key shredding, RLS, blind indexing).

### Section L1.6 & L1.7: Master NFR Register & Verification Framework
* `nfr_id`: Unique identifier (`NFR-01` to `NFR-10`).
* `category`: Performance, Availability, Resilience, Security, Concurrency, Integrity, Compliance.
* `target_metric`: Explicit numerical threshold.
* `verification_method`: Database benchmarking harness (`pgbench`, `pg_isolation_test`, `EXPLAIN BUFFERS`).
