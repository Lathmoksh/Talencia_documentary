# Talentra Enterprise: Published Baseline ER Model v1 Documentation

**Platform:** Talentra Enterprise Workforce & Demand Management Platform  
**Document Reference:** Deliverable 21 — Baseline ER Model & Physical Relational Specification  
**Architecture:** 13 Domain Schemas, 90 Normalized Tables, 893 Columns, 160 Foreign Key Relationships  
**Target RDBMS:** PostgreSQL 16 (Tiered NVMe, Row-Level Security, GiST Temporal Constraints, Double-Entry Balance)  
**Mermaid Source:** [`talentra_er_v1.mmd`](talentra_er_v1.mmd)  

---

## 1. Executive Architecture & Model Overview

The Talentra Baseline ER Model v1 delivers a production-grade relational foundation that completely resolves the defects of the historical draft. It isolates business domains into 13 dedicated schemas, enforces strict 3rd Normal Form (3NF) across operational tables, and implements a Kimball Star Schema across analytical reporting marts.

```
+----------------------------------------------------------------------------------------------------+
|                                    13 DOMAIN SCHEMAS OVERVIEW                                      |
+-------------------+--------------------+--------------------+--------------------+-----------------+
| 1. master_data    | 2. identity        | 3. organisation    | 4. candidate       | 5. recruitment  |
| (11 Tables)       | (6 Tables)         | (7 Tables)         | (9 Tables)         | (5 Tables)      |
+-------------------+--------------------+--------------------+--------------------+-----------------+
| 6. application    | 7. sourcing        | 8. gig             | 9. licensing       | 10. billing     |
| (6 Tables)        | (4 Tables)         | (9 Tables)         | (3 Tables)         | (8 Tables)      |
+-------------------+--------------------+--------------------+--------------------+-----------------+
| 11. engagement    | 12. governance     | 13. analytics      |                    | TOTAL: 90       |
| (9 Tables)        | (4 Tables)         | (9 Tables)         |                    | TABLES          |
+-------------------+--------------------+--------------------+--------------------+-----------------+
```

---

## 2. Domain Schema Summaries & Relationship Semantics

### 2.1 Master Reference & Localization (`master_data` — 11 Tables)
- **Tables:** `country`, `state`, `city`, `currency`, `language`, `industry`, `job_role`, `skill`, `qualification`, `ui_translation_key`, `ui_translation`.
- **Primary Relationships:** Sovereign ISO hierarchies (`country -> state -> city`), ISO 4217 currencies, and multilingual localization strings.
- **Integrity Rule:** `ON DELETE RESTRICT` on all references to guarantee zero orphan references across transactional profiles.

### 2.2 Identity, Security & Access (`identity` — 6 Tables)
- **Tables:** `user_account`, `user_credential`, `role`, `user_role`, `user_active_session`, `service_api_key`.
- **Primary Relationships:** `user_account` acts as the root principal. Credentials and multi-device sessions attach to `user_account`. RBAC permissions are assigned via `user_role`.
- **Integrity Rule:** Hardened status checking (`account_status`) and password hashing via Argon2id.

### 2.3 Corporate Tenancy & Recruiter Governance (`organisation` — 7 Tables)
- **Tables:** `account`, `organisation`, `organisation_location`, `organisation_tax_identifier`, `organisation_verification`, `recruiter_seat_assignment`, `organisation_hierarchy`.
- **Primary Relationships:** Billing tenant boundaries (`account`) own one or more corporate legal entities (`organisation`). Recruiters are allocated to seats (`recruiter_seat_assignment`) up to the licensed quota.

### 2.4 Candidate Profile, Resume & Privacy Shield (`candidate` — 9 Tables)
- **Tables:** `candidate_profile`, `candidate_education`, `candidate_work_experience`, `candidate_skill`, `candidate_project`, `candidate_resume`, `candidate_preference`, `candidate_block_list`, `candidate_language`.
- **Primary Relationships:** `candidate_profile` links to `identity.user_account`. Normalized 3NF child tables store education, employment history, and skills.
- **Privacy Shield:** `candidate_block_list` provides directional employer anti-join filtering, hiding candidates from current/former employers.

