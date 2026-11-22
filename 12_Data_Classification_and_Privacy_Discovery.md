# Deliverable Step 12: Comprehensive Data Classification and Privacy Discovery

**Platform:** Talentra Enterprise Workforce & Contingent Talent Marketplace  
**Document Reference:** Deliverable 12 — Definitive Data Classification, Privacy Architecture, & Regulatory Compliance Register  
**Target RDBMS & Storage:** PostgreSQL 16 (Tiered NVMe Storage, Row-Level Security, GiST Temporal Non-Overlap Constraints, KMS Application Envelope Encryption, S3/GCS Object Stores)  
**Total Platform Scope:** 13 Domain Schemas, 90 Logical Tables, 893 Database Columns Completely Classified  
**Preceding Discovery Baselines:** Step 06 Entity Discovery, Step 07 Attribute Discovery, Step 08 Lifecycle State Machines, Step 09 Logical ER Model, Step 10 Data Dictionary v1, Step 11 Data Rules and Constraints  
**Statutory Governance Framework:** India Digital Personal Data Protection Act, 2023 (DPDP Act 2023), GDPR (Regulation (EU) 2016/679 Art. 17 & 32 Principles for Global Candidate Mobility), ISO/IEC 27001:2022, SOC 2 Type II Trust Services Criteria (Privacy, Confidentiality, Security), Principle of Least Privilege (PoLP)  

---

## 1. Introduction and Scope

### 1.1 Executive Mandate and Privacy by Design
The **Talentra Data Classification and Privacy Register** establishes the architectural, cryptographic, and operational governance framework safeguarding every piece of data processed across the platform. In modern enterprise talent acquisition and contingent workforce platforms, candidate privacy, corporate compensation confidentiality, sovereign tax identifiers, and authentication secrets are primary attack vectors. 

Rather than treating data security and privacy compliance as an afterthought or an infrastructure-layer wrapper, Talentra enforces **Privacy by Design (PbD)** at schema inception. Every database table, column, foreign key relationship, index, and state transition discovered in Steps 06 through 11 is bound to an explicit classification tier, sensitivity rating, role-based access restriction, masking rule, retention schedule, and cryptographic lifecycle.

### 1.2 Enterprise Scope
The scope of this document encompasses all **90 logical database tables** and **893 physical columns** distributed across the 13 domain schemas:
1. `master_data` (11 tables): Sovereign reference taxonomies, ISO standard codes, and localized system copy.
2. `identity` (6 tables): Security principals, Argon2id credentials, RBAC authorizations, and multi-device sessions.
3. `organisation` (7 tables): Multi-tenant corporate accounts, subsidiaries, physical branches, encrypted tax identifiers, and recruiter seats.
4. `candidate` (9 tables): Unified 3NF candidate profiles, academic degrees, work histories, parsed resume search vectors, and privacy shields.
5. `recruitment` (5 tables): Enterprise hiring requisitions, salary bands, and structured screening questionnaires.
6. `application` (6 tables): 13-stage hiring state machine funnels, candidate questionnaire responses, interview feedback scorecards, and formal offers.
7. `sourcing` (4 tables): External staffing agency authorizations, talent nominations, and bulk multi-channel outreach campaigns.
8. `gig` (9 tables): Contingent freelance specialist profiles, service packages, temporal contracts, and milestone escrow balances.
9. `licensing` (3 tables): Enterprise subscription tiers, contract terms, and recurring monthly quota metering.
10. `billing` (8 tables): Append-only double-entry financial ledgers ($0.00 variance), checkout orders, invoices, and profile unlock receipts.
11. `engagement` (9 tables): Saved search alert criteria, direct in-app candidate-recruiter messaging, referrals, and campus placement cohorts.
12. `governance` (4 tables): Statutory DPDP Act 2023 consent tracking, per-user Data Encryption Keys (DEKs), tamper-evident SHA-256 audit logs, and retention policies.
13. `analytics` (9 tables): Kimball star schema dimensional reporting marts and fact tables powering executive intelligence.

### 1.3 Architectural Boundaries and Protection Spheres
To prevent security assumptions from conflating disparate tiers, this discovery model establishes four distinct protection spheres:
* **Storage Tier (Database & Disk):** Transparent Data Encryption (TDE), volume-level NVMe AES-256 hardware encryption, and isolated schema namespaces.
* **Application Tier (Memory & Processing):** Application-level envelope encryption (AES-256-GCM) with per-user Data Encryption Keys (DEKs) wrapped by an HSM-backed Key Encrypting Key (KEK); zero plaintext persistence of credentials.
* **Egress & Ingress Tier (Network & API):** TLS 1.3 transport encryption, API Data Transfer Object (DTO) response scrubbing, dynamic data masking, and role-based filtering.
* **Object Storage Tier (Files & Documents):** S3/GCS Server-Side Encryption with KMS Customer-Managed Keys (SSE-KMS), private access control lists (ACLs), and short-lived pre-signed download URLs ($\le 15	ext{ minutes}$).

---

## 2. Source Documents and Assumptions

### 2.1 Baseline Source Tracing
This document synthesizes and builds strictly upon the verified engineering baselines established in preceding phases:
* **Step 06 Entity Discovery (`talentra_redesigned_erl.md`):** Identifies 90 normalized business entities across 13 core modules.
* **Step 07 Attribute Discovery (`07_Attribute_Discovery.md`):** Defines technical data types, optionality, domain constraints, and initial sensitivity markers for all 893 attributes.
* **Step 08 Entity Lifecycle and State Machines (`08_Entity_Lifecycle_and_State_Machines.md`):** Maps 20 stateful entity state machines, identifying sensitive lifecycle events (e.g. `OFFER_ACCEPTED`, `ESCROW_RELEASED`, `PROFILE_DELETED`).
* **Step 09 Logical ER Model v0 (`09_Database_Tables_and_Relationships_Discovery.md`):** Establishes foreign key cardinalities, junction tables, and referential deletion constraints (`RESTRICT` vs `CASCADE` vs `SET NULL`).
* **Step 10 Data Dictionary v1 (`10_Data_Dictionary_v1.md`):** Authoritative 14-parameter technical catalogue of all 893 columns, business names, and derived formulas.
* **Step 11 Data Rules and Constraints (`11_Data_Rules_and_Constraints_Discovery.md`):** Master repository of 85 table-level rules (`DR-001` through `DR-085`) and 10 cross-table rules (`CTR-01` through `CTR-10`), including anti-join privacy shields and ledger invariance.

### 2.2 Core Architectural & Privacy Assumptions
1. **Multi-Tenancy & Global Candidate Mobility:** Corporate tenant entities (`organisation`, `recruitment`, `application`, `billing`) operate under strict multi-tenant schema isolation bound to `organisation_id`. Conversely, candidate principals (`identity.user_account`, `candidate.candidate_profile`) are global sovereign entities who freely apply across multiple tenant employers without their private profile data leaking between competing organizations.
2. **The Anti-Join Privacy Shield (`candidate_block_list`):** Employed candidates can actively search for new employment or gig engagements without fear of discovery by their current employer. Database queries enforcing `CTR-05` and `DR-024` apply a mandatory anti-join condition:
   $$	ext{WHERE } 	ext{recruiter.organisation\_id} 
otin (	ext{SELECT blocked\_organisation\_id FROM candidate\_block\_list WHERE candidate\_id = c.id})$$
3. **Quota-Gated Contact Disclosure:** Candidate direct contact coordinates (`email`, `phone_number`, `address_line1`) are shielded from recruiter searches. Contact coordinates are revealed only after a recruiter burns a paid profile unlock credit, generating an immutable record in `billing.profile_download_history` (`WF-07`, `REQ-04`).
4. **Cryptographic Key Shredding for Sub-Second Erasure:** To comply with Section 12 of the India DPDP Act 2023 (Right to Erasure) without initiating catastrophic cascading deletes across complex relational trees or invalidating financial ledger history, sensitive candidate PII attributes are encrypted using a dedicated per-user Data Encryption Key (DEK). Erasure is executed by zeroing/shredding the user's DEK in `governance.pii_encryption_key`, instantly rendering all historical ciphertext mathematically unrecoverable across the live database, read replicas, and WAL backups ($\le 2.0	ext{ seconds}$).
5. **Double-Entry Ledger Immutability:** Financial transaction records (`billing.wallet_ledger`) and statutory tax invoices (`billing.invoice`) are legally exempt from erasure under Indian tax legislation (Companies Act 2013 and GST Act). In erasure workflows, user references in billing ledgers are pseudonymized, while accounting amounts and transaction integrity remain strictly intact.

---

## 3. Data Classification Methodology

### 3.1 Primary Classification Tiers
Every column in the Talentra enterprise data store is assigned to exactly one of four mutually exclusive statutory classification tiers:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        Talentra Data Classification Tiers                              │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
        ┌───────────────────┬───────────────┴───────────────┬───────────────────┐
        ▼                   ▼                               ▼                   ▼
┌───────────────┐   ┌───────────────┐               ┌───────────────┐   ┌───────────────┐
│    Public     │   │   Internal    │               │ Confidential  │   │   Personal    │
│  Tier Level 0 │   │  Tier Level 1 │               │  Tier Level 2 │   │  Tier Level 3 │
└───────────────┘   └───────────────┘               └───────────────┘   └───────────────┘
```

1. **`Public` (Tier Level 0):**
   * *Definition:* Information intended for public distribution, freely accessible to unauthenticated Internet visitors and search engine indexing spiders without authentication or authorization barriers.
   * *Examples:* Sovereign country codes, ISO currency lists, global skills taxonomy, published job requisition titles and marketing descriptions, verified enterprise career site profiles.
   * *Exposure Risk:* Negligible. Zero commercial or privacy harm resulting from public disclosure.

2. **`Internal` (Tier Level 1):**
   * *Definition:* Operational business information restricted to authenticated platform users, tenant organizations, or automated background services. Accessible only within legitimate tenant session boundaries.
   * *Examples:* Primary surrogate keys (`id`), foreign keys, entity status flags (`status = 'ACTIVE'`), workflow audit timestamps (`created_at`, `updated_at`), record version integers, pipeline stage configurations, analytical surrogate keys, platform performance telemetry.
   * *Exposure Risk:* Low to Moderate. Unauthorized disclosure could reveal internal system architectures or workflow volumes but contains no direct financial secrets, credentials, or personal privacy data.

3. **`Confidential` (Tier Level 2):**
   * *Definition:* Highly sensitive proprietary business and operational assets requiring strict Role-Based Access Control (RBAC), multi-tenant tenancy isolation, and explicit audit logging. Accessible only to explicitly authorized personnel on a strict need-to-know basis.
   * *Examples:* Commercial billing ledger entries, wallet balances, escrow disbursement schedules, corporate recruitment commission splits, candidate interview evaluation notes, hiring manager feedback scorecards, structured screening question answer keys.
   * *Exposure Risk:* High. Unauthorized disclosure could cause severe commercial harm, breach client non-disclosure agreements (NDAs), spark employment litigation, or compromise corporate talent acquisition strategies.

4. **`Personal` (Tier Level 3):**
   * *Definition:* Any information relating to an identified or identifiable natural person (Data Principal under DPDP Act 2023 / Data Subject under GDPR). Subject to statutory privacy protections, affirmative consent registers, purpose binding, masking policies, and erasure mandates.
   * *Examples:* Candidate full legal names, personal email addresses, phone dialing numbers, residential street addresses, geographic GPS coordinates, dates of birth, parsed resume text, in-app direct chat messages, client login IP addresses.
   * *Exposure Risk:* High to Critical. Unauthorized disclosure triggers mandatory statutory regulatory breach notifications (DPDP Section 8(6)), statutory civil penalties (up to ₹250 Crores under DPDP Schedule), and irreversible candidate reputational damage.

---

### 3.2 Granular Data Subcategories
To enable specialized security controls, each attribute is further categorized into one of nine structural subcategories:

| Data Subcategory | Description | Standard Protection Requirement |
| :--- | :--- | :--- |
| **`Personally Identifiable Information (PII)`** | Direct identifiers that pinpoint an individual's personal identity. | Dynamic masking, DPDP consent tracking, per-user DEK encryption, sub-second erasure capability. |
| **`Authentication Credentials`** | Cryptographic secrets used to authenticate user principals and verify sessions. | Argon2id salted hashing, SHA-256 session digests, strict write-only storage, zero log exposure. |
| **`Financial Information`** | Monetary values, ledger balances, invoices, payment orders, and tax identifiers. | Double-entry balance invariance, AES-256-GCM encryption for Tax IDs, HMAC blind indexing, 8-year statutory retention. |
| **`Employment Information`** | Candidate career history, education degrees, salary expectations, and interview scorecards. | Anti-join privacy shield protection, candidate privacy mode masking, hiring panel RBAC isolation. |
| **`Communication Records`** | Private messaging threads, recruiter outreach text, and dispatched notifications. | Participant-only access isolation, ephemeral notification purge lifecycles (90 days). |
| **`Uploaded Documents & Files`** | Binary file storage pointers for candidate resumes, portfolio artifacts, and offer PDFs. | Private cloud object storage (S3/GCS), KMS SSE encryption, time-limited pre-signed URLs ($\le 15	ext{ min}$). |
| **`Security & Audit Information`** | Audit trail events, immutable tamper hashes, forensic IP addresses, and KMS key metadata. | Append-only database rules, SHA-256 tamper hash chaining, strict immutability, zero-delete audit policy. |
| **`Business Operations`** | Enterprise tenant profiles, job requisitions, departmental units, and taxonomy mappings. | Multi-tenant schema isolation, standard tenant administrator RBAC. |
| **`System Metadata`** | Technical surrogate identifiers, relational foreign keys, timestamps, and optimistic locking versions. | Standard PostgreSQL relational integrity constraints, foreign key referential enforcement. |

---

### 3.3 Sensitivity Levels (L0 through L4)
Talentra applies a 5-tier sensitivity rating system to dictate physical storage encryption, network masking, and logging restrictions:

* **`L0 - Public`**: Unrestricted public data. Cached on public Edge CDNs; zero masking required.
* **`L1 - Internal / Low`**: Operational metadata and general business attributes. Protected by TLS 1.3 in transit and PostgreSQL multi-tenant isolation.
* **`L2 - Confidential / Moderate`**: Proprietary financial and evaluation data. Restricted to designated corporate roles (Org Admin, Finance Auditor, Hiring Manager). Excluded from general logging.
* **`L3 - Personal / High`**: Direct candidate PII, resumes, and communications. Subject to dynamic UI/API masking until explicit authorization/unlock. Governed by DPDP Act 2023.
* **`L4 - Restricted / Critical`**: Cryptographic secrets, authentication hashes, KMS Data Encryption Keys, and raw sovereign tax identifiers. Application-layer envelope encryption or one-way salted hashing mandatory. Direct database query access strictly blocked; accessible solely via dedicated security daemons.

---

### 3.4 Classification Decision Tree
To ensure consistent, objective classification across all 893 attributes, data architects follow this deterministic decision flow:

```
               [ Does the column store or identify a natural person? ]
                                   │
                  ┌────────────────┴────────────────┐
                 YES                                NO
                  │                                 │
     [ Is it an Auth Secret or IP? ]      [ Does it store monetary, tax, or keys? ]
         │                  │                    │                   │
        YES                 NO                  YES                  NO
         │                  │                    │                   │
  ┌───────────────┐  ┌───────────────┐    ┌───────────────┐   [ Is it intended for open web? ]
  │ Confidential  │  │   Personal    │    │ Confidential  │          │               │
  │ L4: Cred/Key  │  │    L3: PII    │    │ L2/L4: Fin/Key│         YES              NO
  │ L3: Client IP │  │  (Candidate)  │    └───────────────┘          │               │
  └───────────────┘  └───────────────┘                        ┌──────────────┐ ┌──────────────┐
                                                              │    Public    │ │   Internal   │
                                                              │  L0: Public  │ │ L1: Metadata │
                                                              └──────────────┘ └──────────────┘
