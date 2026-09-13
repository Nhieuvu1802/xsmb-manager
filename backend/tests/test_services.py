from datetime import date

from xsmb_manager.services import LotterySyncService


class FakeRepository:
    def __init__(self): self.draws, self.logs = [], []
    def upsert_mb_draw(self, draw_date, results): self.draws.append((draw_date, results))
    def upsert_mn_draw(self, draw_date, province, prizes): pass
    def log_sync(self, *args): self.logs.append(args)


class FakeScraper:
    def fetch_mb_draw(self, day):
        if day.day == 2: raise RuntimeError("source unavailable")
        return [("Giải nhất", 1, "12345")], "fake://source"
    def fetch_mb_snapshot(self, day): return {}, "fake://source"
    def fetch_mn_snapshot(self, day): return {}, "fake://source"


def test_sync_service_isolates_failure_and_continues():
    repository = FakeRepository()
    successes, errors = LotterySyncService(repository, FakeScraper()).sync_mb_range(date(2026, 9, 1), date(2026, 9, 3))
    assert successes == 2
    assert len(repository.draws) == len(repository.logs) == 2
    assert errors == ["02/09/2026: source unavailable"]
