Milestone 22 — Integration and Source Mapping Specification

# Talentra Enterprise Workforce & Talent Demand Management Platform

## Document Control & Executive Summary

Milestone: 22 — Integration and Source Mapping

Phase: 4 — Build & Integrate (aligned with Milestone 21 Baseline ER and Physical Model)

Platform: Talentra Enterprise Workforce & Talent Demand Management Platform

Primary Target: PostgreSQL 16 Enterprise Database Architecture

Outputs Produced: Integration Catalogue, Boundary Ownership Matrix, API & File Interface Contracts, Exhaustive Field-Level Source-to-Target Mappings (Inbound/Outbound), and Operational Resilience Playbook.


This specification details the external boundary integration architecture for the Talentra Enterprise Platform. It governs all ingress and egress boundary interactions across Talentra's 13 PostgreSQL 16 domain schemas (identity, organisation, candidate, demand, match, interview, offer, gig, billing, engagement, analytics, governance, audit).


Every external boundary is bound to strict cryptographic, statutory, and structural invariants aligned with Data Rules (DR-001 through DR-085), Complex Transaction Rules (CTR-01 through CTR-10), Finite State Machine Workflows (WF-01 through WF-12), the India Digital Personal Data Protection (DPDP) Act 2023, ISO 3166-1 alpha-2, and ISO 4217 standards.

### Exit Criteria ("Definition of Done")

Boundary Governance: 100% of external integrations (INT-01 to INT-11) have designated Data Owners, Technical Boundary Owners, explicit authentication protocols, and data sensitivity classifications.

Interface Contracts: Fully specified contracts including endpoints, protocols, payload types, schemas, idempotency mechanisms, rate limits, and target database entities.

Field-Level Mapping: Exhaustive field-by-field mapping across inbound and outbound payloads linking source definitions to PostgreSQL 16 target columns, transformation logic, cryptographic rules, and exact DR/CTR constraint references.

Operational Resilience: Fully defined handling strategies for late, duplicate, out-of-order, and malformed inputs, backed by a persistent Dead-Letter Queue (governance.integration_dlq) schema and SLA matrix.



## Integration Architecture & Boundary Ownership Matrix

The Boundary Ownership Matrix establishes data governance, security controls, transport mechanisms, and explicit operational ownership across all eleven core integrations.

### Security & Classification Standards

Data Sensitivity:

Public: Non-sensitive operational reference data.

Internal: Corporate metrics, non-PII transaction metadata, aggregate logs.

Personal: Direct PII (Name, Email, Phone, Student ID) subject to DPDP Act 2023 consent management.

Confidential-Sensitive: Passwords, OAuth Tokens, National Identifiers (PAN, Aadhaar, CIN), Financial Ledger Balances, Bank/Escrow Accounts, and DEK Key Material.

Cryptographic Protocols:

In-Transit: TLS 1.3 required across all endpoints.

At-Rest (Sensitive Fields): AES-256-GCM using per-user Data Encryption Keys (DEKs) managed via KMS.

Blind Search Indexing: HMAC-SHA256 with platform-level peppering for searchable encrypted attributes (e.g., email, mobile number, tax identifiers).


