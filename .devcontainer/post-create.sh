#!/usr/bin/env bash
set -e

echo "==> Installing PostgreSQL 15..."
# Base image ships a stale dl.yarnpkg.com apt source with no valid signing
# key, which breaks `apt-get update` outright. Not needed for this project.
sudo grep -rl "yarnpkg" /etc/apt/sources.list.d/ 2>/dev/null | xargs -r sudo rm -f
sudo apt-get update -qq
sudo apt-get install -y -qq wget gnupg2 lsb-release ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y -qq postgresql-15
sudo service postgresql start
# `sudo -u postgres` prompts for a password in this sudoers config (NOPASSWD
# only covers the root target); `sudo su postgres` avoids that since root
# can switch to any user without a password.
sudo su postgres -c "psql -c \"ALTER USER postgres PASSWORD 'postgres';\""

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
