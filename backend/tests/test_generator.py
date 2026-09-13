"""Engine sinh số: kiểm thử hành vi + parity với bản Dart trong `mobile/`.

Giá trị vàng bên dưới được lấy từ `mobile/test/domain/generator_parity_test.dart`
chạy trên cùng một lịch sử tổng hợp, nên hai bản phải sinh ra đúng cùng bộ số.
"""

from datetime import date, timedelta

import pytest

from xsmb_manager.generator import (
    DISCLAIMER,
    GeneratorSettings,
    archive_from_rows,
    build_weights,
    generate,
    weekday_label,
)

START = date(2026, 7, 1)


def synthetic_history(days: int = 40) -> list[tuple[str, list[str]]]:
    """Lịch sử tổng hợp giống hệt `syntheticHistory()` của bản Dart."""
    return [
        (
            (START + timedelta(days=index)).isoformat(),
            [f"{(index * 37 + slot * 11) % 100:02d}" for slot in range(27)],
        )
        for index in range(days)
    ]


#: `(chiến lược, cấu hình, seed, ngày mục tiêu, các bộ số mong đợi)`.
GOLDEN_CASES = [
    (
        "hot",
        GeneratorSettings(numbers_per_set=6, set_count=3, sort_order="none"),
        20260913,
        None,
        ("94-64-73-33-35-93|", "90-73-97-43-12-61|", "16-17-92-73-97-11|"),
    ),
    (
        "balanced",
        GeneratorSettings(numbers_per_set=5, set_count=2, special_max=12),
        777,
        None,
        ("20-41-45-49-73|03", "11-25-42-65-83|01"),
    ),
    (
        "weekday",
        GeneratorSettings(numbers_per_set=4, set_count=2),
        4242,
        "2026-08-12",
        ("13-40-51-91|", "23-64-76-98|"),
    ),
    (
        "uniform",
        GeneratorSettings(numbers_per_set=6, set_count=2),
        99,
        None,
        ("24-27-50-76-81-95|", "05-23-34-48-52-54|"),
    ),
    (
        "cold",
        GeneratorSettings(numbers_per_set=6, set_count=2),
        31415,
        None,
        ("36-56-76-84-90-95|", "03-27-73-76-78-91|"),
    ),
    (
        "hot",
        GeneratorSettings(
            numbers_per_set=6,
            set_count=2,
            unique_within_set=False,
            sort_order="none",
        ),
        5,
        None,
        ("69-77-21-62-08-59|", "72-45-90-23-78-74|"),
    ),
]


@pytest.mark.parametrize(
    ("strategy", "settings", "seed", "target_date", "expected"),
    GOLDEN_CASES,
    ids=[case[0] for case in GOLDEN_CASES],
)
def test_generated_sets_match_dart_golden(strategy, settings, seed, target_date, expected):
    outcome = generate(synthetic_history(), strategy, settings, target_date=target_date, seed=seed)
    produced = tuple(f"{'-'.join(item.numbers)}|{item.special or ''}" for item in outcome.sets)
    assert produced == expected
    assert outcome.seed == seed
    assert all(item.seed == seed for item in outcome.sets)
    assert "không phải xác suất" in DISCLAIMER


def test_same_seed_and_settings_are_reproducible():
    first = generate(synthetic_history(), "balanced", seed=2026)
    second = generate(synthetic_history(), "balanced", seed=2026)
    other = generate(synthetic_history(), "balanced", seed=2027)
    assert [item.numbers for item in first.sets] == [item.numbers for item in second.sets]
    assert [item.numbers for item in first.sets] != [item.numbers for item in other.sets]


def test_settings_validation_mirrors_dart():
    assert GeneratorSettings().validate() == []
    assert GeneratorSettings(numbers_per_set=0).validate()
    assert GeneratorSettings(numbers_per_set=101).validate()
    assert GeneratorSettings(set_count=0).validate()
    assert GeneratorSettings(set_count=51).validate()
    assert GeneratorSettings(min_value=-1).validate()
    assert GeneratorSettings(min_value=90, max_value=80).validate()
    assert GeneratorSettings(excluded=(150,)).validate()
    assert GeneratorSettings(special_max=0).validate()
    assert GeneratorSettings(min_value=0, max_value=3, numbers_per_set=2, set_count=50).validate()
    assert GeneratorSettings(sort_order="zigzag").validate()
    with pytest.raises(ValueError):
        generate(synthetic_history(), "balanced", GeneratorSettings(numbers_per_set=0))
    with pytest.raises(ValueError):
        generate(synthetic_history(), "không-có")


def test_sets_respect_exclusions_uniqueness_and_special_range():
    settings = GeneratorSettings(
        numbers_per_set=8,
        set_count=6,
        excluded=(0, 5, 42, 99),
        special_max=12,
    )
    outcome = generate(synthetic_history(), "hot", settings, seed=88)

    keys = set()
    for item in outcome.sets:
        assert len(item.numbers) == 8
        assert len(set(item.numbers)) == 8
        assert {"00", "05", "42", "99"}.isdisjoint(item.numbers)
        assert item.sum == sum(int(number) for number in item.numbers)
        assert item.numbers == tuple(sorted(item.numbers))
        assert 1 <= int(item.special) <= 12
        keys.add("-".join(item.numbers))
    assert len(keys) == 6

    descending = generate(
        synthetic_history(),
        "hot",
        GeneratorSettings(numbers_per_set=5, set_count=1, sort_order="descending"),
        seed=88,
    )
    values = [int(number) for number in descending.sets[0].numbers]
    assert values == sorted(values, reverse=True)

    plain = generate(synthetic_history(), "hot", GeneratorSettings(set_count=2), seed=88)
    assert all(item.special is None for item in plain.sets)


def test_hot_and_cold_weights_lean_the_right_way():
    flat = [("2026-07-01", ["05"] * 27), ("2026-07-02", ["05"] * 27)]
    archive = archive_from_rows(flat)

    hot = build_weights(flat, "hot", archive=archive)
    cold = build_weights(flat, "cold", archive=archive)
    assert hot.top_numbers(1) == ["05"]
    assert cold.weight_of("00") > cold.weight_of("05")
    assert archive.draws_since_last_seen("05") == 0
    assert archive.draws_since_last_seen("00") == 2

    outcome = generate(
        flat,
        "hot",
        GeneratorSettings(
            min_value=0,
            max_value=9,
            numbers_per_set=1,
            set_count=40,
            unique_across_sets=False,
        ),
        seed=31337,
    )
    picks = [item.numbers[0] for item in outcome.sets]
    assert picks.count("05") > 30


def test_weekday_strategy_uses_target_weekday_counts():
    history = [
        ("2026-09-07", ["07"] * 27),  # Thứ Hai
        ("2026-09-08", ["08"] * 27),  # Thứ Ba
    ]
    weights = build_weights(history, "weekday", target_date="2026-09-14")
    assert weights.target_weekday == "Thứ Hai"
    assert weights.weight_of("07") > weights.weight_of("08")

    fallback = build_weights(history, "weekday", target_date="2026-09-10")
    assert "Không có kỳ đúng thứ" in fallback.source
    assert weekday_label("2026-01-01") == "Thứ Năm"
    assert weekday_label("không-phải-ngày") is None


def test_outcome_summary_and_flat_numbers():
    outcome = generate(synthetic_history(), "uniform", GeneratorSettings(set_count=2), seed=1)
    assert outcome.summary.endswith("seed 1")
    assert len(outcome.flat_numbers) == 2 * 6
    assert outcome.sets[0].csv.count(",") == 5
