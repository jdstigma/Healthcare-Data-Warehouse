"""
Export dbt mart tables to CSV for Tableau Public.

Usage (from repo root in Codespaces):
  python scripts/export_marts.py

Outputs to exports/  (git-ignored).
"""

import os
import sys
from pathlib import Path

import pandas as pd
import psycopg2

EXPORT_DIR = Path("exports")

MARTS = [
    "mart_patient_demographics",
    "mart_encounter_trends",
    "mart_condition_prevalence",
    "mart_medication_utilization",
]


def get_conn():
    return psycopg2.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=int(os.getenv("PGPORT", 5432)),
        dbname=os.getenv("PGDATABASE", "healthcare"),
        user=os.getenv("PGUSER", "postgres"),
        password=os.getenv("PGPASSWORD", "postgres"),
    )


def export_mart(conn, mart: str) -> None:
    with conn.cursor() as cur:
        cur.execute(f"SELECT * FROM marts.{mart}")
        rows = cur.fetchall()
        cols = [desc[0] for desc in cur.description]
    df = pd.DataFrame(rows, columns=cols)
    out = EXPORT_DIR / f"{mart}.csv"
    df.to_csv(out, index=False)
    print(f"  {mart:<40}  {len(df):>8,} rows  →  {out}")


def main():
    EXPORT_DIR.mkdir(exist_ok=True)
    conn = get_conn()
    print(f"Exporting mart tables to {EXPORT_DIR}/\n")
    for mart in MARTS:
        export_mart(conn, mart)
    conn.close()
    print("\nDone. Upload these CSVs to Tableau Public.")


if __name__ == "__main__":
    main()
