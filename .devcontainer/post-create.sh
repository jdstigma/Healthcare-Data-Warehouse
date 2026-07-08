#!/usr/bin/env bash
set -e

echo "==> Installing Python dependencies..."
pip install -q -r requirements.txt
pip install -q dbt-postgres

echo "==> Waiting for PostgreSQL to be ready..."
until pg_isready -U postgres -h localhost; do sleep 1; done

echo "==> Creating healthcare database..."
psql -U postgres -h localhost -c "CREATE DATABASE healthcare;" 2>/dev/null || echo "Database already exists."

echo "==> Running schema migrations..."
psql -U postgres -h localhost -d healthcare -f schema/01_create_schema.sql
psql -U postgres -h localhost -d healthcare -f schema/02_create_tables.sql
psql -U postgres -h localhost -d healthcare -f schema/03_indexes.sql

echo "==> Installing dbt packages..."
cd dbt/healthcare && dbt deps && cd ../..

echo ""
echo "Setup complete."
echo "Run the full pipeline (download, load, dbt run/test, anomaly notebook, CSV export):"
echo "  python scripts/run_pipeline.py --size large"
