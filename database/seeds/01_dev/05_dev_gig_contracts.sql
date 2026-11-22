-- Development Gig Contracts Seed
-- Gig Worker Profile
INSERT INTO gig.gig_worker_profile (
  id, user_id, professional_title, bio_summary, hourly_rate_amount, daily_rate_amount, rate_currency_code,
  total_completed_gigs, average_rating_score, availability_status, created_at, created_by, updated_at, updated_by
) VALUES (
  '50000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000004',
  'Expert UI/UX Designer & Prototyper', '10+ years designing enterprise SaaS applications and design systems.',
  2500.00, 20000.00, 'INR', 24, 4.92, 'AVAILABLE', '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000', '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000'
) ON CONFLICT (id) DO NOTHING;

-- Gig Worker Availability Window
INSERT INTO gig.gig_worker_availability (
  id, worker_id, available_date, start_time, end_time, availability_window, is_booked, created_at, created_by, updated_at, updated_by
) VALUES (
  '51000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001',
  '2026-11-15', '09:00:00'::time, '18:00:00'::time,
  tstzrange('2026-11-15 09:00:00+00', '2026-11-20 18:00:00+00', '[)'),
  false, '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000', '2026-11-01T00:00:00Z', '00000000-0000-4000-8000-000000000000'
) ON CONFLICT (id) DO NOTHING;
