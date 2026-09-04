from datetime import date

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from xsmb_manager.api.database import PostgresLotteryRepository
from xsmb_manager.api.models import Base


def test_list_mn_results_filters_province_and_date():
    engine = create_engine("sqlite+pysqlite:///:memory:")
    Base.metadata.create_all(engine)

    with Session(engine) as session:
        repository = PostgresLotteryRepository(session)
        prizes = {
            "Giải tám": ["12"],
            "Giải bảy": ["123"],
            "Giải sáu": ["1111", "2222", "3333"],
            "Giải năm": ["4444"],
            "Giải tư": ["10001", "10002", "10003", "10004", "10005", "10006", "10007"],
            "Giải ba": ["55555", "66666"],
            "Giải nhì": ["77777"],
            "Giải nhất": ["88888"],
            "Đặc biệt": ["999999"],
        }
        repository.upsert_mn_draw("2026-09-04", "TP Hồ Chí Minh", prizes)
        repository.upsert_mn_draw("2026-09-04", "An Giang", prizes)

        rows = repository.list_mn_results(
            start=date(2026, 9, 4),
            end=date(2026, 9, 4),
            province="An Giang",
        )

    assert len(rows) == 18
    assert {row.province for row in rows} == {"An Giang"}
    assert {row.draw_date for row in rows} == {date(2026, 9, 4)}
