# PHASE 2 DRAFT PHYSICAL SCHEMAS & ARTIFACTS

> [!CAUTION]
> **DO NOT EXECUTE AS-IS / WORK IN PROGRESS**  
> The SQL files and ER diagrams in this directory are parked preliminary drafts reserved for **Phase 2 (Logical & Physical Modeling, Steps 09 to 21)**.
> 
> They were decoupled from Phase 1 Discover to maintain strict architectural separation between business requirements and physical implementation.
> 
> **Known Pre-Model Draft Defects to be Resolved in Phase 2:**
> 1. `c_schema_design.sql`: Non-hexadecimal UUID fixture seeds (e.g., `00000000-0000-0000-0000-00000000000g`).
> 2. `d_schema_design.sql`: Syntax conflicts with aggregate row-locking (`SELECT COUNT(*) ... FOR UPDATE`).
> 3. `a_schema_design.sql`: Inappropriate truncate privileges permitted on immutable audit trail tables.
> 4. Role nomenclature drift against the canonical 12-persona dictionary defined in [`../phase1/02_actors.md`](../phase1/02_actors.md).
> 
> These files will be systematically refactored and validated during Phase 2 modeling.