| Integration ID | System Name & Functional Role | Direction | Protocol & Transport | Cadence & SLA Target | Security & Auth Standards | Sensitivity Classification | Data Owner (Business) | Technical Boundary Owner |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| INT-01 | Identity Provider & SSO (Google, Entra ID, OIDC) |  | HTTPS / REST, OIDC Core 1.0, OAuth 2.0 | Real-time (< 200ms p99) | TLS 1.3, OAuth2 Bearer, mTLS |  | VP HR / Security Admin | Principal Identity Engineer |
| INT-02 | Corporate Registry & KYB Bureau (MCA, Tax API) |  | HTTPS / REST JSON | Synchronous / Async (< 2000ms p95) | HMAC-SHA256 Payload Signature, API Key |  | Corporate Risk Lead | Enterprise Backend Architect |
| INT-03 | Resume & Document Object Storage + Parser |  | HTTPS REST, AWS S3 / GCS S3 API, Webhooks | Async (Upload < 500ms, Parse < 5s) | S3 Presigned URLs, KMS AES-256, HMAC Webhooks |  | Chief Talent Officer | Cloud Storage Lead |
| INT-04 | Payment Service Provider (Razorpay / Stripe) |  | HTTPS REST API, Signed Webhook Events | Real-time (< 300ms p99), Webhooks Async | mTLS, Webhook HMAC-SHA256 Signature |  | Chief Financial Officer | Billing Platform Engineer |
| INT-05 | Tax & E-Invoicing Gateway (GSTN / Tax Engine) |  | HTTPS REST, JSON / XML Payload | Synchronous (< 1500ms p95) | OAuth 2.0, Mutual TLS, Statutory RSA Signing |  | Head of Finance & Tax | Senior Financial Integrations Lead |
| INT-06 | External Gig Delivery & Timesheet Platform |  | REST API, Webhooks, SSE Streams | Near Real-time (< 1000ms), Webhooks | OAuth 2.0 Client Credentials, HMAC Headers |  | Gig Operations Lead | Workflow & Integration Engineer |
| INT-07 | Omnichannel Notification (SMTP, SMS/WhatsApp, Push) |  | REST API, Webhook Delivery Callbacks | Real-time (< 100ms dispatch) | TLS 1.3, API Bearer Token, Webhook Signing |  | Marketing & Communications Lead | Communications Infra Engineer |
| INT-08 | Calendar & Video Conferencing (Google, Graph, Zoom) |  | REST API, Webhook Subscriptions | Sync (< 800ms), Async Event Push | OAuth 2.0 User Delegation, Webhook Verification |  | Candidate Experience Manager | Integrations Software Engineer |
| INT-09 | Campus Bulk SIS Student Roster Feed |  | SFTP / HTTPS API Batch Upload | Batch (Daily / Ad-hoc On-demand) | SSH Key Authentication, AES-256 File Encryption |  | University Relations Lead | Data Ingestion Pipeline Lead |
| INT-10 | Sovereign Reference Feeds (ISO 3166, ISO 4217, Taxonomy) |  | HTTPS REST, Automated Pull | Daily / Weekly Batch Sync | Mutual TLS, API Token Authentication |  | Lead Data Governance Officer | Core Database Administrator |
| INT-11 | Enterprise BI Warehouse & DPDP Audit/Consent Sink |  | CDC PostgreSQL Logical Replication, Kafka Parquet Stream | Stream (< 5s latency) / Real-time DPDP Shredding (< 2s) | TLS 1.3, mTLS, Enterprise IAM Access Controls |  | Data Protection Officer (DPO) | Lead Data Engineer / Infrastructure Lead |




## Integration Catalogue & Interface Contracts

### INT-01: Identity Provider & SSO / OAuth2 (Google / Entra ID / OIDC)

Functional Scope: Inbound candidate, recruiter, and enterprise user authentication; single sign-on assertion processing; outbound user account creation and status sync.

Direction & Trigger: Inbound/Outbound via User Login Action or Administrative User Sync Event.

Protocol & Payload Format: REST JSON, OIDC JWT assertions, Authorization Code Flow with PKCE.

Endpoint / Topic / File Pattern: POST /api/v1/auth/oidc/callback, POST /api/v1/auth/sso/saml2/consume

Schema Version & Idempotency Key: Schema v1.2.0; Idempotency Key header X-OIDC-Nonce / X-Request-ID.

Target / Source Schemas & Tables: identity.user_account, identity.user_credential, identity.auth_audit_log, organisation.organization_member.

Rate Limits, Timeout & SLA Targets: 500 req/sec per tenant; 2,000ms timeout; 99.95% availability; SLA < 200ms p99.

### INT-02: Corporate Registry & KYB Verification Bureau

Functional Scope: Inbound automated corporate verification (MCA, CIN, LLPIN, PAN, GSTIN verification) for employer organization onboarding and compliance checks.

Direction & Trigger: Bidirectional via Organization Registration Workflow (WF-03) or Annual Recertification.

Protocol & Payload Format: REST JSON over HTTPS.

Endpoint / Topic / File Pattern: POST /api/v1/organisation/kyb/verify-registry

Schema Version & Idempotency Key: Schema v2.0.0; Idempotency via X-KYB-Transaction-ID.

Target / Source Schemas & Tables: organisation.organisation, organisation.organisation_kyb_detail, governance.compliance_log.

Rate Limits, Timeout & SLA Targets: 50 req/min per account; 5,000ms timeout; SLA < 2,000ms p95.

### INT-03: Candidate Resume & Document Storage + Parser Service

Functional Scope: Presigned URL generation for secure resume/portfolio upload; automated asynchronous parsing of candidate resumes into structured profile entities.

Direction & Trigger: Bidirectional via Candidate Profile Maintenance (WF-01) or Resume Re-parse Request.

Protocol & Payload Format: REST HTTPS (S3 API) + Signed Webhook JSON Payload.

Endpoint / Topic / File Pattern: POST /api/v1/candidate/documents/upload-url, POST /webhooks/v1/parser/extract-complete

Schema Version & Idempotency Key: Schema v1.0.0; Idempotency via X-Webhook-Event-ID / S3 ETag.

Target / Source Schemas & Tables: candidate.candidate_profile, candidate.candidate_resume_document, candidate.candidate_experience, candidate.candidate_education, candidate.candidate_skill.

Rate Limits, Timeout & SLA Targets: 100 uploads/min per user; 3,000ms upload URL generation; Async parser delivery < 5,000ms p95.

