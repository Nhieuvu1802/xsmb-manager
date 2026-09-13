"""Export validated latest-result snapshots and manifest for GitHub fallback."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "backend"))

from xsmb_manager.public_export import HISTORY_DAYS, export_public_data  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--database",
        type=Path,
        default=REPO_ROOT / "data" / "xsmb.db",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=REPO_ROOT / "public-data",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=HISTORY_DAYS,
        help="Số ngày lịch sử ghi vào {region}/history.json (mặc định 365).",
    )
    args = parser.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    manifest = export_public_data(
        args.database,
        args.output,
        history_days=args.days,
    )
    print(json.dumps(manifest, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
