-- Reference Seed: DPDP Act 2023 Statutory Data Retention Policies
INSERT INTO governance.data_retention_policy (
    id, entity_type, retention_period_days, statutory_basis, auto_delete_action, description,
    created_at, created_by, updated_at, updated_by
) VALUES
  ('00000000-0000-4000-8000-000000000051', 'INACTIVE_CANDIDATE_PROFILE', 1095, 'India DPDP Act 2023 Sec 12 (Purpose Limitation)', 'CRYPTO_SHRED', 'Candidate profiles inactive for 3 years are crypto-shredded', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('00000000-0000-4000-8000-000000000052', 'REJECTED_JOB_APPLICATION', 730, 'Statutory Labor Audit Defense', 'SOFT_DELETE', 'Rejected job application records retained for 2 years for anti-bias compliance', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('00000000-0000-4000-8000-000000000053', 'SYSTEM_AUDIT_LOG', 2555, 'Statutory Financial & Corporate Compliance', 'ARCHIVE_COLD', 'Immutable system audit logs retained for 7 years for forensic audit', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('00000000-0000-4000-8000-000000000054', 'EXPIRED_NOTIFICATION_LOG', 90, 'Operational Telemetry Hygiene', 'HARD_DELETE', 'Delivery logs for push/SMS/email notifications purged after 90 days', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000')
ON CONFLICT (id) DO NOTHING;