```

---

## 4. Complete Data Classification Register

This register provides an exhaustive, column-level classification for **all 893 database columns** across **all 90 tables** spanning the 13 domain modules of the Talentra Platform.
Each entry specifies the primary **Classification**, **Data Category**, **Sensitivity Tier**, **Business Purpose**, and **Access Restriction**.

### 4.1 Module: `master_data` — Master Reference Data & Localization
**Domain Scope:** Global sovereign reference taxonomies, ISO currencies, geographies, and localized UI copy.  
**Schema Metrics:** 11 Tables | 89 Columns  

#### Table: `master_data.country`
*Sovereign national jurisdictions conforming to ISO 3166-1 alpha-2 and alpha-3 standards.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key identifying the country record. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`iso_alpha2_code`** | `Public` | Business Operations | `L0 - Public` | Two-letter ISO 3166-1 country code used for standardized mapping. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`iso_alpha3_code`** | `Public` | Business Operations | `L0 - Public` | Three-letter ISO 3166-1 country code for customs and reporting. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`country_name`** | `Public` | Business Operations | `L0 - Public` | Official English name of the sovereign nation. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`phone_dialing_code`** | `Public` | Business Operations | `L0 - Public` | International E.164 telecommunication prefix. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`currency_code`** | `Public` | Business Operations | `L0 - Public` | Default sovereign currency code matching ISO 4217. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Operational flag indicating whether the country is active for business. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`sort_order`** | `Public` | Business Operations | `L0 - Public` | Display sort order for UI dropdown rendering. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Timestamp at which the record was created. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Timestamp of most recent record update. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.state`
*First-level administrative subdivision (state, province, territory) within a sovereign country.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key identifying the administrative state. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`country_id`** | `Public` | Business Operations | `L0 - Public` | Foreign key identifying the parent sovereign country. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`state_code`** | `Public` | Business Operations | `L0 - Public` | Standardized administrative state or province abbreviation. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`state_name`** | `Public` | Business Operations | `L0 - Public` | Full official name of the state or province. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Operational availability flag. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`sort_order`** | `Public` | Business Operations | `L0 - Public` | Administrative sort order within country. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Timestamp at which the state was recorded. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Timestamp of most recent update. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.city`
*Metropolitan or municipal locality supporting radial distance searches and location faceting.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key identifying the city or municipality. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`country_id`** | `Public` | Business Operations | `L0 - Public` | Foreign key identifying sovereign national territory. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`state_id`** | `Public` | Business Operations | `L0 - Public` | Foreign key identifying administrative parent state. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`city_name`** | `Public` | Business Operations | `L0 - Public` | Standardized English name of the city or municipality. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`latitude`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Geographic latitude coordinate for radial GIS lookups. | Candidate Self (P-06) and Verified Hiring Employer. Masked to City/State level in public search results. |
| **`longitude`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Geographic longitude coordinate for radial GIS lookups. | Candidate Self (P-06) and Verified Hiring Employer. Masked to City/State level in public search results. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Operational availability flag for search index faceting. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Creation audit timestamp in UTC. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.currency`
*ISO 4217 sovereign currency codes defining monetary symbols and physical decimal arithmetic precision.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`currency_code`** | `Public` | Business Operations | `L0 - Public` | Three-letter ISO 4217 currency identifier used as primary key. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`currency_name`** | `Public` | Business Operations | `L0 - Public` | Full official English currency name. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`currency_symbol`** | `Public` | Business Operations | `L0 - Public` | Display currency symbol for localized client presentation. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`decimal_precision`** | `Public` | Business Operations | `L0 - Public` | Number of fractional decimal places supported (e.g. 2 for USD, 0 for JPY). | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`iso_numeric_code`** | `Public` | Business Operations | `L0 - Public` | ISO 4217 numeric currency code for banking exchanges. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Indicates whether the currency is selectable for transactions. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Creation timestamp in UTC. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.language`
*Standardized human languages conforming to ISO 639-1 supporting multilingual UI and resume tagging.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`language_code`** | `Public` | Business Operations | `L0 - Public` | Two-letter ISO 639-1 code used as primary key. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`language_name`** | `Public` | Business Operations | `L0 - Public` | Standard English name of the language. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`native_name`** | `Public` | Business Operations | `L0 - Public` | Endonym name rendered in native typography. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_rtl`** | `Public` | Business Operations | `L0 - Public` | Flag indicating right-to-left layout rendering (e.g. Arabic, Hebrew). | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Active availability flag for UI translation and profiling. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Record creation timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Record last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.industry`
*Standardized economic sectors and industry classifications (e.g. IT, Healthcare, Finance).*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key identifying the industry sector. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`industry_code`** | `Public` | Business Operations | `L0 - Public` | Unique programmatic identifier for the industry. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`industry_name`** | `Public` | Business Operations | `L0 - Public` | Human-readable industry name. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`description`** | `Public` | Business Operations | `L0 - Public` | Contextual scope of the industrial sector. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Flag indicating whether the sector is active. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`sort_order`** | `Public` | Business Operations | `L0 - Public` | UI dropdown presentation priority. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Record creation timestamp in UTC. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.job_role`
*Standardized occupational roles and functional job titles linked to industrial sectors.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key identifying the occupational role. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`industry_id`** | `Public` | Business Operations | `L0 - Public` | Foreign key identifying the parent industry sector. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`role_code`** | `Public` | Business Operations | `L0 - Public` | Programmatic code for normalized job matching. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`role_title`** | `Public` | Business Operations | `L0 - Public` | Standard display title of the occupational job role. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`description`** | `Public` | Business Operations | `L0 - Public` | Role definition and responsibility boundary. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Active status flag for requisition posting. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`sort_order`** | `Public` | Business Operations | `L0 - Public` | Display ordering within industry hierarchy. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Creation timestamp in UTC. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.skill`
*Standardized technical, functional, and domain competencies used for resume matching and job requirements.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key identifying the skill competency. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`skill_code`** | `Public` | Business Operations | `L0 - Public` | Unique normalized uppercase identifier. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`skill_name`** | `Public` | Business Operations | `L0 - Public` | Display name of the skill competency. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`category`** | `Public` | Business Operations | `L0 - Public` | Competency classification category (e.g. LANGUAGE, FRAMEWORK, DATABASE). | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_verified`** | `Public` | Business Operations | `L0 - Public` | Indicates whether the skill is platform-verified vs user-suggested. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Operational availability flag. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Creation audit timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.qualification`
*Standardized academic degrees, diplomas, and certifications conforming to national education frameworks.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key identifying the qualification level. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`qualification_code`** | `Public` | Business Operations | `L0 - Public` | Unique programmatic code for the qualification. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`qualification_name`** | `Public` | Business Operations | `L0 - Public` | Full academic degree or certification title. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`qualification_level`** | `Public` | Business Operations | `L0 - Public` | Academic tier hierarchy. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`field_of_study`** | `Public` | Business Operations | `L0 - Public` | Specialization or major branch of study. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_active`** | `Public` | Business Operations | `L0 - Public` | Operational active flag. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`sort_order`** | `Public` | Business Operations | `L0 - Public` | Dropdown sorting priority. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Creation audit timestamp in UTC. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.ui_translation_key`
*Immutable programmatic string keys decoupling user interface labels from localized copy.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key for the translation key descriptor. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`translation_key`** | `Public` | Business Operations | `L0 - Public` | Programmatic translation key referenced by frontends. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`category`** | `Public` | Business Operations | `L0 - Public` | UI screen or feature category module. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`description`** | `Public` | Business Operations | `L0 - Public` | Translator guidance describing context of string. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Creation timestamp in UTC. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

#### Table: `master_data.ui_translation`
*Localized text copy mapping programmatic UI translation keys to sovereign languages with English fallback.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Public` | Business Operations | `L0 - Public` | Surrogate primary key for the localized translation entry. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`key_id`** | `Public` | Business Operations | `L0 - Public` | Foreign key identifying the parent translation key. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`language_code`** | `Public` | Business Operations | `L0 - Public` | Foreign key identifying the target human language. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`translated_text`** | `Public` | Business Operations | `L0 - Public` | Localized string copy rendered to end users. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`is_reviewed`** | `Public` | Business Operations | `L0 - Public` | Indicates if translation was verified by professional linguist. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`created_at`** | `Public` | Business Operations | `L0 - Public` | Creation audit timestamp in UTC. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |
| **`updated_at`** | `Public` | Business Operations | `L0 - Public` | Last update timestamp. | Unrestricted Public Read Access. Platform Super Admin (P-01) Write Access. |

### 4.2 Module: `identity` — Identity & Access Management
**Domain Scope:** Zero-trust authentication principals, Argon2id credentials, RBAC authorizations, and multi-device sessions.  
**Schema Metrics:** 6 Tables | 66 Columns  

#### Table: `identity.user_account`
*Core identity principal representing individual human actors across all tenant domains.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the user principal. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`email`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Normalized lowercase email address serving as login username. | Candidate Self (P-06), Org Admin (P-02), and Unlocked Recruiter (P-03). Masked until paid profile credit consumed. |
| **`phone_country_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Sovereign telecommunication country prefix. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`phone_number`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Standardized E.164 contact telephone number. | Candidate Self (P-06), Org Admin (P-02), and Unlocked Recruiter (P-03). Masked until paid profile credit consumed. |
| **`user_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Primary persona classification for login routing. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`account_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Operational lifecycle state of user account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_email_verified`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cryptographic verification status of email address. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_phone_verified`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cryptographic OTP verification status of phone. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`two_factor_enabled`** | `Internal` | Business Operations | `L1 - Internal / Low` | Indicates whether multi-factor authentication is active. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`failed_login_attempts`** | `Internal` | Business Operations | `L1 - Internal / Low` | Consecutive failed password attempts counter. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`locked_until`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp until which account is locked after brute force. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`last_login_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp of most recent successful user authentication. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Timestamp of account registration. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | Actor ID who initiated account creation. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Timestamp of latest account profile update. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | Actor ID of updater. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft deletion timestamp for regulatory compliance. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `identity.user_credential`
*Cryptographically secure password credentials hashed with Argon2id to resist GPU cracking.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the credential record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning user account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`password_hash`** | `Confidential` | Authentication Credentials | `L4 - Restricted / Critical` | Argon2id cryptographic digest string. | Automated Auth Daemon (P-12) Only. Direct SQL/API read strictly prohibited; verified via Argon2id/SHA256. |
| **`password_salt`** | `Confidential` | Authentication Credentials | `L4 - Restricted / Critical` | Cryptographically secure random per-user salt. | Automated Auth Daemon (P-12) Only. Direct SQL/API read strictly prohibited; verified via Argon2id/SHA256. |
| **`hash_algorithm`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cryptographic hashing algorithm designation. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`password_changed_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when current password was set. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`must_change_password`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag forcing password change on next login (e.g. temporary credentials). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `identity.role`
*Standardized platform security roles defining permission sets across the 11 architecture modules.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the role entity. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`role_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Unique programmatic code representing the security role. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`role_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Human-readable role designation. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`role_scope`** | `Internal` | Business Operations | `L1 - Internal / Low` | Scope boundary of the role authority. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`description`** | `Internal` | Business Operations | `L1 - Internal / Low` | Functional responsibility boundaries of role. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_system_role`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag preventing administrative deletion of core platform roles. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_active`** | `Internal` | Business Operations | `L1 - Internal / Low` | Operational availability flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `identity.user_role`
*Associative mapping table assigning granular security roles to authenticated user principals.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the role grant. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying the assigned user account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`role_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying the granted security role. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`granted_by`** | `Internal` | Business Operations | `L1 - Internal / Low` | User ID of administrator who authorized the role assignment. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`granted_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when role became effective. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`expires_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Optional expiration timestamp for temporary or break-glass access. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_active`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag indicating whether role grant is actively enforced. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `identity.user_active_session`
*Enforces strict concurrent device login limits per user account based on subscription licensing rules.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the active login session. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying the authenticated user. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`session_token_hash`** | `Confidential` | Authentication Credentials | `L4 - Restricted / Critical` | SHA-256 hash of issued Bearer JWT session token. | Automated Auth Daemon (P-12) Only. Direct SQL/API read strictly prohibited; verified via Argon2id/SHA256. |
| **`device_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Client hardware/browser fingerprint identifier. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`device_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Client form factor categorization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`client_ip`** | `Personal` | Security & Audit Information | `L3 - Personal / High` | IPv4 or IPv6 network address of authenticating client. | Security Daemon (P-12) and Privacy Compliance Officer (P-11). Forensic access only; excluded from standard app logs. |
| **`user_agent`** | `Personal` | Security & Audit Information | `L3 - Personal / High` | Client HTTP browser user-agent header string. | Security Daemon (P-12) and Privacy Compliance Officer (P-11). Forensic access only; excluded from standard app logs. |
| **`started_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when session was initiated. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`last_activity_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp of most recent authorized API request. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`expires_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Session expiration time enforcing hard timeout. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`revoked_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp of explicit session termination or eviction. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`revocation_reason`** | `Internal` | Business Operations | `L1 - Internal / Low` | Audit explanation for session revocation. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `identity.service_api_key`
*Programmatic API access credentials for machine-to-machine integrations and ATS partners.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the API key. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning developer or service account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`key_prefix`** | `Internal` | Business Operations | `L1 - Internal / Low` | Public non-sensitive prefix for key identification and routing. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`key_hash`** | `Confidential` | Security & Audit Information | `L4 - Restricted / Critical` | SHA-256 cryptographic digest of complete API secret. | Cloud KMS Service Daemon (P-12) & Chief Security Officer (P-01) under dual-authorization control. |
| **`key_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Human-readable label identifying integration purpose. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`scopes`** | `Internal` | Business Operations | `L1 - Internal / Low` | JSON array of authorized RBAC permission scopes. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`rate_limit_per_minute`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Maximum permitted API invocations per 60-second window. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`last_used_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp of most recent API request using this key. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`expires_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Hard cryptographic expiration timestamp. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_active`** | `Internal` | Business Operations | `L1 - Internal / Low` | Operational availability flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`revoked_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when key was explicitly invalidated. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

### 4.3 Module: `organisation` — Multi-Tenant Corporate Accounts
**Domain Scope:** Corporate tenant accounts, subsidiaries, physical branches, encrypted tax IDs, and recruiter seats.  
**Schema Metrics:** 7 Tables | 72 Columns  

