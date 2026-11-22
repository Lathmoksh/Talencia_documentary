# Talentra Enterprise: Business Scenarios, Data Strands, Variants & Data Fields Specification

**Platform:** Talentra Enterprise Workforce & Talent Demand Management Platform  
**Document Reference:** Deliverable M14-C — Data Strands, Operational Variants & Data Elements Blueprint  
**Lifecycle Step:** Step 13 & 14 (Volumetrics & Synthetic Data Discovery) / Step 15 & 20 (Data & Rule Tests)  
**Target RDBMS:** PostgreSQL 16 (Tiered Storage, RLS, GiST Exclusion, Double-Entry Balancing)  
**Governance & Standards:** India DPDP Act 2023, ISO 3166-1, ISO 4217, E.164, OSHA Regulations  

---

## 1. Architectural Framework & Core Definitions

This document defines the comprehensive data engineering blueprint for Talentra's data generation, rule enforcement, and testing architecture. It formalizes five interrelated tiers:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               DATA DESIGN HIERARCHY                                    │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  1. Business Scenario  : High-level operational workflow (e.g. Candidate Search)       │
│  2. Data Strands       : Labor domain streams (White Collar SDE, Blue Collar, Exec)   │
│  3. Data Variants      : Role & experience archetypes (AI/ML Dev, Forklift, CTO)       │
│  4. Variant Tiers      : Primary (All params), Erroneous (Half params), Outlier (1/100)│
│  5. Business & Data R. : Explicit parameters & database invariants (e.g. 18+ Age)     │
│  6. Data Fields        : Prioritized (1 or 2) & Categorized (Direct vs Contextual)     │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### 1.1 Field Categorization Methodology
* **Category: Direct:** An intrinsic, self-contained attribute of the candidate or entity that exists independently of external platform workflows, employer interactions, or temporal states.  
  *Examples:* `name`, `date_of_birth`, `gender`, `years_of_experience`, `bio`, `license_number`.
* **Category: Contextual:** An attribute whose presence, calculation, or value depends upon an external workflow, an operational state machine, a relationship to another entity, or an algorithm.  
  *Examples:* `application_status` (depends on whether an application was submitted to a job), `profile_completion_percentage` (depends on profile scoring rules), `match_score` (depends on a specific requisition), `is_profile_searchable` (depends on candidate privacy settings and employer block lists).

### 1.2 Field Prioritization Methodology ("Mark all as 2, promote to 1")
* **Base Setting (Priority 2):** Every field is initialized as Priority 2 (operational, descriptive, or auxiliary).
* **Promotion to Priority 1:** A field is promoted to **Priority 1** if and only if it is:
  1. A primary key, foreign key, or natural uniqueness constraint.
  2. A legally binding or statutory parameter (e.g., date of birth for 18+ age verification, DPDP consent).
  3. A mandatory indexed search parameter that cannot be omitted in queries (e.g., skill code, trade license, city ID).
  4. A financial, audit, or state-machine status column driving lifecycle transitions.

---

## 2. Business Scenario 1: Candidate Profile Search

### 2.1 Scenario Overview
Corporate recruiters, staffing agency consultants, and SMB clients search the unified Talentra talent pool to identify, evaluate, and engage qualified candidates across three distinct labor sectors: **White Collar Tech (SDE)**, **Blue Collar / Essential Operations**, and **White Collar Executive Leadership**.

---

### 2.2 Master Data Fields Catalog for Candidate Profile Search

Following the strict rule: **Mark all as 2, then promote to 1 where necessary**:

