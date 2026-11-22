-- Development Wallets Seed: Paired Double-Entry Balances ($0.00 Drift)
-- Wallet Accounts
INSERT INTO billing.wallet_account (
  id, account_id, wallet_type, currency_code, current_balance, escrow_reserved_balance, is_locked, created_at, updated_at
) VALUES
  ('60000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'CORPORATE_PREPAID', 'INR', 100000.00, 0.00, false, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;

-- Double-Entry Ledger Initial Funding ($100,000 credit paired with settlement journal)
INSERT INTO billing.wallet_ledger (
  id, wallet_id, transaction_group_id, entry_type, amount, currency_code, balance_after,
  reference_entity_type, reference_entity_id, notes, created_at
) VALUES (
  '61000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
  '62000000-0000-4000-8000-000000000001', 'CREDIT', 100000.00, 'INR', 100000.00,
  'PAYMENT_GATEWAY_DEPOSIT', '63000000-0000-4000-8000-000000000001',
  'Initial prepaid wallet top-up via Razorpay gateway webhook', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