#### Table: `organisation.account`
*Top-level commercial tenant billing boundary grouping one or more legal business entities.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the commercial account. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`account_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Commercial or enterprise business account name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`account_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Commercial scale category. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`account_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Operational subscription billing status. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`billing_currency_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Default invoice currency code conforming to ISO 4217. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Account provisioning timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | Administrator user account initiating onboarding. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | Administrator performing last modification. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft delete timestamp for enterprise offboarding. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `organisation.organisation`
*Specific operating legal entity, subsidiary, or regional division within an enterprise account.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the organization entity. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`account_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent commercial billing account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`legal_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Full statutory registered corporate name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`trade_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Public brand name or DBA (Doing Business As) name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`company_registration_number`** | `Internal` | Business Operations | `L1 - Internal / Low` | Official statutory registration/CIN number. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`website_url`** | `Internal` | Business Operations | `L1 - Internal / Low` | Official corporate website address. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`industry_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying primary industrial sector. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`company_size_tier`** | `Internal` | Business Operations | `L1 - Internal / Low` | Employee headcount bracket. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`verification_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Corporate background and tax verification status. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`logo_url`** | `Internal` | Business Operations | `L1 - Internal / Low` | CDN URL to corporate emblem graphic. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | Administrator user account creating company record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | User modifying organization details. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft delete timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `organisation.organisation_location`
*Physical corporate work sites, branches, headquarters, and interview centers.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the location. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning organization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`location_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Site classification category. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`address_line1`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Physical street address line 1. | Candidate Self (P-06) and Verified Hiring Employer. Masked to City/State level in public search results. |
| **`address_line2`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Physical street address line 2 / Suite number. | Candidate Self (P-06) and Verified Hiring Employer. Masked to City/State level in public search results. |
| **`city_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying the municipality or city. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`state_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying administrative state. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`country_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying sovereign national territory. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`postal_code`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | National postal or ZIP code. | Candidate Self (P-06) and Verified Hiring Employer. Masked to City/State level in public search results. |
| **`is_primary`** | `Internal` | Business Operations | `L1 - Internal / Low` | Indicates primary registered headquarters location. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft delete timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `organisation.organisation_tax_identifier`
*Statutory corporate tax identifiers (GSTIN, EIN, VAT) stored with AES-256 encryption and HMAC blind indexing.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the tax identifier record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning organization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`country_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying sovereign jurisdiction. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`tax_id_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Statutory tax category designation. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`encrypted_tax_id`** | `Confidential` | Financial Information | `L4 - Restricted / Critical` | AES-256-GCM cipher payload of confidential tax identifier. | Tenant Org Admin (P-02) and Statutory Finance Auditor (P-11). Encrypted via AES-256-GCM; blind indexed via HMAC. |
| **`tax_id_blind_index`** | `Confidential` | Financial Information | `L4 - Restricted / Critical` | HMAC-SHA256 deterministic hash supporting exact-match queries. | Tenant Org Admin (P-02) and Statutory Finance Auditor (P-11). Encrypted via AES-256-GCM; blind indexed via HMAC. |
| **`verification_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Government registry cross-validation status. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`verified_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when validation API confirmed legitimacy. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `organisation.organisation_verification`
*Integration exchange log documenting external identity bureau cross-checks for employer legitimacy.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the verification transaction. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying inspected organization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`verification_provider`** | `Internal` | Business Operations | `L1 - Internal / Low` | External compliance verification gateway identifier. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`reference_number`** | `Internal` | Business Operations | `L1 - Internal / Low` | External transaction confirmation reference code. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`verification_outcome`** | `Internal` | Business Operations | `L1 - Internal / Low` | Compliance decision outcome. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`rejection_reason`** | `Internal` | Business Operations | `L1 - Internal / Low` | Explanation if background check failed. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`raw_payload_hash`** | `Internal` | Business Operations | `L1 - Internal / Low` | SHA-256 hash of external gateway JSON verification response. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`verified_by`** | `Internal` | Business Operations | `L1 - Internal / Low` | Compliance officer who reviewed verification manually. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`verified_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Completion timestamp of check. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `organisation.recruiter_seat_assignment`
*Binds internal talent acquisition recruiters to specific employer organizations under subscription quotas.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying recruiter seat allocation. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying employer organization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying recruiter user account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`seat_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Operational status of recruiter seat. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`assigned_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when seat was allocated. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`revoked_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when recruiter access was revoked. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | Administrator who assigned the recruiter seat. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `organisation.organisation_hierarchy`
*Models complex corporate parent-child ownership structures, operating subsidiaries, and business units.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the corporate relation. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`parent_organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent holding company. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`child_organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying subsidiary organization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`relationship_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Corporate legal relationship category. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`effective_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Calendar date when corporate ownership became legally effective. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

### 4.4 Module: `candidate` — Candidate Talent Profiles
**Domain Scope:** Unified 3NF candidate profiles, academic history, GIN trigram skills, resumes, and privacy shields.  
**Schema Metrics:** 9 Tables | 102 Columns  

#### Table: `candidate.candidate_profile`
*Comprehensive professional candidate talent profile consolidated in 3NF.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying candidate profile. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying authenticated user principal. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`first_name`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Legal given or personal name. | Candidate Self (P-06), Org Admin (P-02), and Unlocked Recruiter (P-03). Masked until paid profile credit consumed. |
| **`middle_name`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Secondary or middle name. | Candidate Self (P-06), Org Admin (P-02), and Unlocked Recruiter (P-03). Masked until paid profile credit consumed. |
| **`last_name`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Legal family name or surname. | Candidate Self (P-06), Org Admin (P-02), and Unlocked Recruiter (P-03). Masked until paid profile credit consumed. |
| **`display_name`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Professional public display name. | Candidate Self (P-06) and Sourcing Recruiters. Headline is public; summary subject to candidate privacy mode. |
| **`date_of_birth`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Candidate date of birth for statutory age verification. | Candidate Self (P-06), Org Admin (P-02), and Unlocked Recruiter (P-03). Masked until paid profile credit consumed. |
| **`gender`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Voluntary diversity reporting category. | Candidate Self (P-06) and Sourcing Recruiters. Headline is public; summary subject to candidate privacy mode. |
| **`headline`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Professional resume summary headline. | Candidate Self (P-06) and Sourcing Recruiters. Headline is public; summary subject to candidate privacy mode. |
| **`summary`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Unbounded biographical career overview. | Candidate Self (P-06) and Sourcing Recruiters. Headline is public; summary subject to candidate privacy mode. |
| **`current_city_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying primary residence municipality. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`total_experience_months`** | `Internal` | Business Operations | `L1 - Internal / Low` | Total verified professional work experience in months. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`current_salary_amount`** | `Personal` | Employment Information | `L3 - Personal / High` | Verified current annual compensation figure. | Candidate Self (P-06) and Unlocked Recruiter (P-03). Strictly hidden from unverified search queries. |
| **`expected_salary_amount`** | `Personal` | Employment Information | `L3 - Personal / High` | Target expected annual compensation figure. | Candidate Self (P-06) and Unlocked Recruiter (P-03). Strictly hidden from unverified search queries. |
| **`salary_currency_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Companion ISO 4217 currency code for compensation figures. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`notice_period_days`** | `Personal` | Employment Information | `L3 - Personal / High` | Contractual employment availability lead time in days. | Candidate Self (P-06) and Unlocked Recruiter (P-03). Strictly hidden from unverified search queries. |
| **`profile_completion_percentage`** | `Internal` | Business Operations | `L1 - Internal / Low` | Dynamic profile completeness score. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_profile_searchable`** | `Internal` | Business Operations | `L1 - Internal / Low` | Global visibility toggle allowing discovery in recruiter talent search. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Timestamp of profile creation. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | User principal who initiated creation. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Timestamp of latest profile modification. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | User principal who updated record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft deletion timestamp for regulatory right-to-be-forgotten. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `candidate.candidate_education`
*Chronological academic history, degrees earned, and grading performance.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying education credential. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning candidate profile. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`qualification_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying standardized degree taxonomy. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`institution_name`** | `Personal` | Employment Information | `L3 - Personal / High` | Full registered title of college or university. | Candidate Self (P-06) and Sourcing Recruiters. Anti-join shield hides candidate from blocked current employers. |
| **`field_of_study`** | `Personal` | Employment Information | `L3 - Personal / High` | Academic major or department. | Candidate Self (P-06) and Sourcing Recruiters. Anti-join shield hides candidate from blocked current employers. |
| **`start_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Academic program enrollment commencement date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`end_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Graduation or departure date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`grade_or_gpa`** | `Personal` | Employment Information | `L3 - Personal / High` | Final cumulative GPA or percentage achieved. | Candidate Self (P-06) and Sourcing Recruiters. Anti-join shield hides candidate from blocked current employers. |
| **`grade_system`** | `Internal` | Business Operations | `L1 - Internal / Low` | Grading taxonomy standard. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_completed`** | `Internal` | Business Operations | `L1 - Internal / Low` | Indicates whether graduation was successfully conferred. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record creation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `candidate.candidate_work_experience`
*Chronological employment history, corporate positions held, and functional achievements.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying employment tenure. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning candidate profile. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`company_name`** | `Personal` | Employment Information | `L3 - Personal / High` | Full corporate or organization employer name. | Candidate Self (P-06) and Sourcing Recruiters. Anti-join shield hides candidate from blocked current employers. |
| **`job_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Actual corporate title held during tenure. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`job_role_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying standardized occupational role. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`industry_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying industry sector. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`start_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Employment commencement date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`end_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Employment termination or resignation date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_current_job`** | `Internal` | Business Operations | `L1 - Internal / Low` | Indicates if candidate actively works here. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`description`** | `Personal` | Employment Information | `L3 - Personal / High` | Key achievements and responsibilities. | Candidate Self (P-06) and Sourcing Recruiters. Anti-join shield hides candidate from blocked current employers. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `candidate.candidate_skill`
*Associative entity linking candidates to verified competencies with proficiency ratings.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying candidate skill mapping. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`skill_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying master skill taxonomy. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`proficiency_level`** | `Internal` | Business Operations | `L1 - Internal / Low` | Self-assessed or tested competency rating. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`years_of_experience`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cumulative hands-on experience using skill. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_primary`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag highlighting core primary skills on search cards. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`last_used_year`** | `Internal` | Business Operations | `L1 - Internal / Low` | Most recent calendar year skill was actively used. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record creation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `candidate.candidate_project`
*Portfolio work samples, technical projects, patents, and open-source contributions.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying portfolio project. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning candidate profile. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`project_title`** | `Personal` | Employment Information | `L3 - Personal / High` | Title of technical initiative or portfolio work. | Candidate Self (P-06) and Sourcing Recruiters. Anti-join shield hides candidate from blocked current employers. |
| **`project_role`** | `Internal` | Business Operations | `L1 - Internal / Low` | Specific functional role played in project delivery. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`start_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Project inception date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`end_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Project completion or release date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`description`** | `Personal` | Employment Information | `L3 - Personal / High` | Technical architecture overview and impact. | Candidate Self (P-06) and Sourcing Recruiters. Anti-join shield hides candidate from blocked current employers. |
| **`project_url`** | `Internal` | Business Operations | `L1 - Internal / Low` | Public link to code repository or live demo. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`outcome`** | `Personal` | Employment Information | `L3 - Personal / High` | Quantified business or technical outcome. | Candidate Self (P-06) and Sourcing Recruiters. Anti-join shield hides candidate from blocked current employers. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record creation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `candidate.candidate_resume`
*Versioned CV/resume documents stored as object blobs with parsed tsvector search indexes.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying resume file record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying candidate profile. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`resume_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Display filename of resume artifact. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`storage_path`** | `Personal` | Uploaded Documents & Files | `L3 - Personal / High` | Encrypted object storage URI. | Candidate Self (P-06) and Unlocked Recruiter (P-03). Ephemeral time-bounded pre-signed object storage URL. |
| **`file_format`** | `Internal` | Business Operations | `L1 - Internal / Low` | Document MIME/file extension type. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`file_size_bytes`** | `Internal` | Business Operations | `L1 - Internal / Low` | Physical binary size in bytes. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`parsed_text_search`** | `Personal` | Uploaded Documents & Files | `L3 - Personal / High` | Extracted plaintext tokenized into tsvector for fast keyword search. | Candidate Self (P-06) and Unlocked Recruiter (P-03). Ephemeral time-bounded pre-signed object storage URL. |
| **`is_primary`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag indicating the default resume used for 1-click apply. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`version_number`** | `Internal` | Business Operations | `L1 - Internal / Low` | Incremental revision number. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Upload timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft deletion timestamp upon candidate replacement or purge. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `candidate.candidate_preference`
*Employment preferences, remote working arrangements, and geographic relocation criteria.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying preference settings. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`preferred_job_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Preferred contractual engagement type. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`preferred_work_mode`** | `Internal` | Business Operations | `L1 - Internal / Low` | Physical workplace arrangement preference. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`willing_to_relocate`** | `Internal` | Business Operations | `L1 - Internal / Low` | Indicates willingness to relocate geographically for work. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`preferred_locations_json`** | `Personal` | Employment Information | `L3 - Personal / High` | JSON array of preferred target employment cities. | Candidate Self (P-06) and Unlocked Recruiter (P-03). Strictly hidden from unverified search queries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last modification timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `candidate.candidate_block_list`
*Anti-join privacy shield preventing blocked employers and recruiters from discovering candidate records.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the block rule. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying the candidate establishing the shield. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`blocked_organisation_id`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Foreign key identifying blocked employer company. | Candidate Self (P-06) Only. System daemon enforces anti-join shield; employers cannot view their own block status. |
| **`blocked_recruiter_user_id`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Foreign key identifying blocked individual recruiter. | Candidate Self (P-06) Only. System daemon enforces anti-join shield; employers cannot view their own block status. |
| **`block_reason`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Candidate privacy note explaining block rationale. | Candidate Self (P-06) Only. System daemon enforces anti-join shield; employers cannot view their own block status. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Shield establishment timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `candidate.candidate_language`
*Linguistic proficiencies and communication competencies possessed by candidate.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying linguistic skill. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying candidate profile. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`language_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying sovereign language from master data. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`proficiency_level`** | `Internal` | Business Operations | `L1 - Internal / Low` | CEFR standard competency tier. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`can_read`** | `Internal` | Business Operations | `L1 - Internal / Low` | Reading literacy competency. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`can_write`** | `Internal` | Business Operations | `L1 - Internal / Low` | Written literacy competency. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`can_speak`** | `Internal` | Business Operations | `L1 - Internal / Low` | Verbal articulation competency. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

### 4.5 Module: `recruitment` — Job Requisitions & Screening
**Domain Scope:** Hiring demand requisitions, salary bands, and structured screening questionnaires.  
**Schema Metrics:** 5 Tables | 55 Columns  

#### Table: `recruitment.job_requisition`
*Core job requirement posting defining open headcount, salary boundaries, and qualifications.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the job requisition. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying employer corporate entity. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`posted_by_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying recruiter author. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`job_role_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying master occupational role. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`job_title`** | `Public` | Business Operations | `L0 - Public` | Public title of the employment opening. | Unrestricted Public Read Access once published to Career Portals. Recruiter/Hiring Mgr Write. |
| **`job_category`** | `Internal` | Business Operations | `L1 - Internal / Low` | Business category bracket mandated by brief. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`job_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Employment arrangement type. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`work_mode`** | `Internal` | Business Operations | `L1 - Internal / Low` | Workplace operational policy. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`vacancies_count`** | `Internal` | Business Operations | `L1 - Internal / Low` | Number of authorized positions to fill. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`city_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying target office location. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`min_experience_months`** | `Internal` | Business Operations | `L1 - Internal / Low` | Minimum required professional tenure. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`max_experience_months`** | `Internal` | Business Operations | `L1 - Internal / Low` | Maximum relevant experience bracket. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`min_salary_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Minimum fixed annual compensation band. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`max_salary_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Maximum fixed annual compensation band. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`salary_currency_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Companion ISO 4217 currency code. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_salary_negotiable`** | `Internal` | Business Operations | `L1 - Internal / Low` | Indicates if employer accommodates salary negotiations. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`job_description`** | `Public` | Business Operations | `L0 - Public` | Unbounded markdown job description. | Unrestricted Public Read Access once published to Career Portals. Recruiter/Hiring Mgr Write. |
| **`publish_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Lifecycle publication state. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`open_to_consultants`** | `Internal` | Business Operations | `L1 - Internal / Low` | Authorizes external staffing consultants to source candidates. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`application_deadline`** | `Internal` | Business Operations | `L1 - Internal / Low` | Hard closing cutoff date for submissions. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`published_at`** | `Public` | Business Operations | `L0 - Public` | Timestamp when posting went live. | Unrestricted Public Read Access once published to Career Portals. Recruiter/Hiring Mgr Write. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | User creating requisition record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | User updating requisition. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft delete timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `recruitment.job_requisition_skill`
*Associative entity defining mandatory vs preferred skill competencies for a job requisition.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying skill requirement. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`requisition_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying job opening. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`skill_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying master skill competency. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`requirement_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Competency criticality level. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`min_experience_months`** | `Internal` | Business Operations | `L1 - Internal / Low` | Minimum hands-on tenure required in this skill. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `recruitment.job_questionnaire`
*Screening assessment header configured per requisition with passing score threshold.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying questionnaire. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`requisition_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying target job opening. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`questionnaire_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Title of candidate pre-qualification form. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`passing_score_percentage`** | `Internal` | Business Operations | `L1 - Internal / Low` | Minimum score required to automatically clear screening. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_mandatory`** | `Internal` | Business Operations | `L1 - Internal / Low` | Blocks application submission until completed. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`version_number`** | `Internal` | Business Operations | `L1 - Internal / Low` | Questionnaire version tracking updates. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `recruitment.questionnaire_question`
*Individual screening questions with weighted point scoring and knockout rules.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying screening question. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`questionnaire_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent questionnaire. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`question_text`** | `Internal` | Business Operations | `L1 - Internal / Low` | Text prompt presented to candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`question_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Interactive input control category. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`weight_points`** | `Internal` | Business Operations | `L1 - Internal / Low` | Point weight awarded for fully correct response. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_disqualifying`** | `Internal` | Business Operations | `L1 - Internal / Low` | Knockout flag: incorrect answer triggers automatic disqualification. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`sort_order`** | `Internal` | System Metadata | `L1 - Internal / Low` | Sequential display position in screening form. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `recruitment.question_option`
*Pre-configured multiple-choice answers with associated score values.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying option choice. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`question_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent question. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`option_text`** | `Internal` | Business Operations | `L1 - Internal / Low` | Selectable choice label. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_correct`** | `Internal` | Business Operations | `L1 - Internal / Low` | Designates standard correct response. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`score_value`** | `Internal` | Business Operations | `L1 - Internal / Low` | Points awarded if selected by candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`sort_order`** | `Internal` | System Metadata | `L1 - Internal / Low` | Display ordering of options. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

### 4.6 Module: `application` — Application Funnel & Pipeline
**Domain Scope:** 13-stage hiring state machine funnels, candidate questionnaire answers, interview scorecards, and offers.  
**Schema Metrics:** 6 Tables | 63 Columns  

#### Table: `application.job_application`
*Core job application record governed by 13-stage finite state machine.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the job application. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`requisition_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying applied job requisition. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying applicant candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`resume_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying resume version submitted. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`application_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | 13-stage pipeline state machine milestone. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`screening_score`** | `Internal` | Business Operations | `L1 - Internal / Low` | Calculated score from screening questionnaire. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_passed_screening`** | `Internal` | Business Operations | `L1 - Internal / Low` | Automated pre-qualification result. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`source_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Channel or attribution origin of application. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`consultant_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Agency consultant who submitted application. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`applied_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Formal submission timestamp in UTC. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`withdrawn_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp if withdrawn by candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`rejection_reason`** | `Internal` | Business Operations | `L1 - Internal / Low` | Standardized explanation if application rejected. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft delete timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `application.application_question_answer`
*Persisted candidate screening questionnaire submissions with automated scores.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying answer response. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`application_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent application. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`question_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying answered question. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`selected_option_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying chosen option. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`free_text_answer`** | `Internal` | Business Operations | `L1 - Internal / Low` | Text input for open-ended questions. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`score_awarded`** | `Internal` | Business Operations | `L1 - Internal / Low` | Computed point score awarded for this answer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Answer submission timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `application.application_stage_history`
*Immutable state transition ledger documenting every stage movement across the hiring funnel.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying funnel transition. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`application_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying transitioned application. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`from_stage`** | `Internal` | Business Operations | `L1 - Internal / Low` | Source pipeline stage prior to move. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`to_stage`** | `Internal` | Business Operations | `L1 - Internal / Low` | Destination pipeline stage. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`changed_by_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Recruiter or automated system triggering stage move. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`stage_notes`** | `Internal` | Business Operations | `L1 - Internal / Low` | Contextual justification notes. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`transition_timestamp`** | `Internal` | Business Operations | `L1 - Internal / Low` | Exact chronological timestamp of state transition. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `application.job_interview`
*Scheduled interview rounds, calendar invitations, video conference links, and interview assignments.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying interview session. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`application_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying job application. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`interview_round`** | `Internal` | Business Operations | `L1 - Internal / Low` | Sequential interview stage sequence (e.g. Round 1, Round 2). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`interview_format`** | `Internal` | Business Operations | `L1 - Internal / Low` | Evaluation setting. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`scheduled_start_time`** | `Internal` | Business Operations | `L1 - Internal / Low` | Calendar start timestamp. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`scheduled_end_time`** | `Internal` | Business Operations | `L1 - Internal / Low` | Calendar conclusion timestamp. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`meeting_link`** | `Internal` | Business Operations | `L1 - Internal / Low` | Virtual video conference URL. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`interviewer_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Lead corporate interviewer user account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`interview_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Lifecycle status of interview appointment. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `application.interview_feedback`
*Structured quantitative evaluation and qualitative scorecard submitted by interviewer.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying evaluation scorecard. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`interview_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying completed interview. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`interviewer_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying evaluating interviewer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`technical_score`** | `Confidential` | Employment Information | `L2 - Confidential / Moderate` | Quantitative rating of domain technical competency (1.0 - 5.0). | Assigned Interviewer (P-05), Hiring Manager (P-04), and Corporate Recruiter (P-03). Confidential from Candidate. |
| **`cultural_score`** | `Confidential` | Employment Information | `L2 - Confidential / Moderate` | Quantitative rating of organizational culture and communication fit. | Assigned Interviewer (P-05), Hiring Manager (P-04), and Corporate Recruiter (P-03). Confidential from Candidate. |
| **`overall_score`** | `Confidential` | Employment Information | `L2 - Confidential / Moderate` | Composite summary performance score. | Assigned Interviewer (P-05), Hiring Manager (P-04), and Corporate Recruiter (P-03). Confidential from Candidate. |
| **`recommendation`** | `Confidential` | Employment Information | `L2 - Confidential / Moderate` | Definitive hiring recommendation verdict. | Assigned Interviewer (P-05), Hiring Manager (P-04), and Corporate Recruiter (P-03). Confidential from Candidate. |
| **`strengths`** | `Internal` | Business Operations | `L1 - Internal / Low` | Specific technical and behavioral advantages. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`weaknesses`** | `Internal` | Business Operations | `L1 - Internal / Low` | Identified development areas. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`feedback_notes`** | `Confidential` | Employment Information | `L2 - Confidential / Moderate` | Comprehensive qualitative review notes. | Assigned Interviewer (P-05), Hiring Manager (P-04), and Corporate Recruiter (P-03). Confidential from Candidate. |
| **`submitted_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Submission timestamp. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `application.job_offer`
*Formal corporate employment offer extended to candidate with salary terms and joining commitments.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the job offer. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`application_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying accepted job application. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`offered_salary_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Offered fixed base annual compensation. | Candidate Offeree (P-06), Hiring Manager (P-04), Recruiter (P-03), and Finance Auditor (P-11). |
| **`salary_currency_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Companion ISO 4217 currency code. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`joining_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Agreed start date of corporate employment. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`offer_validity_date`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Deadline by which candidate must accept or decline offer. | Candidate Offeree (P-06), Hiring Manager (P-04), Recruiter (P-03), and Finance Auditor (P-11). |
| **`offer_letter_storage_path`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Encrypted S3 bucket path to generated offer letter PDF. | Candidate Offeree (P-06), Hiring Manager (P-04), Recruiter (P-03), and Finance Auditor (P-11). |
| **`offer_status`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Lifecycle status of employment offer. | Candidate Offeree (P-06), Hiring Manager (P-04), Recruiter (P-03), and Finance Auditor (P-11). |
| **`responded_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when candidate accepted or rejected offer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | Hiring manager or recruiter issuing offer. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

### 4.7 Module: `sourcing` — Talent Sourcing & Staffing Agencies
**Domain Scope:** Staffing agency authorizations, candidate nominations, and bulk multi-channel outreach campaigns.  
**Schema Metrics:** 4 Tables | 39 Columns  

#### Table: `sourcing.consultant_authorization`
*Contracts granting third-party staffing agencies authorization to submit candidates for job openings.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the authorization. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`requisition_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying open job requisition. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`consultant_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying external staffing consultant. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`commission_rate_percentage`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Agreed placement agency commission percentage upon hire. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`authorization_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Lifecycle status of consultant partnership. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`authorized_by_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Employer hiring manager who granted permission. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`authorized_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when permission became active. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`expires_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cutoff date for candidate sourcing authorization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `sourcing.candidate_nomination`
*Candidate profiles formally submitted by authorized staffing consultants for corporate review.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the candidate nomination. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`authorization_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying active consultant sourcing agreement. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying submitted candidate profile. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`nomination_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Corporate review decision on consultant submission. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`review_notes`** | `Internal` | Business Operations | `L1 - Internal / Low` | Employer feedback on nomination quality. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`nominated_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when consultant submitted candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`reviewed_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when corporate recruiter took action. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `sourcing.outreach_campaign`
*Bulk candidate messaging batches across email, SMS, and WhatsApp consuming subscription credits.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the outreach campaign. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying employer running outreach. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_by_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Recruiter executing campaign. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`campaign_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Descriptive title of talent sourcing campaign. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`channel_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Communication dispatch channel. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`message_template`** | `Internal` | Business Operations | `L1 - Internal / Low` | Parameterized message template body. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`total_recipients_count`** | `Internal` | Business Operations | `L1 - Internal / Low` | Number of candidates targeted in campaign. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`credits_deducted`** | `Internal` | Business Operations | `L1 - Internal / Low` | Outreach credits deducted from subscription balance. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `sourcing.outreach_recipient`
*Granular recipient delivery status tracking open rates, link clicks, and candidate responses.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying campaign recipient. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`campaign_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent outreach campaign. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying targeted candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`delivery_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Message transmission status. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`sent_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when gateway accepted transmission. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`opened_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp candidate opened message. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`clicked_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp candidate clicked job requisition link. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`responded_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp candidate sent reply or applied. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`error_message`** | `Internal` | Business Operations | `L1 - Internal / Low` | Failure explanation if delivery bounced. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record creation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

### 4.8 Module: `gig` — Contingent Gig Marketplace
**Domain Scope:** Freelance specialist profiles, packaged services, temporal non-overlapping contracts, and milestone escrow.  
**Schema Metrics:** 9 Tables | 107 Columns  

#### Table: `gig.gig_worker_profile`
*Distinct freelance contractor profile tracking availability, day rates, and aggregate review ratings.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the gig worker profile. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying authenticated user account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`professional_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Public marketplace title for freelance services. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`bio_summary`** | `Internal` | Business Operations | `L1 - Internal / Low` | Detailed contractor biography. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`hourly_rate_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Standard hourly billing rate. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`daily_rate_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Discounted full-day engagement billing rate. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`rate_currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Companion ISO 4217 currency code. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`total_completed_gigs`** | `Internal` | Business Operations | `L1 - Internal / Low` | Total verified completed project milestones on platform. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`average_rating_score`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cumulative employer review rating average (1.00 - 5.00). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`availability_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Current commercial booking availability. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`portfolio_url`** | `Internal` | Business Operations | `L1 - Internal / Low` | External portfolio or verified code showcase. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Profile creation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last profile update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft deletion timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `gig.gig_worker_service`
*Discrete fixed-price or rate-based service offerings packaged by gig workers.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the service offering. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`worker_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying offering contractor. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`service_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Package title of consulting offering. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`service_category_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying industry sector. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`pricing_model`** | `Internal` | Business Operations | `L1 - Internal / Low` | Monetization structure. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`base_price_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Base fixed cost or hourly starting fee. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`price_currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Companion ISO 4217 currency code. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`delivery_time_days`** | `Internal` | Business Operations | `L1 - Internal / Low` | Estimated business turnaround days. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_active`** | `Internal` | Business Operations | `L1 - Internal / Low` | Operational visibility toggle. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `gig.gig_worker_availability`
*Discrete calendar availability slots published by gig workers for scheduling consultations.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying availability slot. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`worker_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying contractor. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`available_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Calendar date of available working window. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`start_time`** | `Internal` | Business Operations | `L1 - Internal / Low` | Daily window start time. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`end_time`** | `Internal` | Business Operations | `L1 - Internal / Low` | Daily window conclusion time. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_booked`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag indicating slot has been confirmed into a contract. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Slot publishing timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `gig.gig_request`
*Short-duration, project-based work requisition carrying start/end windows and defined pricing.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying project gig demand. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying client employer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`posted_by_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying client manager posting project. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Title of project demand. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`description`** | `Internal` | Business Operations | `L1 - Internal / Low` | Full project scope and deliverables. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`project_category_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying industry domain. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`budget_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Budget structure. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`budget_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Authorized project expenditure budget. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`budget_currency_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Companion ISO 4217 currency code. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`booking_window`** | `Internal` | Business Operations | `L1 - Internal / Low` | Target calendar start and completion window. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`request_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Lifecycle status of gig request. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`required_worker_count`** | `Internal` | Business Operations | `L1 - Internal / Low` | Number of contractors needed. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`deleted_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Soft deletion timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `gig.gig_proposal`
*Unidirectional application submitted by gig worker to an open gig request.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying bid proposal. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`request_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying gig request. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`worker_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying bidding contractor. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`cover_letter`** | `Internal` | Business Operations | `L1 - Internal / Low` | Technical proposal pitch and approach. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`proposed_rate_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Proposed price for total delivery. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`proposed_currency_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Companion ISO 4217 currency code. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`estimated_completion_days`** | `Internal` | Business Operations | `L1 - Internal / Low` | Turnaround commitment in calendar days. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`proposal_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Client review verdict on proposal. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`submitted_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when worker applied. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`reviewed_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when client acted on proposal. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `gig.gig_contract`
*Legally binding engagement with GiST temporal exclusion preventing concurrent double-booking.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying gig contract. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`request_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying originated request. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`proposal_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying accepted proposal. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`worker_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying contracted worker. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying hiring client employer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`contract_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Formal title of signed contract. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`agreed_window`** | `Internal` | Business Operations | `L1 - Internal / Low` | Calendar time range locked for exclusive engagement. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`agreed_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Total contracted compensation. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`currency_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Companion ISO 4217 currency code. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`contract_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Lifecycle status of engagement. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`external_fulfillment_reference`** | `Internal` | Business Operations | `L1 - Internal / Low` | Handoff identifier to third-party delivery management system. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Contract generation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`signed_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when both parties signed. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`completed_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when final sign-off was conferred. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `gig.gig_milestone`
*Progress milestones with deliverable verification triggering escrow fund release.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying project milestone. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`contract_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent contract. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`milestone_index`** | `Internal` | Business Operations | `L1 - Internal / Low` | Sequential milestone sequence number (1, 2, 3). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`milestone_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Descriptive title of deliverable milestone. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`deliverable_description`** | `Internal` | Business Operations | `L1 - Internal / Low` | Scope criteria for client acceptance. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`due_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Agreed milestone delivery deadline. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`milestone_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Contractual payout upon milestone sign-off. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`escrow_allocation_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Amount reserved in client wallet escrow. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`currency_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Companion ISO 4217 currency code. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`milestone_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Delivery acceptance lifecycle state. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`submitted_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp worker submitted deliverable. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`approved_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp client approved sign-off. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `gig.gig_rating`
*Bilateral performance evaluations, ratings, and qualitative reviews recorded post-contract.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying contract rating. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`contract_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying completed contract. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`rater_user_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | User principal submitting evaluation. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`rated_user_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | User principal receiving evaluation. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`rating_score`** | `Internal` | Business Operations | `L1 - Internal / Low` | Overall evaluation score (1.00 - 5.00). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`review_text`** | `Internal` | Business Operations | `L1 - Internal / Low` | Qualitative feedback text. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`communication_score`** | `Internal` | Business Operations | `L1 - Internal / Low` | Granular responsiveness score. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`quality_score`** | `Internal` | Business Operations | `L1 - Internal / Low` | Granular technical quality score. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`timeliness_score`** | `Internal` | Business Operations | `L1 - Internal / Low` | Granular schedule adherence score. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`submitted_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Submission timestamp. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `gig.client_gig_worker_preference`
*Client employer favorite and blacklist registers for managing contractor talent relationships.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the preference relationship. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying client employer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`worker_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying gig worker. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`preference_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Relationship category. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`notes`** | `Internal` | Business Operations | `L1 - Internal / Low` | Internal organizational notes. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_by`** | `Internal` | System Metadata | `L1 - Internal / Low` | Client manager adding preference. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