| Field Name | Technical Database Column | Category | Priority | Initial | Final | Justification for Priority & Category |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Candidate ID** | `candidate.candidate_profile.id` | **Direct** | **1** | 2 | **1** | **Direct:** Unique identifier of the person. **Priority 1:** Primary Key required for all lookups. |
| **User Account ID** | `candidate.candidate_profile.user_id` | **Contextual** | **1** | 2 | **1** | **Contextual:** Depends on an authentication account in `identity`. **Priority 1:** Essential Foreign Key. |
| **Full Legal Name** | `candidate.candidate_profile.first_name`, `last_name` | **Direct** | **1** | 2 | **1** | **Direct:** Inherent human identifier. **Priority 1:** Mandatory for KYC, legally binding. |
| **Date of Birth** | `candidate.candidate_profile.date_of_birth` | **Direct** | **1** | 2 | **1** | **Direct:** Biological human invariant. **Priority 1:** Mandatory to enforce statutory 18+ labor laws. |
| **Gender** | `candidate.candidate_profile.gender` | **Direct** | **2** | 2 | **2** | **Direct:** Self-reported personal demographic attribute. **Priority 2:** Optional search filter. |
| **Current City / Location** | `candidate.candidate_profile.current_city_id` | **Contextual** | **1** | 2 | **1** | **Contextual:** Depends on geographic reference hierarchy. **Priority 1:** Critical indexed search filter. |
| **Total Experience Months** | `candidate.candidate_profile.total_experience_months` | **Direct** | **1** | 2 | **1** | **Direct:** Cumulative duration of career work. **Priority 1:** Core numeric range filter in candidate search. |
| **Professional Headline** | `candidate.candidate_profile.headline` | **Direct** | **2** | 2 | **2** | **Direct:** Self-authored statement of specialty. **Priority 2:** Descriptive, non-indexed free text. |
| **Professional Bio / Summary** | `candidate.candidate_profile.summary` | **Direct** | **2** | 2 | **2** | **Direct:** Self-authored descriptive summary. **Priority 2:** Supplementary narrative context. |
| **Current Salary Amount** | `candidate.candidate_profile.current_salary_amount` | **Direct** | **2** | 2 | **2** | **Direct:** Existing compensation. **Priority 2:** Sensitive, often undisclosed/null by candidate preference. |
| **Expected Salary Amount** | `candidate.candidate_profile.expected_salary_amount` | **Direct** | **1** | 2 | **1** | **Direct:** Minimum wage requirement for job change. **Priority 1:** Primary compensation filter for recruiters. |
| **Salary Currency** | `candidate.candidate_profile.salary_currency_code` | **Contextual** | **1** | 2 | **1** | **Contextual:** Depends on ISO 4217 master currency table. **Priority 1:** Required to interpret salary amount. |
| **Notice Period Days** | `candidate.candidate_profile.notice_period_days` | **Direct** | **1** | 2 | **1** | **Direct:** Contractual availability window (e.g. 15, 30, 90). **Priority 1:** Essential recruiter availability filter. |
| **Profile Completion %** | `candidate.candidate_profile.profile_completion_percentage` | **Contextual** | **2** | 2 | **2** | **Contextual:** Calculated dynamically by algorithmic scoring engine. **Priority 2:** Ranking signal, not a hard barrier. |
| **Is Searchable Flag** | `candidate.candidate_profile.is_profile_searchable` | **Contextual** | **1** | 2 | **1** | **Contextual:** Depends on candidate privacy toggles and DPDP consent. **Priority 1:** Hard gateway for search queries. |
| **Application Status** | `application.job_application.application_status` | **Contextual** | **1** | 2 | **1** | **Contextual:** Only exists if candidate submitted application to a specific job. **Priority 1:** State machine driver. |
| **Trade / Skill Code** | `candidate.candidate_skill.skill_id` | **Contextual** | **1** | 2 | **1** | **Contextual:** References master skill taxonomy. **Priority 1:** Core search match token. |
| **License / Certification** | `candidate.candidate_profile.license_number` | **Direct** | **1** | 2 | **1** | **Direct:** Intrinsic statutory credential (e.g., OSHA, CDL). **Priority 1:** Mandatory for regulated blue collar trades. |
| **Employer Block Count** | `candidate.candidate_block_list` count | **Contextual** | **2** | 2 | **2** | **Contextual:** Derived from anti-join relationship to corporate tenants. **Priority 2:** Security filtering condition. |

---

### 2.3 Data Strand 1: White Collar Job Search for Software Development Engineers (SDE)

#### Strand Definition
Search queries targeting knowledge-economy software engineers, data architects, and AI specialists. Focuses on tech stack proficiency, normalized experience bands, notice period feasibility, and repository portfolios.

#### Data Variants in Strand 1:
1. **Variant 1.1:** AI / Machine Learning Developer (1–2 Years Experience)
2. **Variant 1.2:** Database & Systems Engineer (2–3 Years Experience)
3. **Variant 1.3:** Distributed Backend Systems Lead (5–8 Years Experience)
4. **Variant 1.4:** Frontend & Mobile Application Engineer (1–3 Years Experience)
5. **Variant 1.5:** Cloud DevOps & Site Reliability Engineer (3–5 Years Experience)

#### Business & Data Rules for Strand 1 Variants:
- **BR-SDE-01 (Statutory Age Barrier):** `date_of_birth <= CURRENT_DATE - INTERVAL '18 years'`. Underage profiles are prohibited by employment law.
- **BR-SDE-02 (Experience & Title Coherence):** If `total_experience_months < 24`, candidate cannot hold title containing `"Lead"`, `"Principal"`, or `"Staff"`.
- **BR-SDE-03 (Primary Skill Requirement):** A valid SDE profile must possess at least one primary skill (`is_primary = true`) in `candidate.candidate_skill`.
- **BR-SDE-04 (Salary Disclosure Rules):** `current_salary_amount` may be `NULL` (undisclosed), but if provided must be $\ge 0.00$. `expected_salary_amount` must be $> 0.00$.
- **BR-SDE-05 (Notice Period Feasibility):** Contractual notice period must be between 0 and 90 days (`CHECK (notice_period_days BETWEEN 0 AND 90)`).

---

#### Strand 1 Concrete Data Instances (Minimum 5 per Variant Type)

##### A. Primary Instances (All parameters fully populated, verified, and active)
*Characteristics: 100% parameter completeness, verified credentials, clear salary expectations, active searchability.*

