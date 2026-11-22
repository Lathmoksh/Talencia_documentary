#!/usr/bin/env bash
# ==============================================================================
# Talentra Enterprise Platform: CI Execution Script for PostgreSQL 16
# Runs full baseline migration, negative tests, and query verification.
# ==============================================================================
set -euo pipefail

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-talentra_db}"
export PGUSER="${PGUSER:-postgres}"

echo "=== STEP 1: APPLYING POSTGRESQL 16 BASELINE MIGRATION ==="
psql -v ON_ERROR_STOP=1 -f database/migrations/V1__baseline.sql

echo "=== STEP 2: RUNNING NEGATIVE CONSTRAINT & RLS TEST SUITE ==="
psql -v ON_ERROR_STOP=1 -f database/tests/negative_tests_pg16.sql

echo "=== STEP 3: LOADING MASTER REFERENCE SEEDS ==="
for seed in database/seeds/00_reference/*.sql; do
    echo "Applying reference seed: $seed"
    psql -v ON_ERROR_STOP=1 -f "$seed"
done

echo "=== STEP 4: EXECUTING 12 FIXED BENCHMARK QUERIES ==="
psql -v ON_ERROR_STOP=1 -f database/queries/fixed_query_set_12.sql

echo "================================================================================"
echo "    TALENTRA ENTERPRISE PLATFORM: ALL CI POSTGRESQL 16 TESTS PASSED!            "
echo "================================================================================"
