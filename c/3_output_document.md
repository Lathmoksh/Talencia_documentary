# Talentra — Feature Discovery & Competitive Benchmark
**Project**: Talentra Job Search & Demand Management Platform  
**Organization**: Northbridge Workforce Systems  
**Document**: Deliverable C3 — Feature Inventory & Competitive Analysis  
**Document Version**: 1.0 (Approved Baseline)  
**Target Database**: PostgreSQL 15+  

---

## 1. Discovery Approach & Prioritization Rules

Feature capabilities are derived directly from the core business workflows in Section 2 and data domains in Section 4 of the Hackathon Docket. Every discovered feature is prioritized under MoSCoW rules and mapped to concrete database tables and integrity constraints:

* **Must Have**: Core operational capabilities, security boundaries, and revenue-generating workflows.
* **Should Have**: Value-add engagement, customer support, and viral referral loops.
* **Could Have**: Optional market salary benchmarks and administrative feature flags.

```
Workflows (Docket §2) ──┐
Domains (Docket §4)   ──┼──> Feature Discovery ──> 20 Feature Specs (MoSCoW)
Competitors (§4)      ──┘          Engine       ──> 3-Competitor Matrix (LinkedIn, Naukri, Monster)
                                                ──> 11-Schema Database DDL Mapping
```

---

## 2. Feature Inventory (F-01 to F-20)

| ID | Feature Name | Description & Value | Priority | Target Actor | Mapped Database Module |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **F-01** | **Candidate Profiles & Resumes** | Complete career profiles: personal info, education, verified work history, skills taxonomy with proficiencies, languages, and versioned resume attachments. | **Must** | Candidate | `profile.candidate_profile`, `profile.education`, `profile.work_experience` |
| **F-02** | **Job Requisition Management** | Posting vacancies, open positions, publication windows, salary ranges, location criteria, and consultant visibility flag (`open_to_consultants`). | **Must** | Employer / Recruiter | `recruitment.job_requirement`, `recruitment.job_position` |
| **F-03** | **Application Pipeline** | End-to-end applicant tracking (`APPLIED` $\rightarrow$ `SHORTLISTED` $\rightarrow$ `INTERVIEW` $\rightarrow$ `OFFERED` $\rightarrow$ `JOINED` / `REJECTED`), interview notes, and status transition logs. | **Must** | Recruiter / Candidate | `recruitment.job_application`, `recruitment.application_status_history` |
| **F-04** | **Screening Questionnaires** | Pre-qualification screening questionnaires attached to job postings with typed questions, knockout thresholds, and automated scoring. | **Must** | Employer / Recruiter | `recruitment.questionnaire_template`, `recruitment.questionnaire_question` |
| **F-05** | **Multi-Tenant Organisations** | Corporate hierarchies (holding companies, subsidiaries, branches), tax registration, verification status, and mapped recruiter rosters. | **Must** | Account Admin | `organisation.organisation`, `organisation.organisation_recruiter_mapping` |
| **F-06** | **Identity & Access Control** | Credentials, Argon2id password hashing, RBAC role mappings, active session tokens, and candidate privacy blocking lists. | **Must** | All Actors | `administration.user_account`, `administration.role`, `administration.candidate_block_list` |
| **F-07** | **Dedicated Gig Marketplace** | Project-based gig requests, fixed/hourly pricing, delivery milestones, worker availability calendars, gig proposals, contracts, and mutual ratings. | **Must** | Gig Worker / Requester | `gig.gig_worker_profile`, `gig.gig_contract` |
| **F-08** | **Gig Fulfilment Integration** | External fulfilment boundary tracking assignment handoff tokens, task progress updates, and reconciled gross/net earnings figures. | **Must** | Gig Worker / Requester | `gig.gig_contract_handoff` |
| **F-09** | **Consultant Sourcing** | Headhunter discovery of open jobs, employer sourcing authorization requests, bulk outreach, candidate shortlists, and placement commission tracking. | **Must** | Consultant / Employer | `sourcing.sourcing_request`, `sourcing.sourcing_candidate_submission` |
| **F-10** | **Licensing & Device Limits** | Subscription seat provisioning, active user allocations, concurrent device limits, and automated session lockouts at login. | **Must** | Account Admin | `licence.subscription_licence`, `administration.user_active_session` |
| **F-11** | **Subscriptions & Plans** | Plan tiers, billing cycles, entitlement quotas, automated renewals, cancellations, and upgrade prorations. | **Must** | Account Admin | `billing.subscription_plan`, `billing.account_subscription` |
| **F-12** | **Prepaid Wallet Ledgers** | Double-entry append-only wallet transactions: recharges, resume download debits, outreach fees, invoices, and refunds. | **Must** | Employer / Recruiter | `billing.wallet_account`, `billing.wallet_ledger` |
| **F-13** | **Resume Download Audit** | Immutable audit log of every recruiter resume download, recording actor, candidate, timestamp, and wallet debit transaction reference. | **Must** | Recruiter / Candidate | `profile.profile_download_history` |
| **F-14** | **Omnichannel Job Alerts** | Multichannel alerts (Email, SMS, Push, WhatsApp) with user preferences, delivery frequency limits, and quiet hours delivery suppression. | **Should** | All Actors | `engagement.notification_preference`, `engagement.notification_delivery_log` |
| **F-15** | **Professional Community** | Industry topic discussions, posts, threaded replies, reactions (likes/upvotes), moderation flags, and toxic content suppression. | **Should** | Candidate / Recruiter | `engagement.community_post`, `engagement.post_reaction` |
| **F-16** | **Support Ticketing & FAQs** | Categorized support tickets, status lifecycles, priority SLAs, conversation history, and searchable knowledge base articles. | **Should** | All Actors | `engagement.support_ticket`, `engagement.faq_article` |
| **F-17** | **Referral Tracking & Rewards**| Unique referral invite links, referral milestone tracking, and automatic wallet credit payouts upon successful onboarding. | **Should** | Candidate | `engagement.referral_campaign`, `engagement.candidate_referral_event` |
| **F-18** | **Analytics & KPI Marts** | Star schema with SCD Type 2 dimensions, partitioned transactional facts (`fact_applications`), and aggregated KPI marts (time-to-hire, drop-off). | **Must** | Executive / Employer | `analytics.dim_candidate`, `analytics.fact_applications` |
| **F-19** | **Data Privacy & Masking** | Column sensitivity classification, dynamic contact masking (candidate phone/email masked until shortlisted), right-to-be-forgotten, and retention purge. | **Must** | Security Auditor | `administration.data_classification_catalog`, `administration.retention_log` |
| **F-20** | **Synthetic Data Generator** | Laptop-scale synthetic data fixtures (1M candidates, 100k jobs, 5M applications) with realistic distributions and automated schema verification suites. | **Must** | Data Engineer | `scripts/generate_seed_data.py`, `sql/test_all.sql` |