### INT-04: Payment Service Provider / Gateway (Razorpay / Stripe)

Functional Scope: Wallet recharge orders, enterprise escrow funding, milestone payouts, candidate wallet withdrawals, and automated payment gateway event reconciliation.

Direction & Trigger: Bidirectional via Billing & Escrow Workflows (WF-09).

Protocol & Payload Format: REST JSON over HTTPS + Signed Webhook JSON.

Endpoint / Topic / File Pattern: POST /api/v1/billing/orders, POST /webhooks/v1/payments/{provider}

Schema Version & Idempotency Key: Schema v3.1.0; Idempotency Key Idempotency-Key: {wallet_transaction_id} / X-Razorpay-Signature.

Target / Source Schemas & Tables: billing.wallet, billing.wallet_ledger, billing.payment_order, billing.escrow_hold, billing.payment_gateway_event.

Rate Limits, Timeout & SLA Targets: 200 req/sec; 2,500ms timeout; SLA < 300ms p99.

### INT-05: Tax & E-Invoicing Compliance Gateway (GSTN / Tax Engine)

Functional Scope: Real-time GST calculation, statutory invoice generation, e-way bill generation, and statutory e-invoice registering with tax portals.

Direction & Trigger: Bidirectional via Invoice Finalization or Platform Fee Settlement Events (WF-09).

Protocol & Payload Format: REST JSON / XML over mTLS.

Endpoint / Topic / File Pattern: POST /api/v1/tax/e-invoice/generate, POST /api/v1/tax/calculate

Schema Version & Idempotency Key: Schema v1.1.0; Idempotency via X-Invoice-UUID.

Target / Source Schemas & Tables: billing.invoice, billing.invoice_line_item, billing.tax_summary, governance.compliance_log.

Rate Limits, Timeout & SLA Targets: 30 req/sec; 4,000ms timeout; SLA < 1,500ms p95.

### INT-06: External Gig Delivery & Timesheet Handoff Platform

Functional Scope: Handoff of accepted gig contracts to execution environments; receiving timesheet submissions, milestone deliverables, and completion status updates.

Direction & Trigger: Bidirectional via Gig Lifecycle Management Workflows (WF-07).

Protocol & Payload Format: REST JSON, Signed Webhook Callbacks.

Endpoint / Topic / File Pattern: POST /api/v1/gig/handoff, POST /webhooks/v1/gig/milestone-submission

Schema Version & Idempotency Key: Schema v2.0.0; Idempotency via X-Gig-Milestone-Submission-ID.

Target / Source Schemas & Tables: gig.gig_contract, gig.gig_milestone, gig.gig_timesheet, gig.gig_deliverable.

Rate Limits, Timeout & SLA Targets: 100 req/sec; 2,000ms timeout; SLA < 1,000ms p95.

### INT-07: Omnichannel Notification & Outreach Gateway

Functional Scope: Multi-channel outbound messaging (Email, SMS, WhatsApp, Web Push) for workflow notifications, interview invites, and system alerts; receiving delivery/read receipts.

Direction & Trigger: Outbound push (with async Inbound webhook) via Notification Triggers (WF-10).

Protocol & Payload Format: REST JSON over HTTPS.

Endpoint / Topic / File Pattern: POST /api/v1/notifications/send, POST /webhooks/v1/notifications/delivery-status

Schema Version & Idempotency Key: Schema v1.0.0; Idempotency via X-Notification-Tracking-ID.

Target / Source Schemas & Tables: engagement.notification_log, engagement.notification_preference, candidate.candidate_profile.

Rate Limits, Timeout & SLA Targets: 1,000 req/sec; 1,000ms timeout; Delivery dispatch SLA < 100ms.

### INT-08: Calendar & Video Conferencing Provider (Google Calendar / MS Graph / Zoom)

Functional Scope: Calendar availability lookup, automated scheduling of candidate interviews, video meeting link generation, and invite status synchronization.

Direction & Trigger: Bidirectional via Interview Scheduling Workflows (WF-05).

Protocol & Payload Format: REST JSON over HTTPS.

Endpoint / Topic / File Pattern: POST /api/v1/interview/schedule-sync, POST /webhooks/v1/calendar/event-update

Schema Version & Idempotency Key: Schema v1.3.0; Idempotency via X-Interview-Schedule-UUID.

Target / Source Schemas & Tables: interview.interview_schedule, interview.interview_participant, interview.interview_feedback.

Rate Limits, Timeout & SLA Targets: 150 req/min; 3,000ms timeout; Sync SLA < 800ms p95.

### INT-09: University / Campus Bulk SIS Student Roster Feed

Functional Scope: Ingestion of bulk candidate/student enrollment rosters from university partner Student Information Systems (SIS) for campus hiring cohorts.

Direction & Trigger: Inbound via SFTP File Drop or High-Volume Batch API Upload (WF-10).

