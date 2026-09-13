"""History-informed number sets, mirroring the Flutter engine in `mobile/`.

`mobile/lib/src/domain/generator/number_generator.dart` is the reference
implementation: the same seed plus the same settings must give the same sets in
both languages. `tests/test_generator.py` pins golden values copied from Dart,
so any divergence fails the backend test suite.

Everything here is descriptive statistics of past draws: the weights say which
numbers appeared often or are long overdue, never that a number is "due" to hit.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from datetime import date, datetime
from random import SystemRandom
from typing import Sequence

MODEL_NAME = "history-number-generator-v1"

DISCLAIMER = (
    "Bộ số sinh ra chỉ dựa trên thống kê quá khứ nên không phải xác suất "
    "trúng và không bảo đảm kết quả tương lai."
)

STRATEGIES = ("uniform", "hot", "cold", "balanced", "weekday")
SORT_ORDERS = ("none", "ascending", "descending")

WEEKDAY_LABELS = (
    "Thứ Hai",
    "Thứ Ba",
    "Thứ Tư",
    "Thứ Năm",
    "Thứ Sáu",
    "Thứ Bảy",
    "Chủ Nhật",
)

MAX_SETS_PER_RUN = 50
MAX_DEDUPE_ATTEMPTS = 64

#: Một kỳ quay: `(ngày ISO, danh sách số 2 chữ số)`.
DrawRow = tuple[str, Sequence[str]]

_TWO_POW_32 = 4294967296


def u32(value: int) -> int:
    return value % _TWO_POW_32


def imul32(left: int, right: int) -> int:
    """`Math.imul(a, b)` của JavaScript trên 32 bit không dấu."""
    return (u32(left) * u32(right)) % _TWO_POW_32


class Mulberry32:
    """PRNG có seed, trùng khớp từng bước với bản Dart/JS."""

    def __init__(self, seed: int) -> None:
        self._seed = u32(seed)

    def next(self) -> float:
        self._seed = u32(self._seed + 0x6D2B79F5)
        value = imul32(u32(self._seed) ^ (u32(self._seed) >> 15), u32(1 | self._seed))
        value = u32((value + imul32(u32(value) ^ (u32(value) >> 7), u32(61 | value))) ^ value)
        return u32(value ^ (u32(value) >> 14)) / _TWO_POW_32


def random_seed() -> int:
    """Seed mới trong `[0, 2**30)` lấy từ nguồn ngẫu nhiên của hệ điều hành."""
    return SystemRandom().randrange(1 << 30)


def weekday_label(iso_date: str) -> str | None:
    """Nhãn thứ tiếng Việt của một ngày ISO; `None` nếu ngày không hợp lệ."""
    try:
        parsed = date.fromisoformat(iso_date)
    except (TypeError, ValueError):
        return None
    return WEEKDAY_LABELS[parsed.weekday()]


def all_numbers() -> tuple[str, ...]:
    return tuple(f"{value:02d}" for value in range(100))


@dataclass(frozen=True)
class ArchiveEntry:
    """Một dòng tidy `id | date | variable | value` như bản Dart."""

    draw_index: int
    date: str
    variable: str
    value: str


@dataclass(frozen=True)
class LottoArchive:
    """Kho số dạng tidy, đủ để đếm tần suất / gan / theo thứ."""

    region: str
    draw_count: int
    entries: tuple[ArchiveEntry, ...] = field(default_factory=tuple)

    def __bool__(self) -> bool:  # `if archive:` giống `!archive.isEmpty` của Dart
        return bool(self.entries)

    @property
    def is_empty(self) -> bool:
        return not self.entries

    def frequency_table(self, variable: str | None = None) -> dict[str, int]:
        table: dict[str, int] = {}
        for entry in self.entries:
            if variable is not None and entry.variable != variable:
                continue
            table[entry.value] = table.get(entry.value, 0) + 1
        return table

    def frequency(self, number: str) -> int:
        return self.frequency_table().get(number, 0)

    def last_seen_draw_index(self) -> dict[str, int]:
        table: dict[str, int] = {}
        for entry in self.entries:
            if entry.draw_index > table.get(entry.value, 0):
                table[entry.value] = entry.draw_index
        return table

    def draws_since_last_seen(self, number: str) -> int:
        last = self.last_seen_draw_index().get(number, 0)
        return self.draw_count if last == 0 else self.draw_count - last

    def number_by_weekday(self, number: str) -> dict[str, int]:
        counts = {label: 0 for label in WEEKDAY_LABELS}
        for entry in self.entries:
            if entry.value != number:
                continue
            label = weekday_label(entry.date)
            if label is not None:
                counts[label] += 1
        return counts

    def weekday_draw_count(self, label: str) -> int:
        return sum(1 for entry in self.entries if weekday_label(entry.date) == label)


def archive_from_rows(rows: Sequence[DrawRow], region: str = "") -> LottoArchive:
    """Dựng kho số từ `(ngày, các số trong kỳ)`; thứ tự đầu vào không quan trọng."""
    ordered = sorted(rows, key=lambda row: row[0])
    entries: list[ArchiveEntry] = []
    for index, (draw_date, values) in enumerate(ordered, start=1):
        for value in values:
            entries.append(ArchiveEntry(index, draw_date, "Kết quả", f"{int(value) % 100:02d}"))
    return LottoArchive(region=region, draw_count=len(ordered), entries=tuple(entries))


@dataclass(frozen=True)
class NumberWeights:
    """Trọng số rút thăm cho từng số 00–99 theo một chiến lược."""

    strategy: str
    weights: dict[str, float]
    source: str
    target_weekday: str | None = None

    def weight_of(self, number: str) -> float:
        return self.weights.get(number, 0.0)

    def top_numbers(self, count: int = 5) -> list[str]:
        ranked = sorted(self.weights.items(), key=lambda item: (-item[1], item[0]))
        return [number for number, _ in ranked[:count]]


def _rolling_window_rate(hits: Sequence[int], draw_count: int, window: int) -> float:
    start = max(0, draw_count - window)
    span = draw_count - start
    if span == 0:
        return 0.0
    return sum(1 for index in hits if index >= start) / span


def _recency_and_gap(hits: Sequence[int], draw_count: int) -> tuple[float, int]:
    """`(recency, effective_gap)` giống `NumberMetrics` của bản Dart."""
    if not hits:
        return 0.0, draw_count + 1
    gap = draw_count - 1 - hits[-1]
    return 1 / (1 + gap), gap


def build_weights(
    history: Sequence[DrawRow],
    strategy: str = "balanced",
    archive: LottoArchive | None = None,
    target_date: str | None = None,
) -> NumberWeights:
    """Dựng trọng số từ lịch sử; công thức khớp `NumberWeights.fromHistory`."""
    table = archive if archive is not None and not archive.is_empty else archive_from_rows(history)
    draws = max(table.draw_count, 1)
    numbers = all_numbers()

    if strategy == "uniform":
        return NumberWeights(strategy, {number: 1.0 for number in numbers}, "Rút đều 00–99")

    if strategy == "hot":
        frequency = table.frequency_table()
        weights = {
            number: 0.2 + frequency.get(number, 0) / draws for number in numbers
        }
        source = f"Tần suất trong {table.draw_count} kỳ ({len(table.entries)} lượt về)"
        return NumberWeights(strategy, weights, source)

    if strategy == "cold":
        weights = {
            number: 0.2 + table.draws_since_last_seen(number) / draws for number in numbers
        }
        source = f"Gan (số kỳ chưa về) trong {table.draw_count} kỳ"
        return NumberWeights(strategy, weights, source)

    if strategy == "weekday":
        weekday = weekday_label(target_date or "") or _latest_weekday(table)
        has_weekday = weekday is not None and table.weekday_draw_count(weekday) > 0
        if not has_weekday:
            frequency = table.frequency_table()
            weights = {number: 0.2 + frequency.get(number, 0) for number in numbers}
            return NumberWeights(
                strategy,
                weights,
                "Không có kỳ đúng thứ — dùng tần suất toàn kho",
                weekday,
            )
        weights = {
            number: 0.2 + table.number_by_weekday(number)[weekday] for number in numbers
        }
        return NumberWeights(strategy, weights, f"Số hay về vào {weekday}", weekday)

    if strategy != "balanced":
        raise ValueError(f"Chiến lược không hợp lệ: {strategy}")

    ordered = sorted(history, key=lambda row: row[0])
    hits: dict[str, list[int]] = {number: [] for number in numbers}
    for index, (_, values) in enumerate(ordered):
        seen = {f"{int(value) % 100:02d}" for value in values}
        for number in seen:
            hits[number].append(index)
    draw_count = max(len(ordered), 1)
    weights = {}
    for number in numbers:
        hits_for_number = hits[number]
        window30 = _rolling_window_rate(hits_for_number, len(ordered), 30)
        recency, gap = _recency_and_gap(hits_for_number, len(ordered))
        weights[number] = (
            0.05
            + 0.45 * window30
            + 0.25 * recency
            + 0.30 * min(max(gap / draw_count, 0.0), 1.0)
        )
    return NumberWeights(
        strategy,
        weights,
        "Cân bằng: 30 kỳ (0,45) + độ mới (0,25) + gan (0,30)",
    )


def _latest_weekday(table: LottoArchive) -> str | None:
    if not table.entries:
        return None
    return weekday_label(max(entry.date for entry in table.entries))


@dataclass(frozen=True)
class GeneratorSettings:
    """Cấu hình một lần sinh số — tương đương `GeneratorSettings` của Dart."""

    min_value: int = 0
    max_value: int = 99
    numbers_per_set: int = 6
    set_count: int = 3
    excluded: tuple[int, ...] = ()
    sort_order: str = "ascending"
    unique_within_set: bool = True
    unique_across_sets: bool = True
    special_max: int | None = None
    seed: int | None = None

    @property
    def available_count(self) -> int:
        return sum(
            1 for value in range(self.min_value, self.max_value + 1) if value not in self.excluded
        )

    def validate(self) -> list[str]:
        errors: list[str] = []
        if self.min_value < 0 or self.max_value > 99 or self.min_value > self.max_value:
            return ["Khoảng số phải nằm trong 00–99 và min ≤ max."]
        if any(value < self.min_value or value > self.max_value for value in self.excluded):
            errors.append("Số loại trừ phải nằm trong khoảng đang chọn.")
        available = self.available_count
        if self.numbers_per_set < 1:
            errors.append("Mỗi bộ cần ít nhất 1 số.")
        elif self.numbers_per_set > available:
            errors.append(f"Khoảng đang chọn chỉ còn {available} số.")
        if self.set_count < 1 or self.set_count > MAX_SETS_PER_RUN:
            errors.append(f"Số bộ mỗi lần sinh phải từ 1 đến {MAX_SETS_PER_RUN}.")
        if self.special_max is not None and not 1 <= self.special_max <= 99:
            errors.append("Số đặc biệt phải nằm trong 01–99.")
        if self.unique_within_set and self.unique_across_sets:
            if math.comb(available, self.numbers_per_set) < self.set_count:
                errors.append(f"Không đủ tổ hợp để tạo {self.set_count} bộ khác nhau.")
        if self.sort_order not in SORT_ORDERS:
            errors.append(f"Cách sắp xếp không hợp lệ: {self.sort_order}")
        return errors


@dataclass(frozen=True)
class GeneratedSet:
    """Một bộ số đã sinh."""

    index: int
    numbers: tuple[str, ...]
    sum: int
    seed: int
    special: str | None = None

    @property
    def display(self) -> str:
        return " · ".join(self.numbers)

    @property
    def csv(self) -> str:
        return ",".join(self.numbers)

    @property
    def text(self) -> str:
        return self.display if self.special is None else f"{self.display} | {self.special}"


@dataclass(frozen=True)
class GeneratorOutcome:
    """Kết quả một lần sinh số kèm cách tính để giải thích trên UI/API."""

    strategy: str
    settings: GeneratorSettings
    seed: int
    sets: tuple[GeneratedSet, ...]
    weights: NumberWeights
    generated_at: datetime
    target_date: str | None = None

    @property
    def summary(self) -> str:
        return (
            f"{len(self.sets)} bộ · {self.settings.numbers_per_set} số/bộ · "
            f"{self.strategy} · seed {self.seed}"
        )

    @property
    def flat_numbers(self) -> tuple[str, ...]:
        return tuple(number for item in self.sets for number in item.numbers)


def _unit(random: Mulberry32) -> float:
    """Số thực trong khoảng (0, 1] — tránh `log(0)` khi PRNG trả 0."""
    value = random.next()
    if value <= 0:
        return 1e-12
    return 1.0 if value > 1 else value


def _pick_without_replacement(
    pool: Sequence[str], weights: NumberWeights, count: int, random: Mulberry32
) -> list[str]:
    """Efraimidis–Spirakis: khoá `(1/w)·(-ln u)` càng nhỏ càng dễ được chọn."""
    keys = {
        number: -math.log(_unit(random)) / max(weights.weight_of(number), 1e-9)
        for number in pool
    }
    ordered = sorted(pool, key=lambda number: (keys[number], number))
    return ordered[: min(count, len(ordered))]


def _pick_with_replacement(
    pool: Sequence[str], weights: NumberWeights, count: int, random: Mulberry32
) -> list[str]:
    cumulative: list[float] = []
    running = 0.0
    for number in pool:
        running += max(weights.weight_of(number), 0.0) + 1e-9
        cumulative.append(running)
    picks: list[str] = []
    for _ in range(count):
        target = random.next() * running
        position = len(pool) - 1
        for index, value in enumerate(cumulative):
            if value > target:
                position = index
                break
        picks.append(pool[position])
    return picks


def _apply_sort(numbers: Sequence[str], order: str) -> list[str]:
    values = list(numbers)
    if order == "none":
        return values
    values.sort(key=int)
    if order == "descending":
        numbers_desc = list(reversed(values))
        return numbers_desc
    return values


def generate(
    history: Sequence[DrawRow],
    strategy: str = "balanced",
    settings: GeneratorSettings | None = None,
    target_date: str | None = None,
    archive: LottoArchive | None = None,
    seed: int | None = None,
) -> GeneratorOutcome:
    """Sinh bộ số theo `strategy`; trùng khớp bản Dart với cùng seed + cấu hình."""
    resolved = settings or GeneratorSettings()
    errors = resolved.validate()
    if errors:
        raise ValueError(" ".join(errors))
    if strategy not in STRATEGIES:
        raise ValueError(f"Chiến lược không hợp lệ: {strategy}")

    effective_seed = seed if seed is not None else resolved.seed
    if effective_seed is None:
        effective_seed = random_seed()

    weights = build_weights(history, strategy, archive=archive, target_date=target_date)
    pool = [
        f"{value:02d}"
        for value in range(resolved.min_value, resolved.max_value + 1)
        if value not in resolved.excluded
    ]

    random = Mulberry32(effective_seed)
    seen: set[str] = set()
    sets: list[GeneratedSet] = []
    for index in range(resolved.set_count):
        numbers: list[str] = []
        for _ in range(MAX_DEDUPE_ATTEMPTS):
            numbers = (
                _pick_without_replacement(pool, weights, resolved.numbers_per_set, random)
                if resolved.unique_within_set
                else _pick_with_replacement(pool, weights, resolved.numbers_per_set, random)
            )
            numbers = _apply_sort(numbers, resolved.sort_order)
            if not resolved.unique_across_sets:
                break
            key = "-".join(numbers)
            if key not in seen:
                seen.add(key)
                break
        special = None
        if resolved.special_max is not None:
            special = f"{1 + int(random.next() * resolved.special_max):02d}"
        sets.append(
            GeneratedSet(
                index=index + 1,
                numbers=tuple(numbers),
                sum=sum(int(number) for number in numbers),
                seed=effective_seed,
                special=special,
            )
        )

    return GeneratorOutcome(
        strategy=strategy,
        settings=resolved,
        seed=effective_seed,
        sets=tuple(sets),
        weights=weights,
        generated_at=datetime.now(),
        target_date=target_date,
    )
