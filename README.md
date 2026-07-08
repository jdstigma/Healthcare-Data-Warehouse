# Healthcare Data Warehouse

PostgreSQL data warehouse built on [Synthea](https://github.com/synthetichealth/synthea) synthetic patient data, developed in GitHub Codespaces and visualized in Tableau Public.

## Stack

| Layer | Tool |
|---|---|
| Data generation | Synthea (synthetic EHR) |
| Database | PostgreSQL 15 (`synthea` schema) |
| Dev environment | GitHub Codespaces + devcontainer |
| Visualization | Tableau Public, Power BI |

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

## Connecting Power BI

Postgres only runs inside the Codespace container, so Power BI Desktop (on your
local machine) can't reach it directly — same constraint as Tableau Public.
The pipeline is CSV export, refreshed via a notebook. There's no automatic
refresh path here: Power BI Desktop has no built-in scheduler, and scheduled
refresh from the cloud requires publishing to Power BI Service, which needs a
Pro/PPU license or workspace access. Without that, every refresh is a manual
"run the pipeline, then click Refresh" cycle — this setup just keeps that
cycle to as few steps as possible:

1. In the Codespace: `python scripts/run_pipeline.py` (add `--size large`
   for the 10k-patient sample, or `--skip-data` to skip the download/load
   and just rebuild marts + notebook from what's already loaded).
   This downloads Synthea data, loads it, runs `dbt run` + `dbt test`
   (rebuilding all marts, including the two anomaly marts below), then
   executes `notebooks/anomaly_detection.ipynb` via papermill — which
   charts the flagged anomalies and writes CSVs to `exports/`. The
   executed notebook (with output charts) is saved to
   `notebooks/executed/`.
2. Download the CSVs from `exports/` in the Codespace, and save them into
   this repo's local `exports/` folder — e.g.
   `C:\Users\<you>\OneDrive\Desktop\Projects\Healthcare-Data-Warehouse\exports\`.
   (This folder is git-ignored, so it won't get committed.)
3. In Power BI Desktop: **Get Data → Text/CSV** → browse to that local
   `exports/` path → select each mart CSV → Load — once, the first time.
4. To refresh after new data: repeat steps 1–2, then open the `.pbix` in
   Power BI Desktop and hit **Refresh** (Home ribbon). Because the data
   source is already wired to the `exports/` path, Refresh just re-reads
   whatever CSVs are currently there — no need to redo Get Data.

You can also open `notebooks/anomaly_detection.ipynb` directly in Jupyter for
interactive exploration instead of running the full pipeline script.

### Anomaly detection

Two marts are built specifically for anomaly hunting:

- `mart_encounter_cost_anomalies` — every encounter compared against its
  peer group (same `encounter_class` + `encounter_type`) via z-score.
  `is_cost_anomaly` flags encounters ≥3 standard deviations from the peer
  mean (peer groups under 10 encounters are excluded). Use this as a
  drill-down table filtered to `is_cost_anomaly = true`.
- `mart_monthly_encounter_anomalies` — monthly encounter volume per
  `encounter_class`, compared against a trailing 6-month rolling average.
  `is_volume_anomaly` flags months ≥2 standard deviations from the rolling
  mean.

`notebooks/anomaly_detection.ipynb` visualizes both (scatter of cost z-scores,
monthly volume charts with flagged points) before exporting. For a second,
independent check in Power BI itself, plot `encounter_count` over
`encounter_month` in a line chart and add the built-in **Anomaly Detection**
(right-click the line → Analytics pane).
