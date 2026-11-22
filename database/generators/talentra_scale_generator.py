#!/usr/bin/env python3
"""
Talentra Scale Synthetic Data Generator (Milestone 23)
Streaming generator supporting Launch (100k), Year 1 (1M), and Year 3 (10M) volume targets.
Produces high-performance CSV streams for PostgreSQL COPY operations.
"""

import csv
import uuid
import random
import datetime
import sys
import os

SEED = 20261103
random.seed(SEED)

def generate_candidate_csv(output_file, count=1000):
    print(f"Generating {count} candidate records into {output_file}...")
    headers = [
        'id', 'user_id', 'first_name', 'last_name', 'display_name',
        'date_of_birth', 'gender', 'headline', 'summary', 'current_city_id',
        'total_experience_months', 'current_salary_amount', 'expected_salary_amount',
        'salary_currency_code', 'notice_period_days', 'profile_completion_percentage',
        'is_profile_searchable', 'created_at', 'updated_at'
    ]
    
    first_names = ['Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Ayaan', 'Krishna', 'Ishaan',
                   'Diya', 'Saanvi', 'Ananya', 'Aadhya', 'Pari', 'Anika', 'Navya', 'Angel', 'Isha', 'Myra']
    last_names = ['Sharma', 'Verma', 'Patel', 'Reddy', 'Nair', 'Iyer', 'Gupta', 'Kumar', 'Singh', 'Rao']
    
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        
        for i in range(count):
            cid = str(uuid.uuid4())
            uid = str(uuid.uuid4())
            fname = random.choice(first_names)
            lname = random.choice(last_names)
            exp = random.choice([0, 12, 24, 36, 60, 84, 120])
            sal = 0.00 if exp == 0 else round(random.uniform(400000, 3000000), 2)
            exp_sal = round(sal * random.uniform(1.2, 1.4), 2) if sal > 0 else 500000.00
            
            row = [
                cid, uid, fname, lname, f"{fname} {lname}",
                '1995-06-15', 'OTHER', 'Software Professional', 'Generated scale candidate',
                '00000000-0000-4000-8000-000000000021',
                exp, sal, exp_sal, 'INR', 30, 85.0, True,
                '2026-11-01T00:00:00Z', '2026-11-01T00:00:00Z'
            ]
            writer.writerow(row)
            
    print(f"Completed streaming {count} rows.")

if __name__ == '__main__':
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 500
    out = os.path.join(os.path.dirname(__file__), 'scale_candidates_sample.csv')
    generate_candidate_csv(out, count)
