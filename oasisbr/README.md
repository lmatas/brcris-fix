# BRCris - OasisBR Data Correction Process

This directory contains scripts and SQL queries to correct issues related to multiple Lattes identifiers associated with a single entity originating from the OasisBR data source in the BRCris database.

## Problem Description

Entities sourced from OasisBR sometimes incorrectly link multiple Lattes identifiers to a single person entity. This process identifies these problematic entities, corrects the semantic identifier mappings using data from the Lattes provenance, marks the affected entities for reprocessing, and flags the original problematic source entities from OasisBR as deleted.

## Prerequisites

*   Python 3.x
*   `pip` (Python package manager)
*   Access to the PostgreSQL database where BRCris data is stored.
*   Required Python packages (see Setup).

## Setup

1.  **Clone Repository:** If you haven't already, clone the repository containing this project.
2.  **Navigate to Directory:** Change into the `oasisbr` directory:
    ```bash
    cd path/to/brcris-fix/oasisbr
    ```
3.  **Configure Database Connection:**
    *   Run the setup script. It will create a `.env` file from `.env.example` if it doesn't exist and set up a Python virtual environment.
        ```bash
        bash step0_setup_env.sh
        ```
    *   **Edit the `.env` file** with your PostgreSQL database connection details (host, port, database name, user, password).
4.  **Activate Virtual Environment:**
    ```bash
    source venv/bin/activate
    ```
    *(The `step0_setup_env.sh` script already does this and installs requirements)*

## Execution Steps

Execute the Python scripts sequentially from within the activated virtual environment (`source venv/bin/activate`) in the `oasisbr` directory. Each script corresponds to a step in the correction process and executes an associated SQL file from the `sql/` directory.

**Navigate to the scripts directory:**
```bash
cd scripts
```

**Run the steps:**

1.  **`python step1_create_indices.py`**: Creates necessary database indices for performance.
2.  **`python step2_create_aux_tables.py`**: Creates auxiliary tables to store intermediate data (provenance IDs, source entities, broken entities, Lattes semantic IDs).
3.  **`python step3_clean_aux_tables.py`**: Cleans the `aux_oasisbr_source_entities_from_oasis` table, keeping only entries with multiple Lattes identifiers.
4.  **`python step4_fix_entity_semantic_identifiers.py`**: Removes incorrect Lattes mappings from `entity_semantic_identifier` for broken entities and inserts the correct ones based on Lattes provenance data.
5.  **`python step5_mark_entities_dirty.py`**: Marks the corrected final entities as 'dirty' so they are picked up by the merge process.
6.  **`python step6_mark_source_entities_deleted.py`**: Creates a table (`aux_to_be_reloaded_oasisbr_records`) containing the `record_id`s that need reloading from OasisBR and marks the original problematic OasisBR source entities as 'deleted'.
7.  **`python step7_diagnose_multiple_lattes.py`**: Creates a diagnostic table (`aux_diagnose_multiple_lattes_entities`) to identify any remaining entities (not necessarily from OasisBR) that still have multiple Lattes identifiers after the fix. This helps in identifying other potential data issues.

**(Return to the `oasisbr` directory if needed: `cd ..`)**

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

## Project Structure
