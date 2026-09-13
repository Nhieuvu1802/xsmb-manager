"""Incremental, validated lottery collection use case.

The collector only requests dates after the newest stored draw. It never uses
an end-user request as a trigger and never replaces an existing good draw with
an invalid upstream response.
"""

from __future__ import annotations

import sqlite3
from dataclasses import asdict, dataclass, field
from datetime import date, datetime, time, timedelta
from urllib.parse import urlparse

from .config import (
    EXPECTED_PRIZES,
    MB_PRIZE_LENGTHS,
    MN_EXPECTED_PRIZES,
    MN_PRIZE_LENGTHS,
    MN_WEEKLY_SCHEDULE,
    VN_TIMEZONE,
)
from .ports import LotteryScraper


REGION_TABLES = {"XSMB": "draws", "XSMN": "mn_draws"}
REGION_CUTOFFS = {"XSMB": time(19, 0), "XSMN": time(17, 0)}
WEEKDAY_LABELS = (
    "Thứ Hai",
    "Thứ Ba",
    "Thứ Tư",
    "Thứ Năm",
    "Thứ Sáu",
    "Thứ Bảy",
    "Chủ Nhật",
)


@dataclass
class RegionCollectionReport:
    region: str
    before_max_date: str | None
    target_date: str
    missing_dates: list[str]
    inserted: int = 0
    duplicate_skipped: int = 0
    validation_errors: list[str] = field(default_factory=list)
    providers: list[str] = field(default_factory=list)
    inserted_dates: list[str] = field(default_factory=list)
    after_max_date: str | None = None
    remaining_missing_dates: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, object]:
        return asdict(self)


def latest_completed_day(region: str, now: datetime | None = None) -> date:
    """Newest date whose draw should have completed in Vietnam."""

    if region not in REGION_CUTOFFS:
        raise ValueError(f"Unknown region: {region}")
    current = now or datetime.now(VN_TIMEZONE)
    if current.tzinfo is None:
        current = current.replace(tzinfo=VN_TIMEZONE)
    else:
        current = current.astimezone(VN_TIMEZONE)
    if current.timetz().replace(tzinfo=None) < REGION_CUTOFFS[region]:
        return current.date() - timedelta(days=1)
    return current.date()


def max_draw_date(connection: sqlite3.Connection, region: str) -> date | None:
    table = REGION_TABLES[region]
    value = connection.execute(f"SELECT MAX(draw_date) FROM {table}").fetchone()[0]
    return date.fromisoformat(value) if value else None


def missing_dates_after_max(
    connection: sqlite3.Connection,
    region: str,
    through: date,
) -> list[date]:
    newest = max_draw_date(connection, region)
    start = (newest + timedelta(days=1)) if newest else through
    if start > through:
        return []
    return [start + timedelta(days=offset) for offset in range((through - start).days + 1)]


def missing_dates_in_window(
    connection: sqlite3.Connection,
    region: str,
    start: date,
    through: date,
) -> list[date]:
    """Các ngày trong `[start, through]` chưa có bản ghi.

    Khác `missing_dates_after_max` (chỉ đi tới trước từ `MAX(draw_date)`), hàm này
    dùng cho backfill lịch sử: lấp những ngày **cũ hơn** kỳ mới nhất, ví dụ lần
    đầu cài đặt cần đủ cửa sổ 365 ngày cho app.
    """

    if region not in REGION_TABLES:
        raise ValueError(f"Unknown region: {region}")
    if start > through:
        return []
    table = REGION_TABLES[region]
    stored = {
        row[0]
        for row in connection.execute(
            f"""SELECT DISTINCT draw_date FROM {table}
                WHERE draw_date BETWEEN ? AND ?""",
            (start.isoformat(), through.isoformat()),
        )
    }
    days = [start + timedelta(days=offset) for offset in range((through - start).days + 1)]
    return [day for day in days if day.isoformat() not in stored]


def expected_mn_station_count(day: date) -> int:
    return len(MN_WEEKLY_SCHEDULE[WEEKDAY_LABELS[day.weekday()]])


def provider_label(source_url: str) -> str:
    return urlparse(source_url).hostname or source_url


def validate_mb_rows(rows: list[tuple[str, int, str]]) -> list[str]:
    errors: list[str] = []
    grouped: dict[str, list[tuple[int, str]]] = {}
    for prize, position, value in rows:
        grouped.setdefault(prize, []).append((position, value))
    for prize, expected_count in EXPECTED_PRIZES.items():
        values = grouped.get(prize, [])
        if len(values) != expected_count:
            errors.append(f"{prize}: {len(values)}/{expected_count} values")
            continue
        if len({position for position, _ in values}) != expected_count:
            errors.append(f"{prize}: duplicate positions")
        length = MB_PRIZE_LENGTHS[prize]
        for _, value in values:
            if not value.isdigit() or len(value) != length:
                errors.append(f"{prize}: invalid {length}-digit value")
    unexpected = sorted(set(grouped) - set(EXPECTED_PRIZES))
    if unexpected:
        errors.append(f"unexpected prizes: {', '.join(unexpected)}")
    return errors


