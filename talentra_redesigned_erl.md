# Talentra Enterprise: Redesigned Entity Relationship List (ERL) & Relational Architecture Docket

**Document Reference:** Deliverable F1 — Normalized Entity Relationship Catalog  
**Platform:** Talentra Enterprise Workforce Platform  
**Target Engine:** PostgreSQL 16 (Tiered NVMe Storage, RLS, GiST Exclusion, JSONB Audit)  
**Compliance & Governance:** Aligned with Phase 1 Discover Baseline (REQ-01–45, ACT-01–14, F-01–25, WF-01–10, NFR-01–15)  
**Normalization Standard:** 3rd Normal Form (3NF) across OLTP domains; Kimball Star Schema across OLAP marts  

---

## 1. Executive Summary & Critical Analysis of the Previous 301-Entity Draft

The previous 301-entity draft suffered from severe structural pathologies that rendered it unviable for enterprise production deployment. A rigorous architectural audit reveals five fundamental categories of defects:

### 1.1 Unrelated Domain Intrusion & Feature Hallucination
* **Social Media Forum Bloat (20+ entities in `engagement`):** Tables such as `community_post`, `community_comment`, `community_reaction`, `community_report`, `community_moderation_action`, `community_topic`, and `follow_relation` were arbitrarily copied into the project. Talentra is an enterprise workforce, talent acquisition, and contingent labor platform—not a social network. These entities dilute core business logic and violate out-of-scope boundaries (`OOS-07`).
* **Generic Helpdesk Ticketing Clone (10+ entities in `engagement`):** Tables like `support_ticket`, `support_ticket_message`, `support_ticket_attachment`, `support_ticket_status_history`, `ticket_category`, and `ticket_priority` introduced a complete standalone Zendesk clone. Operational disputes in Talentra are handled through specialized dispute sub-ledgers and arbitration workflows tied directly to gig milestones (`WF-05`, `EXC-10`) or payment refunds (`EXC-03`).

### 1.2 Pseudo-Lookup Table Anti-Pattern (Extreme Over-Normalization)
* Over 50 individual tables were created solely to store 2-to-4 static enum values (e.g., `login_outcome`, `login_failure_reason`, `session_end_reason`, `block_reason`, `exchange_status`, `error_severity`, `data_request_status`, `decision_reason`).
* Each of these trivial tables was burdened with 9 boilerplate columns (`id`, `code`, `name`, `description`, `created_by`, `updated_by`, `created_at`, `updated_at`), with foreign keys pointing back to `administration.user_account`. This created circular foreign key dependencies, inflated index trees, and added massive join overhead without providing any business value. In PostgreSQL 16, standardized reference taxonomies belong in consolidated master lookup tables or database-enforced domain check constraints.

### 1.3 Missing Mission-Critical Entities Required by Project Workflows
Despite having 301 tables, the draft completely omitted several core capabilities explicitly mandated in the project brief and operational workflows:
* **Campus Placement Cohort Management (REQ-22, F-19, WF-09):** No entities existed to model University Training & Placement Officers (TPOs), academic institutions, graduation batches, degree programs, and batch student eligibility rosters.
* **Gig Milestones & Escrow Allocation (REQ-20, F-15, WF-05):** Gig contracting was modeled as a flat assignment without milestone schedules, deliverables, escrow reservation states, or sign-off triggers.
* **GiST Temporal Interval Specification (REQ-15, F-14, WF-05):** The gig assignment model failed to define the explicit `tstzrange` calendar booking window required to power PostgreSQL `EXCLUDE USING gist` constraints preventing double-booking.
* **Double-Entry Balancing Structure (REQ-17, F-11, WF-08):** The draft `wallet_ledger` lacked paired debit/credit mechanics, transaction grouping keys, and escrow hold tracking, making mathematical `$0.00` variance enforcement impossible.
* **DPDP Act 2023 Key Shredding (REQ-10, F-17, WF-10):** No Data Encryption Key (DEK) registry existed to operationalize instant cryptographic PII shredding upon consent revocation.
* **In-App Direct Recruiter-Candidate Messaging (REQ-28, F-22):** Secure communication threads between unlocked candidates and corporate recruiters were missing.

### 1.4 Unjustified 1:1 Entity Fracturing
* Core business objects were unnaturally split into multiple 1:1 fragments (e.g., separating `candidate_contact` from `candidate_profile` with 18 columns each, or splitting licensing into four overlapping mapping tables). This introduces gratuitous transaction latency and violates 3NF principles.

---

## 2. Redesign Architecture: 13 Modular Domains & Entity Overview

The redesigned ERL establishes **90 clean, fully normalized, production-grade entities** organized into 13 logical domain schemas. Every entity traces directly to an approved requirement, feature, or workflow tuple:

| Domain Schema | Entity Count | Primary Architectural Scope | Discovered Requirements Covered |
| :--- | :---: | :--- | :--- |
| **`master_data`** | **11** | Global Reference Vocabularies, Geographies, ISO Codes & Taxonomies | REQ-04, REQ-05, REQ-06, REQ-92 |
| **`identity`** | **6** | Zero-Trust Authentication, Credentials, Roles & Multi-Device Sessions | REQ-01, REQ-02, REQ-03, REQ-12, REQ-16 |
| **`organisation`** | **7** | Multi-Tenant Corporate Accounts, Verification, Branches & Recruiter Seats | REQ-05, REQ-13, REQ-19, REQ-20 |
| **`candidate`** | **9** | Comprehensive Profiles, Education, Skills, Resumes & Privacy Shield | REQ-02, REQ-03, REQ-14, REQ-24 |
| **`recruitment`** | **5** | Job Requisitions, Salary Bands, Screening Questionnaires & Scored Trees | REQ-04, REQ-07, REQ-08, REQ-13 |
| **`application`** | **6** | 13-Stage Pipeline State Machine, Question Responses, Interviews & Offers | REQ-07, REQ-08, REQ-29, WF-03 |
| **`sourcing`** | **4** | Consultant Agency Authorizations, Candidate Nominations & Bulk Outreach | REQ-18, REQ-34, REQ-35, WF-04, WF-06 |
| **`gig`** | **9** | Freelance Profiles, Service Catalogs, GiST Scheduling, Milestones & Reviews | REQ-15, REQ-20, REQ-21, REQ-28, WF-05 |
| **`licensing`** | **3** | Tiered Subscription Plans, Corporate Licences & Recruiter Seat Quotas | REQ-16, REQ-18, REQ-19, WF-07 |
| **`billing`** | **8** | Double-Entry Wallet Ledgers, Escrow Holds, Orders, Invoices & Metering | REQ-04, REQ-17, REQ-18, REQ-21, WF-08 |
| **`engagement`** | **9** | Real-Time Job Alerts, Saved Searches, In-App Chat, Referrals & Campus Cohorts | REQ-22, REQ-23, REQ-26, REQ-27, REQ-28 |
| **`governance`** | **4** | DPDP Act 2023 Consent Logs, DEK Key Shredding, Data Retention & Audit Trails | REQ-09, REQ-10, REQ-11, REQ-25, WF-10 |
| **`analytics`** | **9** | Kimball Dimensional Star Schema: Conformed Dimensions & Pipeline Fact Tables | REQ-04, REQ-141, G2 |
| **Total** | **90** | **Complete Multi-Module Enterprise Platform** | **100% Traceability across REQ-01–142** |

---

## 3. Detailed Entity & Relational Specifications by Module

### Module 1: Master Reference & Localization (`master_data`)

*Maintains sovereign global reference taxonomies, geographic hierarchies, ISO standards, and localized string dictionaries.*

#### 1. `master_data.country`
* **Classification:** Independent Reference Taxonomy (6 columns)
* **Description:** Sovereign national territories conforming to ISO 3166-1 alpha-2, providing telephone calling codes and address formatting rules.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `iso_alpha2_code` (CHAR(2), UNIQUE, NOT NULL), `iso_alpha3_code` (CHAR(3), NOT NULL), `country_name` (VARCHAR(100), NOT NULL), `phone_dialing_code` (VARCHAR(10), NOT NULL), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:N with `master_data.state`, `master_data.city`, `organisation.organisation_location`, `candidate.candidate_profile`.
* **Architectural Justification:** Mandated by REQ-02 and REQ-92 to ensure rigorous international E.164 phone validation and corporate physical location compliance.