### 4.9 Module: `licensing` — Subscription Licensing & Quotas
**Domain Scope:** Commercial subscription tiers, contract terms, and recurring monthly quota metering.  
**Schema Metrics:** 3 Tables | 31 Columns  

#### Table: `licensing.subscription_plan`
*Commercial subscription tiers defining recruiter seats, device caps, and monthly unlock quotas.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the subscription plan. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`plan_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Unique programmatic plan identifier. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`plan_name`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Display product tier title. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`tier_level`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Marketplace packaging tier. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`billing_cycle`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Subscription renewal frequency. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`base_price_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Contractual recurring billing fee. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Companion ISO 4217 currency code. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`max_recruiter_seats`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Hard cap on provisioned recruiter user accounts. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`max_devices_per_user`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Strict concurrent login session device limit per user. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`monthly_profile_unlock_quota`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Monthly candidate contact unlock allowance. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`monthly_outreach_credits`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Monthly bulk messaging credits. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`is_active`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Commercial availability flag. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `licensing.subscription_licence`
*Active commercial license granted to an account with non-overlapping temporal validity windows.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the customer licence. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`account_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying commercial account holder. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`plan_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying subscribed plan tier. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`licence_status`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Operational enforcement status. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`validity_period`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Contract term period enforcing non-overlapping active periods. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`allocated_seats_count`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Total recruiter seats currently assigned. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`auto_renew`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Automated recurring renewal trigger. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Licence creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `licensing.licence_entitlement_usage`
*Periodic metering tracking consumption against contract quotas (profile unlocks, job postings).*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the usage tracking record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`licence_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying subscription licence. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`entitlement_type`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Metered feature quota classification. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`billing_period_start`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Start date of current monthly quota cycle. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`billing_period_end`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Conclusion date of current monthly quota cycle. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`allocated_quota`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Total permitted consumption units for cycle. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`consumed_quota`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Units utilized to date in cycle. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Timestamp of most recent atomic consumption increment. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

### 4.10 Module: `billing` — Financial Billing & Double-Entry Ledger
**Domain Scope:** Append-only double-entry wallet ledgers ($0.00 variance), checkout orders, invoices, and profile unlock receipts.  
**Schema Metrics:** 8 Tables | 78 Columns  

#### Table: `billing.wallet_account`
*Prepaid and credit cash repository maintaining available balances and escrow allocations.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the financial wallet. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`account_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying owning commercial account. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`wallet_type`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Wallet operational category. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Sovereign ISO 4217 currency denominator. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`current_balance`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Total liquid spendable balance in wallet. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`escrow_reserved_balance`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Funds locked in active gig milestone escrow. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`is_locked`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Administrative freeze flag preventing debits during fraud review. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Wallet provisioning timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last ledger modification timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `billing.wallet_ledger`
*Append-only double-entry transaction journal with zero-variance debit/credit balancing.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the ledger entry. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`wallet_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying impacted wallet account. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`transaction_group_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Correlation ID grouping paired debit and credit records. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`entry_type`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Double-entry accounting polarity. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Absolute monetary value transferred. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Companion ISO 4217 currency code. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`balance_after`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Point-in-time wallet balance after entry application. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`reference_entity_type`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Business transaction category generating entry. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`reference_entity_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Primary key of originating business transaction. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`notes`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Human-readable accounting explanation. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Timestamp of ledger entry. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `billing.payment_order`
*Commercial checkout order tracking wallet recharges, plan purchases, and enterprise deposits.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the commercial order. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`account_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying purchasing account. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`order_type`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Commercial product purchase category. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Total gross order transaction value. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Companion ISO 4217 currency code. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`order_status`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Commercial order processing lifecycle. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`payment_gateway_order_reference`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | External PSP checkout session reference. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Order creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `billing.payment_transaction`
*PSP payment attempt records documenting charge authorizations, captures, and gateway codes.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the gateway transaction. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`order_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying parent order. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`wallet_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying credited wallet. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`gateway_transaction_reference`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | External payment provider charge reference ID. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`payment_method`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Payment channel used. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Net captured transaction amount. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Companion ISO 4217 currency code. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`transaction_status`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | PSP authorization status. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`gateway_response_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Raw PSP gateway status code for audit. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Transaction execution timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `billing.payment_gateway_event`
*Idempotent inbound webhook buffer recording raw external PSP notifications with payload hashes.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the webhook receipt. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`gateway_event_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | PSP unique event identifier preventing duplicate processing. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`event_type`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | External provider event category. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`payload_json`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Raw incoming webhook JSON payload. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`processing_status`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Idempotent worker execution status. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`error_message`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Worker execution failure notes if unhandled. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`received_at`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Timestamp HTTP POST hit ingress webhook. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`processed_at`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Timestamp worker finalized event. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |

