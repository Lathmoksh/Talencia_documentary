# Milestone 16 — Schema Coverage Against Business Workflow

**Phase:** 3 — Prove  
**Output:** Workflow-step × table coverage matrix, gap list, owner and evidence

## 1. Purpose and exit criteria

Verify that the discovered schema supports how Talentra actually operates: can each workflow step be stored, retrieved, authorized, transitioned, and audited? A table list alone does not prove workflow support.

**Done when:** 100% of workflow steps are mapped to supporting tables and operations, or each gap is documented with an owner, rationale and disposition.

## 2. Workflow baseline

Use the project docket's core workflows and the workflow IDs in Steps 07–12 (`WF-01` through `WF-10`). Confirm exact names and boundaries from the source materials. The coverage matrix should include, at minimum, the following workflow areas:

1. Candidate registration, authentication, profile and resume maintenance.
2. Candidate discovery/search and privacy shielding.
3. Employer/client registration, verification and recruiter mapping.
4. Requisition creation, questionnaire setup, publication and maintenance.
5. Application submission, screening, interview, offer and terminal outcomes.
6. Consultant sourcing request, nomination and employer decision.
7. Gig request, application, acceptance, external handoff and status reconciliation.
8. Licensing, subscriptions, seats, devices, quota and credit use.
9. Wallet recharge, payment order, invoice, refund and ledger reconciliation.
10. Notifications, alerts, referrals and campus cohort operations.
11. Consent, data subject requests, retention, key handling and audit.
12. Analytics reporting at the defined dimensions and fact grains.

## 3. Coverage matrix format

| Workflow ID / step | Actor | Action / decision | Read tables | Write tables | Rule / transition IDs | Audit evidence | Test ID | Coverage |
|---|---|---|---|---|---|---|---|---|
| WF-xx / step-x | actor | action | schema.table | schema.table | BR-/DR-/CTR-/transition | audit record | TC-WF-### | covered / gap |

Use exact schema-qualified table names from the current ER/DDL. For a multi-step transaction, document its transaction boundary and expected atomicity.

## 4. Coverage evaluation questions

For each step, answer:
- Is the required business fact represented without overloading an unrelated attribute?
- Can the actor be authorized and tenant-scoped?
- Can the system retrieve the fact efficiently through a known relationship?
- Are state transitions guarded by the correct preconditions?
- Is sensitive data filtered, masked or gated as required?
- Is a sensitive action audited?
- Can the operation be tested using the Milestone 14 fixture?
- Does the design support failure, retry, cancellation and terminal states where applicable?

## 5. Gap classification

- **Critical:** missing data or enforcement makes a required workflow impossible or unsafe.
- **High:** workflow can run but integrity, authorization, auditability or core business outcome is unreliable.
- **Medium:** a workflow variation, reporting need or maintainability concern is unsupported.
- **Deferred:** intentionally out of scope; record reason, impact, owner and revisit trigger.

Do not mark a gap closed merely because a table name appears in a diagram. Require a stored/retrieved/audited path and a test.

## 6. Outputs and acceptance

- [ ] Matrix covers each workflow step, not just workflow headings.
- [ ] Every table used is identified by exact schema-qualified name.
- [ ] Read/write path, actor, rules, transitions and audit evidence are recorded.
- [ ] Every uncovered item has owner, severity and disposition.
- [ ] SQL tests execute representative workflows against sample data.
- [ ] Coverage totals and gaps are reproducible.

## 7. Go deeper

Run the workflow as SQL against the sample dataset. This exposes missing join paths, state storage, tenant filters and audit records that static ER review may miss.
