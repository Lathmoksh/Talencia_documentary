#!/usr/bin/env python3
"""
Talentra Database Seeding CLI Orchestrator
Applies environment-segregated seed fixtures (reference, dev, test, demo).
"""

import os
import sys
import glob

def get_seed_files(target_env='all'):
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    files = []
    
    # Always include reference
    files.extend(sorted(glob.glob(os.path.join(base_dir, '00_reference', '*.sql'))))
    
    if target_env in ('dev', 'all'):
        files.extend(sorted(glob.glob(os.path.join(base_dir, '01_dev', '*.sql'))))
    if target_env in ('test', 'all'):
        files.extend(sorted(glob.glob(os.path.join(base_dir, '02_test', '*.sql'))))
    if target_env in ('demo', 'all'):
        files.extend(sorted(glob.glob(os.path.join(base_dir, '03_demo', '*.sql'))))
        
    return files

def main():
    target = sys.argv[1] if len(sys.argv) > 1 else 'all'
    print(f"=== Talentra Seed Runner: Target [{target.upper()}] ===")
    seed_files = get_seed_files(target)
    print(f"Found {len(seed_files)} seed files to apply in deterministic order:")
    for f in seed_files:
        print(f"  -> {os.path.relpath(f, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))}")
    print("\nUse run_talentra_suite.py to apply these against your active database.")

if __name__ == '__main__':
    main()