#### Table: `billing.invoice`
*Statutory corporate tax invoices generated for commercial subscriptions and wallet deposits.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying statutory invoice. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`account_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying customer account. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`order_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying paid checkout order. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`invoice_number`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Sequential legal statutory invoice number. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`invoice_date`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Date of legal invoice issuance. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`due_date`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Payment due date. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`subtotal_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Pre-tax taxable invoice subtotal. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`tax_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Total statutory GST/VAT amount charged. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`total_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Final inclusive invoice settlement value. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Companion ISO 4217 currency code. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`invoice_status`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Statutory invoice settlement status. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`pdf_storage_path`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | S3 object URI to signed immutable PDF invoice. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Invoice generation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `billing.invoice_item`
*Itemized line items detailing individual charges, taxes, and service descriptions on an invoice.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying invoice line item. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`invoice_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying parent invoice. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`item_description`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Description of billed product or service. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`quantity`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Billed unit quantity. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`unit_price`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Net unit price per item. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`total_price`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Extended subtotal before taxes. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`currency_code`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Companion ISO 4217 currency code. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`tax_rate_percentage`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Applicable statutory VAT or GST percentage. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Line item generation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `billing.profile_download_history`
*Append-only metering receipt documenting unmasked candidate profile views and resume downloads.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the unlock event. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`recruiter_user_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying recruiter downloading profile. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`organisation_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying employer charged for unlock. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`candidate_id`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Foreign key identifying unlocked candidate. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`credits_deducted`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Subscription quota units debited for unlock. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`unlock_type`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Access level unlocked. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`dpdp_consent_verified`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Validates that active candidate consent was verified prior to unlock. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |
| **`downloaded_at`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Exact chronological timestamp of unlock. | Finance Auditor (P-11), Tenant Org Admin (P-02), and System Billing Daemon (P-12). |

### 4.11 Module: `engagement` — Talent Engagement & Chat
**Domain Scope:** Recruiter saved searches, candidate job alerts, in-app direct chat, referrals, and campus cohorts.  
**Schema Metrics:** 9 Tables | 69 Columns  

#### Table: `engagement.candidate_saved_search`
*Recruiter talent search criteria presets saved for repeat execution and team sharing.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the saved search. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`recruiter_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying recruiter author. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`search_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | User-friendly query title. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`criteria_json`** | `Internal` | Business Operations | `L1 - Internal / Low` | JSON serialization of faceted search filters. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `engagement.job_alert_subscription`
*Candidate automated notifications matching new job openings by role, salary, and location.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the job alert. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying subscribing candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`alert_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | User-friendly alert label. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`filters_json`** | `Internal` | Business Operations | `L1 - Internal / Low` | JSON criteria used by batch evaluation daemon. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`frequency`** | `Internal` | Business Operations | `L1 - Internal / Low` | Notification dispatch frequency. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`channel`** | `Internal` | Business Operations | `L1 - Internal / Low` | Dispatch delivery channel. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_active`** | `Internal` | Business Operations | `L1 - Internal / Low` | Active alert flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`last_notified_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when daemon last dispatched alert. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Creation audit timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `engagement.notification_delivery`
*Multi-channel message dispatch record tracking email, SMS, and in-app alert statuses.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the delivery receipt. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying notification recipient. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`notification_category`** | `Internal` | Business Operations | `L1 - Internal / Low` | Transactional notification classification. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`channel`** | `Internal` | Business Operations | `L1 - Internal / Low` | Communication transmission mechanism. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Header line of notification. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`body_preview`** | `Internal` | Business Operations | `L1 - Internal / Low` | Plaintext preview of notification body. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`delivery_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Gateway transmission state. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`external_delivery_reference`** | `Internal` | Business Operations | `L1 - Internal / Low` | Provider transmission confirmation ID. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`read_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp recipient opened message. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`dispatched_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp gateway transmitted payload. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record creation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `engagement.message_thread`
*Secure in-app direct communication channel between authorized recruiters and candidates.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the messaging conversation. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`recruiter_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying participating recruiter. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying participating candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`requisition_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Associated job requisition being discussed. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`unlock_receipt_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Proof of paid profile unlock authorizing communication. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`thread_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Conversation status. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Thread creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`last_message_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp of most recent message. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `engagement.thread_message`
*Encrypted message payloads exchanged within an authorized recruitment conversation thread.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the thread message. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`thread_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent conversation thread. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`sender_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | User principal authoring message. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`message_body`** | `Personal` | Communication Records | `L3 - Personal / High` | Confidential message content. | Designated Message Sender and Recipient principals only. Direct database inspection strictly forbidden. |
| **`is_read`** | `Internal` | Business Operations | `L1 - Internal / Low` | Read receipt flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Message transmission timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `engagement.candidate_referral_link`
*Unique cryptographic referral tokens generated for users to invite candidate talent.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying referral token. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`referrer_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying user sharing link. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`unique_referral_token`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cryptographically secure random invitation token. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`channel_medium`** | `Internal` | Business Operations | `L1 - Internal / Low` | Distribution medium. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`click_count`** | `Internal` | Business Operations | `L1 - Internal / Low` | Total times link was visited. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_active`** | `Internal` | Business Operations | `L1 - Internal / Low` | Active link flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Link generation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `engagement.referral_attribution_event`
*Multi-touch referral conversion milestones rewarding referrers for successful hires.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying attribution milestone. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`referral_link_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying originating referral link. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`referred_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying new user who registered via link. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`milestone_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Attributed business milestone. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`reward_points_awarded`** | `Internal` | Business Operations | `L1 - Internal / Low` | Referral bonus credits awarded to referrer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`attributed_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Conversion audit timestamp. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `engagement.campus_placement_cohort`
*University placement drive batches managed by academic Training & Placement Officers (TPOs).*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the campus drive batch. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`tpo_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying University Placement Officer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`institution_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Official registered college or university title. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`degree_program`** | `Internal` | Business Operations | `L1 - Internal / Low` | Degree program title. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`graduation_year`** | `Internal` | Business Operations | `L1 - Internal / Low` | Graduating class calendar year. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`cohort_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Operational campus drive status. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Cohort creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `engagement.campus_student_member`
*University student enrollment roster tracking institutional roll numbers and campus drive placements.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying cohort student mapping. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`cohort_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying parent placement cohort. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying student candidate profile. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`university_roll_number`** | `Internal` | Business Operations | `L1 - Internal / Low` | Institutional matriculation or student roll number. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`cumulative_gpa`** | `Internal` | Business Operations | `L1 - Internal / Low` | Official university cumulative grade point average. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`placement_status`** | `Internal` | Business Operations | `L1 - Internal / Low` | Campus drive hiring outcome. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`added_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Roster enrollment timestamp. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

### 4.12 Module: `governance` — Statutory Governance & DPDP
**Domain Scope:** DPDP Act 2023 consent register, per-user cryptographic DEK keys, tamper-evident SHA-256 audit trails, and retention.  
**Schema Metrics:** 4 Tables | 35 Columns  

#### Table: `governance.dpdp_consent_record`
*Immutable consent register tracking affirmative consent and statutory DPDP Act 2023 revocations.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the consent transaction. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying consenting user principal. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`consent_purpose`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Specific purpose-bound statutory processing mandate. | Data Principal Candidate (P-06) and Data Protection Officer (P-11). Immutable historical audit of consent. |
| **`consent_version`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Version of published privacy policy agreed to. | Data Principal Candidate (P-06) and Data Protection Officer (P-11). Immutable historical audit of consent. |
| **`status`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Legal status of affirmative consent. | Data Principal Candidate (P-06) and Data Protection Officer (P-11). Immutable historical audit of consent. |
| **`granted_ip_address`** | `Personal` | Security & Audit Information | `L3 - Personal / High` | IP address from which affirmative consent was logged. | Security Daemon (P-12) and Privacy Compliance Officer (P-11). Forensic access only; excluded from standard app logs. |
| **`granted_at`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Timestamp of affirmative consent grant. | Data Principal Candidate (P-06) and Data Protection Officer (P-11). Immutable historical audit of consent. |
| **`revoked_at`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Timestamp of legal consent revocation. | Data Principal Candidate (P-06) and Data Protection Officer (P-11). Immutable historical audit of consent. |
| **`withdrawal_reason`** | `Personal` | Personally Identifiable Information (PII) | `L3 - Personal / High` | Reason stated by candidate upon consent withdrawal. | Data Principal Candidate (P-06) and Data Protection Officer (P-11). Immutable historical audit of consent. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Record creation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `governance.pii_encryption_key`
*Per-user Data Encryption Keys (DEKs) wrapped by master HSM KEK; zeroing executes cryptographic shredding.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the cryptographic DEK. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying owning user account. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`encrypted_dek`** | `Confidential` | Security & Audit Information | `L4 - Restricted / Critical` | AES-256 Data Encryption Key encrypted under master HSM KEK. | Cloud KMS Service Daemon (P-12) & Chief Security Officer (P-01) under dual-authorization control. |
| **`key_version`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cryptographic key rotation generation index. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_shredded`** | `Internal` | Business Operations | `L1 - Internal / Low` | Cryptographic shredding flag executing instant Right-to-be-Forgotten. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`shredded_at`** | `Internal` | Business Operations | `L1 - Internal / Low` | Timestamp when DEK was overwritten/shredded. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`shredded_by_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Compliance officer or user executing deletion. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | DEK generation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `governance.system_audit_event`
*Append-only tamper-evident compliance audit trail secured by cryptographic SHA-256 chaining.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the audit event. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`actor_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying user or system daemon initiating action. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`actor_ip`** | `Personal` | Security & Audit Information | `L3 - Personal / High` | Client network address. | Security Daemon (P-12) and Privacy Compliance Officer (P-11). Forensic access only; excluded from standard app logs. |
| **`event_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Security classification of operational event. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`resource_entity`** | `Internal` | Business Operations | `L1 - Internal / Low` | Target table modified or read. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`resource_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Primary key of target resource. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`payload_before_json`** | `Confidential` | Security & Audit Information | `L2 - Confidential / Moderate` | Pre-mutation resource state. | Compliance Officer (P-11) and Security Admin (P-01). Masked during routine operational logging. |
| **`payload_after_json`** | `Confidential` | Security & Audit Information | `L2 - Confidential / Moderate` | Post-mutation resource state. | Compliance Officer (P-11) and Security Admin (P-01). Masked during routine operational logging. |
| **`tamper_hash`** | `Confidential` | Security & Audit Information | `L4 - Restricted / Critical` | SHA-256 HMAC digest chaining previous audit record. | Append-only calculation by Security Daemon (P-12). Read-only for Statutory Compliance Auditor (P-11). |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Immutable event timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `governance.data_retention_policy`
*Statutory data retention schedules automating scheduled purging and archival of expired records.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the retention policy. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`entity_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Target table governed by retention mandate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`retention_duration_days`** | `Internal` | Business Operations | `L1 - Internal / Low` | Maximum statutory retention period in days (e.g. 1095 = 3 years). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`action_on_expiry`** | `Internal` | Business Operations | `L1 - Internal / Low` | Compliance action executed by purging daemon. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_active`** | `Internal` | Business Operations | `L1 - Internal / Low` | Enforcement toggle. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Policy creation timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`updated_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Last update timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

### 4.13 Module: `analytics` — Kimball Analytical Reporting Marts
**Domain Scope:** Conformed dimensions and accumulating/transactional fact tables powering executive dashboards and KPIs.  
**Schema Metrics:** 9 Tables | 87 Columns  