Protocol & Payload Format: SFTP CSV / HTTPS Multi-part Batch JSON.

Endpoint / Topic / File Pattern: sftp://sftp.talentra.io/incoming/campus/{university_code}/{yyyy-mm-dd}_roster.csv, POST /api/v1/campus/roster-batch

Schema Version & Idempotency Key: Schema v1.0.0; File Checksum (SHA-256) + Row Unique Composite Natural Key.

Target / Source Schemas & Tables: engagement.campus_cohort, engagement.campus_student_member, candidate.candidate_profile, identity.user_account.

Rate Limits, Timeout & SLA Targets: 50,000 rows/file; File processing time < 10 minutes; API batch 100 req/min.

### INT-10: Sovereign Master Data Reference Feeds

Functional Scope: Automated ingestion and synchronization of sovereign reference data standards (ISO 3166 countries, ISO 4217 currencies, taxonomy standards).

Direction & Trigger: Inbound via Scheduled Nightly Cron Pull.

Protocol & Payload Format: REST JSON over HTTPS.

Endpoint / Topic / File Pattern: Internal Job Engine -> External Sovereign Master Data APIs.

Schema Version & Idempotency Key: Schema v1.0.0; Source ETag / Version Stamp.

Target / Source Schemas & Tables: governance.ref_country, governance.ref_currency, demand.ref_skill_taxonomy.

Rate Limits, Timeout & SLA Targets: 10 req/day; SLA < 5,000ms per batch download.

### INT-11: Enterprise BI / Analytical Warehouse & Statutory DPDP Audit Export

Functional Scope: Change Data Capture (CDC) streaming of platform operations into analytical star schema data warehouses, and statutory real-time consent withdrawal / DEK shredding audit exports.

Direction & Trigger: Outbound continuous logical streaming + Event-driven DPDP compliance execution (WF-11, WF-12).

Protocol & Payload Format: PostgreSQL Logical Replication (pgoutput) / Kafka Parquet / JSON.

Endpoint / Topic / File Pattern: cdc.talentra.events.{domain}, s3://talentra-audit-sink/dpdp_compliance/

Schema Version & Idempotency Key: Schema v1.0.0; Kafka Offset + LSN Sequence Number.

Target / Source Schemas & Tables: analytics.dim_candidate, analytics.dim_organisation, analytics.fact_gig_performance, analytics.fact_billing_ledger, audit.system_audit_log, governance.dpdp_consent_ledger.

Rate Limits, Timeout & SLA Targets: Continuous (< 5s lag); DPDP Shredding Event Export SLA < 2,000ms.



## Comprehensive Field-Level Source-to-Target Mapping

### INT-01: Identity Provider & SSO (Inbound)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-01-01 |  |  | identity.user_account.sso_provider_user_id (varchar(255)) | Trim spaces; exact raw string retention. | DR-001 (Unique SSO Identifier) |  | Identity Lead / Sr. Security Eng |
| MAP-01-02 |  |  | identity.user_account.email_address_hash (bytea) | Lowercase, trim; compute HMAC-SHA256 using pepper. | DR-002, CTR-01 (Valid Email) |  | Security Admin / DB Architect |
| MAP-01-03 |  |  | identity.user_account.email_address_encrypted (bytea) | AES-256-GCM encryption using target User DEK. | DR-002, DR-080 (DPDP PII Protection) |  | Data Protection Officer / Security Eng |
| MAP-01-04 |  |  | candidate.candidate_profile.full_name (varchar(255)) | Trim, concatenate (given_name + ' ' + family_name), normalize title casing. | DR-029 (Candidate Identity) |  | HR Product Mgr / Core Dev |
| MAP-01-05 |  |  | identity.user_account.is_email_verified (boolean) | Map boolean directly (true/false). | DR-003 (Email Verification Verification) |  | Security Admin / Dev |


### INT-02: Corporate Registry & KYB Bureau (Inbound & Outbound)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-02-01 |  | organisation.organisation.registration_number (varchar(50)) | KYB Bureau Request / cin_llpin (string) | Upper-case, remove all hyphens/spaces. | DR-016 (Valid CIN/LLPIN Format) | NOT NULL. Reject outbound payload if missing. | Risk Lead / API Integrations Lead |
| MAP-02-02 |  | KYB Bureau Response / legal_name (string) | organisation.organisation.legal_name (varchar(255)) | Trim spaces; strip unauthorized special chars. | DR-017 (Legal Name Match) | NOT NULL. | Governance Officer / Integration Lead |
| MAP-02-03 |  | KYB Bureau Response / status (string) | organisation.organisation_kyb_detail.kyb_status (varchar(30)) | Map "ACTIVE" -> "VERIFIED", "INACTIVE" -> "REJECTED". | DR-019, CTR-01 (KYB Hard Gate Check) | NOT NULL. Fallback: "UNDER_REVIEW". | Operations Lead / Backend Architect |
| MAP-02-04 |  | KYB Bureau Response / incorporation_date (ISO date) | organisation.organisation_kyb_detail.incorporation_date (date) | Parse ISO 8601 string to YYYY-MM-DD. | DR-018 (Incorporation Verification) | NULLABLE. | Risk Manager / Data Lead |


