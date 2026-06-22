"""
Load Synthea CSV files into PostgreSQL (synthea schema).

Assumes:
  - PostgreSQL is running and the schema has been created (post-create.sh)
  - CSV files are in data/raw/
  - Env vars PGUSER, PGPASSWORD, PGDATABASE, PGHOST, PGPORT are set
    (defaults match the devcontainer settings)

Usage:
  python scripts/load_data.py
  python scripts/load_data.py --table patients  # load a single table
"""

import argparse
import os
import sys
from pathlib import Path

import pandas as pd
import psycopg2
from psycopg2 import sql
from io import StringIO
from tqdm import tqdm

DATA_DIR = Path("data/raw")

# Ordered so FK dependencies are satisfied
LOAD_ORDER = [
    "organizations",
    "providers",
    "payers",
    "patients",
    "encounters",
    "conditions",
    "medications",
    "procedures",
    "observations",
    "immunizations",
    "allergies",
    "careplans",
    "devices",
    "imaging_studies",
    "payer_transitions",
    "claims",
    "claims_transactions",
    "supplies",
]

# Map CSV column names → DB column names where they differ
COLUMN_RENAMES = {
    "encounters": {"START": "start_time", "STOP": "stop_time"},
    "medications": {"START": "start_time", "STOP": "stop_time"},
    "procedures": {"START": "start_time", "STOP": "stop_time"},
    "devices":    {"START": "start_time", "STOP": "stop_time"},
    "observations": {"DATE": "date_time"},
    "immunizations": {"DATE": "date_time"},
    "imaging_studies": {"DATE": "date_time"},
    "supplies": {"DATE": "date_time"},
    "conditions": {"START": "start_time", "STOP": "stop_time"},
    "allergies":  {"START": "start_time", "STOP": "stop_time"},
    "careplans":  {"START": "start_time", "STOP": "stop_time"},
    "payer_transitions": {"START_YEAR": "start_year", "END_YEAR": "end_year"},
    "claims": {"Id": "id", "PATIENTID": "patient_id", "PROVIDERID": "provider_id",
               "PRIMARYPATIENTINSURANCEID": "primary_patient_insurance_id",
               "SECONDARYPATIENTINSURANCEID": "secondary_patient_insurance_id",
               "DEPARTMENTID": "department_id",
               "PATIENTDEPARTMENTID": "patient_department_id",
               "SERVICEDATE": "service_date",
               "CURRENTILLNESSDATE": "current_illness_date"},
}


def get_conn():
    return psycopg2.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=int(os.getenv("PGPORT", 5432)),
        dbname=os.getenv("PGDATABASE", "healthcare"),
        user=os.getenv("PGUSER", "postgres"),
        password=os.getenv("PGPASSWORD", "postgres"),
    )


def table_columns(conn, table: str) -> set[str]:
    """Return the set of column names defined in the DB for this table."""
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'synthea' AND table_name = %s
            """,
            (table,),
        )
        return {row[0] for row in cur.fetchall()}


def copy_df(conn, df: pd.DataFrame, table: str) -> int:
    """Fast bulk load using COPY FROM STDIN."""
    buf = StringIO()
    df.to_csv(buf, index=False, header=False, na_rep="")
    buf.seek(0)

    col_list = sql.SQL(", ").join(sql.Identifier(c) for c in df.columns)
    stmt = sql.SQL("COPY synthea.{} ({}) FROM STDIN WITH (FORMAT CSV, NULL '')").format(
        sql.Identifier(table), col_list
    )
    with conn.cursor() as cur:
        cur.copy_expert(stmt, buf)
    conn.commit()
    return len(df)


def load_table(conn, table: str) -> None:
    csv_path = DATA_DIR / f"{table}.csv"
    if not csv_path.exists():
        print(f"  SKIP  {table} (no CSV found)")
        return

    df = pd.read_csv(csv_path, dtype=str, keep_default_na=False)
    df.columns = [c.lower() for c in df.columns]

    renames = {k.lower(): v for k, v in COLUMN_RENAMES.get(table, {}).items()}
    if renames:
        df.rename(columns=renames, inplace=True)

    # Drop CSV columns that don't exist in the schema so COPY never errors
    # on extra fields Synthea adds between versions.
    known = table_columns(conn, table)
    extra = [c for c in df.columns if c not in known]
    if extra:
        df.drop(columns=extra, inplace=True)

    # Replace empty strings with None so Postgres sees NULL
    df.replace("", None, inplace=True)

    n = copy_df(conn, df, table)
    print(f"  LOAD  {table:<30}  {n:>8,} rows")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--table", help="Load only this table")
    args = parser.parse_args()

    if not DATA_DIR.exists() or not list(DATA_DIR.glob("*.csv")):
        print("No CSV files found. Run:  python scripts/download_synthea.py --size large")
        sys.exit(1)

    tables = [args.table] if args.table else LOAD_ORDER

    conn = get_conn()
    print(f"Connected to {os.getenv('PGDATABASE', 'healthcare')} on {os.getenv('PGHOST', 'localhost')}\n")

    for table in tqdm(tables, desc="Tables", unit="tbl"):
        load_table(conn, table)

    conn.close()
    print("\nAll done.")


if __name__ == "__main__":
    main()