#### Table: `analytics.dim_date`
*Standardized date dimension supporting time-slice aggregations across all business marts.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`date_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Smart integer surrogate key in YYYYMMDD format. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`full_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | Actual calendar date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`day_of_week`** | `Internal` | Business Operations | `L1 - Internal / Low` | Day of week index (1 = Sunday, 7 = Saturday). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`day_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | English day name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`day_of_month`** | `Internal` | Business Operations | `L1 - Internal / Low` | Calendar day of month. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`month_number`** | `Internal` | Business Operations | `L1 - Internal / Low` | Month index (1 to 12). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`month_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | English month name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`calendar_quarter`** | `Internal` | Business Operations | `L1 - Internal / Low` | Fiscal calendar quarter (1 to 4). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`calendar_year`** | `Internal` | Business Operations | `L1 - Internal / Low` | Four-digit calendar year. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_weekend`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag indicating Saturday or Sunday. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_holiday`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag indicating statutory public holiday. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `analytics.dim_candidate`
*Slowly Changing Dimension (Type 2) tracking candidate demographic profiles over time.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`candidate_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Surrogate integer primary key identifying dimensional version. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`candidate_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Natural business key pointing to candidate profile. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Natural user identity principal ID. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`city_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Standardized city name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`state_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Standardized state name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`country_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Standardized sovereign country name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`total_experience_months`** | `Internal` | Business Operations | `L1 - Internal / Low` | Total professional tenure in months. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`highest_qualification`** | `Internal` | Business Operations | `L1 - Internal / Low` | Highest degree attained. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`current_salary_usd`** | `Internal` | Business Operations | `L1 - Internal / Low` | Annualized compensation normalized to USD. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`profile_completion_percentage`** | `Internal` | Business Operations | `L1 - Internal / Low` | Completeness score at snapshot date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`row_effective_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 dimensional row start date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`row_expiration_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 dimensional row expiration date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_current`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 active version flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `analytics.dim_organisation`
*Slowly Changing Dimension (Type 2) tracking employer corporate attributes over time.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`organisation_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Surrogate integer primary key identifying dimensional version. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Natural business key pointing to corporate organization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`account_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Natural billing account reference. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`legal_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Registered legal company name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`industry_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Standardized industrial classification. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`company_size_tier`** | `Internal` | Business Operations | `L1 - Internal / Low` | Headcount tier. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`city_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Headquarters municipality. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`country_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Headquarters country. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_verified`** | `Internal` | Business Operations | `L1 - Internal / Low` | Verification flag at snapshot date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`row_effective_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 row validity start date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`row_expiration_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 row expiration date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_current`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 active version flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `analytics.dim_job_requisition`
*Slowly Changing Dimension (Type 2) tracking job posting criteria and compensation bands.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`requisition_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Surrogate integer primary key identifying dimensional version. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`requisition_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Natural business key pointing to job requisition. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`organisation_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Natural employer organization ID. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`job_role_title`** | `Internal` | Business Operations | `L1 - Internal / Low` | Occupational role designation. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`job_category`** | `Internal` | Business Operations | `L1 - Internal / Low` | Category classification. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`job_type`** | `Internal` | Business Operations | `L1 - Internal / Low` | Employment arrangement. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`work_mode`** | `Internal` | Business Operations | `L1 - Internal / Low` | Workplace operational policy. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`city_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Location municipality. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`min_salary_usd`** | `Internal` | Business Operations | `L1 - Internal / Low` | Minimum compensation band normalized to USD. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`max_salary_usd`** | `Internal` | Business Operations | `L1 - Internal / Low` | Maximum compensation band normalized to USD. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`open_to_consultants`** | `Internal` | Business Operations | `L1 - Internal / Low` | Consultant authorization flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`row_effective_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 row validity start date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`row_expiration_date`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 row expiration date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_current`** | `Internal` | Business Operations | `L1 - Internal / Low` | SCD2 active version flag. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `analytics.dim_pipeline_stage`
*Conformed dimension representing discrete milestones within the 13-stage hiring funnel.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`stage_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Surrogate integer primary key identifying pipeline stage. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`stage_code`** | `Internal` | Business Operations | `L1 - Internal / Low` | Unique programmatic stage identifier. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`stage_name`** | `Internal` | Business Operations | `L1 - Internal / Low` | Human-readable funnel display name. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`funnel_order`** | `Internal` | Business Operations | `L1 - Internal / Low` | Sequential position in hiring progression. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`is_terminal_stage`** | `Internal` | Business Operations | `L1 - Internal / Low` | Flag indicating funnel end state (e.g. JOINED, REJECTED, WITHDRAWN). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |

#### Table: `analytics.fact_application_event`
*Periodic snapshot and accumulating fact capturing candidate progression latency between stages.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the fact record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`date_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying calendar date of transition. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`candidate_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying candidate dimension. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`organisation_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying employer organization dimension. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`requisition_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying job requisition dimension. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`from_stage_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying originating pipeline stage. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`to_stage_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying destination pipeline stage. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`stage_duration_hours`** | `Internal` | Business Operations | `L1 - Internal / Low` | Elapsed hours spent in prior stage before transition. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Fact insertion timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `analytics.fact_profile_download`
*Transactional fact recording recruiter talent searches, profile unlocks, and quota consumption.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the fact record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`date_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying calendar date of download. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`organisation_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying employer organization. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`candidate_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying unlocked candidate. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`recruiter_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Degenerate dimension identifying recruiter actor. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`credits_consumed`** | `Internal` | Business Operations | `L1 - Internal / Low` | Quota credits debited for profile unlock. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Fact insertion timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `analytics.fact_gig_contract`
*Transactional fact tracking contingent project expenditures, completion timelines, and ratings.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the fact record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`date_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying calendar date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`organisation_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying hiring client employer. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`worker_user_id`** | `Internal` | Business Operations | `L1 - Internal / Low` | Degenerate dimension identifying contracted gig worker. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`contract_duration_days`** | `Internal` | Business Operations | `L1 - Internal / Low` | Total contracted calendar span in days. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`total_value_usd`** | `Internal` | Business Operations | `L1 - Internal / Low` | Total contracted project value normalized to USD. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`final_performance_rating`** | `Internal` | Business Operations | `L1 - Internal / Low` | Aggregate review score awarded upon completion. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Fact insertion timestamp in UTC. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

#### Table: `analytics.fact_wallet_transaction`
*Financial fact table tracking daily gross debits, credits, and verification of zero balance drift.*

| Column | Classification | Data Category | Sensitivity | Business Purpose | Access Restriction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`id`** | `Internal` | System Metadata | `L1 - Internal / Low` | Surrogate primary key identifying the fact record. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |
| **`date_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying financial accounting date. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`organisation_key`** | `Internal` | Business Operations | `L1 - Internal / Low` | Foreign key identifying commercial account holder. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`transaction_category`** | `Internal` | Business Operations | `L1 - Internal / Low` | Accounting category. | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`total_debit_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Cumulative debit total for date category. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`total_credit_amount`** | `Confidential` | Financial Information | `L2 - Confidential / Moderate` | Cumulative credit total for date category. | Statutory Finance Auditor (P-11), Org Billing Admin (P-02), and Direct Contracting Parties. |
| **`net_variance`** | `Internal` | Business Operations | `L1 - Internal / Low` | Reconciled variance (Must mathematically equal 0.00). | Authenticated Tenant Users governed by Role-Based Access Control (RBAC) and tenant workspace boundaries. |
| **`created_at`** | `Internal` | System Metadata | `L1 - Internal / Low` | Daily batch fact generation timestamp. | Authenticated System Services (P-12) and Tenant Operations. Governed by multi-tenant schema isolation. |

---

## 5. Sensitive Data Inventory

A focused inventory of the platform's high-risk data assets identifies the primary threat vectors, storage locations, and specialized safeguards required:

### 5.1 Authentication Secrets & Session Bearer Tokens
* **Target Columns:** `identity.user_credential.password_hash`, `identity.user_credential.password_salt`, `identity.user_active_session.session_token_hash`, `identity.service_api_key.key_hash`.
* **Physical Storage:** PostgreSQL 16 `identity` schema.
* **Security Architecture:** 
  * Passwords hashed using memory-hard Argon2id (RFC 9106) with $m=65536	ext{ KiB}$ (64 MB), $t=3	ext{ iterations}$, $p=4	ext{ threads}$, utilizing a 128-bit cryptographically secure per-user salt.
  * Session bearer tokens generated as 256-bit cryptographically secure pseudorandom numbers (CSPRNG). Only their one-way SHA-256 digest is persisted in `session_token_hash`.
  * Plaintext passwords and bearer tokens are never persisted in the database, cached in Redis, or output to application error logs.

### 5.2 Sovereign Tax Identifiers & Organization Compliance
* **Target Columns:** `organisation.organisation_tax_identifier.encrypted_tax_id`, `organisation.organisation_tax_identifier.tax_id_blind_index`.
* **Physical Storage:** PostgreSQL 16 `organisation` schema.
* **Security Architecture:** 
  * National tax identifiers (e.g., Indian PAN/GSTIN, US EIN) encrypted at application runtime using AES-256-GCM before database insertion.
  * To support exact-match duplicate detection without decrypting ciphertext, an HMAC-SHA256 blind index is calculated using a dedicated organization pepper key:
    $$	ext{tax\_id\_blind\_index} = 	ext{HMAC-SHA256}(	ext{TaxPepperKey}, 	ext{UPPER}(	ext{TRIM}(	ext{raw\_tax\_id})))$$
  * The blind index is stored as a deterministic 64-character hexadecimal digest with a database unique index (`DR-013`).

### 5.3 Cryptographic Key Wrappers (Per-User DEKs)
* **Target Columns:** `governance.pii_encryption_key.encrypted_dek`, `governance.pii_encryption_key.key_hash`.
* **Physical Storage:** PostgreSQL 16 `governance` schema.
* **Security Architecture:** 
  * Every candidate principal possesses an individual AES-256 Data Encryption Key (DEK).
  * The DEK is encrypted at rest using an external Hardware Security Module (HSM) or Cloud Key Management Service (AWS KMS / GCP Cloud KMS) Key Encrypting Key (KEK).
  * In sub-second DPDP erasure workflows (`REQ-10`, `WF-10`), `encrypted_dek` is zeroed out and flagged as `is_shredded = TRUE`, permanently rendering the candidate's ciphertext unrecoverable.

### 5.4 Candidate Contact PII & Location Coordinates
* **Target Columns:** `candidate.candidate_profile.first_name`, `last_name`, `date_of_birth`, `candidate.candidate_profile.current_salary_amount`, `identity.user_account.email`, `phone_number`, `candidate.candidate_location.latitude`, `longitude`, `candidate.candidate_block_list.blocked_organisation_id`.
* **Physical Storage:** PostgreSQL 16 `candidate` and `identity` schemas.
* **Security Architecture:** 
  * Email and phone coordinates are dynamically masked in all recruiter talent discovery search results.
  * Coordinates are revealed only upon verified consumption of an organization profile unlock quota credit (`billing.profile_download_history`).
  * Anti-join privacy shield prevents blocked employer organizations from discovering their current employees.

### 5.5 Binary Resumes, Portfolio Artifacts & Executed Offer Letters
* **Target Columns:** `candidate.candidate_resume.storage_path`, `candidate.candidate_resume.parsed_text_search`, `application.job_offer.offer_letter_storage_path`, `billing.invoice.pdf_storage_path`.
* **Physical Storage:** Cloud Object Storage (Amazon S3 / Google Cloud Storage) with bucket policies blocking all public read access; metadata pointers in PostgreSQL.
* **Security Architecture:** 
  * Storage buckets encrypted with Server-Side Encryption using KMS Customer Managed Keys (SSE-KMS).
  * Document access granted strictly via ephemeral, cryptographically signed URLs with a maximum Time-To-Live (TTL) of 15 minutes.
  * S3 access logs and download events audit-logged in `governance.system_audit_event`.

### 5.6 Double-Entry Financial Wallets & Escrow Ledgers
* **Target Columns:** `billing.wallet_account.current_balance`, `billing.wallet_account.escrow_reserved_balance`, `billing.wallet_ledger.amount`, `billing.payment_order.amount`, `gig.gig_contract.escrow_amount`.
* **Physical Storage:** PostgreSQL 16 `billing` and `gig` schemas.
* **Security Architecture:** 
  * Zero-variance double-entry ledger balance enforced by database triggers and immutable append-only constraints (`DR-057`, `DR-058`).
  * Direct updates or deletions prohibited; balance modifications occur solely via compensatory double-entry debit/credit ledger pairings.

---

## 6. Access Control and Privacy Rules (RBAC / ABAC)

### 6.1 Platform Persona & Role Directory
Talentra enforces a dual Role-Based and Attribute-Based Access Control model spanning 12 standardized system personas:

| Role Code | Persona Title | Scope Boundary | Security Privilege Level |
| :--- | :--- | :--- | :--- |
| **`P-01`** | **Platform Super Admin** | Global Cross-Tenant | Infrastructure maintenance, global master taxonomies, emergency break-glass. |
| **`P-02`** | **Tenant Organization Admin** | Organization Tenant | Corporate account management, seat assignments, subscription management. |
| **`P-03`** | **Corporate Recruiter** | Organization Tenant | Requisitions, talent search, candidate unlock, screening workflows. |
| **`P-04`** | **Hiring Manager** | Department / Requisition | Job requisition authoring, candidate shortlisting, interview reviews, offer approval. |
| **`P-05`** | **Technical Interviewer** | Application Assignment | Scorecard submission, technical candidate evaluation. No access to candidate salary. |
| **`P-06`** | **Candidate / Job Seeker** | Self Principal Only | Profile authoring, resume upload, block list management, DPDP consent management. |
| **`P-07`** | **Freelance Specialist** | Self Principal Only | Contingent gig profile, service packages, milestone submission, wallet withdrawals. |
| **`P-08`** | **Client Engagement Manager** | Organization Tenant | Contingent gig requisition, milestone signoff, escrow funding authorization. |
| **`P-09`** | **Staffing Agency Partner** | Agency Tenant | Client-assigned candidate nominations, agency placement tracking. |
| **`P-10`** | **Campus Placement Officer (TPO)** | University Cohort | Campus batch verification, student roster management, drive interview coordination. |
| **`P-11`** | **Compliance & Finance Auditor** | Read-Only Tenant/Global | Double-entry ledger audit, tax verification, DPDP statutory compliance inspection. |
| **`P-12`** | **System Automated Daemon** | Background Service | Ledger settlement, notification delivery, cryptographic key shredding, quota resets. |

---

### 6.2 Persona Access Matrix for Sensitive Domains
The matrix below defines CRUD authorizations across high-risk database schemas:

| Schema / Domain Area | P-01 Super Admin | P-02 Org Admin | P-03 Recruiter | P-04 Hiring Mgr | P-05 Interviewer | P-06 Candidate | P-07 Freelancer | P-11 Auditor | P-12 System |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`identity.user_credential`** | Blocked | Blocked | Blocked | Blocked | Blocked | Write (Self) | Write (Self) | Blocked | Read/Write (Auth) |
| **`identity.user_active_session`** | Revoke | Revoke (Org) | Read (Self) | Read (Self) | Read (Self) | Revoke (Self) | Revoke (Self) | Read-Only | Read/Write |
| **`organisation.tax_identifier`** | Read-Only | Read/Write | Blocked | Blocked | Blocked | Blocked | Blocked | Read-Only | Blocked |
| **`candidate.profile (Full PII)`** | Blocked | Unlocked Only | Unlocked Only | Shortlisted Only | Masked Only | Read/Write (Self) | Read/Write (Self) | Blocked | Read (Index) |
| **`candidate.candidate_block_list`**| Blocked | Blocked | Blocked | Blocked | Blocked | Read/Write (Self) | Read/Write (Self) | Blocked | Read (Anti-Join) |
| **`recruitment.salary_bands`** | Read-Only | Read/Write | Read/Write | Read-Only | Blocked | Blocked | Blocked | Read-Only | Read |
| **`application.interview_feedback`**| Read-Only | Read-Only | Read-Only | Read-Only | Write (Assigned) | Blocked | Blocked | Read-Only | Read |
| **`application.job_offer`** | Read-Only | Read/Write | Read/Write | Read/Write | Blocked | Read/Accept | Blocked | Read-Only | Read/Write |
| **`gig.milestone_escrow`** | Read-Only | Read-Only | Blocked | Blocked | Blocked | Read (Earned) | Read (Earned) | Read-Only | Read/Write |
| **`billing.wallet_ledger`** | Read-Only | Read-Only (Org) | Blocked | Blocked | Blocked | Read-Only (Self) | Read-Only (Self) | Read-Only | Write (Append) |
| **`governance.dpdp_consent`** | Read-Only | Blocked | Blocked | Blocked | Blocked | Read/Write (Self) | Read/Write (Self) | Read-Only | Read |
| **`governance.pii_encryption_key`** | Dual-Auth | Blocked | Blocked | Blocked | Blocked | Shred (Self) | Shred (Self) | Read-Only | Read/Write |

---

### 6.3 Attribute-Based Access Control (ABAC) Policies
In addition to role membership, five mission-critical ABAC security policies are enforced at the application data access layer:

1. **Policy ABAC-01: Candidate Anti-Join Shield**
   * *Rule:* A recruiter ($u \in 	ext{P-03}$) belonging to organization $O_{rec}$ is prohibited from discovering or viewing candidate $C$ if $O_{rec}$ matches any active record in $C$'s `candidate_block_list`.
   * *Enforcement:* Automated SQL query predicate injection on all talent search endpoints:
     ```sql
     AND NOT EXISTS (
         SELECT 1 FROM candidate.candidate_block_list bl
         WHERE bl.candidate_id = c.id
           AND bl.blocked_organisation_id = :current_user_org_id
     )
     ```

2. **Policy ABAC-02: Quota-Gated PII Contact Disclosure**
   * *Rule:* Recruiter $u$ can view candidate $C$'s unmasked email and phone number if and only if:
     $$\exists \, r \in 	ext{billing.profile_download_history} 	ext{ WHERE } r.	ext{organisation\_id} = u.	ext{org\_id} 	ext{ AND } r.	ext{candidate\_id} = C.	ext{id}$$
   * *Enforcement:* API Gateway DTO serializer checks unlock cache. If absent, contact fields are masked with asterisks.

3. **Policy ABAC-03: Multi-Tenant Schema Isolation**
   * *Rule:* All corporate transactions (`job_requisition`, `job_application`, `invoice`, `wallet_account`) are strictly scoped to the session tenant:
     $$	ext{record.organisation\_id} == 	ext{session.current\_organisation\_id}$$
   * *Enforcement:* Tenant ID populated exclusively from cryptographically verified JWT bearer tokens; never accepted from untrusted client URL parameters or request bodies.

4. **Policy ABAC-04: Campus Placement Drive Cohort Boundary**
   * *Rule:* A Training & Placement Officer ($u \in 	ext{P-10}$) can only access candidate profiles who have explicitly enrolled in a campus drive organized by their verified university institution.
   * *Enforcement:* Join constraint against `engagement.campus_student_member` and `engagement.campus_placement_cohort`.

5. **Policy ABAC-05: Escrow Payout Dual-Authorization**
   * *Rule:* Release of gig contract milestone escrow funds exceeding ₹1,00,000 (or $1,500 USD) requires dual approval: Client Engagement Manager ($P	ext{-}08$) signoff followed by Tenant Finance Administrator ($P	ext{-}02$) release authorization.
   * *Enforcement:* Two-phase state machine transition (`APPROVED_PENDING_DISBURSEMENT` $	o$ `DISBURSED`).

---

## 7. Encryption Requirements

### 7.1 Encryption at Rest

#### A. Storage & Database Tier Encryption
1. **NVMe Storage Volume Encryption:** All production PostgreSQL database clusters, write-ahead log (WAL) volumes, and Redis caching nodes operate on NVMe flash volumes encrypted with AES-256 hardware encryption managed by enterprise cloud key infrastructure.
2. **PostgreSQL Transparent Data Encryption (TDE):** All database table data files, temporary work files, and transaction logs are encrypted using PostgreSQL TDE, protecting physical database backup media against offline exfiltration.

#### B. Application-Layer Envelope Encryption (AES-256-GCM)
For high-risk attributes (`governance.pii_encryption_key`, `organisation.organisation_tax_identifier`), Talentra mandates **Application-Level Envelope Encryption** using AES-256 in Galois/Counter Mode (GCM):

$$	ext{Ciphertext} \parallel 	ext{AuthTag} = 	ext{AES-256-GCM}(	ext{DEK}, 	ext{IV}_{96}, 	ext{Plaintext}, 	ext{AAD})$$

* **Key Hierarchy:**
  * **Key Encrypting Key (KEK):** Master KMS key stored in a FIPS 140-2 Level 3 Hardware Security Module (AWS KMS / GCP Cloud KMS). Never exported or exposed to application memory.
  * **Data Encryption Key (DEK):** Per-user 256-bit AES key generated using a CSPRNG. Wrapped by the KEK and stored in `governance.pii_encryption_key.encrypted_dek`.
* **Initialization Vector (IV):** Unique 96-bit cryptographically random IV generated for every encryption invocation. An IV is never reused under the same DEK.
* **Additional Authenticated Data (AAD):** Bound to the owning `user_id` or `organisation_id` to prevent ciphertext relocation attacks.

#### C. Cloud Object Storage (S3 / GCS) Encryption
* All uploaded candidate resume PDFs, portfolio media, and formal offer letters stored in cloud buckets are encrypted using Server-Side Encryption with Customer Managed KMS Keys (`SSE-KMS`).
* Bucket policies enforce `aws:SecureTransport: true` (HTTPS only) and block all public access (`BlockPublicAcls`, `IgnorePublicAcls`, `BlockPublicPolicy`, `RestrictPublicBuckets`).

#### D. Database Backup Encryption
* Automated physical and logical backups (`pg_dump`, WAL-G archives) are compressed and encrypted with a dedicated offline KMS backup key before being replicated to geo-redundant cold storage.
* Backup retention follows the statutory 30-day continuous point-in-time recovery (PITR) window, with backup deletion coordinated with cryptographic DEK shredding.

---

### 7.2 Encryption in Transit

#### A. External Client-to-Edge Ingress
* **Protocol:** Transport Layer Security (TLS) version 1.3 enforced across all public endpoints (HTTPS, Secure WebSockets `wss://`). TLS 1.0, 1.1, and 1.2 are completely disabled on edge load balancers.
* **Cipher Suites:** Restricted strictly to modern forward-secrecy AEAD ciphers:
  * `TLS_AES_256_GCM_SHA384`
  * `TLS_CHACHA20_POLY1305_SHA256`
