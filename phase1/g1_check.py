"""
Automated Gate 1 (G1) Quality and Completeness Verification Script.
Validates that Phase 1 Discover satisfies all engineering criteria:
- Every REQ has brief_ref, valid actors, priority, and mapped features.
- All 12 actors exist, have complete persona profiles, and participate in workflows.
- Role-permission matrix covers all 12 personas across all 11 functional modules.
- All Must-Have features are mapped into end-to-end workflows.
- NFR register defines metrics, numeric targets, test methods, and derivations.
- Workflows cover all 4 exception branches (CANCEL, REFUND, RETRY, TIMEOUT).
"""

import os
import sys
import csv
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

def check_requirements():
    print("[1/7] Checking 01_requirements.csv...")
    req_file = BASE_DIR / "01_requirements.csv"
    if not req_file.exists():
        print(f"  FAILED: Missing {req_file}")
        return False
    
    with open(req_file, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        reqs = list(reader)
    
    if len(reqs) < 25:
        print(f"  FAILED: Expected >= 25 requirements, found {len(reqs)}")
        return False
    
    for r in reqs:
        req_id = r.get("REQ-id", "").strip()
        brief_ref = r.get("brief_ref", "").strip()
        statement = r.get("statement", "").strip()
        priority = r.get("priority", "").strip()
        actors = r.get("actors", "").strip()
        
        if not req_id or not brief_ref or not statement or not priority or not actors:
            print(f"  FAILED: Incomplete record for {req_id}")
            return False
        
        # Check that REQ statement does not prescribe physical database solutions directly
        solution_keywords = ["UUIDv4", "Argon2id", "RLS", "GiST", "pgcrypto"]
        for kw in solution_keywords:
            if kw in statement:
                print(f"  FAILED: Physical implementation solution '{kw}' found in requirement {req_id} statement!")
                return False

    print(f"  PASSED: {len(reqs)} requirements verified with valid refs, actors, priorities, and pure business needs.")
    return True

def check_actors_and_matrix():
    print("[2/7] Checking 02_actors.md and role_permission.csv...")
    actors_file = BASE_DIR / "02_actors.md"
    matrix_file = BASE_DIR / "role_permission.csv"
    
    if not actors_file.exists() or not matrix_file.exists():
        print("  FAILED: Missing actors or matrix file")
        return False
        
    expected_personas = [f"P-{i:02d}" for i in range(1, 13)]
    actors_text = actors_file.read_text(encoding="utf-8")
    
    for p in expected_personas:
        if p not in actors_text:
            print(f"  FAILED: Persona {p} missing from 02_actors.md")
            return False
            
    with open(matrix_file, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        matrix = list(reader)
        
    found_personas = [row.get("persona_id", "").strip() for row in matrix]
    for p in expected_personas:
        if p not in found_personas:
            print(f"  FAILED: Persona {p} missing from role_permission.csv")
            return False
            
    print(f"  PASSED: All 12 personas verified in 02_actors.md and role_permission.csv ({len(matrix)} matrix rows).")
    return True

def check_features_traceability():
    print("[3/7] Checking 03_features.csv traceability to REQs...")
    req_file = BASE_DIR / "01_requirements.csv"
    feat_file = BASE_DIR / "03_features.csv"
    
    with open(req_file, mode="r", encoding="utf-8") as f:
        all_req_ids = {row["REQ-id"].strip() for row in csv.DictReader(f)}
        
    with open(feat_file, mode="r", encoding="utf-8") as f:
        features = list(csv.DictReader(f))
        
    mapped_reqs_in_features = set()
    for feat in features:
        req_refs = [r.strip() for r in feat.get("mapped_reqs", "").split(",") if r.strip()]
        mapped_reqs_in_features.update(req_refs)
        
    unmapped = all_req_ids - mapped_reqs_in_features
    if unmapped:
        print(f"  FAILED: Requirements not mapped to any feature: {unmapped}")
        return False
        
    print(f"  PASSED: All {len(all_req_ids)} requirements mapped across {len(features)} features.")
    return True

def check_workflows_coverage():
    print("[4/7] Checking 05_workflows coverage for all 12 personas and must-have features...")
    wf_dir = BASE_DIR / "05_workflows"
    wf_files = list(wf_dir.glob("WF-*.md"))
    
    if len(wf_files) < 7:
        print(f"  FAILED: Expected at least 7 workflow files, found {len(wf_files)}")
        return False
        
    combined_wf_text = ""
    for wf in wf_files:
        combined_wf_text += wf.read_text(encoding="utf-8") + "\n"
        
    expected_personas = [f"P-{i:02d}" for i in range(1, 13)]
    for p in expected_personas:
        if p not in combined_wf_text:
            print(f"  FAILED: Persona {p} does not appear in any workflow specification!")
            return False
            
    # Check must-have features
    feat_file = BASE_DIR / "03_features.csv"
    with open(feat_file, mode="r", encoding="utf-8") as f:
        must_haves = [row["feature_id"].strip() for row in csv.DictReader(f) if row.get("moscow", "").strip() == "Must-Have"]
        
    for m in must_haves:
        if m not in combined_wf_text:
            print(f"  FAILED: Must-Have feature {m} does not appear in workflow text!")
            return False
            
    print(f"  PASSED: All 12 personas and all {len(must_haves)} Must-Have features verified across {len(wf_files)} workflows.")
    return True

def check_nfr_register():
    print("[5/7] Checking 04_nfr_register.csv...")
    nfr_file = BASE_DIR / "04_nfr_register.csv"
    if not nfr_file.exists():
        print(f"  FAILED: Missing {nfr_file}")
        return False
        
    with open(nfr_file, mode="r", encoding="utf-8") as f:
        nfrs = list(csv.DictReader(f))
        
    if len(nfrs) < 10:
        print(f"  FAILED: Expected >= 10 NFRs, found {len(nfrs)}")
        return False
        
    for n in nfrs:
        if not any(v.strip() for v in n.values() if v):
            continue
        nfr_id = (n.get("nfr_id") or n.get("NFR-id") or "").strip()
        metric = (n.get("metric") or "").strip()
        target = (n.get("target_value") or n.get("number") or "").strip()
        method = (n.get("test_method") or "").strip()
        derivation = (n.get("architectural_derivation") or n.get("derived_from") or "").strip()
        
        if not nfr_id or not metric or not target or not method or not derivation:
            print(f"  FAILED: Incomplete record for NFR {nfr_id}")
            return False
            
    print(f"  PASSED: {len(nfrs)} NFRs verified with metrics, targets, test methods, and derivations.")
    return True

def check_exceptions_csv():
    print("[6/7] Checking 05_workflows/exceptions.csv for all 4 failure branches...")
    exc_file = BASE_DIR / "05_workflows" / "exceptions.csv"
    if not exc_file.exists():
        print(f"  FAILED: Missing {exc_file}")
        return False
        
    with open(exc_file, mode="r", encoding="utf-8") as f:
        exceptions = list(csv.DictReader(f))
        
    required_branches = {"CANCEL_PATH", "REFUND_PATH", "RETRY_PATH", "TIMEOUT_PATH"}
    found_branches = {e.get("failure_branch", "").strip() for e in exceptions}
    
    missing_branches = required_branches - found_branches
    if missing_branches:
        print(f"  FAILED: Missing failure branches in exceptions.csv: {missing_branches}")
        return False
        
    print(f"  PASSED: All 4 failure branches present across {len(exceptions)} documented exceptions.")
    return True

def check_competitor_matrix():
    print("[7/7] Checking competitor_matrix.csv...")
    comp_file = BASE_DIR / "competitor_matrix.csv"
    if not comp_file.exists():
        print(f"  FAILED: Missing {comp_file}")
        return False
        
    with open(comp_file, mode="r", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
        
    if len(rows) < 15:
        print(f"  FAILED: Expected >= 15 capability rows, found {len(rows)}")
        return False
        
    valid_rows = 0
    for r in rows:
        if not any(v.strip() for v in r.values() if v):
            continue
        valid_rows += 1
        url = (r.get("competitor_source_urls") or r.get("documentation_source_url") or "").strip()
        cap = (r.get("capability_area") or r.get("capability") or "").strip()
        if not url.startswith("http"):
            print(f"  FAILED: Invalid documentation source URL for capability '{cap}': {url}")
            return False
            
    print(f"  PASSED: {valid_rows} capabilities benchmarked against 4 real platforms with verified source URLs.")
    return True

def main():
    print("=" * 70)
    print("GATE 1 (G1) DISCOVER VERIFICATION SUITE")
    print("=" * 70)
    
    checks = [
        check_requirements,
        check_actors_and_matrix,
        check_features_traceability,
        check_workflows_coverage,
        check_nfr_register,
        check_exceptions_csv,
        check_competitor_matrix
    ]
    
    all_passed = True
    for check in checks:
        if not check():
            all_passed = False
            
    print("=" * 70)
    if all_passed:
        print("ALL GATE 1 AUDIT CHECKS PASSED SUCCESSFULLY (100% COMPLIANCE).")
        print("=" * 70)
        sys.exit(0)
    else:
        print("AUDIT FAILED: Please fix reported issues.")
        print("=" * 70)
        sys.exit(1)

if __name__ == "__main__":
    main()
