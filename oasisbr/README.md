# BRCris - OasisBR Data Correction Process

This directory contains scripts and SQL queries to correct issues related to multiple Lattes identifiers associated with a single entity originating from the OasisBR data source in the BRCris database.

## Problem Description

Entities sourced from OasisBR sometimes incorrectly link multiple Lattes identifiers to a single person entity. This process identifies these problematic entities, corrects the semantic identifier mappings using data from the Lattes provenance, marks the affected entities for reprocessing, and flags the original problematic source entities from OasisBR as deleted.

## Prerequisites

*   Python 3.x
*   PostgreSQL database containing the BRCris data.
*   Required Python packages (install via `pip install -r requirements.txt`)

## Setup

1.  **Configure Database Connection:**
    *   If it doesn't exist, run the setup script to create a `.env` file: `bash step0_setup_env.sh`
    *   Edit the generated `.env` file with your PostgreSQL database connection details (host, port, database name, user, password).
2.  **Install Dependencies:**
    *   Ensure you are in the `oasisbr` directory.
    *   If you haven't already, run the setup script which also creates a virtual environment and installs requirements: `bash step0_setup_env.sh`
    *   Alternatively, manually create a virtual environment (`python3 -m venv venv`), activate it (`source venv/bin/activate`), and install packages (`pip install -r requirements.txt`).

## Execution Steps

Execute the Python scripts sequentially from within the activated virtual environment (`source venv/bin/activate`) in the `oasisbr` directory:

1.  **`python scripts/step1_create_indices.py`**: Creates necessary database indices for performance.
2.  **`python scripts/step2_create_aux_tables.py`**: Creates auxiliary tables to store intermediate data (provenance IDs, source entities, broken entities, Lattes semantic IDs).
3.  **`python scripts/step3_clean_aux_tables.py`**: Cleans the `aux_oasisbr_source_entities_from_oasis` table, keeping only entries with multiple Lattes identifiers.
4.  **`python scripts/step4_fix_entity_semantic_identifiers.py`**: Removes incorrect Lattes mappings from `entity_semantic_identifier` for broken entities and inserts the correct ones based on Lattes provenance data.
5.  **`python scripts/step5_mark_entities_dirty.py`**: Marks the corrected final entities as 'dirty' so they are picked up by the merge process.
6.  **`python scripts/step6_mark_source_entities_deleted.py`**: Creates a table (`aux_to_be_reloaded_oasisbr_records`) containing the `record_id`s that need reloading from OasisBR and marks the original problematic OasisBR source entities as 'deleted'.
7.  **`python scripts/step7_diagnose_multiple_lattes.py`**: Creates a diagnostic table (`aux_diagnose_multiple_lattes_entities`) to identify any remaining entities (not necessarily from OasisBR) that still have multiple Lattes identifiers after the fix. This helps in identifying other potential data issues.

## Post-Execution

1.  **Run Entity Merge Process:** After completing the steps above, it is crucial to run the main BRCris entity merge process. This process handles entities marked as 'dirty'. You can typically trigger this using a script similar to `orcid/scripts/step11_merge_entities.py` (adapt the path if necessary).
2.  **Reload OasisBR Records:** The records listed in the `aux_to_be_reloaded_oasisbr_records` table should be re-imported or reprocessed from the OasisBR source to ensure the data is fully consistent.
3.  **Review Diagnostics:** Check the contents of the `aux_diagnose_multiple_lattes_entities` table for any remaining issues that might require further investigation.

## SQL Files (`sql/` directory)

This directory contains the individual SQL scripts executed by the Python steps. They are separated for clarity and maintainability.

*   `step1_create_indices.sql`
*   `step2_create_aux_tables.sql`
*   `step3_clean_aux_tables.sql`
*   `step4_fix_entity_semantic_identifiers.sql`
*   `step5_mark_entities_dirty.sql`
*   `step6_mark_source_entities_deleted.sql`
*   `step7_diagnose_multiple_lattes.sql`
