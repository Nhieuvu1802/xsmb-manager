import sqlite3
from datetime import date, datetime
from zoneinfo import ZoneInfo

from xsmb_manager.collector import (
    IncrementalLotteryCollector,
    latest_completed_day,
    max_draw_date,
    missing_dates_in_window,
    validate_mn_snapshot,
)
from xsmb_manager.config import (
    EXPECTED_PRIZES,
    MB_PRIZE_LENGTHS,
    MN_EXPECTED_PRIZES,
    MN_PRIZE_LENGTHS,
)
from xsmb_manager.database import connect


def complete_mb_rows():
    return [
        (prize, position, str(position).zfill(MB_PRIZE_LENGTHS[prize]))
        for prize, count in EXPECTED_PRIZES.items()
        for position in range(1, count + 1)
    ]


def complete_mn_station():
    return {
        prize: [str(position).zfill(MN_PRIZE_LENGTHS[prize]) for position in range(1, count + 1)]
        for prize, count in MN_EXPECTED_PRIZES.items()
    }


class FakeScraper:
    def __init__(self):
        self.mb_calls = []
        self.mn_calls = []

    def fetch_mb_draw(self, day):
        self.mb_calls.append(day)
        return complete_mb_rows(), "https://provider-a.example/xsmb"

    def fetch_mb_snapshot(self, day):
        return {}, "https://provider-a.example/xsmb"

    def fetch_mn_snapshot(self, day):
        self.mn_calls.append(day)
        count = 4 if day.weekday() == 5 else 3
        return (
            {f"Station {index}": complete_mn_station() for index in range(count)},
            "https://provider-a.example/xsmn",
        )


def test_latest_completed_day_respects_region_cutoff():
    timezone = ZoneInfo("Asia/Ho_Chi_Minh")
    morning = datetime(2026, 9, 13, 9, 0, tzinfo=timezone)
    evening = datetime(2026, 9, 13, 19, 30, tzinfo=timezone)

    assert latest_completed_day("XSMB", morning) == date(2026, 9, 12)
    assert latest_completed_day("XSMN", morning) == date(2026, 9, 12)
    assert latest_completed_day("XSMB", evening) == date(2026, 9, 13)


def test_collector_fetches_only_dates_after_max_and_skips_second_run():
    connection = connect(":memory:")
    connection.execute("INSERT INTO draws(draw_date) VALUES ('2026-09-03')")
    scraper = FakeScraper()
    collector = IncrementalLotteryCollector(connection, scraper)

    report = collector.collect("XSMB", through=date(2026, 9, 5))
    second = collector.collect("XSMB", through=date(2026, 9, 5))

    assert report.missing_dates == ["2026-09-04", "2026-09-05"]
    assert report.inserted == 2
    assert report.validation_errors == []
    assert report.providers == ["provider-a.example"]
    assert max_draw_date(connection, "XSMB") == date(2026, 9, 5)
    assert scraper.mb_calls == [date(2026, 9, 4), date(2026, 9, 5)]
    assert second.missing_dates == []
    assert second.inserted == 0
    connection.close()


def test_incomplete_mn_snapshot_is_rejected_before_write():
    snapshot = {"Only one": complete_mn_station()}
    errors = validate_mn_snapshot(date(2026, 9, 4), snapshot)

    assert "stations: 1/3" in errors


def test_collector_writes_all_valid_mn_stations_atomically():
    connection = connect(":memory:")
    scraper = FakeScraper()
    collector = IncrementalLotteryCollector(connection, scraper)

    report = collector.collect("XSMN", through=date(2026, 9, 5))

    assert report.inserted == 4
    assert report.after_max_date == "2026-09-05"
    assert connection.execute("SELECT COUNT(*) FROM mn_draws").fetchone()[0] == 4
    assert connection.execute("SELECT COUNT(*) FROM mn_results").fetchone()[0] == 72
    connection.close()


def test_missing_dates_in_window_skips_dates_already_stored():
    connection = connect(":memory:")
    connection.execute("INSERT INTO draws(draw_date) VALUES ('2026-09-10')")
    connection.execute(
        "INSERT INTO mn_draws(draw_date, province) VALUES ('2026-09-11', 'Tây Ninh')"
    )

    assert missing_dates_in_window(
        connection, "XSMB", date(2026, 9, 9), date(2026, 9, 11)
    ) == [date(2026, 9, 9), date(2026, 9, 11)]
    assert missing_dates_in_window(
        connection, "XSMN", date(2026, 9, 9), date(2026, 9, 11)
    ) == [date(2026, 9, 9), date(2026, 9, 10)]
    # Cửa sổ ngược hoặc rỗng không trả về ngày nào.
    assert missing_dates_in_window(
        connection, "XSMB", date(2026, 9, 12), date(2026, 9, 11)
    ) == []
    connection.close()


def test_collect_one_backfills_dates_older_than_max_without_overwriting():
    connection = connect(":memory:")
    connection.execute("INSERT INTO draws(draw_date) VALUES ('2026-09-05')")
    scraper = FakeScraper()
    collector = IncrementalLotteryCollector(connection, scraper)

    first = collector.collect_one("XSMB", date(2026, 9, 3))
    second = collector.collect_one("XSMB", date(2026, 9, 3))

    assert first == ("https://provider-a.example/xsmb", 1)
    assert second == ("https://provider-a.example/xsmb", 0)
    assert (
        connection.execute(
            "SELECT COUNT(*) FROM results WHERE draw_date='2026-09-03'"
        ).fetchone()[0]
        == 27
    )
    # Backfill lịch sử không làm thay đổi kỳ mới nhất.
    assert max_draw_date(connection, "XSMB") == date(2026, 9, 5)
    connection.close()
