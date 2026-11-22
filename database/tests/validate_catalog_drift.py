#!/usr/bin/env python3
"""
Talentra Enterprise Platform: Catalog Drift Validator (DDDL Step 19)
Single Source of Truth: database/schema_definition_90_tables.json
Validates that every table and column referenced in DDL, migrations, seeds,
negative tests, and benchmark queries exists in the canonical schema catalog.
"""

import os
import sys
import json
import glob
import re

CATALOG_PATH = os.path.join(os.path.dirname(__file__), '..', 'schema_definition_90_tables.json')
if not os.path.exists(CATALOG_PATH):
    CATALOG_PATH = 'database/schema_definition_90_tables.json'

with open(CATALOG_PATH, 'r', encoding='utf-8') as f:
    schema = json.load(f)

# Build canonical catalog: table_name.lower() -> set of column_names.lower()
catalog = {}
table_short_names = {}
schemas = set()
for tname, tinfo in schema.items():
    t_lower = tname.lower()
    cols = set(c['name'].lower() for c in tinfo['columns'])
    catalog[t_lower] = cols
    s, t = t_lower.split('.')
    schemas.add(s)
    table_short_names[t] = t_lower

def validate_sql_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    errors = []

    # 1. Check multi-line INSERT INTO <table> (<cols>)
    for m in re.finditer(r'INSERT\s+INTO\s+([a-zA-Z0-9_\.]+)\s*\(([^)]+)\)', content, re.IGNORECASE):
        tbl = m.group(1).lower()
        if '.' not in tbl and tbl in table_short_names:
            tbl = table_short_names[tbl]
        if tbl not in catalog:
            base_tbl = tbl.split('_part_')[0] if '_part_' in tbl else tbl
            if base_tbl in catalog:
                tbl = base_tbl
            else:
                errors.append(f"INSERT references non-existent table '{tbl}'")
                continue
        cols = [c.strip().lower() for c in m.group(2).split(',') if c.strip()]
        for c in cols:
            clean_c = c.split()[-1].strip('"\'`')
            if clean_c not in catalog[tbl]:
                errors.append(f"INSERT references non-existent column '{clean_c}' on table '{tbl}'")

    # 2. Check CREATE INDEX ON <table> (<cols>)
    for m in re.finditer(r'CREATE\s+(?:UNIQUE\s+)?INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?([a-zA-Z0-9_]+)\s+ON\s+([a-zA-Z0-9_\.]+)(?:\s+USING\s+[a-zA-Z0-9_]+)?\s*\(([^)]+)\)', content, re.IGNORECASE):
        tbl = m.group(2).lower()
        if '.' not in tbl and tbl in table_short_names:
            tbl = table_short_names[tbl]
        if tbl not in catalog:
            errors.append(f"INDEX target table '{tbl}' does not exist")
            continue
        col_exprs = m.group(3).split(',')
        for expr in col_exprs:
            clean = expr.strip().split()[0].strip('"\'`')
            if clean.isalnum() or '_' in clean:
                if clean.lower() not in catalog[tbl] and clean.lower() not in ('gist', 'btree', 'gin', 'hash', 'desc', 'asc', 'nulls', 'first', 'last'):
                    errors.append(f"INDEX references non-existent column '{clean}' on table '{tbl}'")

    # 3. Check UPDATE <table> SET <cols...> WHERE
    for m in re.finditer(r'UPDATE\s+([a-zA-Z0-9_\.]+)\s+SET\s+(.*?)\s+WHERE', content, re.IGNORECASE | re.DOTALL):
        tbl = m.group(1).lower()
        if '.' not in tbl and tbl in table_short_names:
            tbl = table_short_names[tbl]
        if tbl in catalog:
            set_clause = m.group(2)
            for assign in re.finditer(r'([a-zA-Z0-9_]+)\s*=', set_clause):
                col = assign.group(1).lower()
                if col not in catalog[tbl]:
                    errors.append(f"UPDATE references non-existent column '{col}' on table '{tbl}'")

    # 4. Check explicit alias.column references
    alias_map = {
        'cp': 'candidate.candidate_profile',
        'ja': 'application.job_application',
        'nd': 'engagement.notification_delivery',
        'jr': 'recruitment.job_requisition',
        'gc': 'gig.gig_contract',
        'a': 'organisation.account',
        'sl': 'licensing.subscription_licence',
        'sp': 'licensing.subscription_plan',
        's': 'master_data.skill',
        'c': 'master_data.city',
        'csm': 'engagement.campus_student_member',
        'bl': 'candidate.candidate_block_list'
    }
    for alias, tbl in alias_map.items():
        pattern = rf'\b{alias}\.([a-zA-Z0-9_]+)\b'
        for m in re.finditer(pattern, content):
            col = m.group(1).lower()
            if col not in catalog[tbl]:
                errors.append(f"Reference '{alias}.{col}' non-existent on table '{tbl}'")

    return list(dict.fromkeys(errors))

def main():
    print("================================================================================")
    print("      TALENTRA ENTERPRISE PLATFORM: CATALOG DRIFT VALIDATOR (DDDL STEP 19)      ")
    print("      Single Source of Truth: database/schema_definition_90_tables.json         ")
    print("================================================================================")

    target_patterns = [
        'database/ddl/*.sql',
        'database/migrations/*.sql',
        'database/seeds/**/*.sql',
        'database/tests/*.sql',
        'database/queries/*.sql'
    ]

    all_files = []
    for pat in target_patterns:
        all_files.extend(glob.glob(pat, recursive=True))

    total_drift_errors = 0
    scanned_files = 0

    for fp in sorted(set(all_files)):
        scanned_files += 1
        errs = validate_sql_file(fp)
        if errs:
            print(f"\n[DRIFT DEFECT] in {fp}:")
            for msg in errs:
                print(f"  - {msg}")
                total_drift_errors += 1

    print("\n--------------------------------------------------------------------------------")
    print(f"Scanned {scanned_files} core SQL files across DDL, seeds, tests, and queries.")
    if total_drift_errors == 0:
        print("[SUCCESS] ZERO DRIFT: All tables and columns strictly match schema catalog!")
        print("--------------------------------------------------------------------------------")
        return 0
    else:
        print(f"[FAILED] {total_drift_errors} catalog drift defects detected.")
        print("--------------------------------------------------------------------------------")
        return 1

if __name__ == '__main__':
    sys.exit(main())
