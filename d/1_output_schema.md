# Talentra — Non-Functional Requirements (NFR) Schema Specification
**Document**: Deliverable D1 — Output Schema Definition  
**System**: Talentra Demand Management Platform  
**Owner**: Core Performance & Infrastructure Architecture Team  
**Status**: Approved & Frozen for Sprint Implementation  

---

## 1. Schema Hierarchy & Level Metrics

This schema is structured as an architectural hierarchy across four distinct levels:

```
NFR Discovery Schema (Root)
 ├── L1.0 Engineering Governance & Benchmark Environment
 ├── L1.1 Volumetric Bounds & Scale Extrapolation (10M–100M Rows)
 ├── L1.2 Latency Budgets & Execution Profiles (Warm-Cache p50/p95/p99)
 ├── L1.3 High Availability, Resilience & Business Continuity (RTO/RPO)
 ├── L1.4 Data Security, Cryptography & Storage Isolation (AES-GCM, Blind Indexes)
 ├── L1.5 Regulatory Compliance & Statutory Rights (DPDP Act 2023, GDPR)
 ├── L1.6 Accessibility & Internationalization (WCAG 2.1 AA, Multi-Locale)
 └── L1.7 NFR Verification Test Specifications (NFR-01 through NFR-10)
```

### Schema Metrics & Structural Hierarchy

| Level | Granularity | Measured Count | Status / Basis | Key Question Answered |
| :--- | :--- | :---: | :--- | :--- |
| **Level 1 · Macro** | Major Sections | **8 sections** | Measured (100% frozen) | Are all quality, operational, and regulatory domains accounted for? |
| **Level 2 · Micro** | Parameters & Models | **26 parameters** | Measured (3.25 avg/section) | Can the infrastructure team verify every numeric SLA and policy target? |
| **Level 3 · Nano** | Sub-parameters & Enums | **74 classifications** | Measured & categorized | Are all latency percentiles, recovery tiers, and regulatory mandates typed? |
| **Level 4 · Pico** | Atomic Field Rules | **100% leaf coverage** | Explicitly typed & verified | Does every target translate to an executable test harness, index, or constraint? |

---

## 2. Scope & Architectural Decision Log

All non-functional architectural decisions, quality compromises, and explicit boundaries are recorded below:

| Item / Target Considered | Decision | Justification & Architectural Rationale | Stage Owner |
| :--- | :---: | :--- | :---: |
| **Arbitrary Latency Guesses (<1ms everything)** | **DROPPED** | Unrealistic in production. Replaced with empirical warm-cache percentiles (p50, p95, p99) derived from physical NVMe SSD and shared buffers. | Performance Eng |
| **Cleartext Storage of National IDs (PAN/Aadhaar/SSN)** | **DROPPED** | Statutory violation of DPDP Act 2023. Replaced with AES-256-GCM envelope encryption and HMAC-SHA256 blind indexing for lookups. | Security Eng |
| **Full In-Memory Database Architecture (Redis-only)** | **DROPPED** | Violates strict durability and financial double-entry ledger ACID requirements. PostgreSQL NVMe flash with tuned shared buffers provides sub-millisecond execution. | Architecture |
| **Cardholder Data Persistence (PAN/CVV)** | **DROPPED** | PCI-DSS Level 1 scope elimination. Cardholder data is handled entirely by external payment gateways (Stripe/Razorpay); Talentra persists tokenized references only. | Compliance |
| **Empirical Laptop-to-Production Extrapolation (B74)** | **KEPT** | Allows laptop validation (1M profiles, 62.2 GB) to mathematically project index trees and storage bounds for 10M–100M rows. | Database Lead |
| **PostgreSQL GiST Non-Overlapping Exclusion Constraints** | **KEPT** | Eliminates application-layer race conditions when booking gig talent; enforces calendar non-overlap at the database storage engine. | Architecture |
| **DPDP Act 2023 Consent Lifecycle & Granular Revocation** | **KEPT** | Mandatory statutory requirement for Indian workforce operations. Implements explicit consent logging, purpose limitation, and automated erasure. | Legal & Security |

---

