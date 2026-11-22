#!/usr/bin/env python3
"""
Talentra Zero-Loss Validate-Transform-Load (VTL) Ingestion Pipeline (Milestone 25)
Enforces: Source Records = Loaded Records + Quarantined Records.
Zero silent data loss. Every rejected record receives a standardized rejection code.
"""

import uuid
import datetime
import json

REJECTION_TAXONOMY = {
    'ERR_INVALID_EMAIL': 'Email address does not conform to RFC 5322 syntax',
    'ERR_INVALID_PHONE': 'Phone number does not match E.164 international format',
    'ERR_SALARY_NEGATIVE': 'Salary compensation amount cannot be negative',
    'ERR_DUPLICATE_NATURAL_KEY': 'Natural identity key already exists in production domain',
    'ERR_ORPHAN_FOREIGN_KEY': 'Referenced parent foreign key does not exist in reference data'
}

class IngestionPipeline:
    def __init__(self, batch_id=None):
        self.batch_id = batch_id or str(uuid.uuid4())
        self.source_records = []
        self.loaded_records = []
        self.quarantined_records = []
        
    def land_batch(self, records):
        """Stage 1: Register manifest and land source records."""
        self.source_records = records
        print(f"Batch {self.batch_id}: Landed {len(records)} raw source records.")
        
    def validate_and_transform(self):
        """Stage 2 & 3: Validate, transform, and quarantine invalid records."""
        for rec in self.source_records:
            errors = []
            
            # Validation rule 1: Email check
            if '@' not in rec.get('email', ''):
                errors.append('ERR_INVALID_EMAIL')
                
            # Validation rule 2: Salary non-negative
            if rec.get('salary', 0) < 0:
                errors.append('ERR_SALARY_NEGATIVE')
                
            if errors:
                self.quarantined_records.append({
                    'record': rec,
                    'error_codes': errors,
                    'reasons': [REJECTION_TAXONOMY[e] for e in errors],
                    'quarantined_at': datetime.datetime.now(datetime.timezone.utc).isoformat()
                })
            else:
                self.loaded_records.append(rec)
                
    def reconcile(self):
        """Stage 4: Mathematical zero-loss reconciliation."""
        total_source = len(self.source_records)
        total_loaded = len(self.loaded_records)
        total_quarantined = len(self.quarantined_records)
        
        is_balanced = (total_source == total_loaded + total_quarantined)
        
        report = {
            'batch_id': self.batch_id,
            'source_count': total_source,
            'loaded_count': total_loaded,
            'quarantined_count': total_quarantined,
            'reconciliation_status': 'PASS' if is_balanced else 'FAIL_VARIANCE',
            'variance': total_source - (total_loaded + total_quarantined)
        }
        return report

if __name__ == '__main__':
    pipeline = IngestionPipeline()
    sample_batch = [
        {'id': '1', 'email': 'valid.user1@example.com', 'salary': 1200000},
        {'id': '2', 'email': 'broken_email_at_nowhere', 'salary': 800000},
        {'id': '3', 'email': 'valid.user2@example.com', 'salary': -50000},
        {'id': '4', 'email': 'valid.user3@example.com', 'salary': 1500000}
    ]
    pipeline.land_batch(sample_batch)
    pipeline.validate_and_transform()
    rep = pipeline.reconcile()
    print("Reconciliation Report:")
    print(json.dumps(rep, indent=2))