---

## 3. Competitive Coverage Benchmark: Talentra vs. Market Leaders

As required by Section 4 of the Problem Docket, Talentra's data elements are benchmarked directly against **LinkedIn, Naukri, and Monster (Foundit)**:

```
[ Competitive Positioning ]
Talentra Exceeds:     • Unified Multi-Category Workforce (Gig + Staffing + Permanent)
                      • Versioned Pre-Qualification Questionnaires with Knockouts
                      • Database-Tier Session and Device Concurrency
                      • Append-Only Double-Entry Wallet Ledgers
                      • Native Relational UI Translations

Talentra Diverges:    • Omission of algorithmic doom-scrolling social feeds
```

### Detailed Evaluation Matrix

| Capability Area | Talentra Database Design | LinkedIn | Naukri | Monster (Foundit) | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Multi-Category Workforce** | **Unified Data Model**: Natively supports 8 categories (Permanent, Staffing, Campus, Gig, Consultant). Dedicated gig subsystem with availability calendar and milestone billing. | Fragmented: Permanent jobs separated from LinkedIn Services Marketplace; lacks structured staffing and apprenticeship models. | Fragmented: Separate portals for IT vs blue-collar staffing; gig work treated as generic search keyword tags. | Weak: Contract jobs treated as standard permanent listings with duration metadata. | **TALENTRA EXCEEDS**: Only platform with native relational support for permanent, campus, consultant, and gig workflows in one schema. |
| **2. Pre-Qualification Screening** | **Versioned Question Trees**: Structured questions (`BOOLEAN`, `NUMERIC`, `MULTI_SELECT`), question weights, knockout disqualification triggers, and automated scoring. | Basic: Linear screening questions (Yes/No, numeric years) without branching logic, complex weights, or versioned question trees. | Moderate: Custom employer questionnaires available, but stored as semi-structured text without relational score breakdowns. | Basic: Generic screening questionnaires without automated knockout triggers. | **TALENTRA EXCEEDS**: Versioned relational option trees enable precise automated candidate filtering and defensible auditability. |
| **3. Enterprise Licensing & Devices** | **Database-Enforced Concurrency**: `max_users` and `max_devices_per_user` enforced inside database login transactions. Simultaneous multi-device logins beyond limit are rejected at DB tier. | Application-Layer: Session concurrency managed via API gateways; frequent seat sharing across recruitment teams. | Commercial Token: IP-based session locking with manual administrator reset workflows; vulnerable to race conditions. | Basic: Client-side single session enforcement; lacks granular device count controls. | **TALENTRA EXCEEDS**: Prevents commercial revenue leakage by moving concurrency and device enforcement from the app layer to the database layer. |
| **4. Auditability & Ledgers** | **Append-Only Tamper-Evident Ledgers**: Wallet ledgers, payment orders, application stage transitions, and recruiter profile downloads are strictly append-only. Updates/deletes blocked by DB triggers. | Private / Opaque: Application stage history stored in internal event streaming; recruiters cannot inspect audit trails of credit usage. | Ledger History: Invoices and credit usage visible, but adjustments overwrite balances rather than appending correction entries. | Transaction Log: Standard order tables; lacks double-entry relational ledger backing. | **TALENTRA EXCEEDS**: Full double-entry financial integrity where every profile download has a verified, immutable ledger reference. |
| **5. Candidate Privacy & Blocking** | **Negative Sourcing Engine**: Candidates can block specific companies, recruiters, or headhunters. Database views enforce complete exclusion from talent search pools. | Partial: Candidate can hide profile from current employer only if mapped to verified company page. Cannot block third-party headhunters. | Weak: Recruiter blocking is basic and often bypassable by agency recruiters using subsidiary sub-accounts. | Basic: Generic privacy toggles (Public/Private); lacks dynamic negative search filtering. | **TALENTRA EXCEEDS**: Uncompromising candidate privacy enforced at the database view level via anti-joins. |
| **6. Multilingual UI Localization** | **Relational Key-Based Translations**: All UI strings and enumerations stored as translation keys in `sys_translation` with multi-language strings and English fallback. User text tagged with detected language. | Proprietary CDN: Translations handled via proprietary frontend localization bundles; database lacks structured relational translation catalog. | Monolingual: Primarily English-centric with localized keyword search hacks. | Monolingual: English-centric with regional portal clones. | **TALENTRA EXCEEDS**: Database-native multi-language localization designed for diverse, multilingual workforce markets. |
| **7. Social Feed vs Core Utility** | **Focused Professional Utility**: Zero algorithmic doom-scrolling feeds. Engagement focused on structured technical Q&A, industry topics, and verified referrals. | Heavy Social Sprawl: Algorithmic feed prioritization, influencer content, and engagement farming dilutes talent search. | Minimal: Pure search board; lacks candidate community engagement mechanisms. | Portal Content: Editorial career advice articles; lacks community interaction. | **DELIBERATE DIVERGENCE**: Talentra deliberately omits social newsfeeds to optimize for recruitment throughput and data clarity. |