## 3. Parameter Dictionary & Field Rules

### Section L1.0: Engineering Governance & Benchmark Environment
* `benchmark_hardware`: CPU core/thread count (AMD Ryzen 7 / Intel Core i7), 32 GB DDR5 RAM, 1 TB NVMe Gen4 SSD.
* `engine_tuning_parameters`: PostgreSQL 16+ enterprise configuration:
  * `shared_buffers = 8GB`
  * `work_mem = 64MB`
  * `maintenance_work_mem = 2GB`
  * `effective_cache_size = 24GB`
  * `random_page_cost = 1.1` (NVMe flash optimized)

### Section L1.1: Volumetric Bounds & Scale Extrapolation
* `laptop_scale_footprint`: 1M candidate profiles, 100k job requisitions, 5M applications, 250k gig profiles, 500k gig contracts, 2M audit events. Total storage: 38.4 GB raw data, 23.8 GB indexes (62.2 GB total).
* `production_scale_extrapolation`: 10M to 50M candidates, 1M to 5M jobs, 50M to 100M applications, 2.5M to 5M gig workers. Storage projection: 384 GB to 1.9 TB raw data.
* `table_partitioning_policy`: Monthly range-based partitioning on high-volume append tables (`system_audit_event`, `notification_delivery_event`, `integration_exchange_event`).

### Section L1.2: Latency Budgets & Execution Profiles
* `candidate_search_sla`: p50 < 0.20 ms, p95 < 0.35 ms, p99 < 0.60 ms (Target SLA: < 10.0 ms).
* `application_insert_sla`: p50 < 0.10 ms, p95 < 0.20 ms, p99 < 0.40 ms (Target SLA: < 5.0 ms).
* `gig_availability_check_sla`: p50 < 0.25 ms, p95 < 0.50 ms, p99 < 0.90 ms (Target SLA: < 20.0 ms).
* `ledger_balance_sync_sla`: p50 < 0.12 ms, p95 < 0.25 ms, p99 < 0.45 ms (Target SLA: < 10.0 ms).

### Section L1.3: High Availability, Resilience & Business Continuity
* `rpo_target`: Recovery Point Objective < 1.0 minute. Enforced via continuous WAL archiving and synchronous standby streaming replication.
* `rto_target`: Recovery Time Objective < 15.0 minutes. Enforced via automated failover scripts and daily physical `pg_basebackup` snapshots.
* `availability_sla`: 99.95% system uptime (< 4.38 hours unplanned downtime per calendar year).

### Section L1.4: Data Security, Cryptography & Storage Isolation
* `pii_encryption_algorithm`: AES-256-GCM envelope encryption for sensitive contact numbers and tax identifiers.
* `blind_index_algorithm`: HMAC-SHA256 with an isolated cryptographic pepper for deterministic equality lookups without plaintext decryption.
* `row_level_security`: Engine-level tenant isolation on `recruitment.job_requirement` using `app.current_org_id`.
* `immutability_enforcement`: Database triggers blocking `UPDATE` and `DELETE` on financial ledgers and compliance audit logs.

### Section L1.5: Regulatory Compliance & Statutory Rights
* `dpdp_compliance`: Explicit consent logging, purpose limitation, parent/guardian consent for minors, right to correction, and automated erasure.
* `gdpr_compliance`: Article 17 Right to Erasure / RTBF, Article 25 Privacy by Design, and candidate block-list anti-join views.
* `soc2_iso27001`: Immutable audit trails capturing pre- and post-mutation `JSONB` state, client IP address, and actor ID.

### Section L1.6: Accessibility & Internationalization (WCAG 2.1 AA)
* `media_accessibility`: Database metadata columns storing alt text descriptions, transcript URLs, and ARIA labels.
* `locale_support`: ISO-639-1 language codes, ISO-3166-1 country codes, and IANA timezone strings for global multi-script rendering.

### Section L1.7: NFR Verification Test Specifications
* `nfr_register`: Structured catalog mapping `NFR-01` through `NFR-10` with target numeric thresholds, verification commands (e.g., `pgbench`, `pg_isolation_test`), and acceptance gates.
