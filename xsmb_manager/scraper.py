"""HTTP/HTML implementation of the scraper boundary."""

from __future__ import annotations

import re
import sqlite3
import time
from datetime import date

import requests
from bs4 import BeautifulSoup

from .config import DB_PATH, EXPECTED_PRIZES, MB_SOURCES, MN_CODE_TO_PRIZE, MN_EXPECTED_PRIZES, MN_SOURCES, SOURCE_TIMEOUT_SECONDS

SOURCE_SPEED: dict[str, float] = {}


def parse_mb_html(content: bytes) -> dict[str, list[str]]:
    soup, html = BeautifulSoup(content, "html.parser"), content.decode("utf-8", errors="ignore")
    found: dict[str, list[str]] = {}
    lengths = {"Đặc biệt": 5, "Giải nhất": 5, "Giải nhì": 5, "Giải ba": 5, "Giải tư": 4, "Giải năm": 4, "Giải sáu": 3, "Giải bảy": 2}
    codes = {"DB": "Đặc biệt", "ĐB": "Đặc biệt", "1": "Giải nhất", "2": "Giải nhì", "3": "Giải ba", "4": "Giải tư", "5": "Giải năm", "6": "Giải sáu", "7": "Giải bảy"}
    indexed: dict[str, list[tuple[int, str]]] = {}
    for element in soup.find_all(id=re.compile(r"^mb_prize(DB|[1-7])_item\d+$", re.I)):
        match = re.match(r"^mb_prize(DB|[1-7])_item(\d+)$", element.get("id", ""), re.I)
        if match:
            prize = codes[match.group(1).upper()]
            number = re.search(rf"\d{{{lengths[prize]}}}", element.get_text(strip=True))
            if number:
                indexed.setdefault(prize, []).append((int(match.group(2)), number.group(0)))
    found.update({prize: [number for _, number in sorted(items)] for prize, items in indexed.items()})
    pattern = r'<tr[^>]*>\s*<(?:th|td)[^>]*>\s*(?:G(?:iải)?\.?\s*)?(ĐB|DB|[1-7])\s*((?:(?!<tr).)*)'
    for code, body in re.findall(pattern, html, re.I | re.S):
        prize = codes.get(code.upper())
        if prize and len(found.get(prize, [])) != EXPECTED_PRIZES[prize]:
            numbers = re.findall(rf'>\s*(\d{{{lengths[prize]}}})\s*<', body)
            if len(numbers) >= EXPECTED_PRIZES[prize]:
                found[prize] = numbers[:EXPECTED_PRIZES[prize]]
    return found


def parse_xsmn_html(html: str) -> dict[str, dict[str, list[str]]]:
    lengths = {"Giải tám": 2, "Giải bảy": 3, "Giải sáu": 4, "Giải năm": 4, "Giải tư": 5, "Giải ba": 5, "Giải nhì": 5, "Giải nhất": 5, "Đặc biệt": 6}
    for table in re.findall(r'<table[^>]*>(.*?)</table>', html, re.I | re.S):
        if not re.search(r'(?:G\.?\s*)?(?:8|ĐB)', table, re.I):
            continue
        provinces = re.findall(r'title=["\']Xổ số\s+([^"\']+)', table, re.I)
        if not provinces:
            provinces = [re.sub(r'<[^>]+>', '', value).strip() for value in re.findall(r'<h3[^>]*>\s*<a[^>]*>(.*?)</a>', table, re.I | re.S)]
        provinces = list(dict.fromkeys(p for p in provinces if p and len(p) < 40))
        if not 2 <= len(provinces) <= 4:
            continue
        found = {province: {} for province in provinces}
        for code, body in re.findall(r'<tr[^>]*>\s*<(?:th|td)[^>]*>\s*(?:G\.?\s*)?(ĐB|[1-8])\s*((?:(?!<tr).)*)', table, re.I | re.S):
            prize = MN_CODE_TO_PRIZE.get(code.upper())
            if not prize:
                continue
            for province, cell in zip(provinces, re.split(r'<td[^>]*>', body, flags=re.I)[1:]):
                numbers = re.findall(r'data-loto=["\']?(\d{2,6})', cell, re.I) or re.findall(rf'>\s*(\d{{{lengths[prize]}}})\s*<', cell)
                found[province][prize] = numbers[:MN_EXPECTED_PRIZES[prize]]
        if any(values for prizes in found.values() for values in prizes.values()):
            return found
    return {}