---

## 4. Quality Verification: Feature & Invariant Test Taxonomy

Feature correctness and relational integrity are verified across five core architectural branches:

```
Feature Test Graph
 ├── 1. Structure & Project Best Practices (Singular tables, surrogate UUIDs, index patterns)
 ├── 2. Data Integrity & Data Quality (Money precision, rating boundaries, date logic)
 ├── 3. Business Rules & Behaviour (Screening knockout triggers, wallet sync atomicity)
 ├── 4. Security, Privacy & Access (Audit immutability, profile download ledger ties)
 └── 5. Non-Functional Requirements & Concurrency (GiST non-overlapping booking exclusions)
```

| Branch | Test ID | Description | Target Object | Verification Method | Expected Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Structure & Best Practices** | `FEA-STR-01` | Verify table and index naming conventions across all 11 modules. | `profile`, `gig`, `licence`, `billing` | Catalog inspection query | 100% compliant with `idx_table_column` and singular table names. |
| **2. Data Integrity & Quality** | `FEA-INT-01` | Insert gig worker rating with value `5.50` (outside 1.00 to 5.00 range). | `gig.gig_worker_profile` | Invalid SQL insert | Aborts with `chk_gig_worker_rating CHECK constraint violation`. |
| **3. Business Rules & Behavior** | `FEA-BIZ-01` | Candidate submits pre-qualification responses below knockout passing threshold. | `recruitment.job_application` | Trigger execution test | Application status automatically set to `REJECTED_SCREENING`. |
| **3. Business Rules & Behavior** | `FEA-BIZ-02` | Insert new debit entry in `billing.wallet_ledger`. | `billing.wallet_ledger` | SQL insert transaction | Trigger automatically deducts amount from `billing.wallet_account.cached_credit_balance`. |
| **4. Security, Privacy & Access** | `FEA-ACC-01` | User attempts to update or delete record in `profile.profile_download_history`. | `profile.profile_download_history` | DML update attempt | Aborts with trigger exception: `Table is append-only`. |
| **5. Non-Functional & Concurrency** | `FEA-NFR-01` | Insert two overlapping active gig contracts for worker `W-101` (e.g. Oct 1-15 and Oct 10-25). | `gig.gig_contract` | Concurrent contract insert | Second insert aborts with PostgreSQL `exclusion_violation` (`SQLSTATE 23P01`). |
