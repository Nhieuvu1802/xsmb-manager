"""Streamlit presentation layer for the lottery manager."""

from __future__ import annotations

import io
import re
import shutil
import sqlite3
import tempfile
import time
import zipfile
from datetime import date, datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import altair as alt
import numpy as np
import pandas as pd
import requests
import streamlit as st
from bs4 import BeautifulSoup

DB_PATH = Path(__file__).with_name("xsmb.db")
APP_DIR = Path(__file__).resolve().parent
APP_VERSION = "2.7.0"
DB_BACKUP_DIR = APP_DIR / "backups" / "database"
VN_TIMEZONE = ZoneInfo("Asia/Ho_Chi_Minh")
DATE_CANDIDATES = {"date", "ngay", "ngày", "draw_date", "ngay_quay"}
ONLINE_SOURCE = "https://xoso.com.vn/xsmb-{day:%d-%m-%Y}.html"
XSMN_SOURCE = "https://xoso.com.vn/xsmn-{day:%d-%m-%Y}.html"
MB_SOURCES = {
    "Xoso.com.vn": ONLINE_SOURCE,
    "Xổ Số Đại Phát": "https://xosodaiphat.com/xsmb-{day:%d-%m-%Y}.html",
    "Minh Ngọc": "https://www.minhngoc.net.vn/ket-qua-xo-so/mien-bac/{day:%d-%m-%Y}.html",
}
MN_SOURCES = {
    "Xoso.com.vn": XSMN_SOURCE,
    "Xổ Số Đại Phát": "https://xosodaiphat.com/xsmn-{day:%d-%m-%Y}.html",
    "Minh Ngọc": "https://www.minhngoc.net.vn/ket-qua-xo-so/mien-nam/{day:%d-%m-%Y}.html",
}
SOURCE_SPEED: dict[str, float] = {}
SOURCE_TIMEOUT_SECONDS = 6
EXPECTED_PRIZES = {
    "Đặc biệt": 1, "Giải nhất": 1, "Giải nhì": 2, "Giải ba": 6,
    "Giải tư": 4, "Giải năm": 6, "Giải sáu": 3, "Giải bảy": 4,
}
PRIZE_ALIASES = {
    "đb": "Đặc biệt", "gđb": "Đặc biệt", "giải đb": "Đặc biệt", "giải đặc biệt": "Đặc biệt",
    "1": "Giải nhất", "g1": "Giải nhất", "giải nhất": "Giải nhất",
    "2": "Giải nhì", "g2": "Giải nhì", "giải nhì": "Giải nhì",
    "3": "Giải ba", "g3": "Giải ba", "giải ba": "Giải ba",
    "4": "Giải tư", "g4": "Giải tư", "giải tư": "Giải tư",
    "5": "Giải năm", "g5": "Giải năm", "giải năm": "Giải năm",
    "6": "Giải sáu", "g6": "Giải sáu", "giải sáu": "Giải sáu",
    "7": "Giải bảy", "g7": "Giải bảy", "giải bảy": "Giải bảy",
}
MN_EXPECTED_PRIZES = {
    "Giải tám": 1, "Giải bảy": 1, "Giải sáu": 3, "Giải năm": 1,
    "Giải tư": 7, "Giải ba": 2, "Giải nhì": 1, "Giải nhất": 1, "Đặc biệt": 1,
}
MN_CODE_TO_PRIZE = {"8": "Giải tám", "7": "Giải bảy", "6": "Giải sáu", "5": "Giải năm", "4": "Giải tư", "3": "Giải ba", "2": "Giải nhì", "1": "Giải nhất", "ĐB": "Đặc biệt"}
MN_WEEKLY_SCHEDULE = {
    "Thứ Hai": ["TPHCM", "Đồng Tháp", "Cà Mau"],
    "Thứ Ba": ["Bến Tre", "Vũng Tàu", "Bạc Liêu"],
    "Thứ Tư": ["Đồng Nai", "Cần Thơ", "Sóc Trăng"],
    "Thứ Năm": ["Tây Ninh", "An Giang", "Bình Thuận"],
    "Thứ Sáu": ["Vĩnh Long", "Bình Dương", "Trà Vinh"],
    "Thứ Bảy": ["TPHCM", "Long An", "Bình Phước", "Hậu Giang"],
    "Chủ Nhật": ["Tiền Giang", "Kiên Giang", "Đà Lạt"],
}
ALL_MN_PROVINCES = sorted({province for provinces in MN_WEEKLY_SCHEDULE.values() for province in provinces})

# Canonical paths and metadata live outside the presentation layer.
from . import config as _config

APP_DIR = _config.APP_DIR
DB_PATH = _config.DB_PATH
DB_BACKUP_DIR = _config.DB_BACKUP_DIR