def validate_mn_snapshot(
    day: date,
    snapshot: dict[str, dict[str, list[str]]],
) -> list[str]:
    errors: list[str] = []
    expected_stations = expected_mn_station_count(day)
    if len(snapshot) != expected_stations:
        errors.append(f"stations: {len(snapshot)}/{expected_stations}")
    for station, prizes in snapshot.items():
        for prize, expected_count in MN_EXPECTED_PRIZES.items():
            values = prizes.get(prize, [])
            if len(values) != expected_count:
                errors.append(f"{station}/{prize}: {len(values)}/{expected_count} values")
                continue
            length = MN_PRIZE_LENGTHS[prize]
            if any(not value.isdigit() or len(value) != length for value in values):
                errors.append(f"{station}/{prize}: invalid {length}-digit value")
        unexpected = sorted(set(prizes) - set(MN_EXPECTED_PRIZES))
        if unexpected:
            errors.append(f"{station}: unexpected prizes: {', '.join(unexpected)}")
    return errors


class IncrementalLotteryCollector:
    def __init__(
        self,
        connection: sqlite3.Connection,
        scraper: LotteryScraper,
    ):
        self.connection = connection
        self.scraper = scraper

    def collect(self, region: str, through: date | None = None) -> RegionCollectionReport:
        if region not in REGION_TABLES:
            raise ValueError(f"Unknown region: {region}")
        target = through or latest_completed_day(region)
        before = max_draw_date(self.connection, region)
        missing = missing_dates_after_max(self.connection, region, target)
        report = RegionCollectionReport(
            region=region,
            before_max_date=before.isoformat() if before else None,
            target_date=target.isoformat(),
            missing_dates=[day.isoformat() for day in missing],
        )
        for day in missing:
            try:
                source, written = self.collect_one(region, day)
                report.inserted += written
                label = provider_label(source)
                if label not in report.providers:
                    report.providers.append(label)
                report.inserted_dates.append(day.isoformat())
            except Exception as exc:
                report.validation_errors.append(f"{day.isoformat()}: {exc}")
        after = max_draw_date(self.connection, region)
        report.after_max_date = after.isoformat() if after else None
        report.remaining_missing_dates = [
            day.isoformat() for day in missing_dates_after_max(self.connection, region, target)
        ]
        return report

    def collect_one(self, region: str, day: date) -> tuple[str, int]:
        """Thu thập và ghi đúng một ngày; trả về `(nguồn, số bản ghi ghi mới)`.

        Dùng chung cho vòng lặp tiến ([collect]) và backfill lịch sử
        (`scripts/collector/backfill_history.py`) — nơi cần ghi cả những ngày cũ
        hơn `MAX(draw_date)`. Ngày đã có trong database trả về `0` bản ghi mới,
        không ghi đè dữ liệu tốt đang có.
        """

        if region not in REGION_TABLES:
            raise ValueError(f"Unknown region: {region}")
        if region == "XSMB":
            return self._collect_mb(day)
        return self._collect_mn(day)

    def _collect_mb(self, day: date) -> tuple[str, int]:
        rows, source = self.scraper.fetch_mb_draw(day)
        errors = validate_mb_rows(rows)
        if errors:
            raise ValueError("; ".join(errors))
        with self.connection:
            cursor = self.connection.execute(
                "INSERT OR IGNORE INTO draws(draw_date) VALUES (?)",
                (day.isoformat(),),
            )
            if cursor.rowcount == 0:
                return source, 0
            self.connection.executemany(
                """INSERT INTO results(draw_date, prize, position, full_number, loto2)
                   VALUES (?, ?, ?, ?, ?)""",
                [
                    (day.isoformat(), prize, position, value, value[-2:])
                    for prize, position, value in rows
                ],
            )
            self._log("XSMB", day, source, "27 số")
        return source, 1

    def _collect_mn(self, day: date) -> tuple[str, int]:
        snapshot, source = self.scraper.fetch_mn_snapshot(day)
        errors = validate_mn_snapshot(day, snapshot)
        if errors:
            raise ValueError("; ".join(errors))
        with self.connection:
            inserted = 0
            for station, prizes in snapshot.items():
                cursor = self.connection.execute(
                    "INSERT OR IGNORE INTO mn_draws(draw_date, province) VALUES (?, ?)",
                    (day.isoformat(), station),
                )
                if cursor.rowcount == 0:
                    continue
                inserted += 1
                rows = [
                    (day.isoformat(), station, prize, position, value, value[-2:])
                    for prize in MN_EXPECTED_PRIZES
                    for position, value in enumerate(prizes[prize], 1)
                ]
                self.connection.executemany(
                    """INSERT INTO mn_results(
                           draw_date, province, prize, position, full_number, loto2
                       ) VALUES (?, ?, ?, ?, ?, ?)""",
                    rows,
                )
            if inserted != len(snapshot):
                raise ValueError("date already exists or contains duplicate stations")
            self._log("XSMN", day, source, f"{inserted} đài")
        return source, inserted

    def _log(self, region: str, day: date, source: str, details: str) -> None:
        self.connection.execute(
            """INSERT INTO sync_log(region, draw_date, source, status, details)
               VALUES (?, ?, ?, 'success', ?)""",
            (region, day.isoformat(), source, details),
        )
