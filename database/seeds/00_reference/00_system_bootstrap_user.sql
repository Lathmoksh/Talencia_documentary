-- ============================================================================
-- TALENTRA ENTERPRISE PLATFORM: SYSTEM BOOTSTRAP USER & MASTER ROOTS
-- Resolves relational circular dependency by seeding platform actor & master roots.
-- ============================================================================

-- 1. Fixed Platform System Administrator User (ID: 00000000-0000-4000-8000-000000000000)
INSERT INTO identity.user_account (
    id, email, phone_country_code, phone_number, user_type, account_status,
    is_email_verified, is_phone_verified, two_factor_enabled, failed_login_attempts,
    created_at, created_by, updated_at, updated_by
) VALUES (
    '00000000-0000-4000-8000-000000000000',
    'system@talentra.io',
    '+1',
    '0000000000',
    'ADMIN',
    'ACTIVE_VERIFIED',
    true,
    true,
    false,
    0,
    CURRENT_TIMESTAMP,
    '00000000-0000-4000-8000-000000000000',
    CURRENT_TIMESTAMP,
    '00000000-0000-4000-8000-000000000000'
) ON CONFLICT (id) DO NOTHING;

-- 2. Master Currencies (ISO 4217) required by countries and plans
INSERT INTO master_data.currency (
    currency_code, currency_name, currency_symbol, decimal_precision, iso_numeric_code, is_active,
    created_at, created_by, updated_at, updated_by
) VALUES
  ('INR', 'Indian Rupee', '₹', 2, 356, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('USD', 'US Dollar', '$', 2, 840, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('EUR', 'Euro', '€', 2, 978, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('GBP', 'British Pound', '£', 2, 826, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('SGD', 'Singapore Dollar', 'S$', 2, 702, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000')
ON CONFLICT (currency_code) DO NOTHING;

-- 3. Master Languages (ISO 639-1) required by enum lookups and UI translations
INSERT INTO master_data.language (
    language_code, language_name, native_name, is_rtl, is_active,
    created_at, created_by, updated_at, updated_by
) VALUES
  ('en_US', 'English (US)', 'English', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('hi_IN', 'Hindi', 'हिन्दी', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('kn_IN', 'Kannada', 'ಕನ್ನಡ', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('ta_IN', 'Tamil', 'தமிழ்', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('te_IN', 'Telugu', 'తెలుగు', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('mr_IN', 'Marathi', 'मराठी', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000')
,
  ('en', 'English', 'English', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('hi', 'Hindi', 'हिन्दी', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('kn', 'Kannada', 'ಕನ್ನಡ', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000'),
  ('es', 'Spanish', 'Español', false, true, CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000', CURRENT_TIMESTAMP, '00000000-0000-4000-8000-000000000000')
ON CONFLICT (language_code) DO NOTHING;
