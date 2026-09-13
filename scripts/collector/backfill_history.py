"""Backfill a rolling history window (default 365 days) into the database.

`update_lottery.py` chỉ đi tiếp từ `MAX(draw_date)` nên không lấp được lịch sử
cũ. Script này lấp mọi ngày còn thiếu trong cửa sổ `[through - days + 1, through]`
— ví dụ XSMN chỉ có vài ngày gần nhất trong khi app cần đủ 365 ngày để thống kê.

Ngày đã có dữ liệu **không** bị ghi đè: `INSERT OR IGNORE` theo
`(draw_date, province)` và validate 18 số/đài trước khi ghi. Ngày nguồn không có
(ví dụ ngày nghỉ Tết) chỉ được ghi vào `validation_errors` rồi bỏ qua.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from datetime import date, timedelta
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "backend"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

# Dùng lại đúng hai helper của update_lottery.py để hai script không lệch nhau.
from update_lottery import backup_database, mirror_dates  # noqa: E402

from xsmb_manager.collector import (  # noqa: E402
    IncrementalLotteryCollector,
    RegionCollectionReport,
    latest_completed_day,
    max_draw_date,
    missing_dates_in_window,
    provider_label,
)
from xsmb_manager.database import connect  # noqa: E402
from xsmb_manager.scraper import RequestsLotteryScraper  # noqa: E402


DEFAULT_DAYS = 365
PROGRESS_EVERY = 20


def backfill_region(
    connection: sqlite3.Connection,
    collector: IncrementalLotteryCollector,
    region: str,
    start: date,
    through: date,
    progress: bool = True,
) -> RegionCollectionReport:
    """Lấp mọi ngày thiếu trong cửa sổ; trả báo cáo giống `collect`."""

    before = max_draw_date(connection, region)
    missing = missing_dates_in_window(connection, region, start, through)
    report = RegionCollectionReport(
        region=region,
        before_max_date=before.isoformat() if before else None,
        target_date=through.isoformat(),
        missing_dates=[day.isoformat() for day in missing],
    )
    for index, day in enumerate(missing, 1):
        try:
            source, written = collector.collect_one(region, day)
            report.inserted += written
            label = provider_label(source)
            if label not in report.providers:
                report.providers.append(label)
            if written:
                report.inserted_dates.append(day.isoformat())
        except Exception as exc:  # nguồn thiếu ngày (Tết…) không làm hỏng cả lượt
            report.validation_errors.append(f"{day.isoformat()}: {exc}")
        if progress and index % PROGRESS_EVERY == 0:
            print(
                f"   {region}: {index}/{len(missing)} ngày đã xử lý…",
                file=sys.stderr,
                flush=True,
            )
    after = max_draw_date(connection, region)
    report.after_max_date = after.isoformat() if after else None
    remaining = missing_dates_in_window(connection, region, start, through)
    report.remaining_missing_dates = [day.isoformat() for day in remaining]
    return report


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Backfill missing lottery dates inside a rolling window.",
    )
    parser.add_argument(
        "--database",
        type=Path,
        default=REPO_ROOT / "data" / "xsmb.db",
    )
    parser.add_argument("--mirror-database", type=Path)
    parser.add_argument(
        "--region",
        choices=("all", "xsmb", "xsmn"),
        default="all",
    )
    parser.add_argument("--days", type=int, default=DEFAULT_DAYS)
    parser.add_argument("--from", dest="start", type=date.fromisoformat)
    parser.add_argument("--through", type=date.fromisoformat)
    parser.add_argument("--no-backup", action="store_true")
    args = parser.parse_args()

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")

    if args.days < 1:
        parser.error("--days phải >= 1")

    regions = {
        "all": ("XSMB", "XSMN"),
        "xsmb": ("XSMB",),
        "xsmn": ("XSMN",),
    }[args.region]
    connection = connect(args.database)
    reports: list[RegionCollectionReport] = []
    backup_path: Path | None = None
    try:
        targets = {
            region: args.through or latest_completed_day(region)
            for region in regions
        }
        windows = {
            region: (
                args.start
                if args.start is not None
                else targets[region] - timedelta(days=args.days - 1)
            )
            for region in regions
        }
        has_work = any(
            missing_dates_in_window(connection, region, windows[region], targets[region])
            for region in regions
        )
        if has_work and not args.no_backup:
            backup_path = backup_database(connection, args.database)
        collector = IncrementalLotteryCollector(
            connection,
            RequestsLotteryScraper(db_path=args.database),
        )
        reports = [
            backfill_region(
                connection,
                collector,
                region,
                windows[region],
                targets[region],
            )
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
        "window": {
            "days": args.days,
            "from": {region: windows[region].isoformat() for region in regions},
            "through": {region: targets[region].isoformat() for region in regions},
        },
        "regions": [report.to_dict() for report in reports],
        "mirror": mirrored,
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 2 if any(report.validation_errors for report in reports) else 0


if __name__ == "__main__":
    raise SystemExit(main())