* **HTTP Strict Transport Security (HSTS):** Enforced with `max-age=31536000; includeSubDomains; preload`.

#### B. Internal Service-to-Service Communication
* All inter-microservice traffic inside the Kubernetes cluster is secured using Mutual TLS (mTLS) orchestrated by an enterprise service mesh (Istio/Linkerd) utilizing short-lived X.509 SPIFFE/SPIRE certificates with 24-hour automatic rotation.

#### C. Application-to-Database Connections
* Connections from application pods and PgBouncer connection poolers to PostgreSQL 16 enforce `sslmode=verify-full`, requiring root Certificate Authority (CA) validation and server hostname verification to eliminate Man-In-The-Middle (MITM) risks.

---

### 7.3 Password and Authentication Cryptography
* **Password Hashing:** Argon2id (RFC 9106) configured with parameters exceeding OWASP recommendations:
  * Memory Cost: $65,536	ext{ KiB}$ (64 MB)
  * Time Cost: 3 iterations
  * Parallelism: 4 threads
  * Salt: 16 bytes (128 bits) CSPRNG per user principal
* **Bearer Session Tokens:** Client authentication sessions issue high-entropy 256-bit bearer tokens. The database persists only the cryptographic digest:
  $$	ext{session\_token\_hash} = 	ext{SHA-256}(	ext{raw\_bearer\_token})$$
* **HMAC-SHA256 Blind Indexing:** Searchable encrypted fields (such as Organization Tax IDs) calculate a deterministic HMAC-SHA256 hash using a separate, high-security pepper key stored exclusively in KMS:
  $$	ext{blind\_index} = 	ext{HMAC-SHA256}(	ext{KMS\_Pepper}, 	ext{NormalizedValue})$$

---

## 8. Masking and Redaction Policies

### 8.1 Master Data Masking and Redaction Catalogue
To protect sensitive data from unnecessary exposure across user interfaces, API payloads, operational logs, and non-production environments, Talentra enforces the following mandatory masking specifications:

| Table | Field | Masking Requirement | Authorized Unmasked Roles | Masked Representation Example |
| :--- | :--- | :--- | :--- | :--- |
| **`identity.user_account`** | `email` | Dynamic API Masking: Mask local part; expose first char and domain. | P-06 (Self), P-02 (Org Admin), P-03 (Unlocked Recruiter) | `j***e@example.com` |
| **`identity.user_account`** | `phone_number` | Dynamic API Masking: Show country code, mask middle 6 digits, show last 4. | P-06 (Self), P-02 (Org Admin), P-03 (Unlocked Recruiter) | `+91 ******4321` |
| **`organisation.tax_identifier`** | `encrypted_tax_id` | UI & API Redaction: Expose only final 4 alphanumeric characters. | P-02 (Org Admin), P-11 (Auditor) | `******482K` |
| **`candidate.candidate_profile`** | `date_of_birth` | UI & API Masking: Calculate and display age in years; hide exact day/month. | P-06 (Self), P-02 (Verified HR Admin) | `Age: 29` (DOB hidden) |
| **`candidate.candidate_profile`** | `current_salary_amount` | UI & API Redaction: Hide entirely from search; display only salary band tier. | P-06 (Self), P-04 (Hiring Mgr with Offer Privileges) | `Tier 3 (₹18L - ₹24L)` |
| **`candidate.candidate_location`** | `latitude`, `longitude` | Dynamic API Redaction: Suppress GPS coordinates; render only City & State. | P-06 (Self), P-12 (Distance Calc Daemon) | `Bengaluru, Karnataka` (Coordinates omitted) |
| **`candidate.candidate_resume`** | `storage_path` | System URL Masking: Never expose raw cloud bucket paths; issue pre-signed URLs. | P-06 (Self), P-03 (Unlocked Recruiter) | `https://cdn.talentra.com/resumes/signed?token=...` |
| **`application.interview_feedback`**| `feedback_notes` | Role-Based Redaction: Completely hidden from candidate job seeker. | P-05 (Interviewer), P-04 (Hiring Mgr), P-03 (Recruiter) | `[REDACTED FROM CANDIDATE]` |
| **`billing.wallet_ledger`** | `balance_after` | Tenant Isolation: Accessible only within owning tenant context. | P-02 (Org Admin), P-11 (Auditor) | Tenant-scoped ledger display |
| **`governance.system_audit_event`** | `payload_before_json` | Log Filter Redaction: Strip password hashes, tokens, and tax IDs before logging. | P-11 (Auditor), P-01 (Security Admin) | `{"email": "j***e@...", "hash": "[REDACTED]"}` |

---

### 8.2 Operational Enforcement Boundaries

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        Talentra Masking Enforcement Tiers                              │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
        ┌───────────────────┬───────────────┴───────────────┬───────────────────┐
        ▼                   ▼                               ▼                   ▼
