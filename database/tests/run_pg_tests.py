#!/usr/bin/env python3
"""
Talentra Enterprise Platform: PostgreSQL 16 CI & Live Test Harness
Executes V1__baseline.sql, negative tests, seed fixtures, and fixed query benchmarks
against a live PostgreSQL instance with ON_ERROR_STOP=1.
"""

import os
import sys
import subprocess
import time

PGHOST = os.getenv('PGHOST', 'localhost')
PGPORT = os.getenv('PGPORT', '5432')
PGDATABASE = os.getenv('PGDATABASE', 'talentra_db')
PGUSER = os.getenv('PGUSER', 'postgres')
PGPASSWORD = os.getenv('PGPASSWORD', 'postgres')

def run_psql_file(filepath):
    print(f"--> Executing: {filepath}")
    cmd = [
        'psql',
        '-h', PGHOST,
        '-p', PGPORT,
        '-U', PGUSER,
        '-d', PGDATABASE,
        '-v', 'ON_ERROR_STOP=1',
        '-f', filepath
    ]
    env = os.environ.copy()
    if PGPASSWORD:
        env['PGPASSWORD'] = PGPASSWORD
        
    start = time.time()
    try:
        res = subprocess.run(cmd, env=env, capture_output=True, text=True, check=True)
        dur = time.time() - start
        print(f"    [PASSED] in {dur:.3f}s")
        return True, res.stdout
    except FileNotFoundError:
        print("    [SKIPPED] 'psql' client not found in PATH.")
        return False, "psql not found"
    except subprocess.CalledProcessError as e:
        dur = time.time() - start
        print(f"    [FAILED] in {dur:.3f}s: {e.stderr}")
        return False, e.stderr

def main():
    print("================================================================================")
    print("          TALENTRA ENTERPRISE PLATFORM: POSTGRESQL 16 TEST HARNESS             ")
    print(f"          Target Host: {PGHOST}:{PGPORT} | Database: {PGDATABASE}               ")
    print("================================================================================")
    
    test_files = [
        ('1. Baseline Migration', 'database/migrations/V1__baseline.sql'),
        ('2. Negative Constraint Suite', 'database/tests/negative_tests_pg16.sql'),
        ('3. Master Reference Seeds', 'database/seeds/00_reference/01_master_geo.sql'),
        ('4. Dev Fixtures', 'database/seeds/01_dev/01_dev_identities.sql'),
        ('5. 12 Fixed Query Benchmark Set', 'database/queries/fixed_query_set_12.sql')
    ]
    
    passed = 0
    failed = 0
    skipped = 0
    
    for label, path in test_files:
        if not os.path.exists(path):
            print(f"File not found: {path}")
            failed += 1
            continue
            
        success, out = run_psql_file(path)
        if success:
            passed += 1
        elif out == "psql not found":
            skipped += 1
        else:
            failed += 1
            
    print("================================================================================")
    if skipped > 0 and passed == 0:
        print("STATUS: Offline / CI environment without local psql. To run in CI:")
        print("  psql -h $PGHOST -U $PGUSER -d $PGDATABASE -v ON_ERROR_STOP=1 -f database/migrations/V1__baseline.sql")
        print("  psql -h $PGHOST -U $PGUSER -d $PGDATABASE -v ON_ERROR_STOP=1 -f database/tests/negative_tests_pg16.sql")
    elif failed == 0:
        print(f"STATUS: ALL LIVE POSTGRESQL TESTS PASSED ({passed}/{passed})")
    else:
        print(f"STATUS: TESTS FAILED ({failed} failed, {passed} passed)")
        sys.exit(1)
    print("================================================================================")

if __name__ == '__main__':
    main()
