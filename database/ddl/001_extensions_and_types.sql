-- =============================================================
-- Talentra Enterprise Workforce Platform: Extensions & Core Functions
-- Database Engine: PostgreSQL 16 Enterprise
-- =============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Pure PostgreSQL 16 time-ordered UUIDv7 generator for large tables & primary keys (B-tree locality)
CREATE OR REPLACE FUNCTION generate_uuid_v7()
RETURNS UUID AS $$
DECLARE
    unix_time_ms BIGINT;
    uuid_bytes BYTEA;
BEGIN
    unix_time_ms := FLOOR(EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) * 1000);
    uuid_bytes := SET_BYTE(
        SET_BYTE(
            gen_random_bytes(16),
            6,
            (GET_BYTE(gen_random_bytes(1), 0) & 15) | 112 -- version 7
        ),
        8,
        (GET_BYTE(gen_random_bytes(1), 0) & 63) | 128 -- variant 1
    );
    uuid_bytes := SET_BYTE(uuid_bytes, 0, ((unix_time_ms >> 40) & 255)::INT);
    uuid_bytes := SET_BYTE(uuid_bytes, 1, ((unix_time_ms >> 32) & 255)::INT);
    uuid_bytes := SET_BYTE(uuid_bytes, 2, ((unix_time_ms >> 24) & 255)::INT);
    uuid_bytes := SET_BYTE(uuid_bytes, 3, ((unix_time_ms >> 16) & 255)::INT);
    uuid_bytes := SET_BYTE(uuid_bytes, 4, ((unix_time_ms >> 8) & 255)::INT);
    uuid_bytes := SET_BYTE(uuid_bytes, 5, (unix_time_ms & 255)::INT);
    RETURN ENCODE(uuid_bytes, 'hex')::UUID;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for automatic updated_at maintenance
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to enforce immutable append-only ledgers
CREATE OR REPLACE FUNCTION enforce_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Table % is strictly append-only. UPDATE and DELETE operations are prohibited by law.', TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;
