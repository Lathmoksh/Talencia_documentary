-- Development Gig Contracts Seed
-- Gig Worker Profile
INSERT INTO gig.gig_worker_profile (
  id, user_id, headline, bio, hourly_rate_amount, currency_code,
  completed_gigs_count, average_rating, is_available_for_hire, created_at, updated_at
) VALUES (
  '50000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000004',
  'Expert UI/UX Designer & Prototyper', '10+ years designing enterprise SaaS applications and design systems.',
  2500.00, 'INR', 24, 4.92, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;

-- Gig Worker Availability Window
INSERT INTO gig.gig_worker_availability (
  id, worker_id, availability_window, is_booked, notes, created_at, updated_at
) VALUES (
  '51000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001',
  tstzrange('2026-11-15 09:00:00+00', '2026-11-20 18:00:00+00', '[)'),
  false, 'Available for rapid Figma design sprint', '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
) ON CONFLICT (id) DO NOTHING;