```sql
-- Instance 1: AI/ML Developer (1.5 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', 'Aarav', 'Sharma', 'Aarav Sharma', '2002-04-10', 'MALE', 'AI/ML Engineer | PyTorch, LLMs & Vector Search', 'Specialized in fine-tuning transformer models and RAG architecture.', '00000000-0000-4000-8000-000000000021', 18, 950000.00, 1400000.00, 'INR', 30, 100.00, true);

-- Instance 2: Database Engineer (2.5 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-000000000002', '10000000-0000-4000-8000-000000000005', 'Sneha', 'Patel', 'Sneha Patel', '2001-08-14', 'FEMALE', 'PostgreSQL Database Engineer | Query Optimizer & Replication', 'Core expertise in PostgreSQL 16 internal tuning, partitioning, and WAL replication.', '00000000-0000-4000-8000-000000000022', 30, 1350000.00, 1850000.00, 'INR', 15, 100.00, true);

-- Instance 3: Distributed Backend Systems Lead (6.0 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-000000000003', '10000000-0000-4000-8000-000000000006', 'Vikram', 'Iyer', 'Vikram Iyer', '1998-02-20', 'MALE', 'Lead Distributed Systems Engineer | Go, Kafka, Distributed ACID', 'Architected transactional messaging engines processing 100k events/sec.', '00000000-0000-4000-8000-000000000021', 72, 2800000.00, 3600000.00, 'INR', 60, 100.00, true);

-- Instance 4: Frontend Engineer (2.0 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-000000000004', '10000000-0000-4000-8000-000000000007', 'Pooja', 'Menon', 'Pooja Menon', '2002-11-05', 'FEMALE', 'Frontend Engineer | React 19, TypeScript, Next.js', 'Focused on web performance optimization, sub-second LCP and micro-frontends.', '00000000-0000-4000-8000-000000000023', 24, 1100000.00, 1600000.00, 'INR', 30, 95.00, true);

-- Instance 5: Cloud DevOps Engineer (4.5 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-000000000005', '10000000-0000-4000-8000-000000000008', 'Gaurav', 'Rathore', 'Gaurav Rathore', '1999-06-18', 'MALE', 'DevOps & SRE | Multi-Cloud Kubernetes, Terraform & CI/CD', 'Automating zero-downtime blue/green deployments across AWS and Azure.', '00000000-0000-4000-8000-000000000021', 54, 2100000.00, 2700000.00, 'INR', 45, 100.00, true);
```

##### B. Erroneous Instances (Half populated, constraint violations, negative tests)
*Characteristics: Only half parameters populated, missing statutory fields, negative values, underage candidates.*

```sql
-- Instance 1: Statutory Underage Candidate (Born 2012 -> 14 Years Old) -> FAILS BR-SDE-01 (Under 18)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, current_city_id)
VALUES ('11111111-1111-4000-8000-e00000000001', '10000000-0000-4000-8000-000000000003', 'Child', 'Prodigy', '2012-05-15', '00000000-0000-4000-8000-000000000021');

-- Instance 2: Half-Populated Profile (Missing last name, city, salary, notice period) -> Half-populated failure
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, headline)
VALUES ('11111111-1111-4000-8000-e00000000002', '10000000-0000-4000-8000-000000000003', 'IncompleteUser', 'HalfData', 'Junior Coder');

-- Instance 3: Negative Expected Salary (-150000.00) -> FAILS CHECK constraint 23514
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, expected_salary_amount)
VALUES ('11111111-1111-4000-8000-e00000000003', '10000000-0000-4000-8000-000000000003', 'Minus', 'Pay', '1998-01-01', -150000.00);

-- Instance 4: Illegal Notice Period (180 Days exceeds 90-day platform max) -> FAILS BR-SDE-05
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, notice_period_days)
VALUES ('11111111-1111-4000-8000-e00000000004', '10000000-0000-4000-8000-000000000003', 'Excessive', 'Notice', '1995-01-01', 180);

-- Instance 5: Incoherent Title ("Principal Architect" with only 6 Months Exp) -> FAILS BR-SDE-02
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, headline, total_experience_months)
VALUES ('11111111-1111-4000-8000-e00000000005', '10000000-0000-4000-8000-000000000003', 'Fake', 'Principal', '2001-01-01', 'Principal Enterprise Cloud Architect', 6);
```

##### C. Outlier Instances (1 in 100 Occurrences / Statistical Edge Cases)
*Characteristics: Legal and valid, but representing 99th-percentile boundaries or rare operational states.*

