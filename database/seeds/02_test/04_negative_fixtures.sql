-- Negative Fixtures for Test Assertions
-- 1. Candidate Privacy Block on Organisation
INSERT INTO candidate.candidate_block_list (
  id, candidate_id, blocked_organisation_id, block_reason, created_at, updated_at
) VALUES (
  '74000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001',
  '21000000-0000-4000-8000-000000000001', 'Current employer privacy shield - hide my profile from my employer',
  '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
