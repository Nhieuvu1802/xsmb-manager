"""Application configuration and lottery metadata."""

from pathlib import Path
from zoneinfo import ZoneInfo

PACKAGE_DIR = Path(__file__).resolve().parent
BACKEND_DIR = PACKAGE_DIR.parent


def _detect_repo_root(backend_dir: Path) -> Path:
    """Trả về gốc monorepo khi có `mobile/` hoặc `web/`, ngược lại là `backend/`.

    Nhờ vậy cùng một mã nguồn chạy đúng khi đặt trong repo
    (`backend/xsmb_manager`), trong Docker (`/app/xsmb_manager`) hay khi copy
    riêng thư mục backend.
    """

    parent = backend_dir.parent
    if (parent / "mobile").is_dir() or (parent / "web").is_dir():
        return parent
    return backend_dir


REPO_ROOT = _detect_repo_root(BACKEND_DIR)

# Dữ liệu runtime (database, backup, gói phát hành) nằm ngoài source code.
DATA_DIR = REPO_ROOT / "data"
DB_BACKUP_DIR = DATA_DIR / "backups" / "database"
CODE_BACKUP_DIR = DATA_DIR / "backups" / "code"


def resolve_db_path() -> Path:
    """Ưu tiên `data/xsmb.db`, vẫn nhận file `xsmb.db` cũ chưa di chuyển."""

    preferred = DATA_DIR / "xsmb.db"
    for candidate in (preferred, REPO_ROOT / "xsmb.db", BACKEND_DIR / "xsmb.db"):
        if candidate.is_file():
            return candidate
    return preferred


DB_PATH = resolve_db_path()
APP_DIR = BACKEND_DIR
APP_VERSION = "2.7.0"
VN_TIMEZONE = ZoneInfo("Asia/Ho_Chi_Minh")
DATE_CANDIDATES = {"date", "ngay", "ngày", "draw_date", "ngay_quay"}
SOURCE_TIMEOUT_SECONDS = 6

MB_SOURCES = {
    "Xoso.com.vn": "https://xoso.com.vn/xsmb-{day:%d-%m-%Y}.html",
    "Xổ Số Đại Phát": "https://xosodaiphat.com/xsmb-{day:%d-%m-%Y}.html",
    "Minh Ngọc": "https://www.minhngoc.net.vn/ket-qua-xo-so/mien-bac/{day:%d-%m-%Y}.html",
}
MN_SOURCES = {
    "Xoso.com.vn": "https://xoso.com.vn/xsmn-{day:%d-%m-%Y}.html",
    "Xổ Số Đại Phát": "https://xosodaiphat.com/xsmn-{day:%d-%m-%Y}.html",
    "Minh Ngọc": "https://www.minhngoc.net.vn/ket-qua-xo-so/mien-nam/{day:%d-%m-%Y}.html",
}
ONLINE_SOURCE = MB_SOURCES["Xoso.com.vn"]
XSMN_SOURCE = MN_SOURCES["Xoso.com.vn"]

EXPECTED_PRIZES = {
    "Đặc biệt": 1, "Giải nhất": 1, "Giải nhì": 2, "Giải ba": 6,
    "Giải tư": 4, "Giải năm": 6, "Giải sáu": 3, "Giải bảy": 4,
}
MB_PRIZE_LENGTHS = {
    "Đặc biệt": 5, "Giải nhất": 5, "Giải nhì": 5, "Giải ba": 5,
    "Giải tư": 4, "Giải năm": 4, "Giải sáu": 3, "Giải bảy": 2,
}
MN_EXPECTED_PRIZES = {
    "Giải tám": 1, "Giải bảy": 1, "Giải sáu": 3, "Giải năm": 1,
    "Giải tư": 7, "Giải ba": 2, "Giải nhì": 1, "Giải nhất": 1, "Đặc biệt": 1,
}
MN_PRIZE_LENGTHS = {
    "Giải tám": 2, "Giải bảy": 3, "Giải sáu": 4, "Giải năm": 4,
    "Giải tư": 5, "Giải ba": 5, "Giải nhì": 5, "Giải nhất": 5,
    "Đặc biệt": 6,
}
MN_CODE_TO_PRIZE = {
    "8": "Giải tám", "7": "Giải bảy", "6": "Giải sáu", "5": "Giải năm",
    "4": "Giải tư", "3": "Giải ba", "2": "Giải nhì", "1": "Giải nhất", "ĐB": "Đặc biệt",
}
MN_WEEKLY_SCHEDULE = {
    "Thứ Hai": ["TPHCM", "Đồng Tháp", "Cà Mau"],
    "Thứ Ba": ["Bến Tre", "Vũng Tàu", "Bạc Liêu"],
    "Thứ Tư": ["Đồng Nai", "Cần Thơ", "Sóc Trăng"],
    "Thứ Năm": ["Tây Ninh", "An Giang", "Bình Thuận"],
    "Thứ Sáu": ["Vĩnh Long", "Bình Dương", "Trà Vinh"],
    "Thứ Bảy": ["TPHCM", "Long An", "Bình Phước", "Hậu Giang"],
    "Chủ Nhật": ["Tiền Giang", "Kiên Giang", "Đà Lạt"],
}
ALL_MN_PROVINCES = sorted({p for provinces in MN_WEEKLY_SCHEDULE.values() for p in provinces})