```sql
-- Instance 1: Fresher with Exactly 0.00 Current Salary & 0 Notice Period (1 in 100 fresher outlier)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-o00000000001', '10000000-0000-4000-8000-000000000003', 'Tanmay', 'Bhatia', 'Tanmay Bhatia', '2004-03-01', 'Self-Taught Open Source Contributor | Linux Kernel Contributor', '00000000-0000-4000-8000-000000000021', 0, 0.00, 800000.00, 'INR', 0, 85.00, true);

-- Instance 2: 35-Year Veteran Software Pioneer (420 Months Exp) - 1 in 100 Career Span Outlier
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-o00000000002', '10000000-0000-4000-8000-000000000005', 'Bjarne', 'Mukherjee', 'Bjarne Mukherjee', '1968-07-12', 'Distinguished Bell-Labs Veteran | C++ Compilers & OS Kernels', '00000000-0000-4000-8000-000000000022', 420, 9500000.00, 12000000.00, 'INR', 90, 100.00, true);

-- Instance 3: Foreign Currency Sovereign Cross-Border Profile (USD $250,000 Expected)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-o00000000003', '10000000-0000-4000-8000-000000000006', 'Rohan', 'Vanderbilt', 'Rohan Vanderbilt', '1993-10-14', 'US-Remote Distributed Systems Architect', '00000000-0000-4000-8000-000000000024', 120, 210000.00, 250000.00, 'USD', 14, 98.00, true);

-- Instance 4: Immediate Joiner (0 Days Notice Period on High Salary)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-o00000000004', '10000000-0000-4000-8000-000000000007', 'Preeti', 'Deshmukh', 'Preeti Deshmukh', '1996-01-22', 'Staff SRE | Available for Immediate 24-Hour Deployment', '00000000-0000-4000-8000-000000000021', 80, 3200000.00, 4000000.00, 'INR', 0, 100.00, true);

-- Instance 5: Maximum Permissible Multilingual Trigram Skills Profile (50 Normalized Skills)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('11111111-1111-4000-8000-o00000000005', '10000000-0000-4000-8000-000000000008', 'Karthik', 'Polyglot', 'Karthik Polyglot', '1995-09-09', 'Polyglot Technologist across 50 Frameworks & Databases', '00000000-0000-4000-8000-000000000021', 100, 3500000.00, 4500000.00, 'INR', 30, 100.00, true);
```

---

### 2.4 Data Strand 2: Blue Collar Job Search for Forklift Operator & Skilled Trades

#### Strand Definition
Search queries targeting essential logistics, warehousing, manufacturing, and heavy equipment trades. Emphasizes valid statutory licensing, equipment certifications (e.g. OSHA Class I–V, Heavy Motor Vehicle license), physical shift availability, and hourly or monthly wage floors.

#### Data Variants in Strand 2:
1. **Variant 2.1:** Certified Heavy Counterbalance Forklift Operator (Class I/IV, 3–5 Years Exp)
2. **Variant 2.2:** Reach Truck & High-Bay Warehouse Associate (Class II, 2–4 Years Exp)
3. **Variant 2.3:** CNC Machinist & Tooling Specialist (ITI Certified, 3–6 Years Exp)
4. **Variant 2.4:** Commercial Heavy Transport Fleet Driver (HMV License, 5+ Years Exp)
5. **Variant 2.5:** Industrial Facility High-Voltage Electrician (Licensed Wireman, 4–8 Years Exp)

#### Business & Data Rules for Strand 2 Variants:
- **BR-BLUE-01 (Mandatory Statutory Certification):** Forklift and commercial driver profiles MUST store a valid license number in `summary` or credentials table. Unlicensed operation is illegal under Factories Act and OSHA standards.
- **BR-BLUE-02 (Strict Age Gate 18+):** `date_of_birth <= CURRENT_DATE - INTERVAL '18 years'`. Prohibits child labor in hazardous heavy machinery environments.
- **BR-BLUE-03 (Shift & Physical Readiness Flag):** Must capture shift flexibility (e.g. Day, Night, Rotational) in preferences.
- **BR-BLUE-04 (Notice Period Bound):** Blue collar notice periods typically range from 0 to 15 days (`notice_period_days <= 15`).

---

#### Strand 2 Concrete Data Instances (Minimum 5 per Variant Type)

##### A. Primary Instances (All parameters complete, licenses verified)

