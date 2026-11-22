# Milestone 20 — Test Suite v2: Data, Business Rules and NFRs

**Phase:** 3 — Prove  
**Test stage:** Full model proof against sample data, rules, transitions and non-functional targets  
**Output:** Executable suite v2; traceability to rule/transition/NFR IDs; results at target volume

## 1. Purpose and exit criteria

Extend Milestone 15's data-integrity suite to cover every business rule, lifecycle transition and applicable non-functional requirement. Include exact boundary tests and performance/security checks at target volume.

**Done when:** every data rule, business rule, transition and NFR has at least one linked test; the suite passes against the sample data; target-volume results and exceptions are recorded.

## 2. Traceability inputs

- Step 11: `DR-001`–`DR-085`, `CTR-01`–`CTR-10`, existing test mappings.
- Step 08: 20 stateful entity lifecycles and allowed/prohibited transitions.
- Milestone 18: `BR-###` business-rule catalogue.
- Phase 1 requirements and NFR register in the project docket / discovery materials.
- Milestone 13 volume profile and Milestone 14 deterministic dataset.
- Milestone 16 workflow coverage matrix and Milestone 17 refinement log.

Confirm the exact NFR IDs and targets in the source baseline before asserting numerical thresholds. Do not invent latency, throughput, availability or retention targets.

## 3. Test matrix

| Test family | What to verify | Test method / evidence |
|---|---|---|
| Data integrity | PK/FK/unique/check/null/domain/temporal constraints | SQL positive, negative and boundary tests |
| Business rules | Eligibility, policies, calculations, approvals, access | Rule-linked integration tests / decision-table cases |
| Lifecycle | Every permitted and prohibited transition; guard conditions | State-transition table tests |
| Concurrency | Competing updates, credit/seat deductions, booking conflicts, idempotency | Concurrent sessions and transaction assertions |
| Privacy / security | Tenant isolation, candidate block shield, disclosure gating, consent, audit | Role-scoped SQL/API tests and audit evidence |
| Financial | Ledger balance, wallet/quota atomicity, duplicate webhook/idempotency | Transactional reconciliation tests |
| Workflow | End-to-end store/retrieve/transition/audit paths | SQL-driven workflow scenarios |
| NFR / scale | Query plan, latency/throughput, storage, growth, resilience targets | Benchmark at documented row volume and workload |
| Data quality | Completeness, valid domains, referential integrity, distribution | Profiling queries and generator checks |
| Migration / DDL | Clean install and upgrade reproducibility | Empty DB install, migration replay and schema comparison |

## 4. Boundary and transition coverage

For each numeric/date/limit rule test:
- exact lower boundary;
- just below lower boundary;
- exact upper boundary;
- just above upper boundary;
- null / absent behavior where allowed;
- concurrent attempt where state or capacity can race.

For each state machine:
- every allowed edge succeeds under its guard;
- every prohibited edge is rejected;
- terminal states behave as documented;
- unauthorized actor is denied;
- duplicate/replayed action does not create duplicate effects;
- concurrency behavior is deterministic.

## 5. NFR evidence

Build the test workload from Milestone 13's documented population and skew. Record:
- database version/configuration, hardware/container limits and indexes;
- fixture scale and distribution;
- query or workflow under test;
- warm/cold cache conditions if relevant;
- sample count, p50/p95/p99 where the NFR defines latency;
- throughput, error rate, query plan and resource usage;
- exact NFR ID and target from source;
- outcome and limitations.

Do not label a laptop-scale test as proof of 10-million-profile production capacity. Distinguish local smoke test, scaled simulation and representative environment benchmark.

## 6. Execution report

Each test includes `test_id`, `rule_id`/`transition_id`/`NFR_id`, setup, action, expected, actual, pass/fail, evidence, environment and timestamp. Report coverage gaps separately from failures.

## 7. Acceptance checklist

- [ ] Every DR, CTR, BR, lifecycle transition and NFR has a test link.
- [ ] Exact boundaries are tested.
- [ ] Positive, negative, concurrency and replay cases are included where applicable.
- [ ] Workflow tests validate persistence, retrieval, authorization and audit.
- [ ] NFR tests use documented targets and volumes.
- [ ] Suite v2 passes or has explicit, owned exceptions.
- [ ] Test evidence is reproducible and retained.

## 8. Go deeper

Add tests at the exact boundary values. A rule tested only at ordinary values may still fail at its limit or under concurrent execution.
