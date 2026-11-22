-- Reference Seed: Skills, Industries, Roles, Languages, Qualifications
-- Languages
INSERT INTO master_data.language (language_code, language_name, native_name, is_rtl, is_active, created_at, updated_at)
VALUES
  ('en', 'English', 'English', false, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('hi', 'Hindi', 'हिन्दी', false, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('kn', 'Kannada', 'ಕನ್ನಡ', false, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('es', 'Spanish', 'Español', false, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (language_code) DO NOTHING;

-- Industries
INSERT INTO master_data.industry (id, industry_code, industry_name, description, is_active, sort_order, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000031', 'TECH', 'Technology & Software', 'Software engineering, cloud infrastructure, AI and IT services', true, 1, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000032', 'FIN', 'Banking, Financial Services & Insurance', 'Commercial banking, investment banking, fintech, insurance', true, 2, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000033', 'HEALTH', 'Healthcare & Life Sciences', 'Hospitals, pharmaceuticals, biotechnology, medical devices', true, 3, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000034', 'RETAIL', 'Retail & E-Commerce', 'Consumer goods, digital commerce, logistics and supply chain', true, 4, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;

-- Job Roles
INSERT INTO master_data.job_role (id, industry_id, role_code, role_title, description, is_active, sort_order, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000041', '00000000-0000-4000-8000-000000000031', 'SWE_BACKEND', 'Backend Software Engineer', 'Designs, builds, and maintains server-side architecture and databases', true, 1, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000042', '00000000-0000-4000-8000-000000000031', 'SWE_FRONTEND', 'Frontend Engineer', 'Develops responsive client-side web applications and UI systems', true, 2, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000043', '00000000-0000-4000-8000-000000000031', 'DATA_ARCH', 'Data Architect / Engineer', 'Architects large scale analytical databases and streaming pipelines', true, 3, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000044', '00000000-0000-4000-8000-000000000032', 'FIN_ANALYST', 'Financial Quantitative Analyst', 'Builds quantitative models and portfolio risk evaluation systems', true, 4, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;

-- Skills
INSERT INTO master_data.skill (id, skill_code, skill_name, category, is_verified, is_active, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000051', 'POSTGRES', 'PostgreSQL 16', 'Database', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000052', 'PYTHON', 'Python 3.12+', 'Programming Language', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000053', 'REACT', 'React.js / Next.js', 'Frontend Framework', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000054', 'DOCKER', 'Docker & Kubernetes', 'DevOps / Cloud', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000055', 'FASTAPI', 'FastAPI', 'Backend Framework', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000056', 'DATA_MODEL', 'Kimball Dimensional Modeling', 'Data Architecture', true, true, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;

-- Qualifications
INSERT INTO master_data.qualification (id, qualification_code, qualification_name, qualification_level, field_of_study, is_active, sort_order, created_at, updated_at)
VALUES
  ('00000000-0000-4000-8000-000000000061', 'B_TECH', 'Bachelor of Technology', 'UNDERGRADUATE', 'Computer Science & Engineering', true, 1, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000062', 'M_TECH', 'Master of Technology', 'POSTGRADUATE', 'Data Science & Artificial Intelligence', true, 2, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'),
  ('00000000-0000-4000-8000-000000000063', 'MBA', 'Master of Business Administration', 'POSTGRADUATE', 'Human Resource Management', true, 3, '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z')
ON CONFLICT (id) DO NOTHING;