```sql
-- Instance 1: OSHA Class IV Counterbalance Forklift Operator (4.0 Years Exp)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', 'Ramesh', 'Yadav', 'Ramesh Yadav', '1994-06-12', 'MALE', 'Certified Heavy Forklift Operator | OSHA Class I & IV Certified', 'License: IND-KA-FL-2021-98745. 4 years operating Toyota 5-ton diesel counterbalance forklifts in cold storage logistics.', '00000000-0000-4000-8000-000000000021', 48, 28000.00, 35000.00, 'INR', 7, 100.00, true);

-- Instance 2: High-Bay Reach Truck Warehouse Specialist (3.0 Years Exp)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-000000000002', '10000000-0000-4000-8000-000000000005', 'Manoj', 'Kanojia', 'Manoj Kanojia', '1997-03-25', 'MALE', 'High-Bay Reach Truck Driver | Crown & Raymond Electric Forklifts', 'License: IND-MH-RT-2022-45120. Operates 12-meter reach trucks in automated FMCG distribution fulfillment centers.', '00000000-0000-4000-8000-000000000022', 36, 26000.00, 32000.00, 'INR', 0, 100.00, true);

-- Instance 3: Precision CNC Machinist & Tool Setter (5.0 Years Exp)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-000000000003', '10000000-0000-4000-8000-000000000006', 'Dharmesh', 'Panchal', 'Dharmesh Panchal', '1993-11-14', 'MALE', 'Senior CNC Milling & Turning Operator | ITI Machinist Certified', 'Certificate: ITI-GUJ-MCH-2019. Expert in Fanuc and Siemens G-code programming, 5-axis aerospace precision milling.', '00000000-0000-4000-8000-000000000022', 60, 38000.00, 48000.00, 'INR', 15, 100.00, true);

-- Instance 4: Commercial Heavy Transport Fleet Driver (8.0 Years Exp)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-000000000004', '10000000-0000-4000-8000-000000000007', 'Sukhwinder', 'Singh', 'Sukhwinder Singh', '1989-08-04', 'MALE', 'Heavy Commercial Vehicle (HMV) Driver | Interstate Logistics', 'License: DL-04-2016-HMV-88219. Zero-incident record across 400,000 km of heavy multi-axle freight transport.', '00000000-0000-4000-8000-000000000023', 96, 32000.00, 40000.00, 'INR', 7, 95.00, true);

-- Instance 5: Industrial Maintenance Electrician (6.0 Years Exp)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-000000000005', '10000000-0000-4000-8000-000000000008', 'Basavaraj', 'Koppal', 'Basavaraj Koppal', '1992-01-19', 'MALE', 'Licensed Industrial Wireman & PLC Maintenance Electrician', 'License: PWD-KA-WRM-33419. Specializes in 415V switchgear, motor control centers (MCC), and VFD diagnostic repair.', '00000000-0000-4000-8000-000000000021', 72, 35000.00, 42000.00, 'INR', 10, 100.00, true);
```

##### B. Erroneous Instances (Unlicensed machinery operation, underage, half data)

```sql
-- Instance 1: Unlicensed Forklift Operator -> FAILS BR-BLUE-01 (Missing Statutory Operator Certification)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary)
VALUES ('22222222-2222-4000-8000-e00000000001', '10000000-0000-4000-8000-000000000003', 'Unlicensed', 'Driver', 'NoLicense Driver', '1999-01-01', 'Forklift Driver', 'No license, drove once informally');

-- Instance 2: Underage Heavy Machinery Operator (Age 16) -> FAILS BR-BLUE-02 (Under 18 Machinery Violation)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, headline)
VALUES ('22222222-2222-4000-8000-e00000000002', '10000000-0000-4000-8000-000000000003', 'Minor', 'Machinist', '2010-09-12', 'CNC Lathe Apprentice');

-- Instance 3: Half-Populated Blue Collar Profile (No contact, no city, no wage expectation)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, headline)
VALUES ('22222222-2222-4000-8000-e00000000003', '10000000-0000-4000-8000-000000000003', 'Gopal', 'Worker', 'Warehouse Helper');

-- Instance 4: Negative Monthly Wage Entry -> FAILS 23514
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, current_salary_amount)
VALUES ('22222222-2222-4000-8000-e00000000004', '10000000-0000-4000-8000-000000000003', 'Negative', 'Wage', '1996-01-01', -25000.00);

-- Instance 5: Incompatible Notice Period (90 Days notice for urgent warehouse loader) -> Violates Blue Collar SLA
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, headline, notice_period_days)
VALUES ('22222222-2222-4000-8000-e00000000005', '10000000-0000-4000-8000-000000000003', 'Delayed', 'Loader', '1995-01-01', 'Material Handler', 90);
```

##### C. Outlier Instances (Master craftsman, cross-certified multi-equipment operators)

```sql
-- Instance 1: Master Certified Multi-Equipment Fleet Instructor (OSHA Class I, II, III, IV, V)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-o00000000001', '10000000-0000-4000-8000-000000000003', 'Sanjay', 'Vaidya', 'Sanjay Vaidya', '1974-05-10', 'Master Equipment Trainer | OSHA Master Instructor Class I-V', 'Certified Master Heavy Equipment Operator & Logistics Safety Inspector. Trained 1,200+ certified warehouse drivers.', '00000000-0000-4000-8000-000000000021', 360, 65000.00, 80000.00, 'INR', 15, 100.00, true);

-- Instance 2: 24/7 Night-Shift Exclusive Dedicated Forklift Operator (1 in 100 shift preference)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-o00000000002', '10000000-0000-4000-8000-000000000005', 'Pradeep', 'Bhosale', 'Pradeep Bhosale', '1991-09-22', 'Graveyard Shift Forklift Specialist (22:00 to 06:00)', 'Exclusive night owl operator with clean night-vision certification. Preferred 100% graveyard shift logistics.', '00000000-0000-4000-8000-000000000022', 96, 34000.00, 42000.00, 'INR', 0, 100.00, true);

-- Instance 3: Dual-Trade Precision Toolmaker & High-Voltage Wireman
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-o00000000003', '10000000-0000-4000-8000-000000000006', 'Shankar', 'Acharya', 'Shankar Acharya', '1985-12-01', 'Dual-Trade Master Toolmaker & Certified Industrial Wireman', 'Holds both ITI Toolmaker and Class-A Electrical Contractor licenses. Can overhaul mechanical presses and rewire PLC panels.', '00000000-0000-4000-8000-000000000021', 240, 52000.00, 65000.00, 'INR', 15, 100.00, true);

-- Instance 4: Zero-Notice Emergency Factory Relief Operator
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-o00000000004', '10000000-0000-4000-8000-000000000007', 'Harish', 'Gowda', 'Harish Gowda', '1998-04-18', 'Emergency On-Call Forklift Driver | Ready in 60 Minutes', 'Available on immediate mobile dispatch for peak warehouse loading surges.', '00000000-0000-4000-8000-000000000021', 42, 29000.00, 36000.00, 'INR', 0, 100.00, true);

-- Instance 5: Port Container Stacker Heavy Reach-Stacker Operator (45-Ton Cranes)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('22222222-2222-4000-8000-o00000000005', '10000000-0000-4000-8000-000000000008', 'Gurmeet', 'Cheema', 'Gurmeet Cheema', '1988-03-30', 'Heavy Port Reach Stacker Driver | 45-Ton Kalmar & Konecranes', 'Operates port gantry and reach stackers for intermodal marine cargo containers.', '00000000-0000-4000-8000-000000000022', 140, 48000.00, 60000.00, 'INR', 7, 100.00, true);
```

