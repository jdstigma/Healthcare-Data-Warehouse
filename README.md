# Healthcare Data Warehouse

PostgreSQL data warehouse built on [Synthea](https://github.com/synthetichealth/synthea) synthetic patient data, developed in GitHub Codespaces and visualized in Tableau Public.

## Stack

| Layer | Tool |
|---|---|
| Data generation | Synthea (synthetic EHR) |
| Database | PostgreSQL 15 (`synthea` schema) |
| Dev environment | GitHub Codespaces + devcontainer |
| Visualization | Tableau Public |

## Schema — 18 tables

| Domain | Tables |
|---|---|
| Reference | `organizations`, `providers`, `payers` |
| Patient | `patients`, `payer_transitions` |
| Clinical | `encounters`, `conditions`, `medications`, `procedures`, `observations`, `immunizations`, `allergies`, `careplans`, `devices`, `imaging_studies`, `supplies` |
| Financial | `claims`, `claims_transactions` |

## Getting started (Codespaces)

1. Open this repo in GitHub Codespaces — PostgreSQL and Python are installed automatically.
2. Download sample data:

```bash
# 1 000-patient sample (fast)
python scripts/download_synthea.py --size small

# 10 000-patient sample (recommended for dashboards)
python scripts/download_synthea.py --size large
```

3. Load into PostgreSQL:

```bash
python scripts/load_data.py
```

4. Connect your SQL client (SQLTools is pre-configured) or use `psql`:

```bash
psql -U postgres -d healthcare -c "SELECT COUNT(*) FROM synthea.patients;"
```

## Analysis queries

Starter queries live in `sql/analysis/`:

- `01_patient_demographics.sql` — age bands, gender, race, ethnicity
- `02_encounter_volume.sql` — volume, cost, and payer coverage over time
- `03_top_conditions.sql` — prevalence and encounter cost by condition
- `04_medication_utilization.sql` — top drugs, cost, and payer coverage %

## Connecting Tableau Public

1. Export a view to CSV from psql or copy query results.
2. In Tableau Public → **Connect → Text file** → select the CSV.
3. For a live connection, use **PostgreSQL** connector (requires Tableau Desktop; Tableau Public supports extract only).