### INT-03: Candidate Resume & Document Storage + Parser (Bidirectional)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-03-01 |  | S3 Webhook / s3_object_key (string) | candidate.candidate_resume_document.storage_path (varchar(512)) | Direct path string mapping; validate prefix path. | DR-029 (Resume Asset Integrity) | NOT NULL. Reject if null. | Infrastructure Lead / Storage Lead |
| MAP-03-02 |  | Parser Webhook / parsed_skills (array of strings) | candidate.candidate_skill.skill_id (uuid) | Map string to taxonomy UUID via demand.ref_skill_taxonomy. | DR-031, CTR-02 (Taxonomy Alignment) | NULLABLE. Unmatched skills sent to review queue. | Head of AI & Talent Matching / Data Lead |
| MAP-03-03 |  | Parser Webhook / total_experience_years (decimal) | candidate.candidate_profile.years_experience (numeric(4,1)) | Round to 1 decimal place; range check [0.0, 60.0]. | DR-030 (Experience Bounds) | NOT NULL. Default: 0.0. | Talent Product Lead / Dev |
| MAP-03-04 |  | Parser Webhook / extracted_text (string) | candidate.candidate_resume_document.parsed_text_encrypted (bytea) | Encrypt via candidate DEK (AES-256-GCM). | DR-080, CTR-09 (DPDP Encrypted PII) | NULLABLE. | Data Protection Officer / Security Eng |


### INT-04: Payment Service Provider / Gateway (Inbound & Outbound)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-04-01 |  | billing.payment_order.amount (numeric(15,2)) | PSP Request Payload / amount (integer) | Convert major currency units to minor units (e.g., INR 100.50 -> 10050 paise). | DR-066, CTR-04 (Minor Unit Currency Invariant) | NOT NULL. Reject if <= 0. | CFO / Billing Integrations Lead |
| MAP-04-02 |  | billing.payment_order.currency (char(3)) | PSP Request Payload / currency (string) | Convert to uppercase ISO 4217 code. | DR-006, CTR-04 (ISO 4217 Compliance) | NOT NULL. Default: "INR". | Finance Lead / Dev |
| MAP-04-03 |  | PSP Webhook / payload.payment.entity.id (string) | billing.payment_gateway_event.gateway_event_id (varchar(255)) | Direct string extraction. Primary key for idempotency. | DR-070, CTR-05 (Idempotent Webhook Processing) | NOT NULL. Reject payload if missing. | Billing Lead / Backend Architect |
| MAP-04-04 |  | PSP Webhook / payload.payment.entity.status (string) | billing.payment_order.order_status (varchar(30)) | Map "captured" -> "SUCCESS", "failed" -> "FAILED". | DR-068, WF-09 (Payment FSM Transition) | NOT NULL. | Risk Officer / Billing Dev |


### INT-05: Tax & E-Invoicing Compliance Gateway (Inbound & Outbound)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-05-01 |  | billing.invoice.taxable_amount (numeric(15,2)) | Tax Engine / TaxableValue (numeric) | Round to 2 decimal places. | DR-071, CTR-10 (Statutory Tax Computation) | NOT NULL. | Head of Tax / Billing Engineer |
| MAP-05-02 |  | organisation.organisation_kyb_detail.gstin (varchar(15)) | Tax Engine / BuyerGstin (string) | Uppercase, validate 15-character alphanumeric GSTIN format. | DR-072 (GSTIN Validation) | NOT NULL for corporate invoices. | Tax Compliance Lead / Dev |
| MAP-05-03 |  | Tax Engine Response / Irn (string) | billing.invoice.irn_hash (varchar(64)) | Validate 64-character hex string format. | DR-071, CTR-10 (Statutory Invoice Registration) | NULLABLE until registered. | Tax Admin / Integration Lead |
| MAP-05-04 |  | Tax Engine Response / SignedQrCode (string) | billing.invoice.qr_code_data (text) | Store raw statutory JWT string. | DR-071 (E-Invoice Statutory QR) | NULLABLE until signed. | Tax Admin / Integrations Lead |


