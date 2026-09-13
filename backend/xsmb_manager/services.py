"""Use cases composed from repository and scraper ports."""

from datetime import date

import pandas as pd

from .config import MN_EXPECTED_PRIZES
from .ports import LotteryRepository, LotteryScraper


class LotterySyncService:
    def __init__(self, repository: LotteryRepository, scraper: LotteryScraper):
        self.repository = repository
        self.scraper = scraper

    def sync_mb_range(self, start_day: date, end_day: date) -> tuple[int, list[str]]:
        successes, errors = 0, []
        for stamp in pd.date_range(start_day, end_day):
            day = stamp.date()
            try:
                results, source = self.scraper.fetch_mb_draw(day)
                self.repository.upsert_mb_draw(day.isoformat(), results)
                self.repository.log_sync("XSMB", day.isoformat(), source, "27 số")
                successes += 1
            except Exception as exc:
                errors.append(f"{day:%d/%m/%Y}: {exc}")
        return successes, errors

    def sync_mn_range(self, start_day: date, end_day: date) -> tuple[int, list[str]]:
        successes, errors = 0, []
        for stamp in pd.date_range(start_day, end_day):
            day = stamp.date()
            try:
                found, source = self.scraper.fetch_mn_snapshot(day)
                saved = 0
                for province, prizes in found.items():
                    if all(len(prizes.get(prize, [])) == count for prize, count in MN_EXPECTED_PRIZES.items()):
                        self.repository.upsert_mn_draw(day.isoformat(), province, prizes)
                        saved += 1
                if not saved:
                    raise ValueError("chưa có đài nào đủ 18 số")
                self.repository.log_sync("XSMN", day.isoformat(), source, f"{saved} đài")
                successes += saved
            except Exception as exc:
                errors.append(f"{day:%d/%m/%Y}: {exc}")
        return successes, errors
