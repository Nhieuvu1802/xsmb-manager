from datetime import date

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from xsmb_manager.api.database import PostgresLotteryRepository
from xsmb_manager.api.models import Base
from xsmb_manager.api.routes import (
    api_health,
    history,
    public_config,
    version,
    xsmb_history,
    xsmb_by_date,
    xsmb_latest,
    xsmn_by_date,
    xsmn_history,
    xsmn_latest,
)

MN_PRIZES = {
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


@pytest.fixture
def session():
    engine = create_engine("sqlite+pysqlite:///:memory:")
    Base.metadata.create_all(engine)
    with Session(engine) as database:
        repository = PostgresLotteryRepository(database)
        repository.upsert_mb_draw(
            "2026-09-09",
            [("Đặc biệt", 1, "12345"), ("Giải nhất", 1, "67890")],
        )
        repository.upsert_mb_draw("2026-09-10", [("Đặc biệt", 1, "54321")])
        repository.upsert_mn_draw("2026-09-10", "An Giang", MN_PRIZES)
        repository.upsert_mn_draw("2026-09-10", "Bình Thuận", MN_PRIZES)
        yield database


def test_xsmb_latest_trả_kỳ_mới_nhất_trước(session):
    payload = xsmb_latest(days=7, session=session)

    assert payload.region == "mb"
    assert payload.count == 2
    assert payload.draws[0].date == date(2026, 9, 10)
    assert payload.draws[0].station == "Hội đồng XSKT miền Bắc"
    assert payload.draws[0].draw_code == "MB-20260910"
    assert payload.draws[0].results[0].prize == "Đặc biệt"
    assert payload.draws[0].results[0].value == "54321"


def test_xsmb_latest_giới_hạn_số_kỳ(session):
    payload = xsmb_latest(days=1, session=session)
    assert payload.count == 1
    assert payload.draws[0].date == date(2026, 9, 10)


def test_xsmb_theo_ngày(session):
    payload = xsmb_by_date(draw_date=date(2026, 9, 9), session=session)

    assert payload.count == 1
    assert payload.draws[0].date == date(2026, 9, 9)
    assert len(payload.draws[0].results) == 2


def test_xsmb_ngày_không_có_dữ_liệu_trả_rỗng(session):
    payload = xsmb_by_date(draw_date=date(2026, 1, 1), session=session)
    assert payload.count == 0
    assert payload.draws == []


def test_xsmn_latest_tách_từng_đài(session):
    payload = xsmn_latest(days=7, province=None, session=session)

    assert payload.region == "mn"
    assert payload.count == 2
    stations = {draw.station for draw in payload.draws}
    assert stations == {"An Giang", "Bình Thuận"}
    for draw in payload.draws:
        assert len(draw.results) == 18
        assert draw.draw_code.startswith("MN-20260910-")


def test_xsmn_lọc_theo_đài(session):
    payload = xsmn_by_date(
        draw_date=date(2026, 9, 10),
        province="An Giang",
        session=session,
    )

    assert payload.count == 1
    assert payload.draws[0].station == "An Giang"


def test_history_theo_khoảng_ngày_và_region(session):
    payload = history(
        region="mb",
        start=date(2026, 9, 9),
        end=date(2026, 9, 10),
        province=None,
        session=session,
    )
    assert payload.count == 2

    mn_payload = history(
        region="MN",
        start=date(2026, 9, 10),
        end=date(2026, 9, 10),
        province=None,
        session=session,
    )
    assert mn_payload.count == 2


def test_history_alias_theo_từng_vùng(session):
    mb_payload = xsmb_history(
        start=date(2026, 9, 9),
        end=date(2026, 9, 10),
        session=session,
    )
    mn_payload = xsmn_history(
        start=date(2026, 9, 10),
        end=date(2026, 9, 10),
        province=None,
        session=session,
    )

    assert mb_payload.count == 2
    assert mn_payload.count == 2


def test_history_từ_chối_region_lạ(session):
    with pytest.raises(HTTPException) as error:
        history(region="mt", start=None, end=None, province=None, session=session)
    assert error.value.status_code == 422


def test_history_từ_chối_khoảng_ngày_đảo(session):
    with pytest.raises(HTTPException) as error:
        history(
            region="mb",
            start=date(2026, 9, 10),
            end=date(2026, 9, 9),
            province=None,
            session=session,
        )
    assert error.value.status_code == 422


def test_health_trả_về_ok(session):
    payload = api_health(session=session)
    assert payload.status == "ok"
    assert payload.database == "ok"
    assert payload.apiVersion == "v1"
    assert payload.lastDataUpdate == date(2026, 9, 10)


def test_config_và_version_không_chứa_secret():
    config = public_config()
    release = version()

    assert config.apiBaseUrl == "https://api.vvn.freedev.app/v1"
    assert config.githubFallbackEnabled is True
    assert release.apiVersion == "v1"
    assert release.appVersion == "2.7.0"