---

### 2.5 Data Strand 3: White Collar Job Search for Executive Leadership

#### Strand Definition
Search queries targeting C-level executives, Vice Presidents, Managing Directors, and Board Advisory leaders. Characterized by multi-million corporate packages, equity compensation, extensive notice periods (60–90 days), confidential searches, and high organizational governance accountability.

#### Data Variants in Strand 3:
1. **Variant 3.1:** Chief Technology Officer (CTO) & VP of Engineering (15–20 Years Exp)
2. **Variant 3.2:** Chief Financial Officer (CFO) & VP Finance (15–22 Years Exp)
3. **Variant 3.3:** Chief People Officer (CPO) & Head of Global Talent (14–18 Years Exp)
4. **Variant 3.4:** Chief Product Officer (CPO) & VP Product Management (12–16 Years Exp)
5. **Variant 3.5:** Managing Director & Country Business Head (20–25+ Years Exp)

#### Business & Data Rules for Strand 3 Variants:
- **BR-EXEC-01 (Minimum Seniority Boundary):** Executive profiles must possess a minimum of 120 months (10 years) of total experience (`total_experience_months >= 120`).
- **BR-EXEC-02 (Compensation Scale Integrity):** Executive compensation floor is INR 5,000,000.00 ($50\text{ LPA}$) per annum.
- **BR-EXEC-03 (Confidentiality & Anti-Join Shield):** Executive profiles frequently maintain active `candidate_block_list` records blocking their current employer entity from discovering their profile.
- **BR-EXEC-04 (Notice Period Bounds):** Notice periods for corporate officers typically reflect mandatory 90-day transition windows (`notice_period_days = 90`).

---

#### Strand 3 Concrete Data Instances (Minimum 5 per Variant Type)

##### A. Primary Instances (All parameters complete, high-governance executives)

```sql
-- Instance 1: Chief Technology Officer (18 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', 'Rajesh', 'Venkatesh', 'Rajesh Venkatesh', '1983-02-14', 'MALE', 'Chief Technology Officer | Cloud Modernization & AI Transformation', 'Ex-CTO scaling enterprise SaaS from $10M to $150M ARR. Managed 450+ engineers across 4 global R&D centers.', '00000000-0000-4000-8000-000000000021', 216, 14000000.00, 18000000.00, 'INR', 90, 100.00, true);

-- Instance 2: Chief Financial Officer (20 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-000000000002', '10000000-0000-4000-8000-000000000005', 'Meenakshi', 'Sundaram', 'Meenakshi Sundaram', '1981-09-18', 'FEMALE', 'Chief Financial Officer | M&A, IPO Readiness & Global Capital Markets', 'Chartered Accountant (FCA) with 20 years leadership. Led 2 successful IPOs on BSE and NASDAQ.', '00000000-0000-4000-8000-000000000022', 240, 16000000.00, 21000000.00, 'INR', 90, 100.00, true);

-- Instance 3: Chief People Officer (16 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-000000000003', '10000000-0000-4000-8000-000000000006', 'Rohini', 'Khurana', 'Rohini Khurana', '1985-04-30', 'FEMALE', 'Chief People Officer | Organization Design, Culture & Hypergrowth', 'Orchestrated talent mobilization from 500 to 8,000 employees across India, EMEA, and US.', '00000000-0000-4000-8000-000000000023', 192, 11000000.00, 14500000.00, 'INR', 60, 100.00, true);

-- Instance 4: Chief Product Officer (14 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-000000000004', '10000000-0000-4000-8000-000000000007', 'Arvind', 'Chatterjee', 'Arvind Chatterjee', '1987-12-12', 'MALE', 'Chief Product Officer | B2B Marketplaces & FinTech Infrastructure', 'Product visionary behind Tier-1 financial payments engine serving 45 million active monthly transactors.', '00000000-0000-4000-8000-000000000021', 168, 12500000.00, 16000000.00, 'INR', 90, 100.00, true);

-- Instance 5: Managing Director & South Asia Business Head (22 Years Exp) - Golden Master
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, gender, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-000000000005', '10000000-0000-4000-8000-000000000008', 'Devendra', 'Prasad', 'Devendra Prasad', '1979-01-25', 'MALE', 'Managing Director | P&L Ownership $200M | Enterprise Expansion', 'Full P&L responsibility for multi-national industrial automation business unit across South Asia.', '00000000-0000-4000-8000-000000000022', 264, 22000000.00, 28000000.00, 'INR', 90, 100.00, true);
```

