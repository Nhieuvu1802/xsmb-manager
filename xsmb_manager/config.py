"""Application configuration and lottery metadata."""

from pathlib import Path
from zoneinfo import ZoneInfo

APP_DIR = Path(__file__).resolve().parent.parent
DB_PATH = APP_DIR / "xsmb.db"
DB_BACKUP_DIR = APP_DIR / "backups" / "database"
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
MN_EXPECTED_PRIZES = {
    "Giải tám": 1, "Giải bảy": 1, "Giải sáu": 3, "Giải năm": 1,
    "Giải tư": 7, "Giải ba": 2, "Giải nhì": 1, "Giải nhất": 1, "Đặc biệt": 1,
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
