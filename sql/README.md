# SQL (Google BigQuery)

Run in order. Replace `your_project.your_dataset` with the real project and dataset. Nothing here modifies the raw `challan_master` table.

| File | What it does |
|---|---|
| [01_setup_and_checks.sql](01_setup_and_checks.sql) | Post-load checks on the uploaded tables; challan condenser view |
| [02_code_decisions.sql](02_code_decisions.sql) | Client decisions on old challan codes; extra parts; full part list view |
| [03_condenser_series.sql](03_condenser_series.sql) | One monthly condenser series (2009 – latest) and the quarterly view |
| [04_validation.sql](04_validation.sql) | One-row summary of all checks after a rebuild |

Notes for the BigQuery sandbox:

- DML (`INSERT`, `UPDATE`) is not available, so lookup tables are built with `CREATE OR REPLACE TABLE … AS SELECT * FROM UNNEST([...])`.
- Correlated subqueries that reference other tables are not supported; use a pre-aggregated CTE and a `LEFT JOIN`.
- Sandbox tables expire after 60 days unless billing is enabled.

Part codes use the anonymised `PC-` prefix. The full decision list (47 rows) is held with the client data, not in this repository.