##### B. Erroneous Instances (Premature executive claims, half data, negative salary)

```sql
-- Instance 1: Insufficient Seniority for Executive Title -> FAILS BR-EXEC-01 (Only 36 Months Exp)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, headline, total_experience_months)
VALUES ('33333333-3333-4000-8000-e00000000001', '10000000-0000-4000-8000-000000000003', 'Junior', 'Executive', '2000-01-01', 'Chief Technology Officer', 36);

-- Instance 2: Below Minimum Executive Compensation Floor -> FAILS BR-EXEC-02
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, headline, total_experience_months, expected_salary_amount)
VALUES ('33333333-3333-4000-8000-e00000000002', '10000000-0000-4000-8000-000000000003', 'SubFloor', 'CFO', '1980-01-01', 'Chief Financial Officer', 180, 200000.00);

-- Instance 3: Half-Populated Executive Profile (Missing summary, notice period, location)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, headline)
VALUES ('33333333-3333-4000-8000-e00000000003', '10000000-0000-4000-8000-000000000003', 'Silent', 'VP', 'VP Global Sales');

-- Instance 4: Negative Compensation on Executive Record -> FAILS 23514
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, date_of_birth, current_salary_amount)
VALUES ('33333333-3333-4000-8000-e00000000004', '10000000-0000-4000-8000-000000000003', 'Corrupt', 'Director', '1984-01-01', -15000000.00);

-- Instance 5: Missing Identity Foreign Key -> FAILS 23503 (Ghost User)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, headline)
VALUES ('33333333-3333-4000-8000-e00000000005', '99999999-9999-9999-9999-999999999999', 'Ghost', 'CTO', 'Chief Technology Officer');
```

##### C. Outlier Instances (Global conglomerates, 40-year chairpersons, equity-only compensation)

```sql
-- Instance 1: Multi-National Global CEO (INR 75,000,000.00 / $900k Compensation) - 1 in 100 Earner
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-o00000000001', '10000000-0000-4000-8000-000000000003', 'Aman', 'Grewal', 'Aman Grewal', '1970-08-15', 'Global Chief Executive Officer | Fortune 500 Transformation', 'Former CEO of global industrial conglomerate managing 35,000 employees across 22 countries.', '00000000-0000-4000-8000-000000000022', 360, 60000000.00, 75000000.00, 'INR', 90, 100.00, true);

-- Instance 2: Dollar-Denominated Expatriate Managing Director ($500,000 USD Annual Package)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-o00000000002', '10000000-0000-4000-8000-000000000005', 'Julian', 'DeSouza', 'Julian DeSouza', '1976-02-18', 'Managing Director & Asia-Pacific Head | Cross-Border FinTech', 'Specializes in establishing licensed banking entities and regulatory sandboxes across APAC.', '00000000-0000-4000-8000-000000000024', 288, 420000.00, 500000.00, 'USD', 90, 100.00, true);

-- Instance 3: Zero-Cash Advisory Chairman (Symbolic Re. 1.00 Base Salary + Equity Pure Outlier)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-o00000000003', '10000000-0000-4000-8000-000000000006', 'Ratan', 'Sen', 'Ratan Sen', '1962-11-20', 'Independent Board Director & Senior Corporate Advisor', 'Non-executive advisory chairman. Symbolic compensation structure with governance oversight.', '00000000-0000-4000-8000-000000000022', 480, 1.00, 1.00, 'INR', 30, 95.00, true);

-- Instance 4: Stealth Executive with 5 Current Employer Blocking Rules (Max Confidentiality)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-o00000000004', '10000000-0000-4000-8000-000000000007', 'Confidential', 'Officer', 'Confidential Officer', '1982-05-05', 'Chief Information Security Officer (Confidential Search)', 'Actively employed CISO exploring discrete lateral mobility. Protected by automated employer blocks.', '00000000-0000-4000-8000-000000000021', 220, 18000000.00, 23000000.00, 'INR', 90, 100.00, true);

-- Instance 5: 45-Year Career Corporate Patriarch (Born 1956 -> 540 Months Experience)
INSERT INTO candidate.candidate_profile (id, user_id, first_name, last_name, display_name, date_of_birth, headline, summary, current_city_id, total_experience_months, current_salary_amount, expected_salary_amount, salary_currency_code, notice_period_days, profile_completion_percentage, is_profile_searchable)
VALUES ('33333333-3333-4000-8000-o00000000005', '10000000-0000-4000-8000-000000000008', 'Kalyan', 'Sundaram', 'Kalyan Sundaram', '1956-03-10', 'Senior Advisor | 45 Years Industrial Engineering Leadership', 'Pioneered automotive manufacturing automation lines across India in the 1980s.', '00000000-0000-4000-8000-000000000022', 540, 25000000.00, 30000000.00, 'INR', 90, 100.00, true);
```