### INT-06: External Gig Delivery & Timesheet Platform (Bidirectional)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-06-01 |  | gig.gig_contract.gig_contract_id (uuid) | Delivery Platform / external_gig_id (string) | Convert UUID to canonical string representation. | DR-053 (Gig Trackability) | NOT NULL. | Gig Ops Lead / Platform Eng |
| MAP-06-02 |  | External Webhook / hours_logged (decimal) | gig.gig_timesheet.logged_hours (numeric(5,2)) | Round to 2 decimal places; enforce 0.00 < hours <= 24.00. | DR-057, CTR-03 (Timesheet Limit Validation) | NOT NULL. Reject if out of bounds. | Gig Operations Manager / Backend Eng |
| MAP-06-03 |  | External Webhook / submitted_at (ISO timestamp) | gig.gig_timesheet.submission_timestamp (timestamptz) | Parse to UTC ISO 8601 timestamp. | DR-058, WF-07 (5-Day Auto-Approval Rule) | NOT NULL. Default: CURRENT_TIMESTAMP. | Operations Lead / Integration Dev |


### INT-07: Omnichannel Notification & Outreach Gateway (Inbound & Outbound)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-07-01 | OUTBOUND | candidate.candidate_profile.mobile_number_encrypted (bytea) | Notification Gateway / recipient_phone (string) | Decrypt via Candidate DEK; normalize to E.164 format (e.g. +919876543210). | DR-008, DR-080 (E.164 Phone Formatting) | NOT NULL for SMS/WhatsApp. | Communications Lead / Infra Eng |
| MAP-07-02 | INBOUND | Gateway Status Webhook / status (string) | engagement.notification_log.delivery_status (varchar(30)) | Map "DELIVERED" -> "DELIVERED", "FAILED" -> "FAILED", "BOUNCED" -> "BOUNCED". | DR-050 (Delivery Tracking) | NOT NULL. | Comms Product Lead / Integration Dev |


### INT-08: Calendar & Video Conferencing Provider (Bidirectional)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-08-01 | OUTBOUND | interview.interview_schedule.start_time (timestamptz) | Provider API / start.dateTime (ISO string) | Format as UTC ISO 8601 string. | DR-042 (Interview Schedule Bounds) | NOT NULL. | Candidate Experience Mgr / Software Eng |
| MAP-08-02 | INBOUND | Provider API / hangoutLink or join_url (string) | interview.interview_schedule.video_meeting_url (varchar(512)) | Validate HTTPS URI syntax. | DR-042 (Meeting URL Validation) | NULLABLE. | Candidate Experience Lead / Integration Dev |


### INT-09: University / Campus Bulk SIS Student Roster Feed (Inbound)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-09-01 |  | CSV Roster / student_external_id (string) | engagement.campus_student_member.university_roll_number (varchar(100)) | Trim spaces; upper-case. | DR-077 (Unique Student Identifier) | NOT NULL. Reject row if empty. | University Relations Lead / Data Eng |
| MAP-09-02 |  | CSV Roster / cgpa (decimal string) | engagement.campus_student_member.academic_cgpa (numeric(4,2)) | Convert to numeric; validate scale [0.00, 10.00]. | DR-078 (Academic Record Integrity) | NULLABLE. Default: 0.00. | Campus Placement Lead / Data Eng |
| MAP-09-03 |  | CSV Roster / graduation_year (integer string) | engagement.campus_student_member.graduation_year (integer) | Convert to 4-digit integer; range check [current_year, current_year + 6]. | DR-079 (Graduation Year Validation) | NOT NULL. Reject row if invalid. | University Relations Lead / Software Eng |


### INT-10: Sovereign Master Data Reference Feeds (Inbound)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-10-01 | INBOUND | ISO 3166 Feed / alpha-2 (string) | governance.ref_country.country_code_iso2 (char(2)) | Uppercase exact 2-character string. | DR-005, CTR-01 (ISO 3166 Standard) | NOT NULL. Primary Key. | Lead Data Governance Officer / DBA |
| MAP-10-02 | INBOUND | ISO 4217 Feed / alphabetic_code (string) | governance.ref_currency.currency_code_iso3 (char(3)) | Uppercase exact 3-character string. | DR-006, CTR-04 (ISO 4217 Standard) | NOT NULL. Primary Key. | Head of Finance / Core DBA |


### INT-11: Enterprise BI Warehouse & Statutory DPDP Audit Export (Outbound)

| Mapping ID | Direction | Source System & Source Field | Target Column & PostgreSQL Type | Transformation & Normalization Rules | Validation & Business Rules | Nullability & Fallbacks | Field Owners (Business & Tech) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| MAP-11-01 | OUTBOUND | governance.dpdp_consent_ledger.consent_withdrawn_at (timestamptz) | Kafka Topic / dpdp_revocation_event.timestamp (long) | Convert timestamp to Epoch Milliseconds; trigger DEK key destruction event. | DR-085, CTR-09 (Statutory DPDP Ersature) | NOT NULL for revocation events. | Data Protection Officer / Lead Data Eng |
| MAP-11-02 | OUTBOUND | candidate.candidate_profile.candidate_id (uuid) | Analytics Warehouse / dim_candidate.candidate_key (uuid) | Direct UUID propagation via CDC. | DR-080 (Analytical Anonymization Compliance) | NOT NULL. | Lead Analytics Architect / Data Eng |




