"""
Volumetric Capacity and Throughput Modeling Script for Talentra Platform.
Calculates storage sizing, transaction volumes, baseline throughput, and peak burst factors.
Outputs phase1/volumetric_model.csv.
"""
import csv
from pathlib import Path

def calculate_volumes():
    # --------------------------------------------------------------------------
    # INPUT WORKLOAD PARAMETERS & EXPLICIT ASSUMPTIONS
    # --------------------------------------------------------------------------
    # 1. Job Applications:
    #    Assumption: 250 enterprise corporate accounts each receiving ~20,000 applications/yr.
    annual_applications = 5_000_000
    business_days_per_year = 250
    core_hours_per_day = 8
    # Writes per application: 1 master row + 4 questionnaire answers + 1 status history + 1 audit + 1 notification
    writes_per_application = 8
    # Burst factor: 25x peak during seasonal graduate hiring drives and viral enterprise openings
    app_peak_burst_factor = 25.0

    # 2. Recruiter Sourcing & Search:
    #    Assumption: 250 enterprise accounts averaging 40 recruiter seats = 10,000 active recruiters.
    #    Each recruiter executes ~40 candidate search queries per working day.
    active_recruiters = 10_000
    searches_per_recruiter_day = 40
    search_peak_burst_factor = 10.0

    # 3. Contingent Gig Milestones & Wallet Transactions:
    #    Assumption: 40,000 active freelance project contracts averaging 5 milestones each month.
    monthly_gig_milestones = 200_000
    business_days_per_month = 22
    # Writes per milestone: debit + credit + running balance snapshot + audit event
    writes_per_milestone = 4
    # Burst factor: 15x peak during month-end invoicing and weekly payroll settlement cycles
    gig_peak_burst_factor = 15.0

    # 4. Candidate Profile Updates & Consent Mutations:
    #    Assumption: 1,000,000 registered candidates making an average of 2 profile/consent edits per month.
    registered_candidates = 1_000_000
    candidate_updates_per_month = 2
    profile_peak_burst_factor = 10.0
    writes_per_profile_update = 1

    # --------------------------------------------------------------------------
    # MATHEMATICAL COMPUTATIONS
    # --------------------------------------------------------------------------
    # Application intake
    apps_per_day = annual_applications / business_days_per_year
    apps_per_sec_avg = apps_per_day / (core_hours_per_day * 3600)
    apps_per_sec_peak = apps_per_sec_avg * app_peak_burst_factor
    app_write_tps_peak = apps_per_sec_peak * writes_per_application

    # Sourcing queries
    searches_per_day = active_recruiters * searches_per_recruiter_day
    searches_per_sec_avg = searches_per_day / (core_hours_per_day * 3600)
    searches_per_sec_peak = searches_per_sec_avg * search_peak_burst_factor

    # Gig milestones
    milestones_per_day = monthly_gig_milestones / business_days_per_month
    milestones_per_sec_avg = milestones_per_day / (core_hours_per_day * 3600)
    milestones_per_sec_peak = milestones_per_sec_avg * gig_peak_burst_factor
    gig_write_tps_peak = milestones_per_sec_peak * writes_per_milestone

    # Profile updates (dynamically computed from candidate pool)
    total_monthly_profile_updates = registered_candidates * candidate_updates_per_month
    profile_updates_per_day = total_monthly_profile_updates / business_days_per_month
    profile_updates_per_sec_avg = profile_updates_per_day / (core_hours_per_day * 3600)
    profile_updates_per_sec_peak = profile_updates_per_sec_avg * profile_peak_burst_factor
    profile_write_tps_peak = profile_updates_per_sec_peak * writes_per_profile_update

    # Totals
    total_peak_write_tps = app_write_tps_peak + gig_write_tps_peak + profile_write_tps_peak
    safety_headroom_multiplier = 1.5
    designed_write_tps_capacity = total_peak_write_tps * safety_headroom_multiplier

    rows = [
        ["metric_domain", "baseline_daily_volume", "baseline_rate_per_sec", "peak_burst_multiplier", "peak_rate_per_sec", "derived_peak_write_tps", "input_justification_and_assumptions"],
        [
            "Job Applications & Screenings",
            f"{apps_per_day:,.0f} apps/day",
            f"{apps_per_sec_avg:.2f} apps/s",
            f"{app_peak_burst_factor:.0f}x",
            f"{apps_per_sec_peak:.2f} apps/s",
            f"{app_write_tps_peak:.1f} TPS",
            "5M annual apps / 250 days; 8 writes per app (1 master + 4 screening answers + 1 history + 1 audit + 1 notification); 25x peak during seasonal campus hiring bursts."
        ],
        [
            "Candidate Sourcing & Search",
            f"{searches_per_day:,.0f} queries/day",
            f"{searches_per_sec_avg:.2f} qps",
            f"{search_peak_burst_factor:.0f}x",
            f"{searches_per_sec_peak:.2f} qps",
            "Read-only (N/A)",
            "10,000 recruiters (250 corporate accounts x 40 seats) performing 40 queries/day; 10x burst factor yields 139 searches/sec peak query load."
        ],
        [
            "Gig Milestones & Wallet Payouts",
            f"{milestones_per_day:,.0f} tx/day",
            f"{milestones_per_sec_avg:.2f} tx/s",
            f"{gig_peak_burst_factor:.0f}x",
            f"{milestones_per_sec_peak:.2f} tx/s",
            f"{gig_write_tps_peak:.1f} TPS",
            "200k milestones/month / 22 days; 4 writes per milestone (debit + credit + snapshot + audit); 15x peak during month-end payroll settlement."
        ],
        [
            "Profile Updates & Consent Mutations",
            f"{profile_updates_per_day:,.0f} updates/day",
            f"{profile_updates_per_sec_avg:.2f} updates/s",
            f"{profile_peak_burst_factor:.0f}x",
            f"{profile_updates_per_sec_peak:.2f} updates/s",
            f"{profile_write_tps_peak:.1f} TPS",
            "Computed from 1M registered candidates making 2 updates/month (90,909 updates/day); 1 write/update; 10x burst factor yields 31.6 TPS peak."
        ],
        [
            "TOTAL WRITE WORKLOAD",
            "-",
            "-",
            "-",
            f"{total_peak_write_tps:.1f} TPS peak write load",
            f"{designed_write_tps_capacity:.0f} TPS capacity target (with 1.5x headroom)",
            f"Sum of application writes ({app_write_tps_peak:.1f}) + gig ledger writes ({gig_write_tps_peak:.1f}) + profile writes ({profile_write_tps_peak:.1f}) = {total_peak_write_tps:.1f} TPS x 1.5 headroom = {designed_write_tps_capacity:.0f} TPS."
        ]
    ]

    out_file = Path(__file__).resolve().parent / "volumetric_model.csv"
    with open(out_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerows(rows)
    print(f"Generated {out_file}: Peak write load = {total_peak_write_tps:.1f} TPS, Designed capacity target = {designed_write_tps_capacity:.0f} TPS, Peak search queries = {searches_per_sec_peak:.1f} QPS")

if __name__ == "__main__":
    calculate_volumes()
