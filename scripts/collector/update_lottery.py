"""Update only completed lottery dates missing after MAX(draw_date)."""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from datetime import date, datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "backend"))

from xsmb_manager.collector import (  # noqa: E402
    IncrementalLotteryCollector,
    latest_completed_day,
    missing_dates_after_max,
)
from xsmb_manager.database import SQLiteLotteryRepository, connect  # noqa: E402
from xsmb_manager.scraper import RequestsLotteryScraper  # noqa: E402


def backup_database(connection: sqlite3.Connection, source_path: Path) -> Path:
    backup_dir = REPO_ROOT / "data" / "backups" / "database"
    backup_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    target = backup_dir / f"pre-collector-{stamp}-{source_path.name}"
    backup = sqlite3.connect(target)
    try:
        connection.backup(backup)
    finally:
        backup.close()
    return target


def mirror_dates(
    source: sqlite3.Connection,
    target_path: Path,
    reports: list,
) -> dict[str, int]:
    target = connect(target_path)
    repository = SQLiteLotteryRepository(target)
    copied_mb = copied_mn = 0
    try:
        for report in reports:
            for draw_date in report.inserted_dates:
                if report.region == "XSMB":
                    rows = source.execute(
                        """SELECT prize, position, full_number FROM results
                           WHERE draw_date=? ORDER BY prize, position""",
                        (draw_date,),
                    ).fetchall()
                    repository.upsert_mb_draw(draw_date, [tuple(row) for row in rows])
                    repository.log_sync("XSMB", draw_date, "mirror:xsmb.db", "27 số")
                    copied_mb += 1
                    continue
                stations = source.execute(
                    "SELECT province FROM mn_draws WHERE draw_date=? ORDER BY province",
                    (draw_date,),
                ).fetchall()
                for (station,) in stations:
                    rows = source.execute(
                        """SELECT prize, full_number FROM mn_results
                           WHERE draw_date=? AND province=? ORDER BY prize, position""",
                        (draw_date, station),
                    ).fetchall()
                    prizes: dict[str, list[str]] = {}
                    for prize, value in rows:
                        prizes.setdefault(prize, []).append(value)
                    repository.upsert_mn_draw(draw_date, station, prizes)
                    copied_mn += 1
                repository.log_sync(
                    "XSMN",
                    draw_date,
                    "mirror:xsmb.db",
                    f"{len(stations)} đài",
                )
    finally:
        target.close()
    return {"xsmbDraws": copied_mb, "xsmnStationDraws": copied_mn}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--database",
        type=Path,
        default=REPO_ROOT / "data" / "xsmb.db",
    )
    parser.add_argument("--mirror-database", type=Path)
    parser.add_argument("--through", type=date.fromisoformat)
    parser.add_argument(
        "--region",
        choices=("all", "xsmb", "xsmn"),
        default="all",
    )
    parser.add_argument("--no-backup", action="store_true")
    args = parser.parse_args()

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    regions = {
        "all": ("XSMB", "XSMN"),
        "xsmb": ("XSMB",),
        "xsmn": ("XSMN",),
    }[args.region]
    connection = connect(args.database)
    reports = []
    backup_path: Path | None = None
    try:
        targets = {
            region: args.through or latest_completed_day(region)
            for region in regions
        }
        has_work = any(
            missing_dates_after_max(connection, region, targets[region])
            for region in regions
        )
        if has_work and not args.no_backup:
            backup_path = backup_database(connection, args.database)
        collector = IncrementalLotteryCollector(
            connection,
            RequestsLotteryScraper(db_path=args.database),
        )
        reports = [
            collector.collect(region, through=targets[region])
            for region in regions
        ]
        mirrored = (
            mirror_dates(connection, args.mirror_database, reports)
            if args.mirror_database
            else None
        )
    finally:
        connection.close()

    payload = {
        "database": str(args.database.resolve()),
        "backup": str(backup_path.resolve()) if backup_path else None,
        "regions": [report.to_dict() for report in reports],
        "mirror": mirrored,
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 2 if any(report.validation_errors for report in reports) else 0


if __name__ == "__main__":
    raise SystemExit(main())