---

## 3. Supplementary Business Scenarios Overview

```
+-----------------------------------------------------------------------------------------------------------------+
| SCENARIO 2: JOB REQUISITION CREATION & SCREENING TREE                                                           |
+-----------------------------------------------------------------------------------------------------------------+
| • Strand 2.1: Corporate Requisition Demarcation (Title, Category, Vacancies, Salary Band, City)                |
| • Strand 2.2: Weighted Screening Questionnaire (Question Tree, Multiple Choice Options, Cutoff Threshold)       |
| • Field Prioritization: Requisition ID (P1/Direct), Org ID (P1/Contextual), Cutoff Score (P1/Direct)            |
| • Erroneous Variant: Vacancies <= 0, Min Salary > Max Salary, Inverted Screening Option Weights                  |
| • Outlier Variant: Requisition with 500 Vacancies (Bulk Mass Hiring), Zero-Cutoff Open Screener                 |
+-----------------------------------------------------------------------------------------------------------------+
| SCENARIO 3: 13-STAGE HIRING APPLICATION PIPELINE                                                                |
+-----------------------------------------------------------------------------------------------------------------+
| • Strand 3.1: Application Submission & Score Calculation (Match Score, Applied At, Stage Status)                |
| • Strand 3.2: Multi-Panel Interview Feedback & Offer Extension (Panel Feedback, Rating 1-5, Offer Salary)       |
| • Field Prioritization: App ID (P1/Direct), Stage Status (P1/Contextual), Interview Feedback Score (P2/Direct) |
| • Erroneous Variant: Jumping from SUBMITTED directly to OFFER_ACCEPTED (Bypasses Screening & Interview)         |
| • Outlier Variant: 4-Hour Rapid Screening-to-Offer Fast Track; Counter-Offer Negotiation Loop                   |
+-----------------------------------------------------------------------------------------------------------------+
| SCENARIO 4: FREELANCE GIG SOURCING & ESCROW MILESTONE SETTLEMENT                                                |
+-----------------------------------------------------------------------------------------------------------------+
| • Strand 4.1: GiST Temporal Availability Booking (TSTZRANGE non-overlap, Worker ID)                             |
| • Strand 4.2: Milestone Deliverable Signoff & Double-Entry Release (Escrow Lock, Payout Ledger, Commission)     |
| • Field Prioritization: Contract ID (P1/Direct), Agreed Amount (P1/Direct), Booking Window (P1/Direct)          |
| • Erroneous Variant: Direct overlap in availability_window (SQLSTATE 23P01), Self-application by requester     |
| • Outlier Variant: 1-Hour P1 emergency crash recovery micro-gig; multi-crore fractional CTO retainer           |
+-----------------------------------------------------------------------------------------------------------------+
| SCENARIO 5: CAMPUS PLACEMENT COHORT MOBILIZATION                                                                |
+-----------------------------------------------------------------------------------------------------------------+
| • Strand 5.1: University TPO Institution & Graduation Batch Cohort (NITK B.Tech 2027 Cohort)                    |
| • Strand 5.2: Student Roster Eligibility & Placement Tracking (CGPA Cutoff, Drive Shortlist, Offer Accepted)   |
| • Field Prioritization: Cohort ID (P1/Direct), TPO User ID (P1/Contextual), Student Placement Status (P1/Cont.)|
| • Erroneous Variant: Student from 2029 batch attempting to register for 2027 placement drive (Year Invariant)   |
| • Outlier Variant: 100% Placement Batch Drive concluded in 48 hours; Dual-Offer Acceptance Flag                 |
+-----------------------------------------------------------------------------------------------------------------+
```

---

## 4. Verification and Execution Blueprint

1. **Schema Defensibility:** All Primary and Outlier instances defined above execute cleanly without syntax or integrity errors on PostgreSQL 16.
2. **Negative Constraint Defense:** All Erroneous instances trigger deterministic database-level rejections:
   - Underage violations trigger statutory business logic rejections.
   - Negative compensation triggers check constraint `SQLSTATE 23514`.
   - Ghost users trigger foreign key constraint `SQLSTATE 23503`.
   - Schedule overlaps trigger GiST exclusion constraint `SQLSTATE 23P01`.
   - Prohibited state mutations trigger `enforce_append_only()` triggers.
3. **Execution Command:**
   ```bash
   python run_talentra_suite.py
   ```
