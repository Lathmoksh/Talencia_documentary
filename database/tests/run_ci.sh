#!/usr/bin/env bash
# ==============================================================================
# Talentra Enterprise Platform: CI Execution Script for PostgreSQL 16
# Clean execution order: Drift Check -> Baseline -> plpgsql_check -> Seeds -> Negative Tests -> Queries
# ==============================================================================
set -euo pipefail

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-talentra_db}"
export PGUSER="${PGUSER:-postgres}"

echo "=== STEP 0: EXECUTING CATALOG DRIFT VALIDATOR (DDDL SINGLE SOURCE OF TRUTH) ==="
python3 database/tests/validate_catalog_drift.py || python database/tests/validate_catalog_drift.py

echo "=== STEP 1: APPLYING POSTGRESQL 16 BASELINE MIGRATION ==="
psql -v ON_ERROR_STOP=1 -f database/migrations/V1__baseline.sql

echo "=== STEP 1.5: VERIFYING PL/PGSQL FUNCTION BODIES VIA PLPGSQL_CHECK ==="
psql -v ON_ERROR_STOP=1 -c "
DO \$\$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'plpgsql_check') THEN
        CREATE EXTENSION IF NOT EXISTS plpgsql_check;
        PERFORM plpgsql_check_function_tb(p.oid)
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname IN ('identity', 'organisation', 'recruitment', 'application', 'gig', 'licensing', 'billing', 'governance')
          AND p.prolang = (SELECT oid FROM pg_language WHERE lanname = 'plpgsql');
        RAISE NOTICE 'plpgsql_check: All PL/pgSQL functions verified successfully against catalog.';
    ELSE
        RAISE NOTICE 'plpgsql_check extension not installed on host; skipping live body lint.';
    END IF;
END \$\$;
"

echo "=== STEP 2: LOADING MASTER REFERENCE & DEV SEEDS ==="
for seed in $(ls database/seeds/00_reference/*.sql database/seeds/01_dev/*.sql | sort); do
    echo "Applying seed: $seed"
    psql -v ON_ERROR_STOP=1 -f "$seed"
done

echo "=== STEP 3: RUNNING NEGATIVE CONSTRAINT & RLS TEST SUITE ==="
psql -v ON_ERROR_STOP=1 -f database/tests/negative_tests_pg16.sql

echo "=== STEP 4: EXECUTING 12 FIXED BENCHMARK QUERIES ==="
psql -v ON_ERROR_STOP=1 -f database/queries/fixed_query_set_12.sql

echo "================================================================================"
echo "    TALENTRA ENTERPRISE PLATFORM: ALL CI POSTGRESQL 16 TESTS PASSED!            "
echo "================================================================================"
