-- Reference Seed: Statutory Data Retention Rules (India DPDP Act 2023)
INSERT INTO governance.data_retention_policy (id, entity_type, retention_duration_days, action_on_expiry, is_active, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000091', 'candidate.candidate_profile', 1095, 'NOTIFY_AND_ANONYMIZE', true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000092', 'application.job_application', 730, 'PURGE_UNSUCCESSFUL', true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000093', 'governance.system_audit_event', 2920, 'ARCHIVE_COLD_STORAGE', true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000094', 'billing.wallet_ledger', 2920, 'IMMUTABLE_STATUTORY_HOLD', true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;