### 2.5 Recruitment Requisitions & Questionnaires (`recruitment` — 5 Tables)
- **Tables:** `job_requisition`, `job_requisition_skill`, `job_questionnaire`, `questionnaire_question`, `question_option`.
- **Primary Relationships:** Requisitions belong to an organisation and contain weighted screening question trees.

### 2.6 Application Pipeline & State Machine (`application` — 6 Tables)
- **Tables:** `job_application`, `application_question_answer`, `application_stage_history`, `job_interview`, `interview_feedback`, `job_offer`.
- **Primary Relationships:** Connects candidates to requisitions through a 13-stage deterministic FSM (`application_stage_history`).

### 2.7 Sourcing & Outreach (`sourcing` — 4 Tables)
- **Tables:** `consultant_authorization`, `candidate_nomination`, `outreach_campaign`, `outreach_recipient`.
- **Primary Relationships:** Manages agency recruiter authorizations and tracked candidate nominations.

### 2.8 Gig Marketplace & Availability (`gig` — 9 Tables)
- **Tables:** `gig_worker_profile`, `gig_worker_service`, `gig_worker_availability`, `gig_request`, `gig_proposal`, `gig_contract`, `gig_milestone`, `gig_rating`, `client_gig_worker_preference`.
- **Primary Relationships:** Freelancers list services and availability windows. Contracts feature milestone-based escrow reservations.
- **GiST Non-Overlap Constraint:** `gig_worker_availability` enforces `EXCLUDE USING gist (worker_id WITH =, availability_window WITH &&)`.

### 2.9 Licensing & Entitlements (`licensing` — 3 Tables)
- **Tables:** `subscription_plan`, `subscription_licence`, `licence_entitlement_usage`.
- **Primary Relationships:** Multi-tenant SaaS subscription plans and real-time quota metering.

### 2.10 Billing, Double-Entry Ledger & Escrow (`billing` — 8 Tables)
- **Tables:** `wallet_account`, `wallet_ledger`, `payment_order`, `payment_transaction`, `payment_gateway_event`, `invoice`, `invoice_item`, `profile_download_history`.
- **Double-Entry Balance Invariant:** Append-only ledger entries enforce paired debits/credits with guaranteed $0.00 drift.

### 2.11 Engagement & Campus Placement (`engagement` — 9 Tables)
- **Tables:** `candidate_saved_search`, `job_alert_subscription`, `notification_delivery`, `message_thread`, `thread_message`, `candidate_referral_link`, `referral_attribution_event`, `campus_placement_cohort`, `campus_student_member`.
- **Primary Relationships:** Real-time job alerts, in-app recruiter messaging, and University Placement Officer (TPO) cohort drives.

### 2.12 Governance & DPDP Key Shredding (`governance` — 4 Tables)
- **Tables:** `dpdp_consent_record`, `pii_encryption_key`, `system_audit_event`, `data_retention_policy`.
- **Cryptographic Key Shredding:** Stored procedure `governance.sp_shred_candidate_dek` destroys candidate DEK keys upon consent withdrawal.

### 2.13 Kimball Star Schema Analytics Marts (`analytics` — 9 Tables)
- **Dimensions:** `dim_date`, `dim_candidate`, `dim_organisation`, `dim_job_requisition`, `dim_pipeline_stage`.
- **Facts:** `fact_application_event`, `fact_profile_download`, `fact_gig_contract`, `fact_wallet_transaction`.
- **Analytics Function:** Powers executive C-suite KPI queries with 100% mathematical reconciliation to OLTP source tables.

---

## 3. Publication & Gate Sign-Off

The baseline ER model is frozen in `talentra_er_v1.mmd` and matches `10_Data_Dictionary_v1.md`, `11_Data_Rules_and_Constraints_Discovery.md`, and the baseline migration `database/migrations/V1__baseline.sql`.