## Operational Resilience: Late, Duplicated, and Malformed Source Handling

### 5.1 Late Sources & Out-of-Order Events

Watermarking & Ingestion Delta: All inbound integration payloads include a statutory source timestamp (event_timestamp). Upon receipt at the API gateway layer, an immutable ingested_at = CURRENT_TIMESTAMP is appended. The delta delta_t = ingested_at - event_timestamp is evaluated. If delta_t > 300 seconds, the payload is flagged as "LATE_ARRIVING".

Grace Windows & State Machine Guarding:

Timesheets & Gig Submissions (INT-06): Inbound timesheet submissions arriving after the 5-day auto-approval deadline (DR-059, WF-07) are rejected from direct state modification. If the Gig contract has transitioned to a terminal state (APPROVED, SETTLED, CANCELLED), late events are rerouted to governance.integration_dlq with reason FSM_TERMINAL_STATE_LOCKED. Manual operator review is required via the Gig Dispute Desk.

Campus Batch Uploads (INT-09): Roster files dropped past the scheduled batch cutoff time (23:59:59 UTC) are held in quarantine staging (engagement.campus_roster_staging) and scheduled for execution during the subsequent processing window.

DPDP Shredding Priority Bypass (INT-11): Statutory consent withdrawal requests (CTR-09) bypass all late-arriving queues. Regardless of event order or system lag, receipt of a signed DPDP consent revocation instantly revokes access to the candidate's DEK key in memory and schedules background shredding within the mandatory 2.0-second SLA window.

### 5.2 Duplicated Sources & Replay Protection

Idempotency Header Enforcement: All mutating inbound REST API endpoints enforce the presence of an Idempotency-Key HTTP header (UUID v4 format).

Payment Webhooks (INT-04): Webhook payloads from payment gateways are evaluated against billing.payment_gateway_event.gateway_event_id (DR-070).


```sql
INSERT INTO billing.payment_gateway_event (
gateway_event_id, provider, event_type, payload_hash, process_status, created_at
) VALUES (
'evt_1N234567890', 'RAZORPAY', 'payment.captured', SHA256('...'), 'PROCESSED', CURRENT_TIMESTAMP
)
ON CONFLICT (gateway_event_id) DO NOTHING;
```
If zero rows are inserted, the system identifies the event as an exact duplicate and immediately returns an HTTP 200 OK with header X-Talentra-Duplicate: true, suppressing downstream processing.


Batch CSV File Integrity (INT-09): File processing generates an initial cryptographic digest (SHA-256). If the file digest matches a record in governance.batch_job_log within the last 30 days, the entire file is rejected immediately with error DUPLICATE_FILE_DIGEST.

Conflicting Payload Detection (HTTP 409 Conflict): If an incoming request provides an identical Idempotency-Key but a different payload SHA-256 hash digest, the transaction is rejected with HTTP 409 Conflict, logged as a potential replay/tampering attempt, and raised to security monitoring.

### 5.3 Malformed, Partial & Schema-Drifted Sources

Edge Validation Pipeline: Before database execution, every inbound payload passes through strict, two-stage schema validation:

Cryptographic & Signature Integrity: Verification of HMAC-SHA256 signatures, RSA tokens, or mTLS certificates. Failure triggers HTTP 401 Unauthorized / 403 Forbidden and increments security anomaly counters.

Structural & Domain Rule Check: JSON Schema / CSV Column Header validation against canonical definitions. Syntax or type mismatch triggers HTTP 400 Bad Request or 422 Unprocessable Entity.

Campus Roster Row-Level Isolation (INT-09): Batch CSV ingestion operates under partial rejection rules:

Rows containing malformed data (e.g., invalid CGPA bounds per DR-078, malformed Roll Number per DR-077) are quarantined into governance.integration_dlq.

Valid rows within the same file continue processing to prevent entire batch blockages. A summary report (e.g., Processed: 4,800 | Quarantined: 200) is returned to the submitter.

Dead-Letter Queue Schema Structure: Malformed or state-rejected payloads across all integrations are written to governance.integration_dlq for full auditability and operator remediation:


