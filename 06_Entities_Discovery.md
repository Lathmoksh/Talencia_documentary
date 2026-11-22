# Deliverable Step 06: Comprehensive Entities Discovery Docket

**Platform:** Talentra Enterprise Workforce & Talent Demand Management Platform  
**Document Reference:** Deliverable 06 — Business Entity Inventory & Domain Boundaries  
**Phase:** 2 — Model  
**Standards Alignment:** 3rd Normal Form (3NF) Relational Architecture & Kimball Star Schema  
**Scope:** 13 Logical Domain Schemas, 90 Normalized Entities  
**Traceability:** Mapped to Phase 1 Requirements (`REQ-01` to `REQ-45`), Features (`F-01` to `F-25`), and Workflows (`WF-01` to `WF-10`)  

---

## 1. Purpose and Discovery Objectives

This document establishes the formal **Entity Discovery Baseline** for the Talentra platform. Building on Phase 1 Discover deliverables, it extracts, disambiguates, and normalizes all core business entities required to power permanent recruitment, freelance gig marketplaces, university campus placements, and enterprise financial ledgers.

### Key Objectives:
1. **Definitive Entity Inventory:** Catalog exactly 90 production-grade entities across 13 coherent business domains.
2. **Defect Elimination:** Remove all legacy pathologies (social media forum bloat, generic Zendesk ticketing clones, over-normalized 2-row lookup tables, circular foreign keys).
3. **Workflow Completeness:** Ensure every step of workflows `WF-01` through `WF-10` reads or writes at least one named entity.
4. **Kimball Star Schema Decoupling:** Separate transactional OLTP operational entities from analytical OLAP dimensions and fact marts.

---

## 2. Master Entity Inventory by Domain Schema

| Domain Schema | Entity Count | Core Business Entities | Primary Responsibilities |
| :--- | :---: | :--- | :--- |
| **`master_data`** | **11** | `country`, `state`, `city`, `currency`, `language`, `industry`, `job_role`, `skill`, `qualification`, `ui_translation_key`, `ui_translation` | Global reference taxonomies, ISO standards, geographic coordinates, and multilingual translations. |
| **`identity`** | **6** | `user_account`, `user_credential`, `role`, `user_role`, `user_active_session`, `service_api_key` | Authentication principals, Argon2id credentials, RBAC authorization, and active multi-device sessions. |
| **`organisation`** | **7** | `account`, `organisation`, `organisation_location`, `organisation_tax_identifier`, `organisation_verification`, `recruiter_seat_assignment`, `organisation_hierarchy` | Multi-tenant billing boundaries, corporate entities, verification status, and recruiter seat quotas. |
| **`candidate`** | **9** | `candidate_profile`, `candidate_education`, `candidate_work_experience`, `candidate_skill`, `candidate_project`, `candidate_resume`, `candidate_preference`, `candidate_block_list`, `candidate_language` | Candidate profiles, education, employment history, portfolio projects, resumes, and employer privacy shielding. |
| **`recruitment`** | **5** | `job_requisition`, `job_requisition_skill`, `job_questionnaire`, `questionnaire_question`, `question_option` | Corporate hiring requisitions, salary bands, required skills, and screening questionnaires. |
| **`application`** | **6** | `job_application`, `application_question_answer`, `application_stage_history`, `job_interview`, `interview_feedback`, `job_offer` | 13-stage hiring state machine, candidate questionnaire responses, interview schedules, feedback scorecards, and offers. |
| **`sourcing`** | **4** | `consultant_authorization`, `candidate_nomination`, `outreach_campaign`, `outreach_recipient` | Staffing agency contracts, recruiter candidate nominations, and bulk outreach campaigns. |
| **`gig`** | **9** | `gig_worker_profile`, `gig_worker_service`, `gig_worker_availability`, `gig_request`, `gig_proposal`, `gig_contract`, `gig_milestone`, `gig_rating`, `client_gig_worker_preference` | Freelance services, GiST non-overlapping availability, gig proposals, contracts, milestone escrow, and reviews. |
| **`licensing`** | **3** | `subscription_plan`, `subscription_licence`, `licence_entitlement_usage` | SaaS subscription tiers, company licenses, and monthly recruiter entitlement usage metering. |
| **`billing`** | **8** | `wallet_account`, `wallet_ledger`, `payment_order`, `payment_transaction`, `payment_gateway_event`, `invoice`, `invoice_item`, `profile_download_history` | Append-only double-entry wallet ledger ($0.00 drift), payment orders, invoices, and profile download credits. |
| **`engagement`** | **9** | `candidate_saved_search`, `job_alert_subscription`, `notification_delivery`, `message_thread`, `thread_message`, `candidate_referral_link`, `referral_attribution_event`, `campus_placement_cohort`, `campus_student_member` | Candidate alerts, direct in-app messaging, employee referral tracking, and campus placement drives. |
| **`governance`** | **4** | `dpdp_consent_record`, `pii_encryption_key`, `system_audit_event`, `data_retention_policy` | DPDP Act 2023 consent tracking, per-user DEK key management with cryptographic shredding, and immutable audit trails. |
| **`analytics`** | **9** | `dim_date`, `dim_candidate`, `dim_organisation`, `dim_job_requisition`, `dim_pipeline_stage`, `fact_application_event`, `fact_profile_download`, `fact_gig_contract`, `fact_wallet_transaction` | Kimball dimensional star schema powering executive C-suite KPI dashboards and predictive talent analytics. |
| **TOTAL** | **90** | **13 Schemas / 90 Normalized Tables** | **100% Traceability across Discovery Baseline** |

---

## 3. Entity Classification & Lifecycle Boundary

- **Sovereign Independent Entities:** Reference taxonomies with independent lifecycles (`master_data.country`, `master_data.currency`, `master_data.skill`).
- **Core Business Entities:** Primary actors and transactional hubs (`identity.user_account`, `organisation.organisation`, `candidate.candidate_profile`, `recruitment.job_requisition`, `gig.gig_contract`).
- **Stateful Entities (20 FSMs):** Entities governed by formal transition tables defined in Step 08.
- **Append-Only Ledger Entities:** Legally binding financial and audit records (`billing.wallet_ledger`, `governance.system_audit_event`, `application.application_stage_history`).
- **Analytical Mart Entities:** Kimball star schema conformed dimensions and granular fact tables (`analytics.*`).

This inventory serves as the authoritative basis for Step 07 (Attributes Discovery), Step 08 (Lifecycles & State Machines), Step 09 (Logical ER Model), and Step 21 (Baseline Physical DDL).
