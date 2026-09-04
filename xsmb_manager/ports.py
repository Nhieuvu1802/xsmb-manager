"""Dependency-inversion boundaries for persistence and remote data."""

from datetime import date
from typing import Protocol, TypeAlias

MBResult: TypeAlias = tuple[str, int, str]
MBPrizeMap: TypeAlias = dict[str, list[str]]
MNPrizeMap: TypeAlias = dict[str, dict[str, list[str]]]


class LotteryRepository(Protocol):
    """Persistence operations used by application services."""

    def upsert_mb_draw(self, draw_date: str, results: list[MBResult]) -> None: ...
    def upsert_mn_draw(self, draw_date: str, province: str, prizes: MBPrizeMap) -> None: ...
    def log_sync(self, region: str, draw_date: str, source: str, details: str) -> None: ...


class LotteryScraper(Protocol):
    """Remote lottery source independent of requests/HTML details."""

    def fetch_mb_snapshot(self, day: date) -> tuple[MBPrizeMap, str]: ...
    def fetch_mb_draw(self, day: date) -> tuple[list[MBResult], str]: ...
    def fetch_mn_snapshot(self, day: date) -> tuple[MNPrizeMap, str]: ...
