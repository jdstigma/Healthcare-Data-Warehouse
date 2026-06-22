"""
Download Synthea sample CSV data.

Sizes available:
  small  ~  1 000 patients  (fast, good for dev)
  large  ~ 10 000 patients  (COVID-19 dataset, good for dashboards)

Usage:
  python scripts/download_synthea.py --size large
"""

import argparse
import os
import zipfile
import requests
from pathlib import Path
from tqdm import tqdm

DATA_DIR = Path("data/raw")

SYNTHEA_RELEASES = {
    "small": (
        "https://raw.githubusercontent.com/synthetichealth/synthea-sample-data/"
        "main/downloads/latest/synthea_sample_data_csv_latest.zip"
    ),
    "large": (
        "https://raw.githubusercontent.com/synthetichealth/synthea-sample-data/"
        "main/downloads/10k_synthea_covid19_csv.zip"
    ),
}


def download(url: str, dest: Path) -> None:
    print(f"Downloading {url}")
    r = requests.get(url, stream=True, timeout=120)
    r.raise_for_status()
    total = int(r.headers.get("content-length", 0))
    dest.parent.mkdir(parents=True, exist_ok=True)
    with open(dest, "wb") as f, tqdm(total=total, unit="B", unit_scale=True) as bar:
        for chunk in r.iter_content(chunk_size=8192):
            f.write(chunk)
            bar.update(len(chunk))


def extract(zip_path: Path, out_dir: Path) -> None:
    print(f"Extracting to {out_dir}")
    out_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as zf:
        # Flatten: extract all CSVs directly into out_dir
        for member in zf.namelist():
            if member.endswith(".csv"):
                filename = Path(member).name
                with zf.open(member) as src, open(out_dir / filename, "wb") as dst:
                    dst.write(src.read())
    print(f"Extracted {len(list(out_dir.glob('*.csv')))} CSV files.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--size", choices=["small", "large"], default="small")
    args = parser.parse_args()

    url = SYNTHEA_RELEASES[args.size]
    zip_path = DATA_DIR / f"synthea_{args.size}.zip"

    if not any(DATA_DIR.glob("*.csv")):
        download(url, zip_path)
        extract(zip_path, DATA_DIR)
        zip_path.unlink()
    else:
        print(f"CSV files already present in {DATA_DIR}. Skipping download.")

    print("\nDone. Run:  python scripts/load_data.py")


if __name__ == "__main__":
    main()