def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA synchronous = NORMAL")
    conn.execute("PRAGMA busy_timeout = 5000")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS draws (
            draw_date TEXT PRIMARY KEY,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            draw_date TEXT NOT NULL,
            prize TEXT NOT NULL,
            position INTEGER NOT NULL,
            full_number TEXT NOT NULL,
            loto2 TEXT NOT NULL CHECK(length(loto2) = 2),
            FOREIGN KEY(draw_date) REFERENCES draws(draw_date) ON DELETE CASCADE,
            UNIQUE(draw_date, prize, position)
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_results_date_loto ON results(draw_date, loto2)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_results_loto_date ON results(loto2, draw_date)")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS mn_draws (
            draw_date TEXT NOT NULL,
            province TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY(draw_date, province)
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS mn_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            draw_date TEXT NOT NULL,
            province TEXT NOT NULL,
            prize TEXT NOT NULL,
            position INTEGER NOT NULL,
            full_number TEXT NOT NULL,
            loto2 TEXT NOT NULL CHECK(length(loto2) = 2),
            FOREIGN KEY(draw_date, province) REFERENCES mn_draws(draw_date, province) ON DELETE CASCADE,
            UNIQUE(draw_date, province, prize, position)
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_mn_results_province_date_loto ON mn_results(province, draw_date, loto2)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_mn_results_loto_date ON mn_results(loto2, draw_date)")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS sync_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            region TEXT NOT NULL,
            draw_date TEXT NOT NULL,
            source TEXT NOT NULL,
            status TEXT NOT NULL,
            details TEXT,
            synced_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_sync_log_date ON sync_log(draw_date, region)")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS source_health (
            region TEXT NOT NULL,
            source_name TEXT NOT NULL,
            avg_latency_ms REAL NOT NULL DEFAULT 999999,
            successes INTEGER NOT NULL DEFAULT 0,
            failures INTEGER NOT NULL DEFAULT 0,
            last_status TEXT,
            checked_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY(region, source_name)
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS backup_sync_state (
            backup_path TEXT PRIMARY KEY,
            file_size INTEGER NOT NULL,
            modified_ns INTEGER NOT NULL,
            imported_rows INTEGER NOT NULL DEFAULT 0,
            synced_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.execute("PRAGMA user_version = 5")
    return conn


def today_vn() -> date:
    return datetime.now(VN_TIMEZONE).date()


THEMES = {
    "Sáng rõ": {
        "bg": "#ffffff", "panel": "#ffffff", "soft": "#e8eef6",
        "text": "#111827", "muted": "#334155", "navy": "#12355b",
        "line": "#94a3b8", "accent": "#dc2626", "sidebar": "#e8eef6",
    },
    "Tối dịu": {
        "bg": "#111827", "panel": "#1f2937", "soft": "#334155",
        "text": "#f8fafc", "muted": "#dbeafe", "navy": "#93c5fd",
        "line": "#64748b", "accent": "#fb7185", "sidebar": "#172033",
    },
    "Tương phản cao": {
        "bg": "#000000", "panel": "#000000", "soft": "#172554",
        "text": "#ffffff", "muted": "#ffffff", "navy": "#fde047",
        "line": "#ffffff", "accent": "#ff4d4d", "sidebar": "#000000",
    },
}


def active_theme() -> dict[str, str]:
    """Bảng màu đang chọn; mặc định ưu tiên độ dễ đọc."""
    return THEMES.get(st.session_state.get("ui_theme", "Sáng rõ"), THEMES["Sáng rõ"])


def render_table(container, frame: pd.DataFrame, hide_index: bool = True) -> None:
    """Vẽ bảng HTML để màu chữ không bị theme trình duyệt/Streamlit ghi đè."""
    html = frame.to_html(index=not hide_index, escape=True, classes="xs-table", border=0)
    container.markdown(f'<div class="xs-table-wrap">{html}</div>', unsafe_allow_html=True)


def visible_chart(chart):
    """Đặt màu biểu đồ độc lập với dark mode của trình duyệt."""
    theme = active_theme()
    return (chart.configure(background=theme["panel"])
            .configure_axis(labelColor=theme["text"], titleColor=theme["navy"], gridColor=theme["line"], domainColor=theme["line"])
            .configure_view(stroke=theme["line"])
            .configure_legend(labelColor=theme["text"], titleColor=theme["navy"])
            .configure_title(color=theme["navy"]))


def discover_backup_databases() -> list[Path]:
    """Tìm backup trong thư mục dự án, không quét cả ổ đĩa người dùng."""
    DB_BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    candidates = list(DB_BACKUP_DIR.rglob("*.db")) + list(APP_DIR.glob("*backup*.db"))
    current = DB_PATH.resolve()
    return sorted({path.resolve() for path in candidates if path.is_file() and path.resolve() != current})


def validate_backup_database(path: Path) -> set[str]:
    """Kiểm tra SQLite toàn vẹn và trả về các bảng có thể nhập."""
    if path.stat().st_size < 100:
        raise ValueError("file quá nhỏ, không phải database hợp lệ")
    source = sqlite3.connect(str(path))
    try:
        integrity = source.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise ValueError(f"integrity_check: {integrity}")
        tables = {row[0] for row in source.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        if not ({"draws", "results"}.issubset(tables) or {"mn_draws", "mn_results"}.issubset(tables)):
            raise ValueError("không có bảng dữ liệu XSMB/XSMN phù hợp")
        return tables
    finally:
        source.close()


def merge_backup_database(conn, path: Path) -> int:
    """Gộp nhanh bằng ATTACH; dữ liệu chính thắng khi khóa duy nhất bị trùng."""
    tables = validate_backup_database(path)
    before = conn.total_changes
    conn.execute("ATTACH DATABASE ? AS source_backup", (str(path),))
    try:
        with conn:
            if {"draws", "results"}.issubset(tables):
                conn.execute("INSERT OR IGNORE INTO draws(draw_date, created_at) SELECT draw_date, created_at FROM source_backup.draws")
                conn.execute("""
                    INSERT OR IGNORE INTO results(draw_date, prize, position, full_number, loto2)
                    SELECT draw_date, prize, position, full_number, loto2 FROM source_backup.results
                """)
            if {"mn_draws", "mn_results"}.issubset(tables):
                conn.execute("INSERT OR IGNORE INTO mn_draws(draw_date, province, created_at) SELECT draw_date, province, created_at FROM source_backup.mn_draws")
                conn.execute("""
                    INSERT OR IGNORE INTO mn_results(draw_date, province, prize, position, full_number, loto2)
                    SELECT draw_date, province, prize, position, full_number, loto2 FROM source_backup.mn_results
                """)
    finally:
        conn.execute("DETACH DATABASE source_backup")
    imported = conn.total_changes - before
    stat = path.stat()
    with conn:
        conn.execute("""
            INSERT INTO backup_sync_state(backup_path, file_size, modified_ns, imported_rows, synced_at)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(backup_path) DO UPDATE SET file_size=excluded.file_size,
                modified_ns=excluded.modified_ns, imported_rows=excluded.imported_rows,
                synced_at=CURRENT_TIMESTAMP
        """, (str(path), stat.st_size, stat.st_mtime_ns, imported))
    return imported


def sync_changed_backups(conn) -> tuple[int, int, list[str]]:
    """Chỉ đồng bộ file mới hoặc đã thay đổi kể từ lần quét trước."""
    checked = imported = 0
    errors = []
    for path in discover_backup_databases():
        stat = path.stat()
        previous = conn.execute("SELECT file_size, modified_ns FROM backup_sync_state WHERE backup_path=?", (str(path),)).fetchone()
        if previous == (stat.st_size, stat.st_mtime_ns):
            continue
        checked += 1
        try:
            imported += merge_backup_database(conn, path)
        except Exception as exc:
            errors.append(f"{path.name}: {exc}")
    return checked, imported, errors


def save_uploaded_backups(files) -> list[Path]:
    """Lưu bản upload với tên an toàn vào khu vực backup để đồng bộ."""
    DB_BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    saved = []
    timestamp = datetime.now(VN_TIMEZONE).strftime("%Y%m%d-%H%M%S")
    for index, uploaded in enumerate(files, 1):
        safe_stem = re.sub(r"[^A-Za-z0-9_-]+", "-", Path(uploaded.name).stem).strip("-") or "backup"
        target = DB_BACKUP_DIR / f"{timestamp}-{index}-{safe_stem}.db"
        target.write_bytes(uploaded.getvalue())
        saved.append(target)
    return saved


def create_consolidated_backup(conn) -> Path:
    """Tạo snapshot nhất quán bằng SQLite Backup API, kể cả khi WAL đang bật."""
    DB_BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    target = DB_BACKUP_DIR / f"xsmb-xsmn-tong-hop-{datetime.now(VN_TIMEZONE):%Y%m%d-%H%M%S}.db"
    destination = sqlite3.connect(target)
    try:
        conn.backup(destination)
    finally:
        destination.close()
    return target


def install_update_zip(raw: bytes) -> tuple[str, Path]:
    """Kiểm tra và cài gói ZIP; không bao giờ đụng tới database hoặc .venv."""
    allowed = {
        "app.py", "requirements.txt", "requirements-dev.txt", "pyproject.toml", "README.md",
        "ROADMAP_COMMERCIAL.md", "sample_xsmb.csv", ".gitignore", "version.txt",
        ".streamlit/config.toml", "xsmb_manager/__init__.py", "xsmb_manager/config.py",
        "xsmb_manager/ports.py", "xsmb_manager/analytics.py", "xsmb_manager/database.py",
        "xsmb_manager/scraper.py", "xsmb_manager/services.py", "xsmb_manager/ui.py",
        "xsmb_manager/api/__init__.py", "xsmb_manager/api/settings.py", "xsmb_manager/api/models.py",
        "xsmb_manager/api/database.py", "xsmb_manager/api/schemas.py", "xsmb_manager/api/auth.py",
        "xsmb_manager/api/routes.py", "xsmb_manager/api/main.py", "scripts/migrate_sqlite_to_postgres.py",
        "Dockerfile", "Dockerfile.api", "compose.yaml", ".env.example", ".dockerignore",
        ".github/workflows/ci.yml",
    }
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        members = [item for item in archive.infolist() if not item.is_dir()]
        if not members or sum(item.file_size for item in members) > 20 * 1024 * 1024:
            raise ValueError("Gói cập nhật trống hoặc lớn hơn 20 MB")
        for item in members:
            path = Path(item.filename.replace("\\", "/"))
            if path.is_absolute() or ".." in path.parts:
                raise ValueError("ZIP chứa đường dẫn không an toàn")
        app_members = [item for item in members if Path(item.filename).name == "app.py"]
        if len(app_members) != 1:
            raise ValueError("ZIP phải chứa đúng một file app.py")
        package_parent = Path(app_members[0].filename).parent
        package = {}
        for item in members:
            try:
                relative = Path(item.filename).relative_to(package_parent).as_posix()
            except ValueError:
                continue
            if relative in allowed:
                package[relative] = item
        if not {"app.py", "requirements.txt"}.issubset(package):
            raise ValueError("Gói cập nhật thiếu app.py hoặc requirements.txt")
        version = archive.read(package["version.txt"]).decode("utf-8").strip() if "version.txt" in package else "không ghi phiên bản"
        timestamp = datetime.now(VN_TIMEZONE).strftime("%Y%m%d-%H%M%S")
        backup_dir = APP_DIR / "backups" / f"code-{timestamp}"
        backup_dir.mkdir(parents=True, exist_ok=False)
        for relative in allowed:
            current = APP_DIR / relative
            if current.exists():
                backup_target = backup_dir / relative
                backup_target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(current, backup_target)
        with tempfile.TemporaryDirectory(dir=APP_DIR) as staging:
            staging_dir = Path(staging)
            for relative, item in package.items():
                staged = staging_dir / relative
                staged.parent.mkdir(parents=True, exist_ok=True)
                staged.write_bytes(archive.read(item))
                target = APP_DIR / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                staged.replace(target)
    return version, backup_dir


def normalize_date(value) -> str:
    """Chuẩn hóa nhiều kiểu ngày về YYYY-MM-DD."""
    if pd.isna(value):
        raise ValueError("Ngày bị trống")
    if isinstance(value, (datetime, date, pd.Timestamp)):
        return pd.Timestamp(value).strftime("%Y-%m-%d")
    text = str(value).strip()
    # ISO là định dạng không nhập nhằng; xử lý riêng để tránh cảnh báo của pandas.
    if re.fullmatch(r"\d{4}-\d{1,2}-\d{1,2}", text):
        parsed = pd.to_datetime(text, format="%Y-%m-%d", errors="coerce")
        if not pd.isna(parsed):
            return parsed.strftime("%Y-%m-%d")
    for dayfirst in (True, False):
        parsed = pd.to_datetime(text, dayfirst=dayfirst, errors="coerce")
        if not pd.isna(parsed):
            return parsed.strftime("%Y-%m-%d")
    raise ValueError(f"Ngày không hợp lệ: {value}")


def extract_numbers(value) -> list[str]:
    """Tách các số trong ô; giữ số 0 ở đầu nếu CSV được đọc dạng chuỗi."""
    if pd.isna(value):
        return []
    return re.findall(r"\d+", str(value).strip())


def record_source_health(region: str, name: str, latency_ms: float, success: bool, status: str) -> None:
    """Lưu tốc độ/độ ổn định để lần sau ưu tiên nguồn tốt hơn."""
    SOURCE_SPEED[f"{region}:{name}"] = latency_ms if success else SOURCE_TIMEOUT_SECONDS * 1000
    try:
        health = sqlite3.connect(DB_PATH, timeout=2)
        old = health.execute("SELECT avg_latency_ms, successes FROM source_health WHERE region=? AND source_name=?", (region, name)).fetchone()
        average = latency_ms if not old or not old[1] else old[0] * 0.7 + latency_ms * 0.3
        with health:
            health.execute("""
                INSERT INTO source_health(region, source_name, avg_latency_ms, successes, failures, last_status, checked_at)
                VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(region, source_name) DO UPDATE SET avg_latency_ms=excluded.avg_latency_ms,
                    successes=source_health.successes+excluded.successes,
                    failures=source_health.failures+excluded.failures,
                    last_status=excluded.last_status, checked_at=CURRENT_TIMESTAMP
            """, (region, name, average, int(success), int(not success), status[:200]))
        health.close()
    except sqlite3.Error:
        pass


def parse_mb_html(content: bytes) -> dict[str, list[str]]:
    """Bộ phân tích chung cho ba nguồn XSMB, có kiểm tra độ dài từng giải."""
    soup = BeautifulSoup(content, "html.parser")
    html = content.decode("utf-8", errors="ignore")
    found: dict[str, list[str]] = {}
    lengths = {"Đặc biệt": 5, "Giải nhất": 5, "Giải nhì": 5, "Giải ba": 5, "Giải tư": 4, "Giải năm": 4, "Giải sáu": 3, "Giải bảy": 2}
    code_to_prize = {"DB": "Đặc biệt", "ĐB": "Đặc biệt", "1": "Giải nhất", "2": "Giải nhì", "3": "Giải ba", "4": "Giải tư", "5": "Giải năm", "6": "Giải sáu", "7": "Giải bảy"}

    # ID của Xoso.com.vn.
    indexed: dict[str, list[tuple[int, str]]] = {}
    for element in soup.find_all(id=re.compile(r"^mb_prize(DB|[1-7])_item\d+$", re.I)):
        match = re.match(r"^mb_prize(DB|[1-7])_item(\d+)$", element.get("id", ""), re.I)
        if match:
            prize = code_to_prize[match.group(1).upper()]
            number = re.search(rf"\d{{{lengths[prize]}}}", element.get_text(strip=True))
            if number:
                indexed.setdefault(prize, []).append((int(match.group(2)), number.group(0)))
    found.update({prize: [number for _, number in sorted(items)] for prize, items in indexed.items()})

    # Hàng G.ĐB/G.1... của Đại Phát và các bảng có nhãn giải tương tự.
    row_pattern = r'<tr[^>]*>\s*<(?:th|td)[^>]*>\s*(?:G(?:iải)?\.?\s*)?(ĐB|DB|[1-7])\s*((?:(?!<tr).)*)'
    for code, body in re.findall(row_pattern, html, re.I | re.S):
        prize = code_to_prize.get(code.upper())
        if not prize or len(found.get(prize, [])) == EXPECTED_PRIZES[prize]:
            continue
        numbers = re.findall(rf'>\s*(\d{{{lengths[prize]}}})\s*<', body)
        if len(numbers) >= EXPECTED_PRIZES[prize]:
            found[prize] = numbers[:EXPECTED_PRIZES[prize]]
    return found


def fetch_mb_from_source(day: date, name: str, template: str) -> tuple[dict[str, list[str]], str]:
    url = template.format(day=day)
    started = time.perf_counter()
    response = requests.get(
        url,
        timeout=SOURCE_TIMEOUT_SECONDS,
        headers={"User-Agent": "Mozilla/5.0 (XSMB-XSMN Manager/2.5)"},
    )
    response.raise_for_status()
    found = parse_mb_html(response.content)
    latency = (time.perf_counter() - started) * 1000
    record_source_health("XSMB", name, latency, bool(found), f"{sum(map(len, found.values()))}/27 số")
    return found, url


def ordered_sources(region: str, sources: dict[str, str]) -> list[tuple[str, str]]:
    """Ưu tiên nguồn có độ trễ trung bình thấp; nguồn chưa đo được thử theo thứ tự khai báo."""
    persisted = {}
    try:
        health = sqlite3.connect(DB_PATH)
        persisted = {name: latency for name, latency in health.execute("SELECT source_name, avg_latency_ms FROM source_health WHERE region=?", (region,))}
        health.close()
    except sqlite3.Error:
        pass
    return sorted(sources.items(), key=lambda item: (persisted.get(item[0], SOURCE_SPEED.get(f"{region}:{item[0]}", 999999)), list(sources).index(item[0])))


def fetch_online_snapshot(day: date) -> tuple[dict[str, list[str]], str]:
    """Tự chuyển nguồn nếu quá 6 giây, lỗi mạng hoặc không nhận được số."""
    errors = []
    for name, template in ordered_sources("XSMB", MB_SOURCES):
        started = time.perf_counter()
        try:
            found, url = fetch_mb_from_source(day, name, template)
            if found:
                return found, url
            raise ValueError("không nhận diện được kết quả")
        except Exception as exc:
            record_source_health("XSMB", name, (time.perf_counter() - started) * 1000, False, str(exc))
            errors.append(f"{name}: {exc}")
    raise ValueError("Tất cả nguồn XSMB đều lỗi: " + " | ".join(errors))


def fetch_online_draw(day: date) -> tuple[list[tuple[str, int, str]], str]:
    """Tải kết quả theo ngày; chỉ trả về khi đủ đúng 27 số."""
    errors = []
    for name, template in ordered_sources("XSMB", MB_SOURCES):
        try:
            found, url = fetch_mb_from_source(day, name, template)
            missing = [f"{prize} ({len(found.get(prize, []))}/{count})" for prize, count in EXPECTED_PRIZES.items() if len(found.get(prize, [])) != count]
            if missing:
                raise ValueError("thiếu " + ", ".join(missing))
            results = [(prize, pos, number) for prize, expected in EXPECTED_PRIZES.items() for pos, number in enumerate(found[prize][:expected], 1)]
            return results, url
        except Exception as exc:
            errors.append(f"{name}: {exc}")
    raise ValueError("Không nguồn XSMB nào có đủ kết quả: " + " | ".join(errors))


def result_board_html(found: dict[str, list[str]]) -> str:
    """Tạo bảng kết quả trực tiếp; dữ liệu nguồn đã được giới hạn chỉ còn chữ số."""
    rows = []
    short_names = {"Đặc biệt": "ĐB", "Giải nhất": "G1", "Giải nhì": "G2", "Giải ba": "G3", "Giải tư": "G4", "Giải năm": "G5", "Giải sáu": "G6", "Giải bảy": "G7"}
    for prize, count in EXPECTED_PRIZES.items():
        values = found.get(prize, [])
        cells = []
        for index in range(count):
            value = values[index] if index < len(values) else "•••••"
            css = "live-number highlight" if prize in {"Đặc biệt", "Giải bảy"} else "live-number"
            cells.append(f'<span class="{css}">{value}</span>')
        rows.append(f'<div class="live-row"><div class="prize-label">{short_names[prize]}</div><div class="number-grid n{count}">{"".join(cells)}</div></div>')
    return '<div class="live-board">' + "".join(rows) + '</div>'


@st.fragment(run_every="30s")
def render_live_today() -> None:
    """Chỉ phần trực tiếp tự tải lại, tránh tính lại toàn bộ biểu đồ."""
    day = today_vn()
    header_left, header_right = st.columns([3, 1])
    header_left.subheader(f"XSMB trực tiếp hôm nay · {day.strftime('%d/%m/%Y')}")
    header_right.success("Tự lưu: BẬT")
    try:
        found, url = fetch_online_snapshot(day)
        received = sum(len(v) for v in found.values())
        st.markdown(result_board_html(found), unsafe_allow_html=True)
        complete = all(len(found.get(prize, [])) == count for prize, count in EXPECTED_PRIZES.items())
        now_text = datetime.now(VN_TIMEZONE).strftime("%H:%M:%S")
        if complete:
            results = [(prize, pos, number) for prize in EXPECTED_PRIZES for pos, number in enumerate(found[prize], 1)]
            online_conn = connect()
            upsert_draw(online_conn, day.isoformat(), results)
            online_conn.close()
            st.success(f"Đã nhận đủ 27 số · cập nhật lúc {now_text} · đã lưu database")
        else:
            st.info(f"Đang chờ kết quả: {received}/27 số · tự làm mới mỗi 30 giây · lần kiểm tra {now_text}")
        st.caption(f"Nguồn trực tuyến: {url}")
    except Exception as exc:
        st.warning(f"Chưa lấy được kết quả trực tiếp: {exc}")


def parse_xsmn_html(html: str) -> dict[str, dict[str, list[str]]]:
    """Phân tích bảng nhiều đài từ các nguồn XSMN phổ biến."""
    lengths = {"Giải tám": 2, "Giải bảy": 3, "Giải sáu": 4, "Giải năm": 4, "Giải tư": 5, "Giải ba": 5, "Giải nhì": 5, "Giải nhất": 5, "Đặc biệt": 6}
    tables = re.findall(r'<table[^>]*>(.*?)</table>', html, re.I | re.S)
    for table in tables:
        if not re.search(r'(?:G\.?\s*)?(?:8|ĐB)', table, re.I):
            continue
        provinces = re.findall(r'title=["\']Xổ số\s+([^"\']+)', table, re.I)
        if not provinces:
            provinces = [re.sub(r'<[^>]+>', '', value).strip() for value in re.findall(r'<h3[^>]*>\s*<a[^>]*>(.*?)</a>', table, re.I | re.S)]
        provinces = list(dict.fromkeys(p for p in provinces if p and len(p) < 40))
        if not 2 <= len(provinces) <= 4:
            continue
        found = {province: {} for province in provinces}
        row_pattern = r'<tr[^>]*>\s*<(?:th|td)[^>]*>\s*(?:G\.?\s*)?(ĐB|[1-8])\s*((?:(?!<tr).)*)'
        for code, body in re.findall(row_pattern, table, re.I | re.S):
            prize = MN_CODE_TO_PRIZE.get(code.upper())
            if not prize:
                continue
            cells = re.split(r'<td[^>]*>', body, flags=re.I)[1:]
            for province, cell in zip(provinces, cells):
                numbers = re.findall(r'data-loto=["\']?(\d{2,6})', cell, re.I)
                if not numbers:
                    numbers = re.findall(rf'>\s*(\d{{{lengths[prize]}}})\s*<', cell)
                found[province][prize] = numbers[:MN_EXPECTED_PRIZES[prize]]
        if sum(sum(len(v) for v in prizes.values()) for prizes in found.values()):
            return found
    return {}


def fetch_xsmn_snapshot(day: date) -> tuple[dict[str, dict[str, list[str]]], str]:
    """Tự chuyển nguồn XSMN khi nguồn ưu tiên chậm, lỗi hoặc không có dữ liệu."""
    errors = []
    for name, template in ordered_sources("XSMN", MN_SOURCES):
        url = template.format(day=day)
        started = time.perf_counter()
        try:
            response = requests.get(url, timeout=SOURCE_TIMEOUT_SECONDS, headers={"User-Agent": "Mozilla/5.0 (XSMB-XSMN Manager/2.5)"})
            response.raise_for_status()
            found = parse_xsmn_html(response.text)
            if not found:
                raise ValueError("không nhận diện được bảng nhiều đài")
            latency = (time.perf_counter() - started) * 1000
            count = sum(sum(len(v) for v in prizes.values()) for prizes in found.values())
            record_source_health("XSMN", name, latency, True, f"{count} số")
            return found, url
        except Exception as exc:
            record_source_health("XSMN", name, (time.perf_counter() - started) * 1000, False, str(exc))
            errors.append(f"{name}: {exc}")
    raise ValueError("Tất cả nguồn XSMN đều lỗi: " + " | ".join(errors))


def upsert_mn_draw(conn, draw_date: str, province: str, prizes: dict[str, list[str]]) -> None:
    """Lưu hoặc thay thế một đài miền Nam trong một ngày."""
    rows = [(prize, pos, number) for prize in MN_EXPECTED_PRIZES for pos, number in enumerate(prizes.get(prize, []), 1)]
    if len(rows) != 18:
        raise ValueError(f"{province} chưa đủ 18 số")
    with conn:
        conn.execute("INSERT OR IGNORE INTO mn_draws(draw_date, province) VALUES (?, ?)", (draw_date, province))
        conn.execute("DELETE FROM mn_results WHERE draw_date=? AND province=?", (draw_date, province))
        conn.executemany(
            "INSERT INTO mn_results(draw_date, province, prize, position, full_number, loto2) VALUES (?, ?, ?, ?, ?, ?)",
            [(draw_date, province, prize, pos, number, number.zfill(2)[-2:]) for prize, pos, number in rows],
        )


def load_mn_results(conn) -> pd.DataFrame:
    return pd.read_sql_query(
        "SELECT draw_date, province, prize, position, full_number, loto2 FROM mn_results ORDER BY draw_date DESC, province, prize, position",
        conn, parse_dates=["draw_date"],
    )


def update_xsmn_range(conn, start_day: date, end_day: date) -> tuple[int, list[str]]:
    successes, errors = 0, []
    for stamp in pd.date_range(start_day, end_day):
        day = stamp.date()
        try:
            found, _ = fetch_xsmn_snapshot(day)
            saved = 0
            for province, prizes in found.items():
                if all(len(prizes.get(prize, [])) == count for prize, count in MN_EXPECTED_PRIZES.items()):
                    upsert_mn_draw(conn, day.isoformat(), province, prizes)
                    saved += 1
            if not saved:
                raise ValueError("chưa có đài nào đủ 18 số")
            with conn:
                conn.execute("INSERT INTO sync_log(region, draw_date, source, status, details) VALUES ('XSMN', ?, ?, 'success', ?)", (day.isoformat(), XSMN_SOURCE.format(day=day), f"{saved} đài"))
            successes += saved
        except Exception as exc:
            errors.append(f"{day.strftime('%d/%m/%Y')}: {exc}")
    return successes, errors


def run_daily_catchup(conn) -> list[str]:
    """Tự bù tối đa 3 ngày kể từ kỳ cuối; bỏ qua database hoàn toàn mới."""
    messages = []
    today = today_vn()
    mb_last = conn.execute("SELECT MAX(draw_date) FROM draws").fetchone()[0]
    if mb_last:
        start = max(pd.Timestamp(mb_last).date() + pd.Timedelta(days=1), today - pd.Timedelta(days=2))
        if start <= today:
            saved, _ = update_online_range(conn, start, today)
            if saved:
                messages.append(f"Tự bù {saved} kỳ XSMB")
    mn_last = conn.execute("SELECT MAX(draw_date) FROM mn_draws").fetchone()[0]
    if mn_last:
        start = max(pd.Timestamp(mn_last).date() + pd.Timedelta(days=1), today - pd.Timedelta(days=2))
        if start <= today:
            saved, _ = update_xsmn_range(conn, start, today)
            if saved:
                messages.append(f"Tự bù {saved} lượt đài XSMN")
    return messages


def xsmn_board_html(found: dict[str, dict[str, list[str]]]) -> str:
    provinces = list(found)
    header = '<tr><th>Giải</th>' + ''.join(f'<th>{p}</th>' for p in provinces) + '</tr>'
    short = {"Giải tám":"G8", "Giải bảy":"G7", "Giải sáu":"G6", "Giải năm":"G5", "Giải tư":"G4", "Giải ba":"G3", "Giải nhì":"G2", "Giải nhất":"G1", "Đặc biệt":"ĐB"}
    rows = []
    for prize, count in MN_EXPECTED_PRIZES.items():
        cells = []
        for province in provinces:
            values = found[province].get(prize, [])
            shown = values if values else ["•••••"] * count
            cls = "mn-hot" if prize in {"Giải tám", "Đặc biệt"} else ""
            cells.append(f'<td class="{cls}">' + '<br>'.join(shown) + '</td>')
        rows.append(f'<tr><th>{short[prize]}</th>{"".join(cells)}</tr>')
    return f'<div class="mn-board"><table>{header}{"".join(rows)}</table></div>'


@st.fragment(run_every="30s")
def render_live_south() -> None:
    day = today_vn()
    left, right = st.columns([3, 1])
    left.subheader(f"XSMN trực tiếp hôm nay · {day.strftime('%d/%m/%Y')}")
    right.success("Tự lưu: BẬT")
    try:
        found, url = fetch_xsmn_snapshot(day)
        st.markdown(xsmn_board_html(found), unsafe_allow_html=True)
        completed = []
        for province, prizes in found.items():
            if all(len(prizes.get(prize, [])) == count for prize, count in MN_EXPECTED_PRIZES.items()):
                completed.append(province)
                live_conn = connect()
                upsert_mn_draw(live_conn, day.isoformat(), province, prizes)
                live_conn.close()
        now_text = datetime.now(VN_TIMEZONE).strftime("%H:%M:%S")
        if len(completed) == len(found):
            st.success(f"Đã đủ {len(completed)} đài · cập nhật {now_text} · đã lưu database")
        else:
            st.info(f"Đã đủ {len(completed)}/{len(found)} đài · tự làm mới mỗi 30 giây · {now_text}")
        st.caption(f"Nguồn trực tuyến: {url}")
    except Exception as exc:
        st.warning(f"Chưa lấy được XSMN trực tiếp: {exc}")


def render_yesterday_mb(conn) -> None:
    """Hiển thị XSMB hôm qua, ưu tiên database rồi mới tải Internet."""
    day = today_vn() - pd.Timedelta(days=1)
    rows = conn.execute(
        "SELECT prize, position, full_number FROM results WHERE draw_date=? ORDER BY position",
        (day.isoformat(),),
    ).fetchall()
    found: dict[str, list[tuple[int, str]]] = {}
    for prize, position, number in rows:
        if prize in EXPECTED_PRIZES:
            found.setdefault(prize, []).append((position, number))
    normalized = {prize: [number for _, number in sorted(values)] for prize, values in found.items()}
    if not all(len(normalized.get(prize, [])) == count for prize, count in EXPECTED_PRIZES.items()):
        try:
            results, _ = fetch_online_draw(day)
            upsert_draw(conn, day.isoformat(), results)
            normalized = {}
            for prize, position, number in results:
                normalized.setdefault(prize, []).append(number)
        except Exception as exc:
            st.info(f"Chưa có kết quả XSMB ngày {day.strftime('%d/%m/%Y')}: {exc}")
            return
    st.markdown(result_board_html(normalized), unsafe_allow_html=True)
    st.caption(f"XSMB ngày {day.strftime('%d/%m/%Y')} · đã lưu trong database")


def render_yesterday_mn(conn) -> None:
    """Hiển thị tất cả đài XSMN hôm qua, ưu tiên database."""
    day = today_vn() - pd.Timedelta(days=1)
    rows = conn.execute(
        "SELECT province, prize, position, full_number FROM mn_results WHERE draw_date=? ORDER BY province, prize, position",
        (day.isoformat(),),
    ).fetchall()
    found: dict[str, dict[str, list[tuple[int, str]]]] = {}
    for province, prize, position, number in rows:
        found.setdefault(province, {}).setdefault(prize, []).append((position, number))
    normalized = {
        province: {prize: [number for _, number in sorted(values)] for prize, values in prizes.items()}
        for province, prizes in found.items()
    }
    complete = normalized and all(
        all(len(prizes.get(prize, [])) == count for prize, count in MN_EXPECTED_PRIZES.items())
        for prizes in normalized.values()
    )
    if not complete:
        try:
            normalized, _ = fetch_xsmn_snapshot(day)
            complete_provinces = {}
            for province, prizes in normalized.items():
                if all(len(prizes.get(prize, [])) == count for prize, count in MN_EXPECTED_PRIZES.items()):
                    upsert_mn_draw(conn, day.isoformat(), province, prizes)
                    complete_provinces[province] = prizes
            normalized = complete_provinces
        except Exception as exc:
            st.info(f"Chưa có kết quả XSMN ngày {day.strftime('%d/%m/%Y')}: {exc}")
            return
    if not normalized:
        st.info(f"Chưa có đài XSMN đầy đủ ngày {day.strftime('%d/%m/%Y')}")
        return
    st.markdown(xsmn_board_html(normalized), unsafe_allow_html=True)
    st.caption(f"XSMN ngày {day.strftime('%d/%m/%Y')} · {', '.join(normalized)} · đã lưu trong database")


def update_online_range(conn, start_day: date, end_day: date) -> tuple[int, list[str]]:
    """Cập nhật tuần tự một khoảng ngày, trả về số kỳ thành công và lỗi."""
    successes, errors = 0, []
    for stamp in pd.date_range(start_day, end_day):
        day = stamp.date()
        try:
            results, _ = fetch_online_draw(day)
            upsert_draw(conn, day.isoformat(), results)
            with conn:
                conn.execute("INSERT INTO sync_log(region, draw_date, source, status, details) VALUES ('XSMB', ?, ?, 'success', '27 số')", (day.isoformat(), ONLINE_SOURCE.format(day=day)))
            successes += 1
        except Exception as exc:
            errors.append(f"{day.strftime('%d/%m/%Y')}: {exc}")
    return successes, errors


def parse_csv(raw: bytes) -> tuple[list[tuple[str, list[tuple[str, int, str]]]], list[str]]:
    """Đọc CSV dạng rộng (các giải là cột) hoặc dạng date + lô 2 số."""
    last_error = None
    for encoding in ("utf-8-sig", "utf-8", "cp1258", "latin1"):
        try:
            df = pd.read_csv(io.BytesIO(raw), dtype=str, encoding=encoding, sep=None, engine="python")
            break
        except Exception as exc:
            last_error = exc
    else:
        raise ValueError(f"Không đọc được CSV: {last_error}")

    if df.empty:
        raise ValueError("File CSV không có dữ liệu")
    df.columns = [str(c).strip() for c in df.columns]
    date_col = next((c for c in df.columns if c.lower() in DATE_CANDIDATES), None)
    if date_col is None:
        raise ValueError("Không tìm thấy cột ngày (date/ngay/ngày/draw_date)")

    value_cols = [c for c in df.columns if c != date_col]
    if not value_cols:
        raise ValueError("CSV cần có ít nhất một cột kết quả")

    draws, warnings = [], []
    for row_no, (_, row) in enumerate(df.iterrows(), start=2):
        try:
            draw_date = normalize_date(row[date_col])
        except ValueError as exc:
            warnings.append(f"Dòng {row_no}: {exc}; đã bỏ qua")
            continue
        results: list[tuple[str, int, str]] = []
        for col in value_cols:
            for pos, number in enumerate(extract_numbers(row[col]), start=1):
                results.append((col, pos, number))
        if results:
            draws.append((draw_date, results))
        else:
            warnings.append(f"Dòng {row_no}: không có số; đã bỏ qua")
    return draws, warnings


def upsert_draw(conn, draw_date: str, results: list[tuple[str, int, str]]) -> None:
    """Thay thế kết quả của ngày nếu ngày đó đã tồn tại."""
    if not results:
        raise ValueError("Cần nhập ít nhất một số")
    with conn:
        conn.execute("INSERT OR IGNORE INTO draws(draw_date) VALUES (?)", (draw_date,))
        conn.execute("DELETE FROM results WHERE draw_date = ?", (draw_date,))
        conn.executemany(
            "INSERT INTO results(draw_date, prize, position, full_number, loto2) VALUES (?, ?, ?, ?, ?)",
            [(draw_date, prize, pos, num, num.zfill(2)[-2:]) for prize, pos, num in results],
        )


def load_draws(conn) -> pd.DataFrame:
    return pd.read_sql_query(
        "SELECT draw_date, prize, position, full_number, loto2 FROM results ORDER BY draw_date DESC, prize, position",
        conn,
        parse_dates=["draw_date"],
    )


def statistics(df: pd.DataFrame, total_draws: int, latest_date: pd.Timestamp) -> pd.DataFrame:
    counts = df.groupby("loto2").size() if not df.empty else pd.Series(dtype=int)
    last_seen = df.groupby("loto2")["draw_date"].max() if not df.empty else pd.Series(dtype="datetime64[ns]")
    rows = []
    for n in (f"{i:02d}" for i in range(100)):
        last = last_seen.get(n, pd.NaT)
        gap = (latest_date - last).days if pd.notna(last) else None
        freq = int(counts.get(n, 0))
        rows.append({"Số": n, "Số lần xuất hiện": freq, "Số ngày gan": gap, "Xác suất ước lượng": freq / total_draws if total_draws else 0.0})
    return pd.DataFrame(rows)


def probability_ranking(df: pd.DataFrame, total_draws: int) -> pd.DataFrame:
    """Tỷ lệ thực nghiệm: phần trăm kỳ có xuất hiện số, luôn nằm trong 0–100%."""
    if df.empty or not total_draws:
        present = pd.Series(dtype=int)
        last_10 = pd.Series(dtype=int)
    else:
        present = df.drop_duplicates(["draw_date", "loto2"]).groupby("loto2").size()
        recent_dates = sorted(df["draw_date"].unique())[-10:]
        recent = df[df["draw_date"].isin(recent_dates)].drop_duplicates(["draw_date", "loto2"])
        last_10 = recent.groupby("loto2").size()
    recent_denominator = min(10, total_draws)
    rows = []
    for number in (f"{i:02d}" for i in range(100)):
        hits = int(present.get(number, 0))
        recent_hits = int(last_10.get(number, 0))
        # Làm trơn Laplace để tránh tỷ lệ cực đoan khi mẫu dữ liệu nhỏ.
        historical = (hits + 1) / (total_draws + 2)
        recent_rate = (recent_hits + 1) / (recent_denominator + 2)
        estimated_next = 0.7 * historical + 0.3 * recent_rate
        rows.append({
            "Số": number,
            "Số kỳ xuất hiện": hits,
            "Tỷ lệ kỳ có số": hits / total_draws,
            "Tỷ lệ 10 kỳ gần nhất": recent_hits / recent_denominator if recent_denominator else 0,
            "Xác suất mô hình kỳ tới": estimated_next,
        })
    return pd.DataFrame(rows).sort_values(["Xác suất mô hình kỳ tới", "Số"], ascending=[False, True])


def walk_forward_backtest(df: pd.DataFrame, min_train: int = 30) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Đánh giá đúng thứ tự thời gian; mỗi kỳ chỉ dùng dữ liệu của các kỳ trước."""
    dates = sorted(pd.to_datetime(df["draw_date"].unique()))
    if len(dates) <= min_train:
        return pd.DataFrame(), pd.DataFrame()
    date_index = {stamp: index for index, stamp in enumerate(dates)}
    matrix = np.zeros((len(dates), 100), dtype=float)
    for draw_date, loto in df[["draw_date", "loto2"]].drop_duplicates().itertuples(index=False):
        matrix[date_index[pd.Timestamp(draw_date)], int(loto)] = 1.0
    records = []
    decay = np.log(2) / 30  # chu kỳ bán rã 30 kỳ
    for index in range(min_train, len(dates)):
        history, actual = matrix[:index], matrix[index]
        bayes = (history.sum(axis=0) + 1) / (index + 2)
        recent_size = min(10, index)
        recent = (history[-recent_size:].sum(axis=0) + 1) / (recent_size + 2)
        ages = np.arange(index - 1, -1, -1)
        weights = np.exp(-decay * ages)
        ewma = (history * weights[:, None]).sum(axis=0) / weights.sum()
        predictions = {
            "Bayes dài hạn": bayes,
            "Tần suất 10 kỳ": recent,
            "EWMA bán rã 30 kỳ": ewma,
            "Hybrid 70/30": 0.7 * bayes + 0.3 * recent,
        }
        for model, probability in predictions.items():
            top10 = np.argsort(-probability)[:10]
            records.append({
                "Ngày kiểm tra": dates[index].strftime("%Y-%m-%d"),
                "Mô hình": model,
                "Top 10 trúng ít nhất 1 số": int(actual[top10].sum() > 0),
                "Số trúng trong Top 10": int(actual[top10].sum()),
                "Brier score": float(np.mean((probability - actual) ** 2)),
            })
    history_frame = pd.DataFrame(records)
    summary = history_frame.groupby("Mô hình", as_index=False).agg(
        **{
            "Số kỳ backtest": ("Ngày kiểm tra", "count"),
            "Tỷ lệ kỳ Top 10 có trúng": ("Top 10 trúng ít nhất 1 số", "mean"),
            "Trung bình số trúng/Top 10": ("Số trúng trong Top 10", "mean"),
            "Brier score": ("Brier score", "mean"),
        }
    ).sort_values(["Brier score", "Tỷ lệ kỳ Top 10 có trúng"], ascending=[True, False])
    return summary, history_frame


def adaptive_top4(df: pd.DataFrame, min_train: int = 30) -> tuple[pd.DataFrame, str, dict]:
    """Chọn mô hình backtest tốt nhất rồi xếp bốn số cho kỳ kế tiếp."""
    dates = sorted(pd.to_datetime(df["draw_date"].unique()))
    if not dates:
        return pd.DataFrame(), "Không đủ dữ liệu", {}
    date_index = {stamp: index for index, stamp in enumerate(dates)}
    matrix = np.zeros((len(dates), 100), dtype=float)
    for draw_date, loto in df[["draw_date", "loto2"]].drop_duplicates().itertuples(index=False):
        matrix[date_index[pd.Timestamp(draw_date)], int(loto)] = 1.0
    count = len(dates)
    bayes = (matrix.sum(axis=0) + 1) / (count + 2)
    recent_size = min(10, count)
    recent = (matrix[-recent_size:].sum(axis=0) + 1) / (recent_size + 2)
    ages = np.arange(count - 1, -1, -1)
    weights = np.exp(-(np.log(2) / 30) * ages)
    ewma = (matrix * weights[:, None]).sum(axis=0) / weights.sum()
    predictions = {
        "Bayes dài hạn": bayes,
        "Tần suất 10 kỳ": recent,
        "EWMA bán rã 30 kỳ": ewma,
        "Hybrid 70/30": 0.7 * bayes + 0.3 * recent,
    }
    summary, _ = walk_forward_backtest(df, min_train)
    if summary.empty:
        model = "Hybrid 70/30"
        evidence = {"mode": "fallback", "draws": count}
    else:
        best = summary.iloc[0]
        model = str(best["Mô hình"])
        evidence = {
            "mode": "backtest", "draws": count,
            "test_draws": int(best["Số kỳ backtest"]),
            "brier": float(best["Brier score"]),
            "top10_hit_rate": float(best["Tỷ lệ kỳ Top 10 có trúng"]),
        }
    probability = predictions[model]
    order = np.argsort(-probability)[:4]
    ranking = pd.DataFrame({
        "Hạng": np.arange(1, 5),
        "Số": [f"{number:02d}" for number in order],
        "Xác suất mô hình": probability[order],
    })
    return ranking, model, evidence


# Bind UI orchestration to the dependency implementations.  Keeping these names
# preserves the established page code while making the underlying logic testable.
from .analytics import (
    adaptive_top4,
    extract_numbers,
    normalize_date,
    parse_csv,
    probability_ranking,
    statistics,
    walk_forward_backtest,
)
from .database import connect, load_draws, load_mn_results, upsert_draw, upsert_mn_draw
from .scraper import fetch_online_draw, fetch_online_snapshot, fetch_xsmn_snapshot


def render_sidebar(conn) -> None:
    st.sidebar.header("Nhập dữ liệu")
    st.sidebar.subheader("Cập nhật trực tuyến")
    online_mode = st.sidebar.radio("Phạm vi", ["Một ngày", "Khoảng ngày"], horizontal=True)
    if online_mode == "Một ngày":
        online_start = online_end = st.sidebar.date_input("Ngày cần lấy", value=today_vn(), format="DD/MM/YYYY", key="online_one")
    else:
        online_dates = st.sidebar.date_input("Khoảng cần lấy", value=(today_vn(), today_vn()), format="DD/MM/YYYY", key="online_range")
        online_start, online_end = (online_dates if isinstance(online_dates, (tuple, list)) and len(online_dates) == 2 else (None, None))
    if st.sidebar.button("Cập nhật từ Internet", use_container_width=True, disabled=online_start is None):
        with st.spinner("Đang tải và kiểm tra kết quả..."):
            successes, errors = update_online_range(conn, online_start, online_end)
        if successes:
            st.sidebar.success(f"Đã cập nhật {successes} kỳ.")
        for error in errors[:3]:
            st.sidebar.warning(error)
        if len(errors) > 3:
            st.sidebar.info(f"Còn {len(errors) - 3} ngày không cập nhật được.")
        if successes:
            st.rerun()

    st.sidebar.success("Tự lưu kết quả hằng ngày: BẬT")
    st.sidebar.caption("XSMB · chỉ lưu khi đủ 27 số")
    if st.sidebar.button("Cập nhật XSMN cùng khoảng ngày", use_container_width=True, disabled=online_start is None):
        with st.spinner("Đang tải các đài miền Nam..."):
            mn_successes, mn_errors = update_xsmn_range(conn, online_start, online_end)
        if mn_successes:
            st.sidebar.success(f"Đã cập nhật {mn_successes} lượt đài XSMN.")
        for error in mn_errors[:3]:
            st.sidebar.warning(error)
        if mn_successes:
            st.rerun()
    st.sidebar.caption("XSMN · mỗi đài chỉ lưu khi đủ 18 số")
    st.sidebar.divider()

    st.sidebar.subheader("Nạp file CSV")
    upload = st.sidebar.file_uploader("Chọn file CSV", type="csv")
    if st.sidebar.button("Nạp CSV", disabled=upload is None, use_container_width=True):
        try:
            draws, warnings = parse_csv(upload.getvalue())
            for draw_date, results in draws:
                upsert_draw(conn, draw_date, results)
            st.sidebar.success(f"Đã nạp {len(draws)} kỳ quay.")
            for warning in warnings[:5]:
                st.sidebar.warning(warning)
            if len(warnings) > 5:
                st.sidebar.info(f"Còn {len(warnings) - 5} cảnh báo khác.")
            st.rerun()
        except Exception as exc:
            st.sidebar.error(str(exc))

    st.sidebar.divider()
    st.sidebar.subheader("Thêm / sửa một kỳ")
    with st.sidebar.form("manual"):
        draw_day = st.date_input("Ngày quay", value=today_vn(), format="DD/MM/YYYY")
        numbers_text = st.text_area("Các số trúng", placeholder="VD: 12345, 23456, 07, 08\nCó thể cách nhau bằng dấu phẩy hoặc khoảng trắng")
        submitted = st.form_submit_button("Lưu kết quả", use_container_width=True)
    if submitted:
        numbers = extract_numbers(numbers_text)
        if not numbers:
            st.sidebar.error("Hãy nhập ít nhất một số.")
        else:
            upsert_draw(conn, draw_day.isoformat(), [("Nhập tay", i, n) for i, n in enumerate(numbers, 1)])
            st.sidebar.success("Đã lưu. Nếu ngày đã tồn tại, dữ liệu cũ đã được thay thế.")
            st.rerun()

    st.sidebar.divider()
    st.sidebar.subheader(f"Cập nhật phần mềm · v{APP_VERSION}")
    update_zip = st.sidebar.file_uploader("Chọn gói cập nhật ZIP", type="zip", key="software_update_zip")
    confirm_update = st.sidebar.checkbox("Tôi đã sao lưu xsmb.db", key="confirm_software_update")
    if st.sidebar.button("Cài bản cập nhật", disabled=update_zip is None or not confirm_update, use_container_width=True):
        try:
            version, backup_dir = install_update_zip(update_zip.getvalue())
            st.sidebar.success(f"Đã cài phiên bản {version}. Mã cũ nằm trong {backup_dir.name}.")
            st.sidebar.warning("Nhấn Ctrl+C trong Terminal rồi chạy lại app để áp dụng hoàn toàn.")
        except (ValueError, zipfile.BadZipFile, OSError) as exc:
            st.sidebar.error(f"Không cài được: {exc}")


def main() -> None:
    st.set_page_config(page_title="Quản lý XSMB & XSMN", page_icon="🎟️", layout="wide")
    st.sidebar.subheader("🎨 Chỉnh màu giao diện")
    st.sidebar.radio(
        "Chế độ hiển thị",
        list(THEMES),
        key="ui_theme",
        help="Nếu bảng khó đọc, hãy chọn Tương phản cao.",
    )
    theme = active_theme()
    st.title("Quản lý lịch sử XSMB & XSMN")
    st.caption("Trực tiếp · tự lưu hằng ngày · thống kê lô 2 số · xuất và sao lưu dữ liệu")
    interface_css = """
    <style>
    :root { --navy:__NAVY__; --red:__ACCENT__; --soft:__SOFT__; --line:__LINE__; --background-color:__BG__!important; --secondary-background-color:__SOFT__!important; --text-color:__TEXT__!important; color-scheme:__SCHEME__!important; }
    html,body,.stApp,[data-testid="stAppViewContainer"],[data-testid="stMain"] { background:__BG__!important; color:__TEXT__!important; }
    [data-testid="stSidebar"],[data-testid="stSidebarContent"] { background:__SIDEBAR__!important; color:__TEXT__!important; }
    [data-testid="stAppViewContainer"] p,[data-testid="stAppViewContainer"] label,[data-testid="stAppViewContainer"] li,[data-testid="stSidebar"] span { color:__TEXT__!important; }
    [data-baseweb="tab-list"],[data-baseweb="tab-panel"] { background:__BG__!important; color:__TEXT__!important; }
    h1,h2,h3 { color:var(--navy); letter-spacing:-.02em; }
    [data-testid="stMetric"] { background:__PANEL__; color:__TEXT__; border:1px solid var(--line); border-radius:14px; padding:14px; box-shadow:0 4px 16px rgba(18,53,91,.10); }
    .live-board { background:__PANEL__; border:1px solid var(--line); border-radius:16px; overflow:hidden; box-shadow:0 8px 26px rgba(18,53,91,.09); }
    .live-row { display:grid; grid-template-columns:76px 1fr; min-height:64px; border-bottom:1px solid var(--line); }
    .live-row:last-child { border-bottom:0; }
    .prize-label { display:flex; align-items:center; justify-content:center; background:var(--soft); border-right:1px solid var(--line); color:var(--navy); font-weight:800; font-size:18px; }
    .number-grid { display:grid; align-items:stretch; }
    .number-grid.n1 { grid-template-columns:1fr; }.number-grid.n2 { grid-template-columns:repeat(2,1fr); }
    .number-grid.n3 { grid-template-columns:repeat(3,1fr); }.number-grid.n4 { grid-template-columns:repeat(4,1fr); }
    .number-grid.n6 { grid-template-columns:repeat(3,1fr); }
    .live-number { display:flex; align-items:center; justify-content:center; min-height:56px; padding:7px; border-right:1px solid var(--line); color:__TEXT__; font-size:clamp(22px,3vw,34px); font-weight:800; font-variant-numeric:tabular-nums; }
    .number-grid.n6 .live-number { border-bottom:1px solid #edf1f6; }
    .live-number.highlight { color:var(--red); }
    .number-grid.n1 .live-number { font-size:clamp(30px,4vw,46px); }
    .mn-board { overflow-x:auto; background:__PANEL__; border:1px solid var(--line); border-radius:16px; box-shadow:0 8px 26px rgba(18,53,91,.09); }
    .mn-board table { width:100%; border-collapse:collapse; text-align:center; font-variant-numeric:tabular-nums; }
    .mn-board th { background:var(--soft); color:var(--navy); font-weight:800; }
    .mn-board th,.mn-board td { border:1px solid var(--line); padding:10px; min-width:125px; }
    .mn-board td { color:__TEXT__; font-size:clamp(18px,2.2vw,27px); line-height:1.55; font-weight:800; }
    .mn-board td.mn-hot { color:var(--red); }
    .xs-table-wrap { max-height:520px; overflow:auto; border:2px solid var(--line); border-radius:12px; background:__PANEL__; margin:.35rem 0 1rem; }
    table.xs-table { width:100%; border-collapse:collapse; background:__PANEL__!important; color:__TEXT__!important; font-variant-numeric:tabular-nums; }
    table.xs-table thead th { position:sticky; top:0; z-index:1; background:__SOFT__!important; color:__NAVY__!important; font-weight:900; }
    table.xs-table th,table.xs-table td { padding:10px 12px; border:1px solid var(--line)!important; color:__TEXT__!important; background:__PANEL__!important; text-align:left; white-space:nowrap; }
    table.xs-table tbody tr:nth-child(even) td { background:__SOFT__!important; }
    @media(max-width:640px){.live-row{grid-template-columns:52px 1fr}.prize-label{font-size:15px}.live-number{font-size:19px;padding:5px}.number-grid.n6{grid-template-columns:repeat(2,1fr)}}
    </style>
    """
    replacements = {
        "__BG__": theme["bg"], "__PANEL__": theme["panel"],
        "__SOFT__": theme["soft"], "__TEXT__": theme["text"],
        "__NAVY__": theme["navy"], "__LINE__": theme["line"],
        "__ACCENT__": theme["accent"], "__SIDEBAR__": theme["sidebar"],
        "__SCHEME__": "dark" if st.session_state.ui_theme == "Tối dịu" else "light",
    }
    for token, color in replacements.items():
        interface_css = interface_css.replace(token, color)
    st.markdown(interface_css, unsafe_allow_html=True)
    conn = connect()
    if not st.session_state.get("backup_sync_done"):
        st.session_state["backup_sync_done"] = True
        checked_backups, imported_rows, backup_errors = sync_changed_backups(conn)
        if checked_backups and not backup_errors:
            st.toast(f"Đã kiểm tra {checked_backups} backup · thêm {imported_rows} bản ghi", icon="🔄")
        elif backup_errors:
            st.session_state["backup_sync_errors"] = backup_errors
    if not st.session_state.get("daily_catchup_done"):
        st.session_state["daily_catchup_done"] = True
        with st.spinner("Đang kiểm tra dữ liệu hằng ngày..."):
            catchup_messages = run_daily_catchup(conn)
        if catchup_messages:
            st.toast(" · ".join(catchup_messages), icon="✅")
    render_sidebar(conn)
    live_mb, live_mn = st.tabs(["🔴 Trực tiếp Miền Bắc", "🔴 Trực tiếp Miền Nam"])
    with live_mb:
        render_live_today()
        with st.expander("📅 Xem kết quả Miền Bắc hôm qua", expanded=True):
            render_yesterday_mb(conn)
    with live_mn:
        render_live_south()
        with st.expander("📅 Xem kết quả các đài Miền Nam hôm qua", expanded=True):
            render_yesterday_mn(conn)
    st.divider()
    all_data = load_draws(conn)

    if all_data.empty:
        st.info("Chưa có dữ liệu. Hãy nạp CSV hoặc thêm một kỳ quay ở thanh bên trái.")
        st.stop()

    min_date, max_date = all_data["draw_date"].min().date(), all_data["draw_date"].max().date()
    c1, c2 = st.columns([2, 1])
    selected = c1.date_input("Khoảng ngày", value=(min_date, max_date), min_value=min_date, max_value=max_date, format="DD/MM/YYYY")
    n_days = c2.number_input("Top 10 trong N ngày gần nhất", min_value=1, max_value=10000, value=min(30, (max_date - min_date).days + 1))
    if not isinstance(selected, (tuple, list)) or len(selected) != 2:
        st.warning("Hãy chọn đủ ngày bắt đầu và ngày kết thúc.")
        st.stop()
    start, end = pd.Timestamp(selected[0]), pd.Timestamp(selected[1])
    filtered = all_data[all_data["draw_date"].between(start, end)].copy()
    draw_count = filtered["draw_date"].nunique()

    m1, m2, m3 = st.columns(3)
    m1.metric("Số kỳ trong bộ lọc", draw_count)
    m2.metric("Tổng lượt lô 2 số", len(filtered))
    m3.metric("Ngày mới nhất", max_date.strftime("%d/%m/%Y"))

    stats = statistics(filtered, draw_count, end)
    recent_start = pd.Timestamp(max_date) - pd.Timedelta(days=int(n_days) - 1)
    recent = all_data[all_data["draw_date"].between(recent_start, pd.Timestamp(max_date))]
    recent_stats = statistics(recent, recent["draw_date"].nunique(), pd.Timestamp(max_date))

    tab1, tab2, tab3, tab4, tab5, tab6, tab7 = st.tabs(["XSMB 00–99", "Top 10 MB", "Ước lượng MB", "Dữ liệu MB", "Xuất data", "XSMN theo đài", "Backtest mô hình"])
    with tab1:
        chart = alt.Chart(stats).mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3).encode(
            x=alt.X("Số:N", sort=None, axis=alt.Axis(labelAngle=0)),
            y=alt.Y("Số lần xuất hiện:Q"),
            color=alt.Color("Số lần xuất hiện:Q", scale=alt.Scale(scheme="blues"), legend=None),
            tooltip=["Số", "Số lần xuất hiện", "Số ngày gan", alt.Tooltip("Xác suất ước lượng:Q", format=".2%")],
        ).properties(height=360)
        st.altair_chart(visible_chart(chart), use_container_width=True)
        shown = stats.copy()
        shown["Xác suất ước lượng"] = shown["Xác suất ước lượng"].map(lambda x: f"{x:.2%}")
        shown["Số ngày gan"] = shown["Số ngày gan"].map(lambda value: "Chưa xuất hiện" if pd.isna(value) else str(int(value)))
        render_table(st, shown)
    with tab2:
        left, right = st.columns(2)
        most = recent_stats.sort_values(["Số lần xuất hiện", "Số"], ascending=[False, True]).head(10)
        least = recent_stats.sort_values(["Số lần xuất hiện", "Số"], ascending=[True, True]).head(10)
        for box, title, frame, scheme in ((left, "Về nhiều nhất", most, "greens"), (right, "Về ít nhất", least, "oranges")):
            box.subheader(f"{title} trong {int(n_days)} ngày")
            ch = alt.Chart(frame).mark_bar().encode(
                x=alt.X("Số lần xuất hiện:Q"), y=alt.Y("Số:N", sort="-x"),
                color=alt.Color("Số lần xuất hiện:Q", scale=alt.Scale(scheme=scheme), legend=None), tooltip=["Số", "Số lần xuất hiện"]
            ).properties(height=300)
            box.altair_chart(visible_chart(ch), use_container_width=True)
            render_table(box, frame[["Số", "Số lần xuất hiện", "Số ngày gan"]])
    with tab3:
        prediction_base = filtered["draw_date"].max()
        next_draw = prediction_base + pd.Timedelta(days=1)
        st.subheader(f"Ước lượng cho kỳ ngày {next_draw.strftime('%d/%m/%Y')}")
        st.warning("Đây là tỷ lệ do mô hình thống kê lịch sử ước lượng, không phải xác suất thật hoặc cam kết trúng. Mỗi kỳ xổ số vẫn là một sự kiện ngẫu nhiên.")
        if draw_count < 30:
            st.info(f"Bộ lọc hiện chỉ có {draw_count} kỳ. Nên dùng ít nhất 30 kỳ, tốt hơn là 90–365 kỳ, để tỷ lệ bớt dao động.")
        top4, selected_model, top4_evidence = adaptive_top4(filtered)
        st.markdown("### Top 4 mô hình cho kỳ kế tiếp")
        top4_columns = st.columns(4)
        for column, (_, candidate) in zip(top4_columns, top4.iterrows()):
            column.metric(f"Hạng {int(candidate['Hạng'])} · Số {candidate['Số']}", f"{candidate['Xác suất mô hình']:.2%}")
        if top4_evidence.get("mode") == "backtest":
            st.caption(f"Chọn bằng {selected_model} · backtest {top4_evidence['test_draws']} kỳ · Brier {top4_evidence['brier']:.4f} · tỷ lệ Top 10 có ít nhất một số: {top4_evidence['top10_hit_rate']:.2%}.")
        else:
            st.caption(f"Tạm dùng {selected_model} vì mới có {top4_evidence.get('draws', 0)} kỳ, chưa đủ để chọn mô hình bằng backtest.")
        ranking = probability_ranking(filtered, draw_count).head(20).copy()
        top_numbers = ranking.head(10)["Số"].tolist()
        st.markdown("**10 số có tỷ lệ mô hình cao nhất:** " + " · ".join(top_numbers))
        chart = alt.Chart(ranking.head(10)).mark_bar().encode(
            x=alt.X("Xác suất mô hình kỳ tới:Q", axis=alt.Axis(format="%")),
            y=alt.Y("Số:N", sort="-x"),
            color=alt.Color("Xác suất mô hình kỳ tới:Q", scale=alt.Scale(scheme="tealblues"), legend=None),
            tooltip=["Số", "Số kỳ xuất hiện", alt.Tooltip("Tỷ lệ kỳ có số:Q", format=".2%"), alt.Tooltip("Tỷ lệ 10 kỳ gần nhất:Q", format=".2%"), alt.Tooltip("Xác suất mô hình kỳ tới:Q", format=".2%")],
        ).properties(height=360)
        st.altair_chart(visible_chart(chart), use_container_width=True)
        for col in ["Tỷ lệ kỳ có số", "Tỷ lệ 10 kỳ gần nhất", "Xác suất mô hình kỳ tới"]:
            ranking[col] = ranking[col].map(lambda x: f"{x:.2%}")
        render_table(st, ranking)
        st.caption("Xác suất mô hình = 70% tỷ lệ lịch sử đã làm trơn + 30% tỷ lệ 10 kỳ gần nhất đã làm trơn. Ngày kỳ tới được tính là ngày sau kỳ mới nhất trong bộ lọc.")
    with tab4:
        display = filtered.copy()
        display["draw_date"] = display["draw_date"].dt.strftime("%d/%m/%Y")
        display.columns = ["Ngày", "Giải / cột CSV", "Vị trí", "Số đầy đủ", "Lô 2 số"]
        render_table(st, display)
        st.download_button("Tải dữ liệu đang lọc (CSV)", display.to_csv(index=False).encode("utf-8-sig"), "xsmb-da-loc.csv", "text/csv")
    with tab5:
        st.subheader("Chất lượng dữ liệu")
        expected_rows = draw_count * 27
        complete_dates = filtered.groupby("draw_date").size().eq(27).sum() if draw_count else 0
        q1, q2, q3 = st.columns(3)
        q1.metric("Kỳ đủ 27 số", f"{complete_dates}/{draw_count}")
        q2.metric("Dòng dữ liệu", f"{len(filtered)}/{expected_rows}")
        q3.metric("Độ phủ", f"{len(filtered)/expected_rows:.1%}" if expected_rows else "0%")
        if complete_dates == draw_count:
            st.success("Tất cả kỳ trong bộ lọc đều đủ 27 số.")
        else:
            st.warning("Có kỳ thiếu hoặc thừa số. Hãy cập nhật lại ngày đó từ nguồn trực tuyến hoặc CSV chuẩn.")
        st.subheader("Xuất và sao lưu")
        raw_export = filtered.copy()
        raw_export["draw_date"] = raw_export["draw_date"].dt.strftime("%Y-%m-%d")
        stats_export = stats.copy()
        ranking_export = probability_ranking(filtered, draw_count)
        e1, e2, e3, e4 = st.columns(4)
        e1.download_button("Dữ liệu gốc CSV", raw_export.to_csv(index=False).encode("utf-8-sig"), "xsmb-du-lieu-goc.csv", "text/csv", use_container_width=True)
        e2.download_button("Thống kê 00–99", stats_export.to_csv(index=False).encode("utf-8-sig"), "xsmb-thong-ke.csv", "text/csv", use_container_width=True)
        e3.download_button("Ước lượng kỳ tới", ranking_export.to_csv(index=False).encode("utf-8-sig"), "xsmb-uoc-luong.csv", "text/csv", use_container_width=True)
        if DB_PATH.exists():
            e4.download_button("Sao lưu SQLite", DB_PATH.read_bytes(), f"xsmb-backup-{today_vn().isoformat()}.db", "application/x-sqlite3", use_container_width=True)
        st.divider()
        st.subheader("Đồng bộ các database backup")
        st.caption("Database chính được bổ sung các bản ghi còn thiếu; backup gốc không bị sửa và không ghi đè dữ liệu hiện tại khi trùng khóa.")
        discovered = discover_backup_databases()
        sync_state = pd.read_sql_query("SELECT backup_path AS 'File', imported_rows AS 'Đã thêm', synced_at AS 'Đồng bộ lúc' FROM backup_sync_state ORDER BY synced_at DESC", conn)
        s1, s2, s3 = st.columns(3)
        s1.metric("Backup tìm thấy", len(discovered))
        s2.metric("Backup đã ghi nhận", len(sync_state))
        s3.metric("Tổng dòng đã nhập", int(sync_state["Đã thêm"].sum()) if not sync_state.empty else 0)
        if not sync_state.empty:
            sync_state["File"] = sync_state["File"].map(lambda value: Path(value).name)
            render_table(st, sync_state)
        for error in st.session_state.get("backup_sync_errors", []):
            st.warning(error)
        uploaded_databases = st.file_uploader("Thêm một hoặc nhiều database backup", type=["db", "sqlite", "sqlite3"], accept_multiple_files=True, key="backup_db_uploads")
        b1, b2 = st.columns(2)
        if b1.button("Lưu và đồng bộ file tải lên", disabled=not uploaded_databases, use_container_width=True):
            try:
                save_uploaded_backups(uploaded_databases)
                checked, imported, errors = sync_changed_backups(conn)
                if errors:
                    for error in errors:
                        st.error(error)
                else:
                    st.success(f"Đã kiểm tra {checked} database và thêm {imported} bản ghi còn thiếu.")
                    st.rerun()
            except Exception as exc:
                st.error(f"Đồng bộ thất bại: {exc}")
        if b2.button("Quét lại thư mục backup", use_container_width=True):
            checked, imported, errors = sync_changed_backups(conn)
            if errors:
                for error in errors:
                    st.error(error)
            else:
                st.success(f"Đã kiểm tra {checked} file thay đổi và thêm {imported} bản ghi.")
                st.rerun()
        if st.button("Tạo database tổng hợp mới", use_container_width=True):
            consolidated = create_consolidated_backup(conn)
            st.success(f"Đã tạo {consolidated.name}")
            st.download_button("Tải database tổng hợp", consolidated.read_bytes(), consolidated.name, "application/x-sqlite3", use_container_width=True)
    with tab6:
        st.subheader("Lịch mở thưởng 21 đài Miền Nam trong tuần")
        schedule_frame = pd.DataFrame([
            {"Ngày": weekday, "Các đài mở thưởng": " · ".join(provinces)}
            for weekday, provinces in MN_WEEKLY_SCHEDULE.items()
        ])
        render_table(st, schedule_frame)
        mn_data = load_mn_results(conn)
        province = st.selectbox("Chọn một trong 21 tỉnh/đài để tham khảo", ALL_MN_PROVINCES)
        province_data = mn_data[mn_data["province"] == province].copy() if not mn_data.empty else pd.DataFrame()
        if province_data.empty:
            weekday = next(day for day, provinces in MN_WEEKLY_SCHEDULE.items() if province in provinces)
            st.info(f"Đài {province} mở thưởng vào {weekday}. Database chưa có dữ liệu đài này; hãy chọn khoảng ngày phù hợp rồi bấm ‘Cập nhật XSMN cùng khoảng ngày’ ở thanh bên.")
        else:
            mn_min, mn_max = province_data["draw_date"].min().date(), province_data["draw_date"].max().date()
            mn_dates = st.date_input("Khoảng ngày XSMN", value=(mn_min, mn_max), min_value=mn_min, max_value=mn_max, format="DD/MM/YYYY", key="mn_stats_dates")
            if isinstance(mn_dates, (tuple, list)) and len(mn_dates) == 2:
                mn_filtered = province_data[province_data["draw_date"].between(pd.Timestamp(mn_dates[0]), pd.Timestamp(mn_dates[1]))].copy()
                mn_draw_count = mn_filtered["draw_date"].nunique()
                mn_stats = statistics(mn_filtered, mn_draw_count, pd.Timestamp(mn_dates[1]))
                mn_rank = probability_ranking(mn_filtered, mn_draw_count)
                a, b, c = st.columns(3)
                a.metric("Đài", province)
                b.metric("Số kỳ", mn_draw_count)
                c.metric("Kỳ đủ 18 số", int(mn_filtered.groupby("draw_date").size().eq(18).sum()))
                mn_top4, mn_model, mn_evidence = adaptive_top4(mn_filtered)
                st.markdown("### Top 4 mô hình cho kỳ kế tiếp")
                mn_top_columns = st.columns(4)
                for column, (_, candidate) in zip(mn_top_columns, mn_top4.iterrows()):
                    column.metric(f"Hạng {int(candidate['Hạng'])} · Số {candidate['Số']}", f"{candidate['Xác suất mô hình']:.2%}")
                if mn_evidence.get("mode") == "backtest":
                    st.caption(f"Đài {province} · {mn_model} · backtest {mn_evidence['test_draws']} kỳ · Brier {mn_evidence['brier']:.4f}.")
                else:
                    st.caption(f"Đài {province} tạm dùng {mn_model}; cần trên 30 kỳ để chọn mô hình bằng backtest.")
                st.markdown("**Top 10 tỷ lệ mô hình kỳ tới:** " + " · ".join(mn_rank.head(10)["Số"].tolist()))
                mn_chart = alt.Chart(mn_rank.head(10)).mark_bar().encode(
                    x=alt.X("Xác suất mô hình kỳ tới:Q", axis=alt.Axis(format="%")),
                    y=alt.Y("Số:N", sort="-x"),
                    color=alt.Color("Xác suất mô hình kỳ tới:Q", scale=alt.Scale(scheme="tealblues"), legend=None),
                    tooltip=["Số", "Số kỳ xuất hiện", alt.Tooltip("Tỷ lệ kỳ có số:Q", format=".2%")],
                ).properties(height=340)
                st.altair_chart(visible_chart(mn_chart), use_container_width=True)
                show_rank = mn_rank.head(20).copy()
                for col in ["Tỷ lệ kỳ có số", "Tỷ lệ 10 kỳ gần nhất", "Xác suất mô hình kỳ tới"]:
                    show_rank[col] = show_rank[col].map(lambda x: f"{x:.2%}")
                render_table(st, show_rank)
                d1, d2 = st.columns(2)
                export_mn = mn_filtered.copy()
                export_mn["draw_date"] = export_mn["draw_date"].dt.strftime("%Y-%m-%d")
                d1.download_button("Xuất dữ liệu đài CSV", export_mn.to_csv(index=False).encode("utf-8-sig"), f"xsmn-{province}.csv", "text/csv", use_container_width=True)
                d2.download_button("Xuất thống kê đài CSV", mn_stats.to_csv(index=False).encode("utf-8-sig"), f"xsmn-thong-ke-{province}.csv", "text/csv", use_container_width=True)
    with tab7:
        st.subheader("Kiểm chứng mô hình bằng dữ liệu quá khứ")
        st.caption("Walk-forward không cho mô hình nhìn thấy tương lai: dự báo mỗi kỳ chỉ được tính từ các kỳ đứng trước nó.")
        min_train = st.number_input("Số kỳ huấn luyện tối thiểu", min_value=20, max_value=365, value=30, step=10)
        summary, backtest_history = walk_forward_backtest(filtered, int(min_train))
        if summary.empty:
            st.info(f"Cần nhiều hơn {int(min_train)} kỳ trong bộ lọc để chạy backtest.")
        else:
            shown_summary = summary.copy()
            shown_summary["Tỷ lệ kỳ Top 10 có trúng"] = shown_summary["Tỷ lệ kỳ Top 10 có trúng"].map(lambda value: f"{value:.2%}")
            shown_summary["Trung bình số trúng/Top 10"] = shown_summary["Trung bình số trúng/Top 10"].map(lambda value: f"{value:.2f}")
            shown_summary["Brier score"] = shown_summary["Brier score"].map(lambda value: f"{value:.4f}")
            render_table(st, shown_summary)
            best = summary.iloc[0]
            st.info(f"Theo Brier score thấp nhất trong giai đoạn đã chọn: {best['Mô hình']} ({best['Brier score']:.4f}). Kết quả này chỉ mô tả backtest, không bảo đảm kỳ tương lai.")
            test_chart = alt.Chart(summary).mark_bar().encode(
                x=alt.X("Brier score:Q", title="Brier score (thấp hơn tốt hơn)"),
                y=alt.Y("Mô hình:N", sort="x"),
                color=alt.Color("Brier score:Q", scale=alt.Scale(scheme="redyellowgreen", reverse=True), legend=None),
                tooltip=["Mô hình", alt.Tooltip("Brier score:Q", format=".4f"), alt.Tooltip("Tỷ lệ kỳ Top 10 có trúng:Q", format=".2%")],
            ).properties(height=260)
            st.altair_chart(visible_chart(test_chart), use_container_width=True)
            st.download_button("Xuất chi tiết backtest CSV", backtest_history.to_csv(index=False).encode("utf-8-sig"), "xsmb-backtest-mo-hinh.csv", "text/csv", use_container_width=True)

        st.subheader("Tình trạng các nguồn dữ liệu")
        source_frame = pd.read_sql_query("SELECT region AS 'Miền', source_name AS 'Nguồn', ROUND(avg_latency_ms) AS 'Độ trễ ms', successes AS 'Thành công', failures AS 'Thất bại', last_status AS 'Lần cuối', checked_at AS 'Kiểm tra lúc' FROM source_health ORDER BY region, avg_latency_ms", conn)
        if source_frame.empty:
            st.info("Chưa đủ lần tải để đo tốc độ nguồn.")
        else:
            render_table(st, source_frame)
            st.caption(f"Nguồn phản hồi quá {SOURCE_TIMEOUT_SECONDS} giây, lỗi mạng hoặc không đọc được kết quả sẽ bị bỏ qua để chuyển sang nguồn kế tiếp.")