class RequestsLotteryScraper:
    def __init__(self, db_path=DB_PATH, session=requests, record_health: bool = True):
        self.db_path, self.session, self.record_health = db_path, session, record_health

    def _health(self, region, name, latency, success, status):
        SOURCE_SPEED[f"{region}:{name}"] = latency if success else SOURCE_TIMEOUT_SECONDS * 1000
        if not self.record_health:
            return
        try:
            connection = sqlite3.connect(self.db_path, timeout=2)
            old = connection.execute("SELECT avg_latency_ms, successes FROM source_health WHERE region=? AND source_name=?", (region, name)).fetchone()
            average = latency if not old or not old[1] else old[0] * .7 + latency * .3
            with connection:
                connection.execute("""INSERT INTO source_health(region, source_name, avg_latency_ms, successes, failures, last_status, checked_at)
                 VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP) ON CONFLICT(region, source_name) DO UPDATE SET
                 avg_latency_ms=excluded.avg_latency_ms, successes=source_health.successes+excluded.successes,
                 failures=source_health.failures+excluded.failures, last_status=excluded.last_status, checked_at=CURRENT_TIMESTAMP""",
                 (region, name, average, int(success), int(not success), status[:200]))
            connection.close()
        except sqlite3.Error:
            pass

    def _sources(self, region, sources):
        persisted = {}
        try:
            connection = sqlite3.connect(self.db_path)
            persisted = dict(connection.execute("SELECT source_name, avg_latency_ms FROM source_health WHERE region=?", (region,)))
            connection.close()
        except sqlite3.Error:
            pass
        return sorted(sources.items(), key=lambda item: (persisted.get(item[0], SOURCE_SPEED.get(f"{region}:{item[0]}", 999999)), list(sources).index(item[0])))

    def _get(self, url):
        return self.session.get(url, timeout=SOURCE_TIMEOUT_SECONDS, headers={"User-Agent": "Mozilla/5.0 (XSMB-XSMN Manager/2.7)"})

    def fetch_mb_snapshot(self, day: date):
        errors = []
        for name, template in self._sources("XSMB", MB_SOURCES):
            started, url = time.perf_counter(), template.format(day=day)
            try:
                response = self._get(url); response.raise_for_status()
                found = parse_mb_html(response.content)
                if not found: raise ValueError("không nhận diện được kết quả")
                self._health("XSMB", name, (time.perf_counter()-started)*1000, True, f"{sum(map(len, found.values()))}/27 số")
                return found, url
            except Exception as exc:
                self._health("XSMB", name, (time.perf_counter()-started)*1000, False, str(exc)); errors.append(f"{name}: {exc}")
        raise ValueError("Tất cả nguồn XSMB đều lỗi: " + " | ".join(errors))

    def fetch_mb_draw(self, day: date):
        found, url = self.fetch_mb_snapshot(day)
        missing = [f"{prize} ({len(found.get(prize, []))}/{count})" for prize, count in EXPECTED_PRIZES.items() if len(found.get(prize, [])) != count]
        if missing: raise ValueError("thiếu " + ", ".join(missing))
        return [(prize, position, number) for prize, count in EXPECTED_PRIZES.items() for position, number in enumerate(found[prize][:count], 1)], url

    def fetch_mn_snapshot(self, day: date):
        errors = []
        for name, template in self._sources("XSMN", MN_SOURCES):
            started, url = time.perf_counter(), template.format(day=day)
            try:
                response = self._get(url); response.raise_for_status(); found = parse_xsmn_html(response.text)
                if not found: raise ValueError("không nhận diện được bảng nhiều đài")
                count = sum(sum(len(v) for v in prizes.values()) for prizes in found.values())
                self._health("XSMN", name, (time.perf_counter()-started)*1000, True, f"{count} số")
                return found, url
            except Exception as exc:
                self._health("XSMN", name, (time.perf_counter()-started)*1000, False, str(exc)); errors.append(f"{name}: {exc}")
        raise ValueError("Tất cả nguồn XSMN đều lỗi: " + " | ".join(errors))


_default = RequestsLotteryScraper()
fetch_online_snapshot = _default.fetch_mb_snapshot
fetch_online_draw = _default.fetch_mb_draw
fetch_xsmn_snapshot = _default.fetch_mn_snapshot
