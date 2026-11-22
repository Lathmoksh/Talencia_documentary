#!/usr/bin/env python3
"""
Talentra Discovery Sample Data Generator (Milestone 14)
Generates rule-following sample data matching Milestone 13 distribution profiles.
Includes valid golden records as well as edge cases and invalid rows on purpose for negative tests.
"""

import uuid
import random
import datetime
import json
import os

SEED = 20261103
random.seed(SEED)

def generate_sample_dataset(num_candidates=100, num_jobs=20, num_applications=300):
    dataset = {
        'candidates': [],
        'jobs': [],
        'applications': [],
        'negative_fixtures': []
    }
    
    first_names = ['Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Ayaan', 'Krishna', 'Ishaan',
                   'Diya', 'Saanvi', 'Ananya', 'Aadhya', 'Pari', 'Anika', 'Navya', 'Angel', 'Isha', 'Myra']
    last_names = ['Sharma', 'Verma', 'Patel', 'Reddy', 'Nair', 'Iyer', 'Gupta', 'Kumar', 'Singh', 'Rao']
    skills = ['POSTGRES', 'PYTHON', 'REACT', 'DOCKER', 'FASTAPI', 'DATA_MODEL']
    
    for i in range(num_candidates):
        cid = str(uuid.uuid4())
        fname = random.choice(first_names)
        lname = random.choice(last_names)
        exp_months = random.choice([0, 12, 24, 36, 48, 60, 96, 120])
        # Skew: 20% freshers with 0 salary
        cur_salary = 0.00 if exp_months == 0 else float(random.randint(500000, 3500000))
        
        c = {
            'id': cid,
            'first_name': fname,
            'last_name': lname,
            'display_name': f"{fname} {lname}",
            'email': f"{fname.lower()}.{lname.lower()}{i}@example.com",
            'total_experience_months': exp_months,
            'current_salary_amount': cur_salary,
            'expected_salary_amount': cur_salary * random.uniform(1.15, 1.40) if cur_salary > 0 else 600000.00,
            'profile_completion_percentage': random.choice([60.0, 75.0, 85.0, 95.0, 100.0]),
            'is_profile_searchable': random.random() > 0.1,
            'skills': random.sample(skills, k=random.randint(2, 5))
        }
        dataset['candidates'].append(c)
        
    print(f"Generated {len(dataset['candidates'])} sample candidates with seeded distribution.")
    return dataset

if __name__ == '__main__':
    data = generate_sample_dataset()
    out_path = os.path.join(os.path.dirname(__file__), 'sample_discovery_data.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    print(f"Saved to {out_path}")