┌───────────────┐   ┌───────────────┐               ┌───────────────┐   ┌───────────────┐
│  Presentation │   │  API DTO /    │               │  Application  │   │ Non-Prod /    │
│  UI Masking   │   │  Serialization│               │  Log Filter   │   │ ETL Synthesis │
│ (React / Web) │   │ (Spring / Node│               │ (Winston / Log│   │ (Faker / Mask)│
└───────────────┘   └───────────────┘               └───────────────┘   └───────────────┘
```

1. **Presentation UI Masking:** Frontend client web applications (React/Next.js) render candidate contact info as masked pills until a recruiter clicks "Unlock Candidate Profile".
2. **API DTO & Serialization Filtering:** The primary security boundary. The backend application layer inspects caller permissions and candidate unlock state during JSON serialization. If unearned, the server returns masked strings (`j***e@***.com`). The client never receives unmasked data over the network unless authorized.
3. **Database Dynamic Views & Row-Level Security (RLS):** Database reporting users and data warehouse extract pipelines connect via PostgreSQL views that automatically mask PII columns using SQL functions.
4. **Application Log Redaction:** Structured loggers (Winston, Logback) pass all log records through an automated PII redaction pipeline. Regular expression filters scrub Authorization bearer tokens, cookie headers, email patterns, phone patterns, and tax IDs, substituting them with `[REDACTED]`.
5. **Non-Production Data Synthesis:** Staging and QA databases never receive production database dumps without passing through an automated anonymization pipeline that replaces names, contact details, and identifiers with synthetic mock data.

---

## 9. Data Retention and Deletion Strategy

### 9.1 Statutory Data Retention Register
Talentra establishes explicit retention periods for all data categories, balancing operational business needs against statutory record-keeping laws and the DPDP principle of storage limitation:

| Data Category | Representative Tables | Retention Period | Deletion Trigger | Deletion Method | Statutory / Business Justification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Active Candidate Profiles** | `candidate.candidate_profile`, `candidate_resume` | Duration of active job seeking + 36 months inactivity | Inactivity notification unanswered after 30 days OR candidate erasure request | Cryptographic DEK shredding followed by row anonymization | India DPDP Act 2023 Sec 8(7) storage limitation; talent rediscovery agreement. |
| **Unsuccessful Job Applications** | `application.job_application`, `interview_feedback` | 24 months post hiring requisition closure | Requisition closed date + 24 months | Hard deletion of stage history; feedback anonymization | Defense against unlawful discrimination claims under Indian labor laws. *(Requires formal Legal confirmation)* |
| **Successful Hire Dossiers** | `application.job_offer`, `job_application` | Transferred to Employer HRIS; retained 7 years | Employee onboarding confirmation | Transferred to tenant external HRIS; retained for employment audit | Corporate labor compliance and proof of offer terms. |
| **Commercial Tax Invoices** | `billing.invoice`, `billing.invoice_item` | 8 years from close of financial year | Financial year closure + 8 years | Archived to immutable cold storage; purged after statutory window | **Mandatory:** Indian Companies Act 2013 Sec 128(5) & GST Act Sec 36 (8-year statutory rule). |
| **Double-Entry Financial Ledger** | `billing.wallet_ledger`, `billing.wallet_account` | 8 years from transaction date | Transaction date + 8 years | Soft-delete / Archive flag; permanent immutability | **Mandatory:** RBI Master Directions & Indian tax regulations. Zero delete allowed on active ledger. |
| **Contingent Gig Contracts** | `gig.gig_contract`, `gig.gig_milestone` | 7 years post contract completion | Milestone completion & payout | Cold storage archive | Indian Contract Act 1872 & Limitation Act 1963 statutory limitation window. |
| **System Security Audit Trails** | `governance.system_audit_event` | 7 years continuous retention | Event timestamp + 7 years | Archived to WORM (Write Once Read Many) storage | Cert-In Cyber Security Directions 2022 & ISO 27001 auditability compliance. |
| **DPDP Consent History** | `governance.dpdp_consent_record` | Lifetime of active processing + 3 years post withdrawal | Consent revocation + 3 years | Cold storage archive; then hard deletion | DPDP Act 2023 evidentiary burden of proof for historical lawful processing. |
| **User Active Sessions** | `identity.user_active_session` | 30 days post token expiration | Session expiry timestamp | Automated Hard Deletion via cleanup daemon | Principle of storage minimization; operational hygiene. |
| **In-App Direct Chat Messages** | `engagement.thread_message` | 12 months post thread inactivity | Thread inactivity + 12 months | Hard deletion of message bodies; metadata pseudonymized | Storage minimization; candidate communication privacy. |
| **Saved Search Alerts & Queries** | `engagement.candidate_saved_search` | Active subscription + 90 days inactivity | Subscription cancellation | Hard deletion | Operational hygiene; zero compliance value. |

---

### 9.2 Deletion Mechanisms: Soft vs. Hard vs. Cryptographic

Talentra employs three distinct deletion methodologies tailored to the data classification tier:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        Talentra Tiered Deletion Lifecycle                              │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
        ┌───────────────────┬───────────────┴───────────────┬───────────────────┐
        ▼                   ▼                               ▼                   ▼
┌───────────────┐   ┌───────────────┐               ┌───────────────┐   ┌───────────────┐
│ Soft Deletion │   │ Hard Deletion │               │ Cryptographic │   │ Legal Hold    │
│ (Operational) │   │ (Compliance)  │               │   Shredding   │   │  Freeze       │
│ deleted_at IS │   │ DELETE FROM   │               │ Shred DEK in  │   │ Suspends all  │
│ NOT NULL      │   │ live database │               │ governance    │   │ deletions     │
└───────────────┘   └───────────────┘               └───────────────┘   └───────────────┘
```

1. **Soft Deletion (`deleted_at TIMESTAMPTZ`):** Used for non-sensitive operational records (job requisitions, candidate experiences, skills) allowing reversible accidental-deletion recovery within a 30-day grace window. All application SELECT queries filter `WHERE deleted_at IS NULL`.
2. **Hard Deletion (`DELETE FROM`):** Used for ephemeral tokens, expired active sessions, temporary files, and unconsented search alerts. The record is permanently excised from disk blocks during PostgreSQL `VACUUM` processing.
3. **Cryptographic Shredding (`governance.pii_encryption_key`):** Used for statutory DPDP Right-to-Erasure requests. Overwrites and zeroes out the user's AES-256 Data Encryption Key (DEK). This achieves instantaneous cryptographic anonymization across all active tables, read replicas, and immutable WAL backup media without requiring expensive, error-prone database-wide cascading row deletions.
4. **Legal Hold Override (`is_legal_hold_active`):** Any automated retention expiration or candidate deletion trigger is immediately suspended if the candidate or tenant organization is flagged under an active legal hold resulting from formal litigation, regulatory subpoena, or criminal investigation.

---

## 10. Right to Erasure (DPDP Act 2023 & GDPR Art. 17)

### 10.1 Sub-Second Cryptographic Erasure Architecture
Section 12 of the India Digital Personal Data Protection Act, 2023 guarantees data principals the right to the correction, completion, and **erasure** of their personal data. However, in an enterprise relational workforce platform, executing physical `DELETE` statements across 90 interconnected tables containing millions of historical applications, double-entry financial ledger records, and audit events would either:
* Violate referential integrity constraints, causing database corruption.
* Break statutory financial accounting invariants ($0.00 double-entry balance).
* Take minutes or hours to propagate across terabyte-scale distributed read replicas and immutable tape backups.

Talentra solves this engineering dilemma through **Sub-Second Cryptographic Shredding**:

```
[ Candidate Submits DPDP Erasure Request ]
                   │
                   ▼
[ Step 1: Pre-Condition Validation ] ──► (Active escrow or open legal hold? ──► REJECT / DEFER)
                   │
                   ▼ (Clear)
[ Step 2: Cryptographic DEK Shredding ]
  - Update governance.pii_encryption_key 
    SET encrypted_dek = 'SHREDDED_ZEROES', is_shredded = TRUE, shredded_at = NOW()
  - Evict user DEK from Redis cache & application memory
  ==> ALL PII IN DATABASE, REPLICAS & BACKUPS PERMANENTLY UNRECOVERABLE (<= 2.0s)
                   │
                   ▼
[ Step 3: Relational Pseudonymization & S3 Hard Delete ]
  - candidate.candidate_profile: first_name = 'ANONYMIZED', last_name = 'CANDIDATE', email = 'erased_<uuid>@erased.talentra.invalid'
  - Hard delete binary resume PDFs & portfolio files from S3/GCS bucket
  - candidate.candidate_block_list: Hard delete all block records
                   │
                   ▼
[ Step 4: Immutable Statutory Audit Event ]
  - Append to governance.system_audit_event: 'DATA_PRINCIPAL_ERASURE_COMPLETED'
  - Financial ledger entries & tax invoices preserved under statutory exemption
```

### 10.2 Mathematical Verification of Key Shredding
When `encrypted_dek` is overwritten with cryptographically random zeroes:
$$\lim_{t 	o 	ext{shred}} P(	ext{Decrypt}(	ext{Ciphertext})) = 2^{-256} pprox 0$$
The candidate's historical personal attributes stored in PostgreSQL live tables, WAL archives, daily snapshots, and offsite disaster recovery backups are rendered mathematically indistinguishable from random white noise.

### 10.3 Relational Preservation of Business Integrity
To maintain enterprise platform stability and comply with non-waivable statutory record-keeping obligations:
* **Statutory Financial Exemption:** In accordance with Section 8(8) of the DPDP Act 2023 and the Indian Companies Act 2013, transaction history in `billing.wallet_ledger` is preserved for 8 years. The candidate's `user_id` foreign key is preserved, but all linked profile names are replaced with `ANONYMIZED_USER_<UUID>`.
* **Historical Interview Notes:** Anonymized interview scores are retained so corporate hiring managers maintain historical record of why past requisitions were closed, but the candidate's personal dossier is severed.
* **Integrity Guarantee:** Foreign key relationships remain syntactically valid (`ON DELETE NO ACTION / RESTRICT`), eliminating broken database constraints.

---

## 11. Consent and Purpose Management

### 11.1 Granular DPDP Consent Architecture
Under Section 6 of the DPDP Act 2023, consent must be **free, specific, informed, unconditional, and unambiguous**, accompanied by an explicit notice specifying the personal data collected and the distinct purpose of processing. Talentra implements granular, purpose-bound consent recorded in `governance.dpdp_consent_record`:

| Purpose Identifier | Business Processing Scope | Mandatory / Optional | Revocation Impact |
| :--- | :--- | :---: | :--- |
| **`PURPOSE_TALENT_SOURCING`** | Creation of searchable candidate profile; parsing resume for recruiter search indexing. | Optional | Candidate profile hidden from recruiter talent search; existing applications unaffected. |
| **`PURPOSE_AI_MATCHING`** | Automated matching of candidate skill vector embeddings against job requisition requirements. | Optional | Automated matching disabled; candidate must manually apply to job requisitions. |
| **`PURPOSE_AGENCY_SHARING`** | Sharing candidate dossier with verified external staffing agency partners (`sourcing.agency_contract`). | Optional | Agency partners blocked from viewing profile or nominating candidate. |
| **`PURPOSE_MARKETING_ALERTS`** | Dissemination of weekly job alerts, career digest newsletters, and platform promotional SMS/emails. | Optional | Immediate cessation of all non-transactional marketing communications. |
| **`PURPOSE_CORE_SERVICE`** | Core account authentication, password recovery, session maintenance, and billing processing. | Mandatory | Account termination workflow initiated; service cannot be provided without core consent. |

---

### 11.2 Consent Record Lifecycle & Audit Trail
Every consent interaction (grant, update, or withdrawal) generates an immutable record in `governance.dpdp_consent_record`:
* `user_id`: Unique identifier of the Data Principal candidate.
* `consent_purpose`: Standardized purpose code.
* `consent_version`: Exact version of privacy policy presented (e.g. `v2.4_2026_09`).
* `status`: Enumerated state (`GRANTED`, `WITHDRAWN`, `EXPIRED`).
* `granted_ip_address`: Forensic client IPv4/IPv6 address at moment of consent.
* `granted_at`: UTC timestamp of affirmative consent capture.
* `revoked_at`: UTC timestamp of consent revocation.
* `withdrawal_reason`: Candidate-provided reason for consent withdrawal.

### 11.3 Seamless One-Click Withdrawal Workflow
Under DPDP Section 6(4), data principals have the statutory right to withdraw consent with the same ease with which it was given. Talentra provides a dedicated self-service "Privacy & Consent Dashboard" in the candidate portal:
1. Candidate toggles off any optional consent purpose with a single click.
2. The frontend triggers `POST /api/v1/governance/consent/withdraw`.
3. The application updates `governance.dpdp_consent_record`, publishes a `CONSENT_WITHDRAWN` event to Kafka, and immediately invalidates candidate search cache entries.
4. Downstream search indexing workers de-index the candidate profile within $\le 60	ext{ seconds}$.

---

## 12. Non-Production Data Protection

### 12.1 Absolute Prohibition of Production PII
To eliminate the severe risk of data breaches originating in pre-production environments, Talentra establishes an absolute, non-negotiable policy:
> **Zero Production Personal Data in Non-Production:** Live personal data, unmasked candidate resumes, production password hashes, and corporate tax identifiers are strictly prohibited from residing in Development, QA, Staging, Demo, or Local developer sandbox environments.

### 12.2 Automated Synthetic Data Generation
All automated unit, integration, performance, and user-acceptance testing pipelines rely on synthetically generated datasets:
* **Tooling:** Automated synthetic seed scripts built on Python Faker and FactoryBoy libraries.
* **Realistic Referential Schemas:** Synthetic generators populate all 90 tables with structurally authentic, normalized datasets:
  * Names drawn from diverse regional Indian and international name taxonomies.
  * Email addresses formatted strictly as `@synthetic.talentra.internal` (domain non-routable on public DNS).
  * Phone numbers prefixed with standard non-operational telecom testing prefixes (`+91 99999 XXXXX`).
  * Organization Tax Identifiers formatted with valid checksum syntax but registered in mock test namespaces.
  * Salary amounts generated within realistic statistical bell curves matching market hiring bands.

### 12.3 Production-to-Staging Sanitization ETL Pipeline
In rare scenarios where production data volumes are required for high-scale load and stress testing, data must pass through an automated one-way Sanitization ETL Pipeline before reaching Staging:

```
[ Production Read Replica Snapshot ]
                  │
                  ▼
[ Air-Gapped Sanitization Runner ]
  1. Names replaced with synthetic equivalents (Faker)
  2. Emails replaced with <hash>@synthetic.talentra.internal
  3. Phone numbers overwritten with +91-99999-00000
  4. password_hash reset to uniform bcrypt hash for 'StagingTestPassword123!'
  5. S3 storage_path pointers repointed to synthetic mock 1-page sample resumes
  6. Double-entry monetary amounts scaled by randomized +/- 15% noise factor
  7. Audit event IP addresses overwritten with 127.0.0.1
                  │
                  ▼
[ Verification Check: DLP Scan for Residual PII ] ──► (Fail: ABORT & ALERT)
                  │ (Pass)
                  ▼
[ Load Sanitized Database into Staging Cluster ]
```

---

## 13. Audit and Monitoring Requirements

### 13.1 Privacy-Related Audit Event Catalogue
To satisfy SOC 2 Type II criteria, ISO 27001 requirements, and DPDP Act compliance, all privacy-critical actions are recorded in the tamper-evident audit repository `governance.system_audit_event`:

| Event Code | Triggering Scenario | Captured Metadata | Retention |
| :--- | :--- | :--- | :--- |
| **`PII_PROFILE_UNLOCKED`** | Recruiter consumes credit to unlock candidate contact details. | `actor_user_id`, `candidate_id`, `organisation_id`, `credits_deducted` | 7 Years |
| **`PII_DEK_SHREDDED`** | Statutory DPDP Right-to-Erasure key shredding executed. | `actor_user_id`, `target_user_id`, `shred_timestamp`, `status` | 7 Years |
| **`CONSENT_STATUS_CHANGED`** | Candidate grants or revokes processing consent. | `user_id`, `purpose_code`, `previous_status`, `new_status`, `ip` | 7 Years |
| **`TAX_ID_ACCESSED`** | Administrator or Auditor accesses decrypted organization tax ID. | `actor_user_id`, `organisation_id`, `access_justification` | 7 Years |
| **`RESUME_DOWNLOAD_SIGNED`** | Ephemeral pre-signed S3 URL generated for candidate resume PDF. | `actor_user_id`, `resume_id`, `url_expiry_timestamp` | 7 Years |
| **`ESCROW_DISBURSED`** | Contingent gig milestone payout released from escrow to freelancer. | `contract_id`, `milestone_id`, `amount`, `approver_user_id` | 8 Years |
| **`AUTH_SESSION_REVOKED`** | User or Security Admin terminates an active session. | `session_id`, `actor_user_id`, `revocation_reason` | 7 Years |

---

### 13.2 Tamper-Evident SHA-256 Hash Chain
To guarantee that audit logs cannot be modified, deleted, or backdated by malicious administrators or compromised database superusers, `governance.system_audit_event` incorporates a cryptographic hash chain:

$$H_i = 	ext{SHA-256}\left(H_{i-1} \parallel 	ext{id}_i \parallel 	ext{actor\_user\_id}_i \parallel 	ext{event\_type}_i \parallel 	ext{created\_at}_i \parallel 	ext{payload\_after\_json}_iight)$$

* Each record stores `tamper_hash` ($H_i$), computed over its own attributes concatenated with the previous record's hash ($H_{i-1}$).
* The platform publishes the latest hash $H_n$ daily to an external, write-once, immutable public timestamping service (or public blockchain notary).
* Any unauthorized modification, row deletion, or insertion of historical audit events breaks the mathematical hash chain, immediately alerting the Chief Information Security Officer (CISO).

### 13.3 Strict Proscription Against Credential Logging
Application logging frameworks (Winston, Logstash, FluentBit) enforce strict interceptors:
* Passwords, password hashes, and salts are completely stripped from incoming request payloads before reaching logger memory.
* Session tokens (`Authorization: Bearer <token>`) and cookie headers are redacted into `Bearer [SCRUBBED]`.
* Decrypted DEK key bytes and plaintext Tax IDs are explicitly blocked from all application logging calls.

---

## 14. Privacy Risk Assessment

Talentra's data privacy threat modeling evaluates 10 primary security risk scenarios across probability, operational impact, and architectural mitigation:

| Risk ID | Threat Scenario | Inherent Severity | Likelihood | Impact Description | Technical & Architectural Mitigation | Residual Risk |
| :---: | :--- | :---: | :---: | :--- | :--- | :---: |
| **`RSK-01`** | **Unauthorized Lateral Recruiter Scraping** | High | High | Rogue recruiters bulk scrape candidate contact details to build off-platform databases. | Quota-gated unlock architecture (`billing.profile_download_history`), rate limiting (20 unlocks/hour), and automated behavioral anomaly detection. | **Low** |
| **`RSK-02`** | **Employer Discovery of Employed Candidate** | Critical | Medium | Employed candidate discovered searching for jobs by current employer; leads to wrongful termination. | Mandatory database anti-join shield (`candidate_block_list`) enforced at SQL layer (`CTR-05`); employer orgs blocked from viewing blocked status. | **Low** |
| **`RSK-03`** | **Database Backup Exfiltration / Theft** | Critical | Low | Backup media stolen from cloud storage; attacker gains full offline database copy. | PostgreSQL TDE volume encryption + AES-256 backup archive encryption with KMS key stored in separate air-gapped cloud project. | **Low** |
| **`RSK-04`** | **Sensitive PII Leaking into Application Logs** | High | High | Developer logs raw request payloads containing candidate passwords, emails, or tax IDs. | Centralized log interception pipeline with automated regex-based PII scrubbers; build CI-CD linters rejecting `console.log(req.body)`. | **Low** |
| **`RSK-05`** | **Insecure Cloud S3 Bucket Permissions** | Critical | Low | Misconfigured S3 bucket policy exposes millions of candidate resume PDFs to open web. | AWS S3 Block Public Access enforced at cloud account level; all downloads routed through 15-minute expiring KMS pre-signed URLs. | **Low** |
| **`RSK-06`** | **Excessive Stale Candidate Data Retention** | High | High | Accumulating millions of inactive resumes creates catastrophic breach liability under DPDP. | Automated 36-month inactivity retention daemon (`governance.data_retention_policy`) issuing notifications followed by auto-erasure. | **Medium** |
| **`RSK-07`** | **Incomplete Deletion on Erasure Request** | High | Medium | Candidate erased from live table but persists across read replicas, caches, and backups. | Per-user cryptographic key shredding (`governance.pii_encryption_key`); zeroing DEK renders all distributed copies unrecoverable instantly. | **Low** |
| **`RSK-08`** | **Production Data Leakage into Staging / QA** | Critical | Medium | Staging database populated with production dump; breached via weaker staging credentials. | Absolute prohibition of production dumps in non-prod; automated synthetic generation (Faker) and one-way sanitization ETL pipeline. | **Low** |
| **`RSK-09`** | **Privilege Escalation via Tenant Org Admin** | High | Low | Tenant administrator attempts cross-tenant SQL injection to access competing corporate data. | PostgreSQL multi-tenant schema isolation bound to cryptographically verified JWT claims; zero cross-tenant query execution paths. | **Low** |
| **`RSK-10`** | **Third-Party SMS/Email Gateway Interception** | Medium | Medium | SMS gateway provider logs OTPs and candidate outreach notifications in plaintext. | Notification delivery bodies masked in transit; OTPs delivered via expiring ephemeral tokens; vendor DPAs signed under DPDP Act. | **Low** |

---

## 15. Open Questions and Legal Dependencies

To finalize the platform's production privacy postures, the following operational and legal questions are catalogued for formal confirmation by Corporate Legal Counsel and the Data Protection Officer (DPO):

| Item ID | Governance Domain | Open Legal / Regulatory Question | Current Architectural Working Assumption | Action Required for Signoff |
| :---: | :--- | :--- | :--- | :--- |
| **`LEG-01`** | **Application Dossier Retention** | What is the maximum statutory period for retaining rejected candidate resumes under Indian labor jurisprudence (to defend against discriminatory hiring claims)? | Working assumption: 24 months post requisition closure, followed by automated anonymization. | Legal confirmation on whether 12, 24, or 36 months is mandated by local labor courts. |
| **`LEG-02`** | **AI Assessment Biometrics** | Do recorded video interview snippets and AI-derived speech/expression scores constitute sensitive biometric data under DPDP Act 2023? | Working assumption: Treated as High-Risk Personal Data requiring explicit affirmative consent before recording. | Legal determination on whether biometric regulatory compliance requirements apply. |
| **`LEG-03`** | **Cross-Border Talent Mobility** | Under DPDP Act 2023 Section 16, can multinational enterprise clients transfer Indian candidate profiles to servers located in the EU/US? | Working assumption: Permitted unless transferred to countries explicitly blacklisted by the Central Government of India. | Corporate legal validation of standard cross-border data transfer contractual clauses. |
| **`LEG-04`** | **Campus Recruits Age of Majority** | Does the platform require verifiable parental consent under DPDP Section 9 for college campus recruits aged 17 years and 10 months? | Working assumption: System restricts registration to individuals aged $\ge 18$ years via date of birth validation (`DR-018`). | Legal counsel guidance on campus drive age thresholds and parental consent workflows. |
| **`LEG-05`** | **Statutory Erasure SLA** | What is the legally permissible turnaround time for completing a data principal's Right-to-Erasure request? | Working assumption: Cryptographic shredding executed within $\le 48	ext{ hours}$ of verified identity confirmation. | Legal confirmation of DPDP statutory SLA (30 days vs proposed 7 days). |

---

## 16. Completion Checklist

This comprehensive Data Classification and Privacy Discovery document has been verified against the complete functional and non-functional requirements:

* [x] **100% Column Classification Coverage:** Every single one of the **893 physical columns** across all **90 tables** in the 13 domain schemas has been identified, classified, and documented in Section 4.
* [x] **Four Standard Classification Tiers:** Every attribute is categorized into `Public`, `Internal`, `Confidential`, or `Personal`.
* [x] **Granular Subcategories Assigned:** Attributes are mapped into 9 subcategories (PII, Credentials, Financial, Employment, Communications, Files, Audit, Operations, Metadata).
* [x] **Five-Level Sensitivity Scale:** Attributes are assigned explicit ratings from `L0 - Public` to `L4 - Restricted / Critical`.
* [x] **Role-Based & Attribute-Based Access Control:** Section 6 documents the complete 12-persona RBAC model (`P-01` through `P-12`) and specifies 5 mission-critical ABAC security policies (including candidate anti-join shield and quota-gated reveals).
* [x] **Rigorous Cryptographic Architecture:** Section 7 specifies NVMe encryption, PostgreSQL TDE, application-level envelope encryption (AES-256-GCM), Argon2id password hashing, and HMAC-SHA256 blind indexing.
* [x] **Master Masking Catalogue:** Section 8 details exact UI, API, database, and log masking requirements with concrete examples.
* [x] **Statutory Data Retention Schedules:** Section 9 provides an exhaustive retention register with explicit legal and business justifications (e.g. 8-year Companies Act financial ledger rule).
* [x] **Sub-Second Right-to-Erasure Workflow:** Section 10 defines the cryptographic key shredding mechanism ($\le 2.0	ext{ seconds}$) complying with DPDP Act 2023 without breaking relational integrity.
* [x] **Granular Consent Management:** Section 11 specifies purpose-bound consent records, version tracking, and one-click self-service withdrawal.
* [x] **Non-Production Data Protection:** Section 12 mandates synthetic data generation (Faker) and an air-gapped production sanitization ETL pipeline.
* [x] **Tamper-Evident Audit Chains:** Section 13 establishes the SHA-256 cryptographic hash chain formula for immutable audit trails in `governance.system_audit_event`.
* [x] **Comprehensive Risk Assessment:** Section 14 presents a 10-scenario privacy risk matrix with severity ratings and architectural mitigations.
* [x] **Ranked Legal Dependencies:** Section 15 catalogues open questions requiring formal Legal Counsel confirmation.
* [x] **Cross-Deliverable Consistency:** Perfectly synchronized with Steps 06, 07, 08, 09, 10, and 11.

---
**End of Deliverable Step 12: Comprehensive Data Classification and Privacy Discovery**