```sql
CREATE TABLE governance.integration_dlq (
dlq_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
integration_id VARCHAR(10) NOT NULL,
source_system VARCHAR(50) NOT NULL,
endpoint_or_topic VARCHAR(255) NOT NULL,
payload_json JSONB NOT NULL,
headers_json JSONB NULL,
error_code VARCHAR(50) NOT NULL,
error_message TEXT NOT NULL,
associated_dr_ctr_id VARCHAR(20) NULL,
retry_count INT NOT NULL DEFAULT 0,
max_retries INT NOT NULL DEFAULT 3,
status VARCHAR(20) NOT NULL DEFAULT 'QUARANTINED',
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
last_retried_at TIMESTAMPTZ NULL,
resolved_by_user_id UUID NULL,
resolution_notes TEXT NULL
);
CREATE INDEX idx_dlq_status_integration ON governance.integration_dlq(status, integration_id);
Consolidated Exception & Failure Behavior Matrix
```
| Failure Mode / Scenario | Detection Mechanism | HTTP / Protocol Response | Persistence & DLQ Action | Automated Retry Policy | Escalation & Recovery Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Invalid Signature / HMAC Failure | API Gateway Cryptographic Verification Failure | 401 Unauthorized | Logged to audit.system_audit_log (Security Alert). No DLQ persistence. | No Retry. Immediate Drop. | Security Operations Center (SOC) Lead |
| Malformed Syntax / Schema Drift | JSON Schema Validator / Parser Engine | 400 Bad Request or 422 Unprocessable Entity | Written to governance.integration_dlq (error_code: SCHEMA_INVALID). | No Retry. Awaits manual payload fix. | Technical Boundary Owner |
| Domain Constraint Failure (DR/CTR Violation) | PostgreSQL Driver / Business Rule Engine | 422 Unprocessable Entity | Written to governance.integration_dlq (error_code: DR_CTR_VIOLATION). | No Automated Retry. Alert sent to owner. | Domain Business Steward |
| Exact Duplicate Event (Replay) | DB Unique Constraint Check (gateway_event_id) | 200 OK (with X-Talentra-Duplicate: true) | Suppressed. Event logged in billing.payment_gateway_event. | None (Idempotent Success returned). | Operations Support Lead |
| Conflicting Duplicate Payload | Idempotency Key Match + SHA-256 Hash Mismatch | 409 Conflict | Logged to governance.integration_dlq (error_code: IDEMPOTENCY_CONFLICT). | No Retry. Security Alert. | Security Operations / Lead Integrations Eng |
| Late Event / Terminal State Lockout | FSM State Guard Check (WF-01 to WF-12) | 409 Conflict or 200 OK (Partial Processing) | Written to governance.integration_dlq (error_code: FSM_STATE_LOCKED). | No Automated Retry. | Operations Escalation Lead |
| Downstream System Timeout / 5xx | HTTP Client Connection Timeout (> SLA Target) | Inbound: 504 Gateway Timeout / Outbound Internal | Written to Outbound Execution Retry Queue (governance.integration_dlq). | Exponential Backoff with Jitter (5 retries: 1s, 2s, 4s, 8s, 16s). | Cloud Infrastructure / Platform Eng |




## Acceptance Checklist & Sign-Off Criteria

```sql
[X] CRITERIA 1: BOUNDARY GOVERNANCE & OWNERSHIP
├── All 11 external integrations (INT-01 through INT-11) fully catalogued.
├── Every boundary has explicit Data Owners (Business) and Technical Boundary Owners.
└── Security classifications (Public, Internal, Personal, Confidential-Sensitive) assigned to all flows.
[X] CRITERIA 2: INTERFACE CONTRACTS & PROTOCOLS
├── Transport protocol, authentication mechanisms, schema versions, endpoints, and rate limits defined.
├── SLA targets specified for synchronous (< 200ms to < 2000ms) and asynchronous operations.
└── Idempotency mechanisms (Idempotency-Key headers, UUID natural keys, event IDs) mapped.
[X] CRITERIA 3: EXHAUSTIVE SOURCE-TO-TARGET FIELD MAPPING
├── Direct schema-qualified PostgreSQL target alignment (e.g. identity.user_account, billing.wallet_ledger).
├── Precise field transformations defined (HMAC hashing, AES-256 encryption, minor/major currency conversions).
└── Every mapped row links directly to specific Data Rules (DR-001 to DR-085) and Complex Transaction Rules (CTR-01 to CTR-10).
[X] CRITERIA 4: OPERATIONAL RESILIENCE & ERROR HANDLING
├── Out-of-order and late-arriving event rules specified with state machine guard interactions.
├── Idempotent deduplication routines detailed using ON CONFLICT DO NOTHING and SHA-256 checks.
├── Dead-Letter Queue schema (governance.integration_dlq) designed with retries, ownership, and statuses.
└── Consolidated Exception Matrix establishes exact failure modes, HTTP statuses, and escalation paths.
```

## Verification & Sign-Off

Lead Data Governance Officer: Approved for Alignment with India DPDP Act 2023 & Enterprise Master Data Standards.

Principal Identity & Security Architect: Approved for HMAC-SHA256, AES-256 DEK Architecture, and Replay Protection Controls.

Head of Enterprise Platform Engineering: Approved for PostgreSQL 16 Target Schema Integration and DLQ Operational Design.

