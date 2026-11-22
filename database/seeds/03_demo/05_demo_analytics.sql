-- Pre-Calculated Kimball Star Schema Analytics Marts
-- dim_date
INSERT INTO analytics.dim_date (
  date_key, calendar_date, year_number, quarter_number, month_number, month_name,
  day_of_month, day_of_week_number, day_of_week_name, is_weekend, is_holiday
) VALUES
  (20261101, '2026-11-01', 2026, 4, 11, 'November', 1, 7, 'Sunday', true, false),
  (20261102, '2026-11-02', 2026, 4, 11, 'November', 2, 1, 'Monday', false, false),
  (20261103, '2026-11-03', 2026, 4, 11, 'November', 3, 2, 'Tuesday', false, false)
ON CONFLICT (date_key) DO NOTHING;

-- dim_pipeline_stage
INSERT INTO analytics.dim_pipeline_stage (
  stage_key, stage_code, stage_name, stage_order, is_terminal
) VALUES
  (1, 'DRAFT', 'Draft Application', 1, false),
  (2, 'SUBMITTED', 'Submitted', 2, false),
  (3, 'SCREENING_PASSED', 'Screening Passed', 3, false),
  (4, 'TECHNICAL_ASSESSMENT', 'Technical Assessment', 4, false),
  (5, 'INTERVIEW_SCHEDULED', 'Interview Scheduled', 5, false),
  (6, 'OFFER_EXTENDED', 'Offer Extended', 6, false),
  (7, 'OFFER_ACCEPTED', 'Offer Accepted / Hired', 7, true),
  (8, 'REJECTED', 'Rejected', 8, true)
ON CONFLICT (stage_key) DO NOTHING;
