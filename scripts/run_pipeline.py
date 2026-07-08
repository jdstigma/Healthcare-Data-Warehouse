"""
End-to-end refresh: pull Synthea data, load it, rebuild the dbt marts,
then run the anomaly-detection notebook to visualize and export CSVs.

Run this inside the Codespace (Postgres + dbt live there).

Usage:
  python scripts/run_pipeline.py                  # small sample, full refresh
  python scripts/run_pipeline.py --size large      # 10k-patient sample
  python scripts/run_pipeline.py --skip-data       # reuse data already loaded,
                                                    # just rebuild marts + notebook
"""

import argparse
import subprocess
import sys
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DBT_DIR = REPO_ROOT / "dbt" / "healthcare"
NOTEBOOK_IN = REPO_ROOT / "notebooks" / "anomaly_detection.ipynb"
NOTEBOOK_OUT_DIR = REPO_ROOT / "notebooks" / "executed"


def run(cmd: list[str], cwd: Path = REPO_ROOT) -> None:
    print(f"\n$ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--size", choices=["small", "large"], default="small")
    parser.add_argument(
        "--skip-data", action="store_true",
        help="Skip download + load; assume Postgres already has current data.",
    )
    args = parser.parse_args()

    if not args.skip_data:
        run([sys.executable, "scripts/download_synthea.py", "--size", args.size])
        run([sys.executable, "scripts/load_data.py"])

    run(["dbt", "run"], cwd=DBT_DIR)
    run(["dbt", "test"], cwd=DBT_DIR)

    NOTEBOOK_OUT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    notebook_out = NOTEBOOK_OUT_DIR / f"anomaly_detection_{stamp}.ipynb"

    run([
        sys.executable, "-m", "papermill",
        str(NOTEBOOK_IN), str(notebook_out),
    ])

    print(f"\nPipeline complete. Executed notebook: {notebook_out}")
    print("CSVs written to exports/ — Get Data -> Text/CSV in Power BI.")


if __name__ == "__main__":
    main()
