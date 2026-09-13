"""One-time migration from the legacy SQLite database to PostgreSQL."""

import argparse
import sqlite3
import sys
from pathlib import Path

# Make direct execution from the repository root resolve the backend package.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "backend"))

from xsmb_manager.api.database import PostgresLotteryRepository, SessionLocal, create_schema


def migrate(source_path: Path) -> tuple[int, int]:
    if not source_path.is_file():
        raise FileNotFoundError(source_path)
    create_schema()
    mb_count = mn_count = 0
    source = sqlite3.connect(source_path)
    source.row_factory = sqlite3.Row
    try:
        with SessionLocal() as session:
            repository = PostgresLotteryRepository(session)
            dates = source.execute("SELECT draw_date FROM draws ORDER BY draw_date").fetchall()
            for item in dates:
                rows = source.execute(
                    "SELECT prize, position, full_number FROM results WHERE draw_date=? ORDER BY prize, position",
                    (item["draw_date"],),
                ).fetchall()
                if rows:
                    repository.upsert_mb_draw(item["draw_date"], [(row["prize"], row["position"], row["full_number"]) for row in rows])
                    mb_count += 1
            mn_draws = source.execute("SELECT draw_date, province FROM mn_draws ORDER BY draw_date, province").fetchall()
            for item in mn_draws:
                rows = source.execute(
                    "SELECT prize, position, full_number FROM mn_results WHERE draw_date=? AND province=? ORDER BY prize, position",
                    (item["draw_date"], item["province"]),
                ).fetchall()
                prizes: dict[str, list[str]] = {}
                for row in rows:
                    prizes.setdefault(row["prize"], []).append(row["full_number"])
                repository.upsert_mn_draw(item["draw_date"], item["province"], prizes)
                mn_count += 1
    finally:
        source.close()
    return mb_count, mn_count


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, nargs="?", default=Path("data/xsmb.db"))
    args = parser.parse_args()
    mb, mn = migrate(args.source)
    print(f"Migrated {mb} XSMB draws and {mn} XSMN province draws")
