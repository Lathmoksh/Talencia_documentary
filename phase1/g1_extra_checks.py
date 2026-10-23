"""Extra G1 checks: reference integrity, substance, and governance invariants.
Run from the phase1/ folder:  python g1_extra_checks.py
Exit code 1 if any check fails.
"""
import csv, re, sys
from pathlib import Path
from urllib.parse import urlparse
from collections import defaultdict

B = Path(__file__).resolve().parent
rows = lambda f: list(csv.DictReader(open(B / f, encoding="utf-8")))
reqs, feats = rows("01_requirements.csv"), rows("03_features.csv")
nfrs, comp = rows("04_nfr_register.csv"), rows("competitor_matrix.csv")
roles, excs = rows("role_permission.csv"), rows("05_workflows/exceptions.csv")
actors_md = (B / "02_actors.md").read_text(encoding="utf-8")
wf_paths = list((B / "05_workflows").glob("WF-*.md"))
wf_ids = {re.match(r"(WF-\d\d)", p.name).group(1) for p in wf_paths}
persona_ids = {r["persona_id"] for r in roles}
req_ids = {r["REQ-id"] for r in reqs}
fails = []
def fail(check, msg): fails.append(f"[{check}] {msg}")
split = lambda s: [x.strip() for x in s.split(",") if x.strip()]

# 1 Reference integrity
for f in feats:
    for r in split(f["mapped_reqs"]):
        if r not in req_ids: fail("refs", f"{f['feature_id']} maps to unknown {r}")
for r in reqs:
    for p in split(r["actors"]):
        if p not in persona_ids: fail("refs", f"{r['REQ-id']} names unknown actor {p}")
for e in excs:
    if e["workflow_id"] not in wf_ids: fail("refs", f"{e['exception_id']} points to missing {e['workflow_id']}")
for r in roles:
    if f"`{r['role_code']}`" not in actors_md: fail("roles", f"{r['role_code']} not in 02_actors.md vocabulary")
used = {a for r in reqs for a in split(r["actors"])}
for p in sorted(persona_ids - used): fail("actors", f"{p} is named by no requirement")

# 1b Persona / Requirement mapping synchronization
csv_persona_reqs = defaultdict(set)
for r in reqs:
    for p in split(r["actors"]):
        csv_persona_reqs[p].add(r["REQ-id"])

for p in sorted(persona_ids):
    # Extract mapped requirements line from 02_actors.md
    m = re.search(rf"### {p}:.*?\* \*\*Mapped Requirements\*\*:(.*?)\n", actors_md, re.DOTALL)
    if not m:
        fail("persona-sync", f"Could not find mapped requirements for {p} in 02_actors.md")
    else:
        doc_reqs = set(re.findall(r"REQ-\d\d", m.group(1)))
        csv_reqs = csv_persona_reqs[p]
        if doc_reqs != csv_reqs:
            diff_doc = doc_reqs - csv_reqs
            diff_csv = csv_reqs - doc_reqs
            fail("persona-sync", f"{p} mismatch between CSV and 02_actors.md (in doc but not CSV: {diff_doc}, in CSV but not doc: {diff_csv})")

# 2 Permission matrix vs. stated invariants (REQ-09 audit append-only, REQ-17 ledger append-only)
for r in roles:
    a = r["system_audit"]
    if a[2] != "-" or a[3] != "-":
        fail("matrix", f"{r['persona_id']} has {a} on system_audit, but the audit trail must be append-only (REQ-09)")
    if r["wallet_billing"][3] == "D":
        fail("matrix", f"{r['persona_id']} has D on wallet_billing, but ledger entries are never deleted (REQ-17)")

# 3 Requirements must state needs, not solutions (open_question included)
SOL = r"\b(Argon2\w*|bcrypt|memory-hard|kernel|trigger|PostgreSQL|GiST|RLS|UUID\w*|surrogate|HMAC|AES\S*|WAL|partition\w*|index\w*|database level)\b"
for r in reqs:
    for col in ("statement", "open_question"):
        m = re.findall(SOL, r[col], flags=re.I)
        if m: fail("solution-leak", f"{r['REQ-id']}.{col}: {sorted(set(m))}")

# 4 NFRs need a number and a derivation that is not the design itself
for n in nfrs:
    if not re.search(r"\d", n["target_value"]): fail("nfr", f"{n['nfr_id']} target has no number")
    if re.search(r"GiST|double-entry|index depth|trigger", n["architectural_derivation"], re.I):
        fail("nfr-circular", f"{n['nfr_id']} is 'derived' from a design choice: {n['architectural_derivation'][:70]}")
    if re.search(r"\b(\w+) \1\b", n["architectural_derivation"], re.I): fail("nfr", f"{n['nfr_id']} typo (repeated word)")

# 5 Competitor sources must be deep links, not homepages
for c in comp:
    urls_str = c.get("competitor_source_urls") or ""
    if not urls_str:
        # Check individual deep links if present
        urls_str = " | ".join(c.get(f"{comp_name}_deep_link", "") for comp_name in ("linkedin", "naukri", "monster", "upwork") if c.get(f"{comp_name}_deep_link"))
    for u in [x.strip() for x in urls_str.split("|") if x.strip()]:
        if len(urlparse(u).path.strip("/")) == 0:
            fail("sources", f"'{c['capability_area']}': homepage-only URL {u}")

# 6 Feature trace_note column check
for f in feats:
    note = f.get("trace_note", "").strip()
    if not note or len(note) < 15:
        fail("trace-note", f"{f['feature_id']} is missing a descriptive trace_note explaining why it maps to {f.get('mapped_reqs')}")

# 7 Orphan EXC check: every EXC-id in exceptions.csv must be cited in workflow text
combined_wf_text = "\n".join(p.read_text(encoding="utf-8") for p in wf_paths)
for e in excs:
    eid = e["exception_id"].strip()
    if eid not in combined_wf_text:
        fail("orphan-exc", f"{eid} in exceptions.csv is not cited in any workflow markdown file")

# 8 Exception branches coverage per workflow
branches_per_wf = defaultdict(set)
for e in excs:
    branches_per_wf[e["workflow_id"]].add(e["failure_branch"])

for wfid in sorted(wf_ids):
    b = branches_per_wf[wfid]
    if "CANCEL_PATH" not in b: fail("wf-coverage", f"{wfid} is missing a CANCEL_PATH")
    if "RETRY_PATH" not in b: fail("wf-coverage", f"{wfid} is missing a RETRY_PATH")

print(f"{len(fails)} problem(s)")
for f in fails: print(" -", f)
sys.exit(1 if fails else 0)