#### 2. `master_data.state`
* **Classification:** Dependent Reference Taxonomy (5 columns)
* **Description:** First-level administrative sub-divisions (states, provinces, union territories) within a sovereign country.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `country_id` (UUID, NOT NULL), `state_code` (VARCHAR(10), NOT NULL), `state_name` (VARCHAR(100), NOT NULL), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** `country_id` ➔ `master_data.country(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** N:1 with `master_data.country`; 1:N with `master_data.city`.
* **Architectural Justification:** Normalizes regional jurisdiction hierarchy to 3NF, eliminating repetitive state string storage across candidate and organization profiles.

#### 3. `master_data.city`
* **Classification:** Dependent Reference Taxonomy (7 columns)
* **Description:** Municipality and metropolitan locations providing geographic coordinates for faceted talent search.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `country_id` (UUID, NOT NULL), `state_id` (UUID, NOT NULL), `city_name` (VARCHAR(100), NOT NULL), `latitude` (NUMERIC(9,6)), `longitude` (NUMERIC(9,6)), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** 
  - `country_id` ➔ `master_data.country(id)` [ON DELETE RESTRICT]
  - `state_id` ➔ `master_data.state(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** N:1 with `master_data.state`; 1:N with `candidate.candidate_profile`, `recruitment.job_requisition`, `organisation.organisation_location`.
* **Architectural Justification:** Required by REQ-24, REQ-26, and REQ-117 to power low-latency radial distance searches and faceted job filtering without text matching overhead.

#### 4. `master_data.currency`
* **Classification:** Independent Reference Taxonomy (5 columns)
* **Description:** Sovereign currency units conforming to ISO 4217, defining physical monetary decimal precisions.
* **Primary Key:** `currency_code` (CHAR(3))
* **Key Attributes:** `currency_code` (CHAR(3), PK), `currency_name` (VARCHAR(50), NOT NULL), `currency_symbol` (VARCHAR(5), NOT NULL), `decimal_precision` (SMALLINT, DEFAULT 2), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:N with `recruitment.job_requisition`, `billing.wallet_account`, `billing.wallet_ledger`, `gig.gig_contract`, `billing.invoice`.
* **Architectural Justification:** Directly satisfies REQ-04 and REQ-92. Fixed-precision `NUMERIC(12,2)` amounts must bind to valid ISO currency codes to eliminate floating-point rounding errors across multi-currency operations.

#### 5. `master_data.language`
* **Classification:** Independent Reference Taxonomy (5 columns)
* **Description:** Standard linguistic codes conforming to ISO 639-1, specifying text directionality for internationalization.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `iso_code` (CHAR(2), UNIQUE, NOT NULL), `language_name` (VARCHAR(50), NOT NULL), `direction` (VARCHAR(3), DEFAULT 'LTR', CHECK: IN ('LTR', 'RTL')), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:N with `master_data.ui_translation`, `candidate.candidate_language`.
* **Architectural Justification:** Mandated by REQ-06 and REQ-96 for multilingual UI localization and candidate language proficiency matrices.

#### 6. `master_data.industry`
* **Classification:** Independent Reference Taxonomy (5 columns)
* **Description:** Standardized industrial sector classifications (e.g., Information Technology, Healthcare, Manufacturing).
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `industry_code` (VARCHAR(30), UNIQUE, NOT NULL), `industry_name` (VARCHAR(100), NOT NULL), `display_order` (SMALLINT, DEFAULT 0), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:N with `master_data.job_role`, `organisation.organisation`, `recruitment.job_requisition`.
* **Architectural Justification:** Enforces consistent corporate classification and candidate sector filtering per REQ-05.

#### 7. `master_data.job_role`
* **Classification:** Dependent Reference Taxonomy (6 columns)
* **Description:** Canonical occupational titles and standardized job designations grouped by industry sector.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `industry_id` (UUID, NOT NULL), `role_code` (VARCHAR(50), UNIQUE, NOT NULL), `role_title` (VARCHAR(100), NOT NULL), `display_order` (SMALLINT, DEFAULT 0), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** `industry_id` ➔ `master_data.industry(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** N:1 with `master_data.industry`; 1:N with `recruitment.job_requisition`, `candidate.candidate_preference`.
* **Architectural Justification:** Resolves inconsistent job role nomenclature across legacy systems per REQ-002 and REQ-05.

#### 8. `master_data.skill`
* **Classification:** Independent Reference Taxonomy (6 columns)
* **Description:** Controlled vocabulary of technical, functional, and trade skills organized into distinct categories.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `skill_code` (VARCHAR(50), UNIQUE, NOT NULL), `skill_name` (VARCHAR(100), NOT NULL), `skill_category` (VARCHAR(50), NOT NULL, CHECK: IN ('TECHNICAL', 'SOFT', 'DOMAIN', 'TRADE')), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:N with `candidate.candidate_skill`, `recruitment.job_requisition_skill`, `gig.gig_worker_skill`.
* **Architectural Justification:** Foundational for sub-millisecond semantic skill matching and GIN trigram indexing per REQ-24 and F-06.

#### 9. `master_data.qualification`
* **Classification:** Independent Reference Taxonomy (5 columns)
* **Description:** Standardized educational degree tiers (Doctorate, Master's, Bachelor's, Diploma, Secondary).
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `qualification_tier` (VARCHAR(30), NOT NULL), `degree_title` (VARCHAR(100), NOT NULL), `hierarchy_rank` (SMALLINT, NOT NULL), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:N with `candidate.candidate_education`.
* **Architectural Justification:** Standardizes educational pre-requisites for automated screening evaluation per REQ-07 and REQ-22.

#### 10. `master_data.ui_translation_key`
* **Classification:** Independent Reference Taxonomy (4 columns)
* **Description:** Unique programmatic label identifiers mapped to front-end presentation strings.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `resource_key` (VARCHAR(100), UNIQUE, NOT NULL), `module_scope` (VARCHAR(50), NOT NULL), `description` (TEXT)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:N with `master_data.ui_translation`.
* **Architectural Justification:** Directly satisfies REQ-06 and REQ-96, decoupling static code strings from dynamic database-driven localized text.

#### 11. `master_data.ui_translation`
* **Classification:** Dependent Reference Taxonomy (5 columns)
* **Description:** Localized localized copy strings per language with English fallback guarantees.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `translation_key_id` (UUID, NOT NULL), `language_id` (UUID, NOT NULL), `translated_text` (TEXT, NOT NULL), `is_verified` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:**
  - `translation_key_id` ➔ `master_data.ui_translation_key(id)` [ON DELETE CASCADE]
  - `language_id` ➔ `master_data.language(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (translation_key_id, language_id)`
* **Architectural Justification:** Guarantees sub-millisecond translation resolution and English fallback compliance per REQ-06.

---

### Module 2: Identity, Security & Access Governance (`identity`)

*Manages user credentials, authentication security, role-based authorization, and active multi-device concurrency control.*

#### 12. `identity.user_account`
* **Classification:** Core Business Entity (10 columns)
* **Description:** Master root identity for all human and system actors accessing the Talentra platform.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `canonical_email` (VARCHAR(254), UNIQUE, NOT NULL), `phone_number` (VARCHAR(20), NOT NULL), `user_type` (VARCHAR(30), NOT NULL, CHECK: IN ('CANDIDATE', 'RECRUITER', 'EMPLOYER', 'CONSULTANT', 'GIG_WORKER', 'TPO', 'ADMINISTRATOR', 'SYSTEM_DAEMON')), `account_status` (VARCHAR(20), NOT NULL, CHECK: IN ('PENDING_VERIFICATION', 'ACTIVE', 'SUSPENDED', 'LOCKED', 'DEACTIVATED')), `is_email_verified` (BOOLEAN, DEFAULT FALSE), `is_phone_verified` (BOOLEAN, DEFAULT FALSE), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `updated_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:1 with `identity.user_credential`, `candidate.candidate_profile`, `gig.gig_worker_profile`; 1:N with `identity.user_role`, `identity.user_active_session`, `governance.dpdp_consent_record`, `governance.system_audit_event`.
* **Architectural Justification:** Directly satisfies REQ-01, REQ-02, and REQ-03 by enforcing lowercased canonical email uniqueness and E.164 phone formatting at the database constraint layer.

#### 13. `identity.user_credential`
* **Classification:** Security Credential Entity (8 columns)
* **Description:** Secure cryptographic password store protected against hardware-accelerated offline cracking.
* **Primary Key:** `user_account_id` (UUID)
* **Key Attributes:** `password_hash` (VARCHAR(255), NOT NULL), `password_salt` (BYTEA, NOT NULL), `hash_algorithm` (VARCHAR(30), DEFAULT 'Argon2id', NOT NULL), `failed_login_attempts` (SMALLINT, DEFAULT 0), `lockout_until` (TIMESTAMPTZ), `password_changed_at` (TIMESTAMPTZ, NOT NULL)
* **Outbound Foreign Keys:** `user_account_id` ➔ `identity.user_account(id)` [ON DELETE CASCADE]
* **Relationships & Cardinalities:** 1:1 with `identity.user_account`.
* **Architectural Justification:** Satisfies REQ-12 and F-01 by enforcing computationally expensive Argon2id transformations ($m=64\text{MB}, t=3, p=4$) isolated in a dedicated table to prevent credential leakage during broad SELECT queries.

#### 14. `identity.role`
* **Classification:** Authorization Reference Entity (5 columns)
* **Description:** System-wide role catalog defining access boundaries and entitlement scopes.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `role_code` (VARCHAR(50), UNIQUE, NOT NULL), `role_name` (VARCHAR(100), NOT NULL), `role_description` (TEXT), `is_system_role` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** None
* **Relationships & Cardinalities:** 1:N with `identity.user_role`.
* **Architectural Justification:** Mandated by REQ-50 to support the 9 primary human roles and platform governance actors defined in Playbook Step 02.

#### 15. `identity.user_role`
* **Classification:** Association / Bridge Entity (5 columns)
* **Description:** M:N role assignment linking users to authorized administrative and business roles.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `user_account_id` (UUID, NOT NULL), `role_id` (UUID, NOT NULL), `assigned_by_user_id` (UUID), `assigned_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `user_account_id` ➔ `identity.user_account(id)` [ON DELETE CASCADE]
  - `role_id` ➔ `identity.role(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (user_account_id, role_id)`
* **Architectural Justification:** Enforces strict role separation and auditable privilege granting per REQ-51 and Rule Group 4.

#### 16. `identity.user_active_session`
* **Classification:** Session Governance Entity (10 columns)
* **Description:** Real-time active login session registry enforcing device concurrency caps.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `user_account_id` (UUID, NOT NULL), `session_token_hash` (VARCHAR(64), UNIQUE, NOT NULL), `device_fingerprint` (VARCHAR(128), NOT NULL), `client_ip` (INET, NOT NULL), `user_agent` (VARCHAR(255)), `issued_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `last_active_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `expires_at` (TIMESTAMPTZ, NOT NULL), `is_terminated` (BOOLEAN, DEFAULT FALSE)
* **Outbound Foreign Keys:** `user_account_id` ➔ `identity.user_account(id)` [ON DELETE CASCADE]
* **Relationships & Cardinalities:** N:1 with `identity.user_account`.
* **Architectural Justification:** Satisfies REQ-16, F-10, and NFR-12 by enabling database triggers to terminate the oldest active session when a recruiter exceeds the contractual device concurrency cap (`max_devices = 2`).

#### 17. `identity.service_api_key`
* **Classification:** Security Credential Entity (8 columns)
* **Description:** Authenticated machine-to-machine tokens for automated background daemons and external boundary relays.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `service_account_name` (VARCHAR(100), UNIQUE, NOT NULL), `api_key_hash` (VARCHAR(64), UNIQUE, NOT NULL), `authorized_scopes` (TEXT[], NOT NULL), `is_revoked` (BOOLEAN, DEFAULT FALSE), `expires_at` (TIMESTAMPTZ, NOT NULL)
* **Outbound Foreign Keys:** None
* **Architectural Justification:** Supports the 16 dedicated system service accounts (`SYS-01` to `SYS-16`) identified in Step 02, ensuring background daemons have explicit, auditable security identities.

---

### Module 3: Corporate Tenancy & Recruiter Governance (`organisation`)

*Manages enterprise accounts, employer subsidiaries, physical branches, corporate KYC verification, and recruiter seat assignments.*

#### 18. `organisation.account`
* **Classification:** Core Commercial Entity (8 columns)
* **Description:** Top-level commercial entity that contracts with Talentra, holds subscriptions, and owns one or more employer organizations.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `account_name` (VARCHAR(150), NOT NULL), `account_owner_user_id` (UUID, NOT NULL), `billing_email` (VARCHAR(254), NOT NULL), `account_status` (VARCHAR(20), DEFAULT 'ACTIVE', CHECK: IN ('ACTIVE', 'DELINQUENT', 'SUSPENDED', 'CLOSED')), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** `account_owner_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:N with `organisation.organisation`, `licensing.subscription_licence`, `billing.wallet_account`.
* **Architectural Justification:** Directly addresses Assumption A2 and REQ-75 by separating the legal/commercial billing account from operating hiring organizations.

#### 19. `organisation.organisation`
* **Classification:** Core Multi-Tenant Entity (12 columns)
* **Description:** Operating corporate employer or recruitment agency that posts jobs and sources candidates under strict Row-Level Security isolation.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `account_id` (UUID, NOT NULL), `legal_name` (VARCHAR(150), NOT NULL), `trade_name` (VARCHAR(150)), `corporate_domain` (VARCHAR(100), NOT NULL), `industry_id` (UUID, NOT NULL), `company_size` (VARCHAR(30), CHECK: IN ('1-10', '11-50', '51-200', '201-500', '501-1000', '1000+')), `kyc_verification_status` (VARCHAR(20), DEFAULT 'UNVERIFIED', CHECK: IN ('UNVERIFIED', 'SUBMITTED', 'VERIFIED', 'REJECTED')), `is_active` (BOOLEAN, DEFAULT TRUE), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `account_id` ➔ `organisation.account(id)` [ON DELETE RESTRICT]
  - `industry_id` ➔ `master_data.industry(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** N:1 with `organisation.account`; 1:N with `organisation.organisation_location`, `organisation.recruiter_seat_assignment`, `recruitment.job_requisition`, `candidate.candidate_block_list`.
* **Architectural Justification:** The cornerstone of multi-tenant Row-Level Security (`RLS`) per REQ-13 and F-02. All corporate data filtering evaluates `organisation_id = current_setting('app.current_org_id')::UUID`.

#### 20. `organisation.organisation_location`
* **Classification:** Dependent Business Entity (9 columns)
* **Description:** Corporate operating offices, manufacturing plants, and branch locations.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `organisation_id` (UUID, NOT NULL), `location_name` (VARCHAR(100), NOT NULL), `address_line1` (VARCHAR(150), NOT NULL), `city_id` (UUID, NOT NULL), `state_id` (UUID, NOT NULL), `country_id` (UUID, NOT NULL), `postal_code` (VARCHAR(20), NOT NULL), `is_headquarters` (BOOLEAN, DEFAULT FALSE)
* **Outbound Foreign Keys:**
  - `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
  - `city_id` ➔ `master_data.city(id)` [ON DELETE RESTRICT]
  - `state_id` ➔ `master_data.state(id)` [ON DELETE RESTRICT]
  - `country_id` ➔ `master_data.country(id)` [ON DELETE RESTRICT]
* **Architectural Justification:** Satisfies REQ-05 and F-02, enabling corporate branch location mapping without polluting the master organization table.

#### 21. `organisation.organisation_tax_identifier`
* **Classification:** Sensitive Security Entity (7 columns)
* **Description:** Statutory corporate registrations (CIN, GSTIN, PAN, Tax ID) protected by column encryption and HMAC blind indexing.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `organisation_id` (UUID, NOT NULL), `identifier_type` (VARCHAR(30), NOT NULL, CHECK: IN ('CIN', 'GSTIN', 'PAN', 'EIN', 'VAT')), `encrypted_identifier_value` (BYTEA, NOT NULL), `blind_index_hash` (VARCHAR(64), NOT NULL), `country_id` (UUID, NOT NULL), `is_verified` (BOOLEAN, DEFAULT FALSE)
* **Outbound Foreign Keys:**
  - `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
  - `country_id` ➔ `master_data.country(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (identifier_type, blind_index_hash)`
* **Architectural Justification:** Fulfills REQ-20, REQ-112, and Rule Group 6: sensitive statutory tax identifiers are encrypted using AES-256-GCM, while HMAC-SHA256 blind indexing allows exact-match verification without exposing plaintext.

#### 22. `organisation.organisation_verification`
* **Classification:** Compliance Audit Entity (8 columns)
* **Description:** Immutable record of corporate legal verification checks performed by third-party registries.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `organisation_id` (UUID, NOT NULL), `verification_provider` (VARCHAR(50), NOT NULL), `provider_reference_id` (VARCHAR(100)), `verification_status` (VARCHAR(20), NOT NULL, CHECK: IN ('VERIFIED', 'FAILED', 'MANUAL_REVIEW')), `verification_payload` (JSONB), `verified_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
* **Architectural Justification:** Mandated by REQ-112 and REQ-32 for corporate KYC compliance and preventing fraudulent recruiter account creation.

#### 23. `organisation.recruiter_seat_assignment`
* **Classification:** Association / Governance Entity (7 columns)
* **Description:** Links authorized individual recruiter accounts to an enterprise employer organization under an active license seat.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `organisation_id` (UUID, NOT NULL), `recruiter_user_id` (UUID, NOT NULL), `licence_id` (UUID, NOT NULL), `assigned_by_user_id` (UUID, NOT NULL), `assigned_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `revoked_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:**
  - `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
  - `recruiter_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
  - `licence_id` ➔ `licensing.subscription_licence(id)` [ON DELETE RESTRICT]
* **Architectural Justification:** Satisfies REQ-19, F-10, and WF-07: enforces hard contractual seat limits via database triggers (`COUNT(active_seats) <= max_seats`).

#### 24. `organisation.organisation_hierarchy`
* **Classification:** Recursive Association Entity (5 columns)
* **Description:** Models parent-subsidiary enterprise corporate structures with cycle-detection constraints.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `parent_organisation_id` (UUID, NOT NULL), `child_organisation_id` (UUID, NOT NULL), `relationship_type` (VARCHAR(30), DEFAULT 'SUBSIDIARY', CHECK: IN ('SUBSIDIARY', 'BRANCH', 'AFFILIATE')), `established_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `parent_organisation_id` ➔ `organisation.organisation(id)` [ON DELETE RESTRICT]
  - `child_organisation_id` ➔ `organisation.organisation(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (parent_organisation_id, child_organisation_id)`
* **Architectural Justification:** Directly satisfies REQ-75 and F-02, allowing conglomerate clients to roll up subsidiary billing while maintaining operational pipeline isolation.

---

### Module 4: Candidate Profile, Resume & Privacy Shield (`candidate`)

*Stores comprehensive candidate curriculum vitae data, academic credentials, skill matrices, and the proprietary Candidate Privacy Shield.*

#### 25. `candidate.candidate_profile`
* **Classification:** Core Master Profile Entity (14 columns)
* **Description:** Central candidate profile entity containing professional career summaries and discovery parameters.
* **Primary Key:** `user_account_id` (UUID)
* **Key Attributes:** `professional_headline` (VARCHAR(150)), `career_summary` (TEXT), `total_experience_months` (INTEGER, DEFAULT 0), `current_annual_salary` (NUMERIC(12,2)), `expected_annual_salary` (NUMERIC(12,2)), `salary_currency` (CHAR(3)), `city_id` (UUID, NOT NULL), `country_id` (UUID, NOT NULL), `notice_period_days` (INTEGER, DEFAULT 30), `profile_completion_percentage` (SMALLINT, DEFAULT 0), `is_open_to_work` (BOOLEAN, DEFAULT TRUE), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `updated_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:**
  - `user_account_id` ➔ `identity.user_account(id)` [ON DELETE CASCADE]
  - `salary_currency` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
  - `city_id` ➔ `master_data.city(id)` [ON DELETE RESTRICT]
  - `country_id` ➔ `master_data.country(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:1 with `identity.user_account`; 1:N with all candidate sub-entities, `application.job_application`, `candidate.candidate_block_list`.
* **Architectural Justification:** The primary entity for the 10M-candidate scale target (REQ-120, REQ-121). Merges core contact and headline attributes into a compact 3NF schema averaging 4.0 KB per row.

#### 26. `candidate.candidate_education`
* **Classification:** Dependent History Entity (9 columns)
* **Description:** Formal academic qualifications, university accreditations, and graduation years.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `qualification_id` (UUID, NOT NULL), `institution_name` (VARCHAR(150), NOT NULL), `degree_name` (VARCHAR(100), NOT NULL), `field_of_study` (VARCHAR(100), NOT NULL), `start_year` (SMALLINT, NOT NULL), `end_year` (SMALLINT), `grade_or_cgpa` (VARCHAR(20))
* **Outbound Foreign Keys:**
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
  - `qualification_id` ➔ `master_data.qualification(id)` [ON DELETE RESTRICT]
* **Architectural Justification:** Satisfies REQ-61 and REQ-22 for academic background screening and campus fresher eligibility validation.

#### 27. `candidate.candidate_work_experience`
* **Classification:** Dependent History Entity (9 columns)
* **Description:** Chronological employment history, employer names, designations, and achievements.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `company_name` (VARCHAR(150), NOT NULL), `designation` (VARCHAR(100), NOT NULL), `employment_type` (VARCHAR(30), DEFAULT 'FULL_TIME'), `start_date` (DATE, NOT NULL), `end_date` (DATE), `is_current_employment` (BOOLEAN, DEFAULT FALSE), `responsibilities_text` (TEXT)
* **Outbound Foreign Keys:** `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
* **Architectural Justification:** Core element of candidate qualification evaluation and recruiter search filtering per REQ-61 and REQ-24.

#### 28. `candidate.candidate_skill`
* **Classification:** Dependent Skill Association Entity (6 columns)
* **Description:** Relational mapping of candidate verified and self-asserted technical and domain competencies.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `skill_id` (UUID, NOT NULL), `proficiency_level` (VARCHAR(20), CHECK: IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')), `experience_months` (INTEGER, DEFAULT 0), `is_verified` (BOOLEAN, DEFAULT FALSE)
* **Outbound Foreign Keys:**
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
  - `skill_id` ➔ `master_data.skill(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (candidate_profile_id, skill_id)`
* **Architectural Justification:** Directly satisfies REQ-24 and F-06. Indexed via GIN trigrams to deliver warm-cache $p95 < 10\text{ ms}$ candidate discovery queries across 1,000,000+ profiles.

#### 29. `candidate.candidate_project`
* **Classification:** Dependent Portfolio Entity (7 columns)
* **Description:** Significant personal, academic, or professional projects demonstrating applied skills.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `project_title` (VARCHAR(150), NOT NULL), `role_description` (TEXT), `project_url` (VARCHAR(255)), `start_date` (DATE), `end_date` (DATE)
* **Outbound Foreign Keys:** `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
* **Architectural Justification:** Mandated by REQ-77 to showcase technical projects and freelance portfolio work.

#### 30. `candidate.candidate_resume`
* **Classification:** Dependent Document Entity (8 columns)
* **Description:** Versioned uploaded curriculum vitae files and extracted full-text search vectors.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `document_title` (VARCHAR(150), NOT NULL), `storage_object_uri` (VARCHAR(255), NOT NULL), `file_format` (VARCHAR(10), NOT NULL, CHECK: IN ('PDF', 'DOCX')), `file_size_bytes` (INTEGER, NOT NULL), `parsed_tsvector` (TSVECTOR), `is_primary_default` (BOOLEAN, DEFAULT TRUE), `uploaded_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
* **Relationships & Cardinalities:** 1:N with `application.job_application`.
* **Architectural Justification:** Satisfies REQ-30, REQ-24, and F-06: decouples resume document storage (object URI) while maintaining a pre-computed `tsvector` column for sub-second keyword matching.

#### 31. `candidate.candidate_preference`
* **Classification:** Dependent Search Preference Entity (7 columns)
* **Description:** Candidate career preferences regarding desired roles, locations, minimum compensation, and remote work.
* **Primary Key:** `candidate_profile_id` (UUID)
* **Key Attributes:** `desired_role_id` (UUID), `desired_city_id` (UUID), `minimum_acceptable_salary` (NUMERIC(12,2)), `salary_currency` (CHAR(3)), `preferred_work_mode` (VARCHAR(20), CHECK: IN ('ON_SITE', 'REMOTE', 'HYBRID', 'ANY')), `is_willing_to_relocate` (BOOLEAN, DEFAULT FALSE)
* **Outbound Foreign Keys:**
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
  - `desired_role_id` ➔ `master_data.job_role(id)` [ON DELETE SET NULL]
  - `desired_city_id` ➔ `master_data.city(id)` [ON DELETE SET NULL]
  - `salary_currency` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Architectural Justification:** Satisfies REQ-76, powering automated matching engines and candidate job alerts (`WF-01`).

#### 32. `candidate.candidate_block_list`
* **Classification:** Privacy Shield Boundary Entity (5 columns)
* **Description:** Proprietary Candidate Privacy Shield table storing corporate organizations and competitors forbidden from discovering the candidate.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `blocked_organisation_id` (UUID, NOT NULL), `block_reason` (VARCHAR(100)), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
  - `blocked_organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
* **Unique Constraints:** `UNIQUE (candidate_profile_id, blocked_organisation_id)`
* **Architectural Justification:** Directly satisfies REQ-14, REQ-54, F-03, and D-11. Powers the materialized anti-join view `v_discoverable_candidates`, guaranteeing that blocked employer recruiters receive zero search hits for passive candidates.

#### 33. `candidate.candidate_language`
* **Classification:** Linguistic Proficiency Entity (5 columns)
* **Description:** Multi-language competency matrix capturing spoken, reading, and writing proficiency.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `language_id` (UUID, NOT NULL), `proficiency_level` (VARCHAR(20), NOT NULL, CHECK: IN ('BASIC', 'CONVERSATIONAL', 'FLUENT', 'NATIVE'))
* **Outbound Foreign Keys:**
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
  - `language_id` ➔ `master_data.language(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (candidate_profile_id, language_id)`
* **Architectural Justification:** Mandated by REQ-06 and REQ-61 for multi-region linguistically sensitive recruitment drives.

---

### Module 5: Job Requisition & Screening Questionnaires (`recruitment`)

*Models corporate job requirements across all eight workforce categories, compensation boundaries, and versioned screening questionnaire trees.*

#### 34. `recruitment.job_requisition`
* **Classification:** Core Master Demand Entity (18 columns)
* **Description:** Formal corporate job opening encompassing full-time, contingent, consultant, and campus positions.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `organisation_id` (UUID, NOT NULL), `job_title` (VARCHAR(150), NOT NULL), `job_role_id` (UUID, NOT NULL), `job_category` (VARCHAR(30), NOT NULL, CHECK: IN ('GIG', 'GENERAL_STAFFING', 'PROFESSIONAL_STAFFING', 'PERMANENT', 'APPRENTICE', 'CAMPUS', 'CONSULTANT', 'REMOTE')), `employment_type` (VARCHAR(30), NOT NULL, CHECK: IN ('FULL_TIME', 'PART_TIME', 'CONTRACT', 'INTERNSHIP')), `min_salary` (NUMERIC(12,2), NOT NULL), `max_salary` (NUMERIC(12,2), NOT NULL), `salary_currency` (CHAR(3), NOT NULL), `city_id` (UUID, NOT NULL), `country_id` (UUID, NOT NULL), `remote_policy` (VARCHAR(20), CHECK: IN ('ON_SITE', 'REMOTE', 'HYBRID')), `openings_count` (INTEGER, DEFAULT 1, CHECK: openings_count > 0), `is_consultant_open` (BOOLEAN, DEFAULT FALSE), `consultant_bounty_amount` (NUMERIC(12,2), DEFAULT 0.00), `requisition_status` (VARCHAR(20), DEFAULT 'DRAFT', CHECK: IN ('DRAFT', 'PENDING_APPROVAL', 'PUBLISHED', 'ON_HOLD', 'FILLED', 'CANCELLED')), `published_at` (TIMESTAMPTZ), `expires_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:**
  - `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
  - `job_role_id` ➔ `master_data.job_role(id)` [ON DELETE RESTRICT]
  - `salary_currency` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
  - `city_id` ➔ `master_data.city(id)` [ON DELETE RESTRICT]
  - `country_id` ➔ `master_data.country(id)` [ON DELETE RESTRICT]
* **Table Constraints:** `CHECK (min_salary <= max_salary)`
* **Relationships & Cardinalities:** N:1 with `organisation.organisation`; 1:N with `recruitment.job_requisition_skill`, `recruitment.job_questionnaire`, `application.job_application`, `sourcing.consultant_authorization`.
* **Architectural Justification:** Implements REQ-10 through REQ-17, REQ-04, REQ-13, and F-04. Fixed-precision salary ranges, consultant split-fee flags, and tenant RLS scoping are enforced at the database level.

#### 35. `recruitment.job_requisition_skill`
* **Classification:** Dependent Requisition Association (6 columns)
* **Description:** Explicit skill pre-requisites attached to a job requisition.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `job_requisition_id` (UUID, NOT NULL), `skill_id` (UUID, NOT NULL), `is_mandatory` (BOOLEAN, DEFAULT TRUE), `min_experience_months` (INTEGER, DEFAULT 0)
* **Outbound Foreign Keys:**
  - `job_requisition_id` ➔ `recruitment.job_requisition(id)` [ON DELETE CASCADE]
  - `skill_id` ➔ `master_data.skill(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (job_requisition_id, skill_id)`
* **Architectural Justification:** Mandated by REQ-24 and REQ-63 to compute candidate-job match compatibility scores.

#### 36. `recruitment.job_questionnaire`
* **Classification:** Screening Assessment Header Entity (7 columns)
* **Description:** Versioned pre-qualification screening questionnaire attached to an active requisition.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `job_requisition_id` (UUID, NOT NULL), `questionnaire_title` (VARCHAR(150), NOT NULL), `passing_score_threshold` (SMALLINT, NOT NULL, CHECK: passing_score_threshold >= 0), `is_mandatory` (BOOLEAN, DEFAULT TRUE), `version_number` (SMALLINT, DEFAULT 1), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** `job_requisition_id` ➔ `recruitment.job_requisition(id)` [ON DELETE CASCADE]
* **Relationships & Cardinalities:** 1:N with `recruitment.questionnaire_question`.
* **Architectural Justification:** Directly satisfies REQ-07, REQ-08, F-05, and WF-02: defines automated candidate qualification thresholds and supports versioned questionnaire updates.

#### 37. `recruitment.questionnaire_question`
* **Classification:** Screening Question Entity (7 columns)
* **Description:** Individual pre-qualification evaluation questions with weighted scores.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `questionnaire_id` (UUID, NOT NULL), `question_text` (TEXT, NOT NULL), `question_type` (VARCHAR(20), NOT NULL, CHECK: IN ('SINGLE_CHOICE', 'MULTIPLE_CHOICE', 'NUMERIC_INPUT', 'TEXT_INPUT')), `score_weight` (SMALLINT, DEFAULT 1), `display_order` (SMALLINT, DEFAULT 0)
* **Outbound Foreign Keys:** `questionnaire_id` ➔ `recruitment.job_questionnaire(id)` [ON DELETE CASCADE]
* **Relationships & Cardinalities:** N:1 with `recruitment.job_questionnaire`; 1:N with `recruitment.question_option`, `application.application_question_answer`.
* **Architectural Justification:** Required by REQ-07 to build dynamic assessment evaluation trees.

#### 38. `recruitment.question_option`
* **Classification:** Screening Answer Choice Entity (6 columns)
* **Description:** Discrete answer options for multiple-choice screening questions.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `question_id` (UUID, NOT NULL), `option_text` (VARCHAR(255), NOT NULL), `is_correct_choice` (BOOLEAN, DEFAULT FALSE), `option_score_value` (SMALLINT, DEFAULT 0), `display_order` (SMALLINT, DEFAULT 0)
* **Outbound Foreign Keys:** `question_id` ➔ `recruitment.questionnaire_question(id)` [ON DELETE CASCADE]
* **Architectural Justification:** Enables instant, zero-latency automated evaluation of candidate screening submissions during application ingest per REQ-07 and WF-03.

---

### Module 6: Application Pipeline & Candidate Journey (`application`)

*Tracks the candidate's journey through the 13-stage hiring state machine, candidate questionnaire evaluations, interview scoring, and formal employment offers.*

#### 39. `application.job_application`
* **Classification:** Core Transactional Pipeline Entity (12 columns)
* **Description:** Master candidate application record representing entry into an employer's hiring funnel.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `job_requisition_id` (UUID, NOT NULL), `candidate_profile_id` (UUID, NOT NULL), `resume_document_id` (UUID, NOT NULL), `current_stage` (VARCHAR(30), DEFAULT 'APPLIED', NOT NULL, CHECK: IN ('APPLIED', 'SCREENING', 'SCREENING_PASSED', 'ASSESSMENT_PENDING', 'ASSESSMENT_COMPLETED', 'SHORTLISTED', 'INTERVIEW_SCHEDULED', 'INTERVIEW_COMPLETED', 'OFFER_EXTENDED', 'OFFER_ACCEPTED', 'OFFER_DECLINED', 'REJECTED', 'WITHDRAWN')), `screening_total_score` (SMALLINT, DEFAULT 0), `is_screen_passed` (BOOLEAN, DEFAULT FALSE), `applied_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `stage_updated_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `job_requisition_id` ➔ `recruitment.job_requisition(id)` [ON DELETE RESTRICT]
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE RESTRICT]
  - `resume_document_id` ➔ `candidate.candidate_resume(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (job_requisition_id, candidate_profile_id)` (Enforces strict one-active-application rule per job)
* **Relationships & Cardinalities:** 1:N with `application.application_question_answer`, `application.application_stage_history`, `application.job_interview`, `application.job_offer`.
* **Architectural Justification:** Core transactional object scaling to 5M–100M rows (REQ-120, REQ-121). Partitioned monthly by `applied_at` (`PARTITION BY RANGE`) to bound index maintenance overhead per REQ-135.

#### 40. `application.application_question_answer`
* **Classification:** Dependent Answer Entity (7 columns)
* **Description:** Candidate-submitted answers to screening questionnaires evaluated during application.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `job_application_id` (UUID, NOT NULL), `question_id` (UUID, NOT NULL), `selected_option_id` (UUID), `text_response` (TEXT), `awarded_score` (SMALLINT, DEFAULT 0), `evaluated_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `job_application_id` ➔ `application.job_application(id)` [ON DELETE CASCADE]
  - `question_id` ➔ `recruitment.questionnaire_question(id)` [ON DELETE RESTRICT]
  - `selected_option_id` ➔ `recruitment.question_option(id)` [ON DELETE SET NULL]
* **Architectural Justification:** Preserves immutable record of screening responses and qualification scoring per REQ-07 and WF-03.

#### 41. `application.application_stage_history`
* **Classification:** State Machine Audit Entity (7 columns)
* **Description:** Append-only operational audit tracking every progression across the 13 applicant pipeline stages.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `job_application_id` (UUID, NOT NULL), `from_stage` (VARCHAR(30), NOT NULL), `to_stage` (VARCHAR(30), NOT NULL), `actor_user_id` (UUID, NOT NULL), `transition_notes` (TEXT), `transitioned_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `job_application_id` ➔ `application.job_application(id)` [ON DELETE CASCADE]
  - `actor_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Architectural Justification:** Directly satisfies REQ-29, F-07, and F-23: powers the interactive candidate journey timeline and provides non-repudiable hiring audit logs.

#### 42. `application.job_interview`
* **Classification:** Interview Workflow Entity (10 columns)
* **Description:** Scheduled candidate evaluation rounds, virtual video meetings, and interviewer assignments.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `job_application_id` (UUID, NOT NULL), `round_number` (SMALLINT, NOT NULL), `interview_type` (VARCHAR(30), NOT NULL, CHECK: IN ('TECHNICAL', 'BEHAVIORAL', 'SYSTEM_DESIGN', 'HR_SCREEN', 'EXECUTIVE')), `interviewer_user_id` (UUID, NOT NULL), `scheduled_start_time` (TIMESTAMPTZ, NOT NULL), `scheduled_end_time` (TIMESTAMPTZ, NOT NULL), `meeting_url` (VARCHAR(255)), `interview_status` (VARCHAR(20), DEFAULT 'SCHEDULED', CHECK: IN ('SCHEDULED', 'COMPLETED', 'RESCHEDULED', 'CANCELLED', 'NO_SHOW'))
* **Outbound Foreign Keys:**
  - `job_application_id` ➔ `application.job_application(id)` [ON DELETE CASCADE]
  - `interviewer_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:1 with `application.interview_feedback`.
* **Architectural Justification:** Mandated by REQ-001 and REQ-64 to structure multi-stage interview coordination within corporate recruitment pipelines.

#### 43. `application.interview_feedback`
* **Classification:** Interview Evaluation Entity (8 columns)
* **Description:** Interviewer evaluation rubric, quantitative competence scores, and hiring recommendations.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `interview_id` (UUID, UNIQUE, NOT NULL), `interviewer_user_id` (UUID, NOT NULL), `technical_competence_score` (SMALLINT, CHECK: technical_competence_score BETWEEN 1 AND 5), `cultural_alignment_score` (SMALLINT, CHECK: cultural_alignment_score BETWEEN 1 AND 5), `recommendation` (VARCHAR(20), NOT NULL, CHECK: IN ('STRONG_HIRE', 'HIRE', 'NEUTRAL', 'DO_NOT_HIRE')), `feedback_notes` (TEXT, NOT NULL), `submitted_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `interview_id` ➔ `application.job_interview(id)` [ON DELETE CASCADE]
  - `interviewer_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Architectural Justification:** Supports structured, evidence-based hiring decisions isolated behind recruiter role permissions per REQ-64.

#### 44. `application.job_offer`
* **Classification:** Commercial Offer Entity (10 columns)
* **Description:** Formal offer letter issued to a shortlisted candidate, specifying compensation terms and acceptance deadlines.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `job_application_id` (UUID, UNIQUE, NOT NULL), `offered_base_salary` (NUMERIC(12,2), NOT NULL), `offered_bonus_amount` (NUMERIC(12,2), DEFAULT 0.00), `salary_currency` (CHAR(3), NOT NULL), `joining_date` (DATE, NOT NULL), `offer_expiry_timestamp` (TIMESTAMPTZ, NOT NULL), `offer_status` (VARCHAR(20), DEFAULT 'EXTENDED', CHECK: IN ('EXTENDED', 'ACCEPTED', 'DECLINED', 'REVISED', 'EXPIRED')), `extended_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `responded_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:**
  - `job_application_id` ➔ `application.job_application(id)` [ON DELETE RESTRICT]
  - `salary_currency` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Architectural Justification:** Directly satisfies REQ-04 and REQ-64, enforcing fixed-precision monetary offers and automated offer expiration timeout daemons (`EXC-12`).

---

### Module 7: Sourcing, Consultant Marketplace & Split Bounty (`sourcing`)

*Enables corporate talent searches, bulk recruiter outreach, external consultant placement contracts, and split-commission bounties.*

#### 45. `sourcing.consultant_authorization`
* **Classification:** Agency Partnership Entity (7 columns)
* **Description:** Corporate authorization permitting an independent recruitment consultant to source candidates for a designated opening.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `job_requisition_id` (UUID, NOT NULL), `consultant_user_id` (UUID, NOT NULL), `split_bounty_amount` (NUMERIC(12,2), NOT NULL), `currency_code` (CHAR(3), NOT NULL), `authorization_status` (VARCHAR(20), DEFAULT 'ACTIVE', CHECK: IN ('ACTIVE', 'REVOKED', 'EXPIRED')), `expires_at` (TIMESTAMPTZ, NOT NULL)
* **Outbound Foreign Keys:**
  - `job_requisition_id` ➔ `recruitment.job_requisition(id)` [ON DELETE CASCADE]
  - `consultant_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
  - `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:N with `sourcing.candidate_nomination`.
* **Architectural Justification:** Implements REQ-16, REQ-53, F-08, and WF-06: strictly restricts consultant access to requisitions with `is_consultant_open = TRUE`.

#### 46. `sourcing.candidate_nomination`
* **Classification:** Candidate Agency Submission Entity (8 columns)
* **Description:** Candidate dossier submission by an authorized consultant, establishing placement attribution.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `consultant_authorization_id` (UUID, NOT NULL), `candidate_profile_id` (UUID, NOT NULL), `nomination_status` (VARCHAR(20), DEFAULT 'SUBMITTED', CHECK: IN ('SUBMITTED', 'ACCEPTED', 'DECLINED', 'HIRED', 'BOUNTY_PAID')), `employer_notes` (TEXT), `nominated_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `decided_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:**
  - `consultant_authorization_id` ➔ `sourcing.consultant_authorization(id)` [ON DELETE CASCADE]
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (consultant_authorization_id, candidate_profile_id)`
* **Architectural Justification:** Mandated by REQ-35, F-08, and WF-06 to govern split-commission bounties and resolve candidate ownership disputes (`EXC-10`).

#### 47. `sourcing.outreach_campaign`
* **Classification:** Talent Engagement Batch Entity (8 columns)
* **Description:** Bulk recruiter outreach campaigns dispatching personalized messaging to candidate cohorts.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `organisation_id` (UUID, NOT NULL), `recruiter_user_id` (UUID, NOT NULL), `campaign_name` (VARCHAR(150), NOT NULL), `filter_criteria_jsonb` (JSONB, NOT NULL), `recipient_count` (INTEGER, NOT NULL), `campaign_status` (VARCHAR(20), DEFAULT 'DISPATCHED'), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
  - `recruiter_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:N with `sourcing.outreach_recipient`.
* **Architectural Justification:** Satisfies REQ-34 and F-10, supporting high-throughput recruiter outreach batches of up to 10,000 recipients.

#### 48. `sourcing.outreach_recipient`
* **Classification:** Dependent Outreach Receipt Entity (7 columns)
* **Description:** Individual candidate recipient status within an active recruiter outreach campaign.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `campaign_id` (UUID, NOT NULL), `candidate_profile_id` (UUID, NOT NULL), `delivery_status` (VARCHAR(20), DEFAULT 'SENT', CHECK: IN ('SENT', 'DELIVERED', 'OPENED', 'RESPONDED', 'BOUNCED')), `dispatched_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `responded_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:**
  - `campaign_id` ➔ `sourcing.outreach_campaign(id)` [ON DELETE CASCADE]
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
* **Architectural Justification:** Enables recruiter conversion tracking and candidate response telemetry per REQ-34.

---

### Module 8: Freelance Gig Marketplace & GiST Scheduling (`gig`)

*Governs contingent freelance service profiles, project requests, proposals, contracts with PostgreSQL GiST non-overlap constraints, milestones, and ratings.*

#### 49. `gig.gig_worker_profile`
* **Classification:** Specialized Contingent Profile Entity (9 columns)
* **Description:** Decoupled freelance professional profile capturing specialized trades, rack rates, and verified KYC status.
* **Primary Key:** `user_account_id` (UUID)
* **Key Attributes:** `trade_headline` (VARCHAR(150), NOT NULL), `trade_category` (VARCHAR(50), NOT NULL), `bio_summary` (TEXT), `default_hourly_rate` (NUMERIC(12,2), NOT NULL), `rate_currency` (CHAR(3), NOT NULL), `is_identity_verified` (BOOLEAN, DEFAULT FALSE), `total_gigs_completed` (INTEGER, DEFAULT 0), `average_rating_score` (NUMERIC(3,2), DEFAULT 5.00)
* **Outbound Foreign Keys:**
  - `user_account_id` ➔ `identity.user_account(id)` [ON DELETE CASCADE]
  - `rate_currency` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:1 with `identity.user_account`; 1:N with `gig.gig_worker_service`, `gig.gig_worker_availability`, `gig.gig_proposal`, `gig.gig_contract`.
* **Architectural Justification:** Directly satisfies REQ-22 and REQ-27: decouples gig workers into a dedicated subsystem to avoid NULL-polluting core lateral candidate tables.

#### 50. `gig.gig_worker_service`
* **Classification:** Service Offering Catalog Entity (7 columns)
* **Description:** Discrete freelance services offered with itemized pricing units (hourly, daily, deliverable-based).
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `worker_profile_id` (UUID, NOT NULL), `service_title` (VARCHAR(150), NOT NULL), `service_description` (TEXT), `pricing_unit` (VARCHAR(20), NOT NULL, CHECK: IN ('HOURLY', 'DAILY', 'FIXED_MILESTONE')), `unit_rate` (NUMERIC(12,2), NOT NULL), `currency_code` (CHAR(3), NOT NULL)
* **Outbound Foreign Keys:**
  - `worker_profile_id` ➔ `gig.gig_worker_profile(user_account_id)` [ON DELETE CASCADE]
  - `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Architectural Justification:** Mandated by REQ-22 and F-13 to showcase verified freelance capabilities.

#### 51. `gig.gig_worker_availability`
* **Classification:** Calendar Temporal Schedule Entity (5 columns)
* **Description:** Freelancer availability intervals specifying when the professional is open for project bookings.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `worker_profile_id` (UUID, NOT NULL), `available_interval` (TSTZRANGE, NOT NULL), `is_recurring` (BOOLEAN, DEFAULT FALSE), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** `worker_profile_id` ➔ `gig.gig_worker_profile(user_account_id)` [ON DELETE CASCADE]
* **Architectural Justification:** Satisfies REQ-22 and F-14: captures temporal intervals for booking availability checks.

#### 52. `gig.gig_request`
* **Classification:** Core Contingent Demand Entity (11 columns)
* **Description:** Client-posted contingent project requirements with fixed or hourly pricing and temporal delivery windows.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `organisation_id` (UUID, NOT NULL), `requester_user_id` (UUID, NOT NULL), `project_title` (VARCHAR(150), NOT NULL), `project_scope` (TEXT, NOT NULL), `required_skill_id` (UUID, NOT NULL), `budget_amount` (NUMERIC(12,2), NOT NULL), `budget_currency` (CHAR(3), NOT NULL), `pricing_model` (VARCHAR(20), NOT NULL, CHECK: IN ('FIXED_PRICE', 'HOURLY_RATE')), `target_contract_window` (TSTZRANGE, NOT NULL), `request_status` (VARCHAR(20), DEFAULT 'OPEN', CHECK: IN ('OPEN', 'AWARDED', 'COMPLETED', 'CANCELLED'))
* **Outbound Foreign Keys:**
  - `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
  - `requester_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
  - `required_skill_id` ➔ `master_data.skill(id)` [ON DELETE RESTRICT]
  - `budget_currency` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:N with `gig.gig_proposal`; 1:1 with `gig.gig_contract`.
* **Architectural Justification:** Implements REQ-20 and REQ-70: enforces start/end temporal windows, fixed-precision budgets, and currency bindings.

#### 53. `gig.gig_proposal`
* **Classification:** Unidirectional Bid Entity (8 columns)
* **Description:** Freelancer-submitted proposals with proposed pricing and delivery intervals. Requesters cannot initiate unsolicited price bids.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `gig_request_id` (UUID, NOT NULL), `worker_profile_id` (UUID, NOT NULL), `proposed_amount` (NUMERIC(12,2), NOT NULL), `proposed_currency` (CHAR(3), NOT NULL), `proposed_window` (TSTZRANGE, NOT NULL), `proposal_status` (VARCHAR(20), DEFAULT 'PENDING', CHECK: IN ('PENDING', 'ACCEPTED', 'DECLINED', 'WITHDRAWN')), `submitted_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `gig_request_id` ➔ `gig.gig_request(id)` [ON DELETE CASCADE]
  - `worker_profile_id` ➔ `gig.gig_worker_profile(user_account_id)` [ON DELETE CASCADE]
  - `proposed_currency` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (gig_request_id, worker_profile_id)`
* **Architectural Justification:** Directly enforces REQ-21: unidirectional bidding where workers submit proposals and requesters accept or reject.

#### 54. `gig.gig_contract`
* **Classification:** Executed Agreement & GiST Concurrency Entity (11 columns)
* **Description:** Legally binding gig contract protected by PostgreSQL GiST temporal exclusion constraints preventing double-booking.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `gig_request_id` (UUID, UNIQUE, NOT NULL), `proposal_id` (UUID, UNIQUE, NOT NULL), `worker_profile_id` (UUID, NOT NULL), `client_organisation_id` (UUID, NOT NULL), `contract_window` (TSTZRANGE, NOT NULL), `total_contract_value` (NUMERIC(12,2), NOT NULL), `currency_code` (CHAR(3), NOT NULL), `escrow_status` (VARCHAR(20), DEFAULT 'PENDING_FUNDING', CHECK: IN ('PENDING_FUNDING', 'ESCROW_LOCKED', 'PARTIALLY_RELEASED', 'SETTLED', 'REFUNDED')), `contract_status` (VARCHAR(20), DEFAULT 'SCHEDULED', CHECK: IN ('SCHEDULED', 'IN_PROGRESS', 'DELIVERED', 'COMPLETED', 'DISPUTED', 'CANCELLED')), `external_fulfilment_ref` (VARCHAR(100))
* **Outbound Foreign Keys:**
  - `gig_request_id` ➔ `gig.gig_request(id)` [ON DELETE RESTRICT]
  - `proposal_id` ➔ `gig.gig_proposal(id)` [ON DELETE RESTRICT]
  - `worker_profile_id` ➔ `gig.gig_worker_profile(user_account_id)` [ON DELETE RESTRICT]
  - `client_organisation_id` ➔ `organisation.organisation(id)` [ON DELETE RESTRICT]
  - `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Table Constraint:**
  ```sql
  EXCLUDE USING gist (
      worker_profile_id WITH =,
      contract_window WITH &&
  ) WHERE (contract_status IN ('SCHEDULED', 'IN_PROGRESS'))
  ```
* **Relationships & Cardinalities:** 1:N with `gig.gig_milestone`; 1:1 with `gig.gig_rating`.
* **Architectural Justification:** Fulfills REQ-15, REQ-28, F-14, F-16, NFR-11, and WF-05. The GiST exclusion constraint mathematically prevents freelancer double-booking at the storage engine layer, raising error `23P01` on overlapping contract intervals.

#### 55. `gig.gig_milestone`
* **Classification:** Contract Deliverable Entity (9 columns)
* **Description:** Scheduled milestone deliverables tied to client escrow reserves and sign-off payouts.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `gig_contract_id` (UUID, NOT NULL), `milestone_number` (SMALLINT, NOT NULL), `milestone_title` (VARCHAR(150), NOT NULL), `milestone_amount` (NUMERIC(12,2), NOT NULL), `due_date` (DATE, NOT NULL), `escrow_ledger_id` (UUID), `signoff_status` (VARCHAR(20), DEFAULT 'PENDING', CHECK: IN ('PENDING', 'SUBMITTED', 'APPROVED', 'DISPUTED')), `completed_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:**
  - `gig_contract_id` ➔ `gig.gig_contract(id)` [ON DELETE CASCADE]
  - `escrow_ledger_id` ➔ `billing.wallet_ledger(id)` [ON DELETE SET NULL]
* **Architectural Justification:** Directly satisfies REQ-20, F-15, and WF-08: ensures that completed milestones trigger atomic escrow disbursement via double-entry ledger transfers.

#### 56. `gig.gig_rating`
* **Classification:** Two-Sided Evaluation Entity (7 columns)
* **Description:** Mutual post-completion performance review submitted by the employer and freelancer.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `gig_contract_id` (UUID, NOT NULL), `rater_user_id` (UUID, NOT NULL), `rated_user_id` (UUID, NOT NULL), `rating_score` (NUMERIC(3,2), NOT NULL, CHECK: rating_score BETWEEN 1.00 AND 5.00), `review_notes` (TEXT), `submitted_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `gig_contract_id` ➔ `gig.gig_contract(id)` [ON DELETE CASCADE]
  - `rater_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
  - `rated_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (gig_contract_id, rater_user_id)`
* **Architectural Justification:** Implements REQ-26 and F-18: post-completion feedback locked until contract sign-off.

#### 57. `gig.client_gig_worker_preference`
* **Classification:** Organizational Favoritism / Blacklist Entity (5 columns)
* **Description:** Employer favorite and blacklist registers for freelance contractors.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `organisation_id` (UUID, NOT NULL), `worker_profile_id` (UUID, NOT NULL), `preference_type` (VARCHAR(20), NOT NULL, CHECK: IN ('FAVOURITE', 'BLACKLISTED')), `notes` (TEXT), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE CASCADE]
  - `worker_profile_id` ➔ `gig.gig_worker_profile(user_account_id)` [ON DELETE CASCADE]
* **Unique Constraints:** `UNIQUE (organisation_id, worker_profile_id)`
* **Architectural Justification:** Directly satisfies REQ-23: blacklisted gig workers are automatically filtered from discovering employer postings via anti-join views.

---

### Module 9: Enterprise Subscription Licensing & Quotas (`licensing`)

*Manages tiered enterprise contracts, recruiter seat caps, and monthly resume unlock quotas.*

#### 58. `licensing.subscription_plan`
* **Classification:** Commercial Product Catalog Entity (8 columns)
* **Description:** Standard commercial subscription packages defining seat limits, features, and pricing tariffs.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `plan_code` (VARCHAR(50), UNIQUE, NOT NULL), `plan_name` (VARCHAR(100), NOT NULL), `billing_interval` (VARCHAR(20), NOT NULL, CHECK: IN ('MONTHLY', 'ANNUAL')), `base_price` (NUMERIC(12,2), NOT NULL), `currency_code` (CHAR(3), NOT NULL), `max_recruiter_seats` (INTEGER, NOT NULL), `monthly_resume_download_quota` (INTEGER, NOT NULL), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:** `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:N with `licensing.subscription_licence`.
* **Architectural Justification:** Mandated by REQ-73 and F-10 to define commercial entitlement boundaries.

#### 59. `licensing.subscription_licence`
* **Classification:** Enterprise Contract Entity (10 columns)
* **Description:** Active enterprise contractual license binding an account to a plan and governing seat allocations.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `account_id` (UUID, NOT NULL), `subscription_plan_id` (UUID, NOT NULL), `start_date` (DATE, NOT NULL), `end_date` (DATE, NOT NULL), `allocated_recruiter_seats` (INTEGER, NOT NULL), `licence_status` (VARCHAR(20), DEFAULT 'ACTIVE', CHECK: IN ('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELLED', 'EXPIRED')), `auto_renew` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:**
  - `account_id` ➔ `organisation.account(id)` [ON DELETE RESTRICT]
  - `subscription_plan_id` ➔ `licensing.subscription_plan(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:N with `organisation.recruiter_seat_assignment`, `licensing.licence_entitlement_usage`.
* **Architectural Justification:** Fulfills REQ-19, REQ-71, F-10, and WF-07: establishes contractual seat ceilings enforced during recruiter provisioning.

#### 60. `licensing.licence_entitlement_usage`
* **Classification:** Metered Consumption Entity (7 columns)
* **Description:** Tracks real-time monthly usage against contractual candidate resume unlock quotas.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `subscription_licence_id` (UUID, NOT NULL), `billing_period_start` (DATE, NOT NULL), `billing_period_end` (DATE, NOT NULL), `resume_downloads_consumed` (INTEGER, DEFAULT 0), `max_downloads_allowed` (INTEGER, NOT NULL)
* **Outbound Foreign Keys:** `subscription_licence_id` ➔ `licensing.subscription_licence(id)` [ON DELETE CASCADE]
* **Unique Constraints:** `UNIQUE (subscription_licence_id, billing_period_start)`
* **Architectural Justification:** Directly satisfies REQ-18, F-09, and WF-04: enables atomic decrementing of monthly download quotas prior to falling back on prepaid wallet balances.

---

### Module 10: Double-Entry Wallet, Escrow & Billing (`billing`)

*Implements double-entry append-only financial ledgers, milestone escrow holds, payment gateway orders, and tax invoices with guaranteed $0.00 accounting variance.*

#### 61. `billing.wallet_account`
* **Classification:** Core Financial Entity (8 columns)
* **Description:** Prepaid monetary wallet holding cleared funds and escrow reserves for employers and gig workers.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `owner_type` (VARCHAR(20), NOT NULL, CHECK: IN ('ORGANISATION', 'GIG_WORKER')), `owner_id` (UUID, NOT NULL), `cleared_balance` (NUMERIC(12,2), DEFAULT 0.00, NOT NULL), `escrow_locked_balance` (NUMERIC(12,2), DEFAULT 0.00, NOT NULL), `currency_code` (CHAR(3), NOT NULL), `wallet_status` (VARCHAR(20), DEFAULT 'ACTIVE', CHECK: IN ('ACTIVE', 'FROZEN', 'CLOSED'))
* **Outbound Foreign Keys:** `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (owner_type, owner_id, currency_code)`
* **Relationships & Cardinalities:** 1:N with `billing.wallet_ledger`, `billing.payment_order`.
* **Architectural Justification:** Mandated by REQ-04, REQ-17, F-11, and WF-08. Represents current balance state synchronized atomically with the double-entry ledger.

#### 62. `billing.wallet_ledger`
* **Classification:** Immutable Financial Ledger Entity (12 columns)
* **Description:** Sovereign, append-only double-entry transaction ledger enforcing zero balance drift.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `transaction_group_id` (UUID, NOT NULL), `wallet_account_id` (UUID, NOT NULL), `entry_type` (VARCHAR(10), NOT NULL, CHECK: IN ('DEBIT', 'CREDIT')), `amount` (NUMERIC(12,2), NOT NULL, CHECK: amount > 0), `running_cleared_balance` (NUMERIC(12,2), NOT NULL), `running_escrow_balance` (NUMERIC(12,2), NOT NULL), `reference_type` (VARCHAR(30), NOT NULL, CHECK: IN ('PREPAID_RECHARGE', 'RESUME_UNLOCK_FEE', 'ESCROW_LOCK', 'ESCROW_RELEASE', 'REFUND', 'DISPUTE_FREEZE')), `reference_id` (UUID, NOT NULL), `idempotency_key` (VARCHAR(64), UNIQUE, NOT NULL), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** `wallet_account_id` ➔ `billing.wallet_account(id)` [ON DELETE RESTRICT]
* **Table Triggers:** Database trigger strictly revokes direct `UPDATE` or `DELETE` operations on this table.
* **Architectural Justification:** Implements REQ-17, REQ-99, F-11, F-12, NFR-09, and WF-08. Enforces double-entry equality ($\sum \text{Debits} = \sum \text{Credits}$ per `transaction_group_id`) with guaranteed $\$0.00$ variance.

#### 63. `billing.payment_order`
* **Classification:** Transaction Intent Entity (9 columns)
* **Description:** Payment recharge order initiating an external payment gateway transaction.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `account_id` (UUID, NOT NULL), `wallet_account_id` (UUID, NOT NULL), `order_amount` (NUMERIC(12,2), NOT NULL), `currency_code` (CHAR(3), NOT NULL), `order_status` (VARCHAR(20), DEFAULT 'CREATED', CHECK: IN ('CREATED', 'PROCESSING', 'PAID', 'FAILED', 'CANCELLED')), `gateway_order_reference` (VARCHAR(100), UNIQUE), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `account_id` ➔ `organisation.account(id)` [ON DELETE RESTRICT]
  - `wallet_account_id` ➔ `billing.wallet_account(id)` [ON DELETE RESTRICT]
  - `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:1 with `billing.payment_transaction`; 1:1 with `billing.invoice`.
* **Architectural Justification:** Satisfies REQ-110 and REQ-74 for tracking prepaid deposit intents without persisting raw credit card credentials.

#### 64. `billing.payment_transaction`
* **Classification:** Settled Payment Entity (10 columns)
* **Description:** Successfully captured payment gateway transaction record confirming fund transfer.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `payment_order_id` (UUID, UNIQUE, NOT NULL), `gateway_transaction_id` (VARCHAR(100), UNIQUE, NOT NULL), `payment_method_type` (VARCHAR(30), NOT NULL, CHECK: IN ('CREDIT_CARD', 'DEBIT_CARD', 'NET_BANKING', 'UPI', 'WIRE')), `amount_settled` (NUMERIC(12,2), NOT NULL), `currency_code` (CHAR(3), NOT NULL), `settled_at` (TIMESTAMPTZ, NOT NULL)
* **Outbound Foreign Keys:**
  - `payment_order_id` ➔ `billing.payment_order(id)` [ON DELETE RESTRICT]
  - `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Architectural Justification:** PCI-DSS Level 1 compliance per REQ-110: stores tokenized gateway references and settlement timestamps with zero PAN/CVV storage.

#### 65. `billing.payment_gateway_event`
* **Classification:** Idempotent Webhook Log Entity (8 columns)
* **Description:** Asynchronous webhook event log guaranteeing exactly-once transaction processing.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `gateway_event_id` (VARCHAR(100), UNIQUE, NOT NULL), `event_type` (VARCHAR(50), NOT NULL), `payload_jsonb` (JSONB, NOT NULL), `payload_sha256` (VARCHAR(64), NOT NULL), `processing_status` (VARCHAR(20), DEFAULT 'PROCESSED', CHECK: IN ('PROCESSED', 'DUPLICATE_IGNORED', 'FAILED')), `received_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** None
* **Architectural Justification:** Directly satisfies REQ-21, REQ-119, and WF-08: guarantees idempotent webhook processing and eliminates double-credit posting during network retries.

#### 66. `billing.invoice`
* **Classification:** Corporate Tax Accounting Entity (11 columns)
* **Description:** Official corporate tax invoice with legal serial numbers, GST/VAT breakdowns, and PDF download links.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `account_id` (UUID, NOT NULL), `payment_order_id` (UUID, UNIQUE), `invoice_number` (VARCHAR(50), UNIQUE, NOT NULL), `subtotal_amount` (NUMERIC(12,2), NOT NULL), `tax_amount` (NUMERIC(12,2), NOT NULL), `total_amount` (NUMERIC(12,2), NOT NULL), `currency_code` (CHAR(3), NOT NULL), `invoice_status` (VARCHAR(20), DEFAULT 'PAID', CHECK: IN ('ISSUED', 'PAID', 'VOID', 'REFUNDED')), `invoice_pdf_uri` (VARCHAR(255)), `issued_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `account_id` ➔ `organisation.account(id)` [ON DELETE RESTRICT]
  - `payment_order_id` ➔ `billing.payment_order(id)` [ON DELETE SET NULL]
  - `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:N with `billing.invoice_item`.
* **Architectural Justification:** Mandated by REQ-74 for enterprise statutory tax compliance.

#### 67. `billing.invoice_item`
* **Classification:** Itemized Tax Entity (6 columns)
* **Description:** Detailed line-item breakdown of services rendered (seats, credits, subscriptions).
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `invoice_id` (UUID, NOT NULL), `item_description` (VARCHAR(255), NOT NULL), `quantity` (INTEGER, NOT NULL), `unit_price` (NUMERIC(12,2), NOT NULL), `total_line_amount` (NUMERIC(12,2), NOT NULL)
* **Outbound Foreign Keys:** `invoice_id` ➔ `billing.invoice(id)` [ON DELETE CASCADE]
* **Architectural Justification:** 3NF normalization for multi-item invoices per REQ-74.

#### 68. `billing.profile_download_history`
* **Classification:** Metered Unlock Receipt Entity (8 columns)
* **Description:** Append-only receipt generated whenever a recruiter unmasks candidate PII or downloads a resume.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `recruiter_user_id` (UUID, NOT NULL), `organisation_id` (UUID, NOT NULL), `candidate_profile_id` (UUID, NOT NULL), `credit_charge` (INTEGER, DEFAULT 1), `wallet_ledger_id` (UUID), `unlocked_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `recruiter_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
  - `organisation_id` ➔ `organisation.organisation(id)` [ON DELETE RESTRICT]
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE RESTRICT]
  - `wallet_ledger_id` ➔ `billing.wallet_ledger(id)` [ON DELETE SET NULL]
* **Unique Constraints:** `UNIQUE (organisation_id, candidate_profile_id)` (Recruiter pays once per candidate profile unlock)
* **Architectural Justification:** Directly satisfies REQ-18, REQ-78, F-09, and WF-04: enforces atomic quota deductions and generates non-repudiable candidate unlock receipts.

---

### Module 11: Candidate Engagement, Alerts, Messaging & Referrals (`engagement`)

*Drives candidate retention through personalized job alerts, real-time in-app recruiter messaging, tracked referral bonuses, and university campus cohort onboarding.*

#### 69. `engagement.candidate_saved_search`
* **Classification:** Search Preference Entity (7 columns)
* **Description:** Candidate-saved multi-facet search configurations for instantaneous re-execution.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `search_name` (VARCHAR(100), NOT NULL), `search_criteria_jsonb` (JSONB, NOT NULL), `is_alert_enabled` (BOOLEAN, DEFAULT TRUE), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
* **Architectural Justification:** Fulfills REQ-26 and F-20: powers candidate faceted job discovery and persistence.

#### 70. `engagement.job_alert_subscription`
* **Classification:** Automated Alert Entity (7 columns)
* **Description:** Candidate alert feed dispatching notifications when newly published requisitions match saved criteria.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `candidate_profile_id` (UUID, NOT NULL), `desired_job_role_id` (UUID), `city_id` (UUID), `min_salary_threshold` (NUMERIC(12,2)), `alert_frequency` (VARCHAR(20), DEFAULT 'DAILY', CHECK: IN ('INSTANT', 'DAILY', 'WEEKLY')), `is_active` (BOOLEAN, DEFAULT TRUE)
* **Outbound Foreign Keys:**
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
  - `desired_job_role_id` ➔ `master_data.job_role(id)` [ON DELETE CASCADE]
  - `city_id` ➔ `master_data.city(id)` [ON DELETE SET NULL]
* **Architectural Justification:** Directly satisfies REQ-27 and F-21: batch evaluation of newly published job requisitions against candidate subscriptions.

#### 71. `engagement.notification_delivery`
* **Classification:** Multi-Channel Notification Entity (9 columns)
* **Description:** Outbound notification queue tracking in-app, email, and SMS message delivery statuses.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `recipient_user_id` (UUID, NOT NULL), `channel_type` (VARCHAR(20), NOT NULL, CHECK: IN ('IN_APP', 'EMAIL', 'SMS')), `notification_title` (VARCHAR(150), NOT NULL), `notification_body` (TEXT, NOT NULL), `payload_jsonb` (JSONB), `delivery_status` (VARCHAR(20), DEFAULT 'QUEUED', CHECK: IN ('QUEUED', 'SENT', 'DELIVERED', 'READ', 'FAILED')), `sent_at` (TIMESTAMPTZ), `read_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:** `recipient_user_id` ➔ `identity.user_account(id)` [ON DELETE CASCADE]
* **Architectural Justification:** Mandated by REQ-38, REQ-69, and REQ-115 for reliable event dispatching across messaging boundaries.

#### 72. `engagement.message_thread`
* **Classification:** Direct Communication Channel Entity (7 columns)
* **Description:** Secure in-app communication channel between an authorized recruiter and an unlocked candidate.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `job_requisition_id` (UUID, NOT NULL), `recruiter_user_id` (UUID, NOT NULL), `candidate_user_id` (UUID, NOT NULL), `unlock_receipt_id` (UUID, NOT NULL), `thread_status` (VARCHAR(20), DEFAULT 'ACTIVE', CHECK: IN ('ACTIVE', 'ARCHIVED', 'BLOCKED')), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `job_requisition_id` ➔ `recruitment.job_requisition(id)` [ON DELETE RESTRICT]
  - `recruiter_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
  - `candidate_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
  - `unlock_receipt_id` ➔ `billing.profile_download_history(id)` [ON DELETE RESTRICT]
* **Unique Constraints:** `UNIQUE (job_requisition_id, recruiter_user_id, candidate_user_id)`
* **Relationships & Cardinalities:** 1:N with `engagement.thread_message`.
* **Architectural Justification:** Directly satisfies REQ-28 and F-22: ensures direct recruiter-candidate messaging is unlocked only after authorized profile unlock receipts exist.

#### 73. `engagement.thread_message`
* **Classification:** Communication Message Entity (6 columns)
* **Description:** Individual chronological text messages exchanged within an authorized recruitment thread.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `message_thread_id` (UUID, NOT NULL), `sender_user_id` (UUID, NOT NULL), `message_body` (TEXT, NOT NULL), `is_read` (BOOLEAN, DEFAULT FALSE), `sent_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `message_thread_id` ➔ `engagement.message_thread(id)` [ON DELETE CASCADE]
  - `sender_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Architectural Justification:** Satisfies REQ-28: provides encrypted, auditable messaging between recruiters and candidates.

#### 74. `engagement.candidate_referral_link`
* **Classification:** Referral Tracking Entity (7 columns)
* **Description:** Unique attribution-tracked alphanumeric referral links generated by candidates and employees.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `referrer_user_id` (UUID, NOT NULL), `referral_code` (VARCHAR(30), UNIQUE, NOT NULL), `target_job_requisition_id` (UUID), `total_clicks` (INTEGER, DEFAULT 0), `is_active` (BOOLEAN, DEFAULT TRUE), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:**
  - `referrer_user_id` ➔ `identity.user_account(id)` [ON DELETE CASCADE]
  - `target_job_requisition_id` ➔ `recruitment.job_requisition(id)` [ON DELETE SET NULL]
* **Relationships & Cardinalities:** 1:N with `engagement.referral_attribution_event`.
* **Architectural Justification:** Directly satisfies REQ-23 and F-18 for candidate viral referral attribution.

#### 75. `engagement.referral_attribution_event`
* **Classification:** Referral Reward Settlement Entity (7 columns)
* **Description:** Tracks referee application, hiring milestones, and bonus bounty payouts to the referring user.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `referral_link_id` (UUID, NOT NULL), `referred_candidate_id` (UUID, NOT NULL), `hiring_application_id` (UUID, NOT NULL), `referral_bonus_amount` (NUMERIC(12,2), NOT NULL), `currency_code` (CHAR(3), NOT NULL), `payout_status` (VARCHAR(20), DEFAULT 'PENDING', CHECK: IN ('PENDING', 'APPROVED', 'DISBURSED', 'REJECTED')), `awarded_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:**
  - `referral_link_id` ➔ `engagement.candidate_referral_link(id)` [ON DELETE RESTRICT]
  - `referred_candidate_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE RESTRICT]
  - `hiring_application_id` ➔ `application.job_application(id)` [ON DELETE RESTRICT]
  - `currency_code` ➔ `master_data.currency(currency_code)` [ON DELETE RESTRICT]
* **Architectural Justification:** Mandated by REQ-23 and F-18 to prevent duplicate referral bounty claims.

#### 76. `engagement.campus_placement_cohort`
* **Classification:** Academic Batch Group Entity (8 columns)
* **Description:** University student cohorts managed by academic Training & Placement Officers (TPOs).
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `placement_officer_user_id` (UUID, NOT NULL), `university_name` (VARCHAR(150), NOT NULL), `college_code` (VARCHAR(50), NOT NULL), `degree_program` (VARCHAR(100), NOT NULL), `graduation_year` (SMALLINT, NOT NULL), `minimum_cgpa_cutoff` (NUMERIC(4,2), DEFAULT 0.00), `is_verified_cohort` (BOOLEAN, DEFAULT FALSE)
* **Outbound Foreign Keys:** `placement_officer_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Relationships & Cardinalities:** 1:N with `engagement.campus_student_member`.
* **Architectural Justification:** Fulfills REQ-22, REQ-15, F-19, and WF-09: models academic institutional boundaries and batch onboarding drives.

#### 77. `engagement.campus_student_member`
* **Classification:** Academic Roster Association Entity (6 columns)
* **Description:** Individual student membership within an accredited university campus placement cohort.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `cohort_id` (UUID, NOT NULL), `candidate_profile_id` (UUID, NOT NULL), `university_roll_number` (VARCHAR(50), NOT NULL), `cumulative_cgpa` (NUMERIC(4,2), NOT NULL), `is_placed` (BOOLEAN, DEFAULT FALSE)
* **Outbound Foreign Keys:**
  - `cohort_id` ➔ `engagement.campus_placement_cohort(id)` [ON DELETE CASCADE]
  - `candidate_profile_id` ➔ `candidate.candidate_profile(user_account_id)` [ON DELETE CASCADE]
* **Unique Constraints:** `UNIQUE (cohort_id, candidate_profile_id)`
* **Architectural Justification:** Satisfies REQ-22 and WF-09: allows enterprise recruiters to conduct campus placement drives targeted at specific student cohorts.

---

### Module 12: Regulatory Compliance, DPDP Consent & Forensic Audit (`governance`)

*Enforces statutory DPDP Act 2023 purpose-bound consent lifecycles, Data Encryption Key (DEK) shredding, and immutable append-only forensic audit trails.*

#### 78. `governance.dpdp_consent_record`
* **Classification:** Statutory Privacy Register Entity (8 columns)
* **Description:** Affirmative, purpose-bound consent collection register mandated by the Indian Digital Personal Data Protection Act 2023.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `user_account_id` (UUID, NOT NULL), `consent_purpose_code` (VARCHAR(50), NOT NULL, CHECK: IN ('JOB_APPLICATION_PROCESSING', 'RECRUITER_SEARCH_DISCOVERY', 'MARKETPLACE_OUTREACH', 'CAMPUS_PLACEMENT_SHARING')), `consent_status` (VARCHAR(20), NOT NULL, CHECK: IN ('GRANTED', 'REVOKED')), `client_ip_hash` (VARCHAR(64), NOT NULL), `user_agent` (VARCHAR(255)), `granted_at` (TIMESTAMPTZ, DEFAULT clock_timestamp()), `revoked_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:** `user_account_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Architectural Justification:** Directly satisfies REQ-10, F-17, NFR-08, and WF-01/WF-10: provides verifiable legal proof of affirmative consent and tracks instant statutory withdrawal.

#### 79. `governance.pii_encryption_key`
* **Classification:** Cryptographic Key Registry Entity (7 columns)
* **Description:** Stores encrypted Data Encryption Keys (DEKs) for envelope encryption, enabling instant Right-to-be-Forgotten data shredding.
* **Primary Key:** `key_id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `user_account_id` (UUID, UNIQUE, NOT NULL), `encrypted_dek_payload` (BYTEA, NOT NULL), `key_algorithm` (VARCHAR(30), DEFAULT 'AES-256-GCM'), `key_version` (SMALLINT, DEFAULT 1), `is_shredded` (BOOLEAN, DEFAULT FALSE), `shredded_at` (TIMESTAMPTZ)
* **Outbound Foreign Keys:** `user_account_id` ➔ `identity.user_account(id)` [ON DELETE CASCADE]
* **Architectural Justification:** Implements REQ-10, REQ-136, F-17, and WF-10. Upon candidate consent withdrawal, deleting or zeroing the candidate's DEK renders all stored PII cryptographically unrecoverable within $\le 2.0\text{ seconds}$ without executing destructive table purges that corrupt historical financial ledgers.

#### 80. `governance.system_audit_event`
* **Classification:** Immutable Forensic Audit Trail (11 columns)
* **Description:** Sovereign append-only event log capturing all security, administrative, and data unlock mutations.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `actor_user_id` (UUID, NOT NULL), `actor_role_code` (VARCHAR(50), NOT NULL), `client_ip` (INET, NOT NULL), `action_type` (VARCHAR(100), NOT NULL), `target_entity` (VARCHAR(100), NOT NULL), `target_record_id` (UUID, NOT NULL), `pre_mutation_state` (JSONB), `post_mutation_state` (JSONB), `record_sha256_hash` (VARCHAR(64), NOT NULL), `created_at` (TIMESTAMPTZ, DEFAULT clock_timestamp())
* **Outbound Foreign Keys:** `actor_user_id` ➔ `identity.user_account(id)` [ON DELETE RESTRICT]
* **Table Triggers:** PostgreSQL database trigger strictly aborts any `UPDATE` or `DELETE` statement.
* **Architectural Justification:** Satisfies REQ-09, REQ-56, F-16, and NFR-07: guarantees legal non-repudiation of administrative mutations and compliance event auditing.

#### 81. `governance.data_retention_policy`
* **Classification:** Regulatory Lifecycle Policy Entity (6 columns)
* **Description:** Defines statutory retention windows and automated archival actions per data classification tier.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `entity_name` (VARCHAR(100), UNIQUE, NOT NULL), `sensitivity_tier` (VARCHAR(20), NOT NULL, CHECK: IN ('PUBLIC', 'INTERNAL', 'PERSONAL', 'SENSITIVE')), `retention_months` (SMALLINT, NOT NULL), `legal_basis` (VARCHAR(100), NOT NULL), `purge_action` (VARCHAR(30), NOT NULL, CHECK: IN ('ANONYMIZE', 'HARD_DELETE', 'ARCHIVE_COLD_STORAGE'))
* **Outbound Foreign Keys:** None
* **Architectural Justification:** Directly satisfies REQ-11 and REQ-95: governs automated background purge daemons (`SYS-01`) enforcing statutory data minimization.

---

### Module 13: Analytical Star Schema & Aggregates (`analytics`)

*Kimball dimensional star schema supporting executive C-suite dashboards, talent acquisition pipeline conversion reporting, recruiter productivity metrics, and contractor earnings.*

#### 82. `analytics.dim_date`
* **Classification:** Role-Playing Date Dimension (10 columns)
* **Description:** Standard temporal dimension mapping continuous calendar dates to fiscal quarters, months, and working days.
* **Primary Key:** `date_key` (INTEGER, Format: YYYYMMDD)
* **Key Attributes:** `calendar_date` (DATE, UNIQUE, NOT NULL), `day_of_week` (SMALLINT), `day_name` (VARCHAR(10)), `calendar_month` (SMALLINT), `month_name` (VARCHAR(10)), `calendar_quarter` (SMALLINT), `calendar_year` (SMALLINT), `is_weekend` (BOOLEAN), `is_national_holiday` (BOOLEAN)
* **Outbound Foreign Keys:** None
* **Architectural Justification:** Foundational dimensional spine enabling slice-and-dice aggregations across all transactional facts per REQ-141.

#### 83. `analytics.dim_candidate`
* **Classification:** Type-1 Conformed Dimension (8 columns)
* **Description:** Denormalized candidate dimension capturing demographic and qualification groupings.
* **Primary Key:** `candidate_key` (INTEGER, IDENTITY)
* **Key Attributes:** `candidate_profile_id` (UUID, UNIQUE, NOT NULL), `experience_tier` (VARCHAR(30)), `primary_skill_name` (VARCHAR(100)), `highest_qualification` (VARCHAR(100)), `city_name` (VARCHAR(100)), `country_code` (CHAR(2))
* **Outbound Foreign Keys:** None
* **Architectural Justification:** Powers candidate retention and recruitment funnel analytics per REQ-003 and REQ-141.

#### 84. `analytics.dim_organisation`
* **Classification:** Type-1 Conformed Dimension (6 columns)
* **Description:** Denormalized corporate employer dimension capturing industry and organizational size tiers.
* **Primary Key:** `organisation_key` (INTEGER, IDENTITY)
* **Key Attributes:** `organisation_id` (UUID, UNIQUE, NOT NULL), `legal_name` (VARCHAR(150), NOT NULL), `industry_name` (VARCHAR(100), NOT NULL), `company_size_tier` (VARCHAR(30))
* **Outbound Foreign Keys:** None
* **Architectural Justification:** Enables multi-tenant corporate productivity benchmarking per REQ-141.

#### 85. `analytics.dim_job_requisition`
* **Classification:** Conformed Dimension (7 columns)
* **Description:** Denormalized job requisition dimension tracking job categories and compensation tiers.
* **Primary Key:** `requisition_key` (INTEGER, IDENTITY)
* **Key Attributes:** `job_requisition_id` (UUID, UNIQUE, NOT NULL), `job_title` (VARCHAR(150), NOT NULL), `job_category` (VARCHAR(30), NOT NULL), `employment_type` (VARCHAR(30), NOT NULL), `salary_tier` (VARCHAR(30))
* **Outbound Foreign Keys:** None
* **Architectural Justification:** Supports job category conversion and time-to-fill analytics across all 8 workforce models per REQ-141.

#### 86. `analytics.dim_pipeline_stage`
* **Classification:** Conformed Dimension (5 columns)
* **Description:** Represents discrete milestones within the 13-stage hiring funnel.
* **Primary Key:** `stage_key` (INTEGER, IDENTITY)
* **Key Attributes:** `stage_code` (VARCHAR(30), UNIQUE, NOT NULL), `stage_name` (VARCHAR(50), NOT NULL), `funnel_order` (SMALLINT, NOT NULL), `is_terminal_stage` (BOOLEAN, DEFAULT FALSE)
* **Outbound Foreign Keys:** None
* **Architectural Justification:** Powers application drop-off and conversion rate analysis per REQ-001 and REQ-141.

#### 87. `analytics.fact_application_event`
* **Classification:** Periodic Snapshot / Accumulating Fact (9 columns)
* **Description:** Captures candidate progression velocity between application stages.
* **Primary Key:** `id` (UUID, DEFAULT gen_random_uuid())
* **Key Attributes:** `date_key` (INTEGER, NOT NULL), `candidate_key` (INTEGER, NOT NULL), `organisation_key` (INTEGER, NOT NULL), `requisition_key` (INTEGER, NOT NULL), `from_stage_key` (INTEGER, NOT NULL), `to_stage_key` (INTEGER, NOT NULL), `stage_duration_hours` (NUMERIC(8,2), NOT NULL)
* **Outbound Foreign Keys:**
  - `date_key` ➔ `analytics.dim_date(date_key)`
  - `candidate_key` ➔ `analytics.dim_candidate(candidate_key)`
  - `organisation_key` ➔ `analytics.dim_organisation(organisation_key)`
  - `requisition_key` ➔ `analytics.dim_job_requisition(requisition_key)`
  - `from_stage_key` ➔ `analytics.dim_pipeline_stage(stage_key)`
  - `to_stage_key` ➔ `analytics.dim_pipeline_stage(stage_key)`
* **Architectural Justification:** Directly satisfies G1 and REQ-141: calculates precise time-to-hire, funnel bottleneck latency, and recruiter drop-off ratios.

#### 88. `analytics.fact_profile_download`
* **Classification:** Transactional Fact (7 columns)
* **Description:** Records recruiter sourcing activity, quota consumption, and talent search monetization.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `date_key` (INTEGER, NOT NULL), `organisation_key` (INTEGER, NOT NULL), `candidate_key` (INTEGER, NOT NULL), `recruiter_user_id` (UUID, NOT NULL), `credits_consumed` (INTEGER, NOT NULL)
* **Outbound Foreign Keys:**
  - `date_key` ➔ `analytics.dim_date(date_key)`
  - `organisation_key` ➔ `analytics.dim_organisation(organisation_key)`
  - `candidate_key` ➔ `analytics.dim_candidate(candidate_key)`
* **Architectural Justification:** Measures recruiter talent sourcing velocity and quota utilization per REQ-18 and REQ-141.

#### 89. `analytics.fact_gig_contract`
* **Classification:** Transactional Fact (9 columns)
* **Description:** Tracks contingent project values, milestone delivery timeliness, and contractor rating scores.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `date_key` (INTEGER, NOT NULL), `organisation_key` (INTEGER, NOT NULL), `worker_user_id` (UUID, NOT NULL), `contract_duration_days` (INTEGER, NOT NULL), `total_value_usd` (NUMERIC(12,2), NOT NULL), `final_performance_rating` (NUMERIC(3,2))
* **Outbound Foreign Keys:**
  - `date_key` ➔ `analytics.dim_date(date_key)`
  - `organisation_key` ➔ `analytics.dim_organisation(organisation_key)`
* **Architectural Justification:** Mandated by REQ-25 and REQ-141 for contingent workforce spend reporting and contractor earnings benchmarks.

#### 90. `analytics.fact_wallet_transaction`
* **Classification:** Transactional Financial Fact (8 columns)
* **Description:** High-level daily financial reconciliations derived from the double-entry ledger.
* **Primary Key:** `id` (UUID)
* **Key Attributes:** `date_key` (INTEGER, NOT NULL), `organisation_key` (INTEGER, NOT NULL), `transaction_category` (VARCHAR(30), NOT NULL), `total_debit_amount` (NUMERIC(14,2), NOT NULL), `total_credit_amount` (NUMERIC(14,2), NOT NULL), `net_variance` (NUMERIC(14,2), DEFAULT 0.00)
* **Outbound Foreign Keys:**
  - `date_key` ➔ `analytics.dim_date(date_key)`
  - `organisation_key` ➔ `analytics.dim_organisation(organisation_key)`
* **Architectural Justification:** Verifies ongoing financial reconciliation and zero balance drift ($0.00 variance) per REQ-17 and REQ-141.

---

## 4. Entity Delta Matrix: Critique & Rationalization Analysis

| Entity Group / Topic | Original Draft (301 Tables) | Redesigned ERL (90 Tables) | Delta Impact | Concrete Technical Justification |
| :--- | :---: | :---: | :---: | :--- |
| **Social Community & Forum** | 25 tables (`community_post`, `comment`, `reaction`, etc.) | **0 tables** | **-25** | **Removed:** Unrelated to enterprise workforce platform; violates boundary `OOS-07`. |
| **Generic Support Ticketing** | 10 tables (`support_ticket`, `message`, `attachment`, etc.) | **0 tables** | **-10** | **Removed:** Replaced by dispute sub-ledgers and arbitration workflows on gigs (`WF-05`, `EXC-10`). |
| **Boilerplate Lookup Tables** | 50+ 9-column lookup tables with circular user FKs | **11 normalized lookups** | **-39** | **Consolidated:** Replaced with standardized ISO reference tables or check constraints. |
| **Campus Placement Cohorts** | 0 tables | **2 tables** (`campus_placement_cohort`, `campus_student_member`) | **+2** | **Added:** Essential for University Placement Officers (TPOs) and graduate batch onboarding (`REQ-22`, `WF-09`). |
| **Gig Milestones & Deliverables** | 0 tables (flat assignment only) | **1 table** (`gig_milestone`) | **+1** | **Added:** Required for milestone sign-off and escrow disbursements (`REQ-20`, `WF-05`, `F-15`). |
| **GiST Non-Overlap Enforcement** | Untyped date columns | **`tstzrange` on `gig_contract`** | **Schema Fix** | **Added:** Enables PostgreSQL `EXCLUDE USING gist` to mathematically prevent gig double-booking (`REQ-15`, `NFR-11`). |
| **Double-Entry Paired Ledger** | 1 table without debit/credit balancing | **1 table with strict paired entries** (`wallet_ledger`) | **Schema Fix** | **Fixed:** Implements true double-entry accounting with transaction grouping keys (`REQ-17`, `NFR-09`). |
| **DPDP Cryptographic DEK Shredding** | 0 tables | **1 table** (`pii_encryption_key`) | **+1** | **Added:** Operationalizes statutory $\le 2.0\text{s}$ Right-to-be-Forgotten PII erasure via key shredding (`REQ-10`, `WF-10`). |
| **In-App Direct Messaging** | 0 tables | **2 tables** (`message_thread`, `thread_message`) | **+2** | **Added:** Provides secure, auditable communication between recruiters and unlocked candidates (`REQ-28`, `F-22`). |
| **Screening Questionnaire Trees** | 3 shallow tables without scoring | **3 structured tables with scoring weights** | **Refactored** | **Fixed:** Versioned questionnaires with weighted question scoring and passing thresholds (`REQ-07`, `F-05`). |
| **Candidate 1:1 Contact Splitting** | Fractured across `candidate_profile` & `candidate_contact` | **Merged into `candidate_profile`** | **-1** | **Normalized:** Eliminates unnecessary 1:1 table join overhead; satisfies 3NF. |
| **Analytics Star Schema** | 48 tables (mixed staging, reject, and fact tables) | **9 conformed dimensions & facts** | **-39** | **Refactored:** True Kimball dimensional star schema cleanly separated from transactional OLTP tables (`REQ-141`). |

---

## 5. Master Relational Cardinality & Integrity Mapping

```
                               ┌─────────────────────────────────────────┐
                               │       identity.user_account             │
                               └───────┬────────────┬────────────┬───────┘
                                       │ 1:1        │ 1:1        │ 1:N
                  ┌────────────────────┘            │            └────────────────────┐
                  ▼                                 ▼                                 ▼
┌──────────────────────────────────┐ ┌──────────────────────────────┐ ┌──────────────────────────────────┐
│    candidate.candidate_profile   │ │    gig.gig_worker_profile    │ │   identity.user_active_session   │
└───────┬─────────────┬────────────┘ └───────┬─────────────┬────────┘ └──────────────────────────────────┘
        │ 1:N         │ 1:N                  │ 1:N         │ 1:N
        ▼             ▼                      ▼             ▼
┌──────────────┐ ┌─────────────────┐ ┌──────────────┐ ┌──────────────────────────────────────────────┐
│cand._skill   │ │cand._block_list │ │gig_service   │ │             gig.gig_contract                 │
└──────────────┘ └─────────────────┘ └──────────────┘ │ [EXCLUDE USING gist (worker_id, window)]     │
                                                      └───────┬──────────────────────────────────────┘
                                                              │ 1:N
                                                              ▼
                                                      ┌──────────────────────────────────────────────┐
                                                      │              gig.gig_milestone               │
                                                      │ (Milestone signoff releases escrow payout)   │
                                                      └───────┬──────────────────────────────────────┘
                                                              │
                                                              ▼
                                                      ┌──────────────────────────────────────────────┐
                                                      │             billing.wallet_ledger            │
                                                      │ (Append-Only Double-Entry: $0.00 Variance)   │
                                                      └──────────────────────────────────────────────┘
```

### Key Relational Cardinalities:
1. **User Identity to Candidate Profile:** `identity.user_account` $\mathbf{1:1}$ `candidate.candidate_profile`
2. **User Identity to Session Concurrency:** `identity.user_account` $\mathbf{1:N}$ `identity.user_active_session`
3. **Candidate to Privacy Shield:** `candidate.candidate_profile` $\mathbf{1:N}$ `candidate.candidate_block_list`
4. **Corporate Account to Organizations:** `organisation.account` $\mathbf{1:N}$ `organisation.organisation`
5. **Organization to Job Requisitions:** `organisation.organisation` $\mathbf{1:N}$ `recruitment.job_requisition`
6. **Job Requisition to Screening Questionnaire:** `recruitment.job_requisition` $\mathbf{1:1}$ `recruitment.job_questionnaire`
7. **Screening Questionnaire to Questions:** `recruitment.job_questionnaire` $\mathbf{1:N}$ `recruitment.questionnaire_question`
8. **Requisition & Candidate to Application:** `(recruitment.job_requisition, candidate.candidate_profile)` $\mathbf{1:N}$ `application.job_application` (Unique constraint enforces 1 active application per job)
9. **Job Application to Stage History:** `application.job_application` $\mathbf{1:N}$ `application.application_stage_history`
10. **Job Application to Interviews & Offers:** `application.job_application` $\mathbf{1:N}$ `application.job_interview`, `application.job_application` $\mathbf{1:1}$ `application.job_offer`
11. **Gig Worker to Contract (GiST Protected):** `gig.gig_worker_profile` $\mathbf{1:N}$ `gig.gig_contract` (`EXCLUDE USING gist`)
12. **Gig Contract to Milestones:** `gig.gig_contract` $\mathbf{1:N}$ `gig.gig_milestone`
13. **Wallet Account to Double-Entry Ledger:** `billing.wallet_account` $\mathbf{1:N}$ `billing.wallet_ledger` (Paired DEBIT/CREDIT with matching `transaction_group_id`)
14. **User to DPDP Consent Register:** `identity.user_account` $\mathbf{1:N}$ `governance.dpdp_consent_record`
15. **User to Cryptographic DEK Key:** `identity.user_account` $\mathbf{1:1}$ `governance.pii_encryption_key` (Zeroing DEK executes instant erasure)
16. **Campus TPO to Placement Cohorts:** `identity.user_account` $\mathbf{1:N}$ `engagement.campus_placement_cohort`
17. **Placement Cohort to Student Roster:** `engagement.campus_placement_cohort` $\mathbf{1:N}$ `engagement.campus_student_member`
18. **Recruiter & Candidate to Messaging Thread:** `(identity.user_account, candidate.candidate_profile)` $\mathbf{1:N}$ `engagement.message_thread` (Bound to `unlock_receipt_id`)
