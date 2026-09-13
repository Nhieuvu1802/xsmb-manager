"""SQLite implementation of the repository boundary."""

from __future__ import annotations

import sqlite3
from pathlib import Path

import pandas as pd

from .config import DB_PATH, MN_EXPECTED_PRIZES
from .ports import MBPrizeMap, MBResult


SCHEMA = """
CREATE TABLE IF NOT EXISTS draws (draw_date TEXT PRIMARY KEY, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS results (
 id INTEGER PRIMARY KEY AUTOINCREMENT, draw_date TEXT NOT NULL, prize TEXT NOT NULL,
 position INTEGER NOT NULL, full_number TEXT NOT NULL, loto2 TEXT NOT NULL CHECK(length(loto2) = 2),
 FOREIGN KEY(draw_date) REFERENCES draws(draw_date) ON DELETE CASCADE, UNIQUE(draw_date, prize, position));
CREATE INDEX IF NOT EXISTS idx_results_date_loto ON results(draw_date, loto2);
CREATE INDEX IF NOT EXISTS idx_results_loto_date ON results(loto2, draw_date);
CREATE TABLE IF NOT EXISTS mn_draws (
 draw_date TEXT NOT NULL, province TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(draw_date, province));
CREATE TABLE IF NOT EXISTS mn_results (
 id INTEGER PRIMARY KEY AUTOINCREMENT, draw_date TEXT NOT NULL, province TEXT NOT NULL, prize TEXT NOT NULL,
 position INTEGER NOT NULL, full_number TEXT NOT NULL, loto2 TEXT NOT NULL CHECK(length(loto2) = 2),
 FOREIGN KEY(draw_date, province) REFERENCES mn_draws(draw_date, province) ON DELETE CASCADE,
 UNIQUE(draw_date, province, prize, position));
CREATE INDEX IF NOT EXISTS idx_mn_results_province_date_loto ON mn_results(province, draw_date, loto2);
CREATE INDEX IF NOT EXISTS idx_mn_results_loto_date ON mn_results(loto2, draw_date);
CREATE TABLE IF NOT EXISTS sync_log (
 id INTEGER PRIMARY KEY AUTOINCREMENT, region TEXT NOT NULL, draw_date TEXT NOT NULL, source TEXT NOT NULL,
 status TEXT NOT NULL, details TEXT, synced_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE INDEX IF NOT EXISTS idx_sync_log_date ON sync_log(draw_date, region);
CREATE TABLE IF NOT EXISTS source_health (
 region TEXT NOT NULL, source_name TEXT NOT NULL, avg_latency_ms REAL NOT NULL DEFAULT 999999,
 successes INTEGER NOT NULL DEFAULT 0, failures INTEGER NOT NULL DEFAULT 0, last_status TEXT,
 checked_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(region, source_name));
CREATE TABLE IF NOT EXISTS backup_sync_state (
 backup_path TEXT PRIMARY KEY, file_size INTEGER NOT NULL, modified_ns INTEGER NOT NULL,
 imported_rows INTEGER NOT NULL DEFAULT 0, synced_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
"""


def connect(path: Path | str = DB_PATH) -> sqlite3.Connection:
    connection = sqlite3.connect(path)
    connection.execute("PRAGMA foreign_keys = ON")
    connection.execute("PRAGMA journal_mode = WAL")
    connection.execute("PRAGMA synchronous = NORMAL")
    connection.execute("PRAGMA busy_timeout = 5000")
    connection.executescript(SCHEMA)
    connection.execute("PRAGMA user_version = 5")
    return connection


class SQLiteLotteryRepository:
    """Repository backed by an injected SQLite connection."""

    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection

    def upsert_mb_draw(self, draw_date: str, results: list[MBResult]) -> None:
        if not results:
            raise ValueError("Cần nhập ít nhất một số")
        with self.connection:
            self.connection.execute("INSERT OR IGNORE INTO draws(draw_date) VALUES (?)", (draw_date,))
            self.connection.execute("DELETE FROM results WHERE draw_date = ?", (draw_date,))
            self.connection.executemany(
                "INSERT INTO results(draw_date, prize, position, full_number, loto2) VALUES (?, ?, ?, ?, ?)",
                [(draw_date, prize, position, number, number.zfill(2)[-2:]) for prize, position, number in results],
            )

    def upsert_mn_draw(self, draw_date: str, province: str, prizes: MBPrizeMap) -> None:
        rows = [(prize, position, number) for prize in MN_EXPECTED_PRIZES
                for position, number in enumerate(prizes.get(prize, []), 1)]
        if len(rows) != 18:
            raise ValueError(f"{province} chưa đủ 18 số")
        with self.connection:
            self.connection.execute("INSERT OR IGNORE INTO mn_draws(draw_date, province) VALUES (?, ?)", (draw_date, province))
            self.connection.execute("DELETE FROM mn_results WHERE draw_date=? AND province=?", (draw_date, province))
            self.connection.executemany(
                "INSERT INTO mn_results(draw_date, province, prize, position, full_number, loto2) VALUES (?, ?, ?, ?, ?, ?)",
                [(draw_date, province, prize, position, number, number.zfill(2)[-2:]) for prize, position, number in rows],
            )

    def log_sync(self, region: str, draw_date: str, source: str, details: str) -> None:
        with self.connection:
            self.connection.execute(
                "INSERT INTO sync_log(region, draw_date, source, status, details) VALUES (?, ?, ?, 'success', ?)",
                (region, draw_date, source, details),
            )

    def load_mb_results(self) -> pd.DataFrame:
        return pd.read_sql_query(
            "SELECT draw_date, prize, position, full_number, loto2 FROM results ORDER BY draw_date DESC, prize, position",
            self.connection, parse_dates=["draw_date"])

    def load_mn_results(self) -> pd.DataFrame:
        return pd.read_sql_query(
            "SELECT draw_date, province, prize, position, full_number, loto2 FROM mn_results ORDER BY draw_date DESC, province, prize, position",
            self.connection, parse_dates=["draw_date"])


# Compatibility helpers keep the Streamlit layer small while preserving its API.
def upsert_draw(connection, draw_date: str, results: list[MBResult]) -> None:
    SQLiteLotteryRepository(connection).upsert_mb_draw(draw_date, results)


def upsert_mn_draw(connection, draw_date: str, province: str, prizes: MBPrizeMap) -> None:
    SQLiteLotteryRepository(connection).upsert_mn_draw(draw_date, province, prizes)


def load_draws(connection) -> pd.DataFrame:
    return SQLiteLotteryRepository(connection).load_mb_results()


def load_mn_results(connection) -> pd.DataFrame:
    return SQLiteLotteryRepository(connection).load_mn_results()
