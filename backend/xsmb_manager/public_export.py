"""Build small, deterministic public snapshots from the validated database."""

from __future__ import annotations

import hashlib
import json
import sqlite3
from datetime import date, datetime, timedelta, timezone
from pathlib import Path


API_BASE_URL = "https://api.vvn.freedev.app/v1"
GITHUB_DATA_URL = (
    "https://raw.githubusercontent.com/Nhieuvu1802/xsmb-manager/main/public-data"
)
MB_STATION = "Hội đồng XSKT miền Bắc"

# Cửa sổ lịch sử mặc định xuất ra `public-data/{region}/history.json`: đủ để app
# thống kê/backtest ngay lần cài đầu mà không phải chờ nhiều lần đồng bộ.
HISTORY_DAYS = 365


def _json_bytes(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _atomic_write(path: Path, value: object) -> bytes:
    content = _json_bytes(value)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_bytes(content)
    temporary.replace(path)
    return content


def _prizes(
    connection: sqlite3.Connection,
    table: str,
    draw_date: str,
    station: str | None = None,
) -> list[dict[str, object]]:
    condition = "draw_date=?"
    parameters: tuple[str, ...] = (draw_date,)
    if station is not None:
        condition += " AND province=?"
        parameters += (station,)
    rows = connection.execute(
        f"""SELECT prize, position, full_number FROM {table}
            WHERE {condition} ORDER BY prize, position""",
        parameters,
    ).fetchall()
    return [
        {"prize": prize, "position": position, "value": value}
        for prize, position, value in rows
    ]


def _mb_draw(
    connection: sqlite3.Connection,
    draw_date: str,
    generated_at: str,
) -> dict[str, object]:
    return {
        "region": "mb",
        "date": draw_date,
        "station": MB_STATION,
        "source": "vvn-database",
        "verification": "VERIFIED",
        "collected_at": generated_at,
        "draw_code": f"MB-{draw_date.replace('-', '')}",
        "results": _prizes(connection, "results", draw_date),
    }


def _mn_draws(
    connection: sqlite3.Connection,
    draw_date: str,
    generated_at: str,
) -> list[dict[str, object]]:
    """Kỳ quay của mọi đài trong đúng một ngày XSMN.

    Miền Nam (và miền Trung) mỗi ngày quay một bộ đài khác nhau nên snapshot
    luôn ghi kèm tên đài của từng ngày, không dùng danh sách đài cố định.
    """

    stations = [
        row[0]
        for row in connection.execute(
            "SELECT province FROM mn_draws WHERE draw_date=? ORDER BY province",
            (draw_date,),
        )
    ]
    return [
        {
            "region": "mn",
            "date": draw_date,
            "station": station,
            "source": "vvn-database",
            "verification": "VERIFIED",
            "collected_at": generated_at,
            "draw_code": f"MN-{draw_date.replace('-', '')}-{station}",
            "results": _prizes(connection, "mn_results", draw_date, station),
        }
        for station in stations
    ]


def build_latest_payload(
    connection: sqlite3.Connection,
    region: str,
    generated_at: str,
) -> dict[str, object]:
    if region == "xsmb":
        draw_date = connection.execute("SELECT MAX(draw_date) FROM draws").fetchone()[0]
        draws = [] if not draw_date else [_mb_draw(connection, draw_date, generated_at)]
    elif region == "xsmn":
        draw_date = connection.execute("SELECT MAX(draw_date) FROM mn_draws").fetchone()[0]
        draws = [] if not draw_date else _mn_draws(connection, draw_date, generated_at)
    else:
        raise ValueError(f"Unknown region: {region}")
    return {
        "success": True,
        "source": "vvn-github-backup",
        "region": region,
        "date": draw_date,
        "updatedAt": generated_at,
        "count": len(draws),
        "draws": draws,
    }


def _history_dates(
    connection: sqlite3.Connection,
    table: str,
    latest: str,
    days: int,
) -> list[str]:
    """Các ngày có dữ liệu trong cửa sổ `days` ngày tính ngược từ `latest`."""

    window_start = (date.fromisoformat(latest) - timedelta(days=days - 1)).isoformat()
    return [
        row[0]
        for row in connection.execute(
            f"""SELECT DISTINCT draw_date FROM {table}
                WHERE draw_date BETWEEN ? AND ? ORDER BY draw_date DESC""",
            (window_start, latest),
        )
    ]


def build_history_payload(
    connection: sqlite3.Connection,
    region: str,
    days: int,
    generated_at: str,
) -> dict[str, object]:
    """Snapshot nhiều ngày (mặc định 365) để app có đủ dữ liệu ngay lần cài đầu.

    Cửa sổ tính theo **ngày lịch** kết thúc ở kỳ mới nhất, nên số kỳ thực tế có
    thể ít hơn `days` (ngày nghỉ Tết, ngày chưa quay, ngày nguồn thiếu). Mỗi kỳ
    giữ nguyên `date` + `station` riêng của nó.
    """

    if days < 1:
        raise ValueError("days phải >= 1")
    if region == "xsmb":
        latest = connection.execute("SELECT MAX(draw_date) FROM draws").fetchone()[0]
        draws: list[dict[str, object]] = (
            []
            if not latest
            else [
                _mb_draw(connection, draw_date, generated_at)
                for draw_date in _history_dates(connection, "draws", latest, days)
            ]
        )
    elif region == "xsmn":
        latest = connection.execute("SELECT MAX(draw_date) FROM mn_draws").fetchone()[0]
        draws = (
            []
            if not latest
            else [
                draw
                for draw_date in _history_dates(connection, "mn_draws", latest, days)
                for draw in _mn_draws(connection, draw_date, generated_at)
            ]
        )
    else:
        raise ValueError(f"Unknown region: {region}")
    dates = [str(draw["date"]) for draw in draws]
    return {
        "success": True,
        "source": "vvn-github-backup",
        "region": region,
        "date": latest,
        "firstDate": min(dates) if dates else None,
        "updatedAt": generated_at,
        "days": days,
        "count": len(draws),
        "draws": draws,
    }


def export_public_data(
    database_path: Path,
    output_dir: Path,
    now: datetime | None = None,
    history_days: int = HISTORY_DAYS,
) -> dict[str, object]:
    if history_days < 1:
        raise ValueError("history_days phải >= 1")
    generated_at = (now or datetime.now(timezone.utc)).isoformat()
    connection = sqlite3.connect(database_path)
    try:
        mb = build_latest_payload(connection, "xsmb", generated_at)
        mn = build_latest_payload(connection, "xsmn", generated_at)
        mb_history = build_history_payload(connection, "xsmb", history_days, generated_at)
        mn_history = build_history_payload(connection, "xsmn", history_days, generated_at)
    finally:
        connection.close()

    config = {
        "apiBaseUrl": API_BASE_URL,
        "apiVersion": "v1",
        "fallbackDataUrl": GITHUB_DATA_URL,
        "maintenance": False,
        "minimumAppVersion": "2.0.0",
        "githubFallbackEnabled": True,
    }
    contents = {
        "config.json": _atomic_write(output_dir / "config.json", config),
        "xsmb/latest.json": _atomic_write(output_dir / "xsmb/latest.json", mb),
        "xsmn/latest.json": _atomic_write(output_dir / "xsmn/latest.json", mn),
        "xsmb/history.json": _atomic_write(
            output_dir / "xsmb" / "history.json",
            mb_history,
        ),
        "xsmn/history.json": _atomic_write(
            output_dir / "xsmn" / "history.json",
            mn_history,
        ),
    }
    history = {
        "xsmb": {
            "days": history_days,
            "firstDate": mb_history["firstDate"],
            "latestDate": mb_history["date"],
            "draws": mb_history["count"],
        },
        "xsmn": {
            "days": history_days,
            "firstDate": mn_history["firstDate"],
            "latestDate": mn_history["date"],
            "draws": mn_history["count"],
        },
    }
    dataset_hash = hashlib.sha256()
    for relative_path in sorted(contents):
        dataset_hash.update(relative_path.encode("utf-8"))
        dataset_hash.update(contents[relative_path])
    dataset_version = dataset_hash.hexdigest()[:16]
    files = {
        path: {
            "sha256": hashlib.sha256(content).hexdigest(),
            "bytes": len(content),
        }
        for path, content in contents.items()
    }
    manifest = {
        "schemaVersion": 1,
        "generatedAt": generated_at,
        "xsmbLatestDate": mb["date"],
        "xsmnLatestDate": mn["date"],
        "historyDays": history_days,
        "history": history,
        "datasetVersion": dataset_version,
        "files": files,
    }
    health = {
        "status": "ok",
        "datasetDate": max(str(mb["date"] or ""), str(mn["date"] or "")),
        "datasetVersion": dataset_version,
        "apiVersion": "v1",
        "generatedAt": generated_at,
        "historyDays": history_days,
    }
    _atomic_write(output_dir / "manifest.json", manifest)
    _atomic_write(output_dir / "status.json", health)
    _atomic_write(output_dir / "status" / "health.json", health)
    return manifest
