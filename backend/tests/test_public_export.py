import json
from datetime import datetime, timezone

import pytest

from xsmb_manager.config import (
    EXPECTED_PRIZES,
    MB_PRIZE_LENGTHS,
    MN_EXPECTED_PRIZES,
    MN_PRIZE_LENGTHS,
)
from xsmb_manager.database import SQLiteLotteryRepository, connect
from xsmb_manager.public_export import (
    HISTORY_DAYS,
    export_public_data,
    build_history_payload,
)


def test_export_writes_manifest_health_config_and_latest_snapshot(tmp_path):
    database = tmp_path / "lottery.db"
    connection = connect(database)
    repository = SQLiteLotteryRepository(connection)
    rows = [
        (prize, position, str(position).zfill(MB_PRIZE_LENGTHS[prize]))
        for prize, count in EXPECTED_PRIZES.items()
        for position in range(1, count + 1)
    ]
    repository.upsert_mb_draw("2026-09-12", rows)
    connection.close()

    output = tmp_path / "public-data"
    manifest = export_public_data(
        database,
        output,
        now=datetime(2026, 9, 13, tzinfo=timezone.utc),
    )

    config = json.loads((output / "config.json").read_text(encoding="utf-8"))
    latest = json.loads((output / "xsmb" / "latest.json").read_text(encoding="utf-8"))
    health = json.loads((output / "status" / "health.json").read_text(encoding="utf-8"))
    assert config["apiBaseUrl"] == "https://api.vvn.freedev.app/v1"
    assert latest["date"] == "2026-09-12"
    assert len(latest["draws"][0]["results"]) == 27
    assert manifest["datasetVersion"] == health["datasetVersion"]
    assert manifest["files"]["xsmb/latest.json"]["bytes"] > 0
def mb_rows() -> list[tuple[str, int, str]]:
    return [
        (prize, position, str(position).zfill(MB_PRIZE_LENGTHS[prize]))
        for prize, count in EXPECTED_PRIZES.items()
        for position in range(1, count + 1)
    ]


def mn_station() -> dict[str, list[str]]:
    return {
        prize: [
            str(position).zfill(MN_PRIZE_LENGTHS[prize])
            for position in range(1, count + 1)
        ]
        for prize, count in MN_EXPECTED_PRIZES.items()
    }


def test_history_snapshot_keeps_window_order_and_station_per_day(tmp_path):
    database = tmp_path / "lottery.db"
    connection = connect(database)
    repository = SQLiteLotteryRepository(connection)
    for day in ("2025-09-13", "2025-09-14", "2026-09-12"):
        repository.upsert_mb_draw(day, mb_rows())
    repository.upsert_mn_draw("2026-09-12", "Long An", mn_station())
    connection.close()

    output = tmp_path / "public-data"
    manifest = export_public_data(
        database,
        output,
        now=datetime(2026, 9, 13, tzinfo=timezone.utc),
    )

    history = json.loads((output / "xsmb" / "history.json").read_text(encoding="utf-8"))
    assert HISTORY_DAYS == 365
    assert history["days"] == HISTORY_DAYS
    assert history["date"] == "2026-09-12"
    assert history["firstDate"] == "2025-09-13"
    assert history["count"] == len(history["draws"]) == 3
    assert [draw["date"] for draw in history["draws"]] == [
        "2026-09-12",
        "2025-09-14",
        "2025-09-13",
    ]
    assert all(len(draw["results"]) == 27 for draw in history["draws"])

    mn = json.loads((output / "xsmn" / "history.json").read_text(encoding="utf-8"))
    assert [draw["station"] for draw in mn["draws"]] == ["Long An"]
    assert mn["draws"][0]["draw_code"] == "MN-20260912-Long An"

    assert manifest["historyDays"] == 365
    assert manifest["history"]["xsmb"]["firstDate"] == "2025-09-13"
    assert manifest["history"]["xsmn"]["draws"] == 1
    assert manifest["files"]["xsmb/history.json"]["bytes"] > 0
    assert manifest["files"]["xsmn/history.json"]["bytes"] > 0


def test_history_window_drops_draws_older_than_requested_days(tmp_path):
    database = tmp_path / "lottery.db"
    connection = connect(database)
    repository = SQLiteLotteryRepository(connection)
    for day in ("2025-09-13", "2026-08-14", "2026-09-12"):
        repository.upsert_mb_draw(day, mb_rows())
    connection.close()

    output = tmp_path / "public-data"
    export_public_data(
        database,
        output,
        now=datetime(2026, 9, 13, tzinfo=timezone.utc),
        history_days=30,
    )

    history = json.loads((output / "xsmb" / "history.json").read_text(encoding="utf-8"))
    assert history["days"] == 30
    assert [draw["date"] for draw in history["draws"]] == ["2026-09-12", "2026-08-14"]
    # latest.json vẫn chỉ chứa kỳ mới nhất để client tải nhanh.
    latest = json.loads((output / "xsmb" / "latest.json").read_text(encoding="utf-8"))
    assert latest["count"] == 1
    assert latest["draws"][0]["date"] == "2026-09-12"


def test_history_payload_rejects_invalid_window():
    connection = connect(":memory:")
    with pytest.raises(ValueError):
        build_history_payload(connection, "xsmb", 0, "2026-09-13T00:00:00+00:00")
    with pytest.raises(ValueError):
        build_history_payload(connection, "xsmn", -1, "2026-09-13T00:00:00+00:00")
    connection.close()

