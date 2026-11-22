-- Reference Seed: ISO 4217 Currencies
INSERT INTO master_data.currency (currency_code, currency_name, currency_symbol, decimal_precision, iso_numeric_code, is_active, created_at, updated_at)
VALUES 
  ('INR', 'Indian Rupee', '₹', 2, 356, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('USD', 'United States Dollar', '$', 2, 840, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('EUR', 'Euro', '€', 2, 978, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('GBP', 'British Pound Sterling', '£', 2, 826, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('SGD', 'Singapore Dollar', 'S$', 2, 702, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (currency_code) DO NOTHING;
