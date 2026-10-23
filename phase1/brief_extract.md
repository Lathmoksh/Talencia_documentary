# Talentra Project Specification Brief Extract
**Document Reference:** `phase1/brief_extract.md`  
**Classification:** Reconstructed Reference Extract (Not Verbatim Original)  
**Source Baseline:** Synthesized from Talentra Problem Statement, Business Briefings & Domain Architecture Notes  
**Traceability Target:** Provides the baseline reference clauses (`BRIEF-SEC-*.`) cited in [01_requirements.csv](01_requirements.csv).

> **Note on Document Provenance:**  
> This docket is a reconstructed reference summary created to provide explicit clause citations for requirements engineering and traceability validation. It captures the essential contractual, functional, and regulatory mandates established for the Talentra platform. Requirements derived from competitive intelligence and gap analysis are tagged separately as `COMP-DISC-*`.

---

### Section 1: Foundation, User Identity & Security Boundaries (`BRIEF-SEC-01`)
* **BRIEF-SEC-01.1**: User registration must enforce case-insensitive uniqueness across email addresses so users cannot register identical accounts with mixed casing.
* **BRIEF-SEC-01.2**: All contact phone numbers must be validated and stored conforming to the international ITU-T E.164 standard (`+[country_code][subscriber_number]`).
* **BRIEF-SEC-01.3**: All primary entities across users, corporate tenants, job requisitions, and contracts must possess immutable unique identifiers that do not expose sequential business volumes.
* **BRIEF-SEC-01.4**: Platform lookup categories (industry codes, job roles, trade skills) must provide active status indicators and administrative display ordering.
* **BRIEF-SEC-01.5**: Platform user interfaces and static messaging catalogs must support localized multi-language presentation with default English fallback.
* **BRIEF-SEC-01.6**: User authentication credentials must be protected against brute-force extraction and dictionary attacks using computationally expensive cryptographic transformations.
* **BRIEF-SEC-01.7**: Enterprise recruiter accounts must restrict concurrent multi-device logins to prevent unmetered credential sharing across unauthorized personnel.

---

### Section 2: Talent Sourcing, Screening & Academic Cohorts (`BRIEF-SEC-02`)
* **BRIEF-SEC-02.1**: Job requisitions must support attached structured questionnaires featuring weighted scoring benchmarks and minimum automated passing thresholds.
* **BRIEF-SEC-02.2**: Hiring organizations must have the capability to attach dynamic custom pre-qualification assessment criteria per job requisition.
* **BRIEF-SEC-02.3**: Candidate privacy controls must empower individuals to designate specific corporate organizations and competing employers who are strictly forbidden from seeing their profile.
* **BRIEF-SEC-02.4**: Academic partners and placement officers must be able to batch-onboard graduate student cohorts grouped by university, degree program, and graduation year.
* **BRIEF-SEC-02.5**: The platform must support attribution-tracked referral links enabling employees and candidates to refer applicants with verified hiring attribution.
* **BRIEF-SEC-02.6**: Sourcing talent discovery across multi-million candidate profiles must deliver interactive low-latency keyword and skill similarity matching under heavy concurrent loads.

---

### Section 3: Multi-Tenancy & Contingent Freelance Scheduling (`BRIEF-SEC-03`)
* **BRIEF-SEC-03.1**: Corporate enterprise client data, candidate pipelines, and evaluation dossiers must maintain absolute organizational isolation between competing corporate accounts.
* **BRIEF-SEC-03.2**: Freelance professional calendars must enforce strict temporal non-overlapping booking guarantees to prevent simultaneous project double-booking.

---

### Section 4: Billing, Quotas & Financial Settlement (`BRIEF-SEC-04`)
* **BRIEF-SEC-04.1**: All monetary transactions, compensation bands, and wallet balances must employ fixed-precision decimal arithmetic paired with ISO 4217 standard currency codes.
* **BRIEF-SEC-04.2**: Client prepaid wallet balances, milestone escrow reserves, and contractor disbursements must maintain mathematical double-entry equality with zero variance.
* **BRIEF-SEC-04.3**: Recruiter access to unmasked candidate contact details and resumes must be metered against paid monthly quota balances or wallet deductions.
* **BRIEF-SEC-04.4**: Tiered corporate subscription plans must strictly enforce contractual seat caps on the maximum number of simultaneously provisioned recruiters.
* **BRIEF-SEC-04.5**: External integration webhooks for payment gateways and verification providers must guarantee idempotent exactly-once transaction processing.

---

### Section 5: Regulatory Governance, Audit & Business Continuity (`BRIEF-SEC-05`)
* **BRIEF-SEC-05.1**: All security-critical operational events, administrative mutations, and contact unlocks must write to an immutable, append-only audit trail.
* **BRIEF-SEC-05.2**: Candidate personal data processing must record affirmative, purpose-bound consent with instant personal data erasure upon candidate consent revocation.
* **BRIEF-SEC-05.3**: All platform data attributes must be classified by statutory confidentiality tiers with automated retention and purging rules.
* **BRIEF-SEC-05.4**: Sensitive tax identifiers and national identity numbers must be searchable for verification without exposing unencrypted plaintext values.
* **BRIEF-SEC-05.5**: The platform architecture must support automated disaster recovery replication with near-zero data loss (RPO <= 1 min) and rapid service restoration (RTO <= 15 min).
