from datetime import date

import pandas as pd
import pytest

from xsmb_manager.analytics import extract_numbers, normalize_date, parse_csv, probability_ranking, statistics


@pytest.mark.parametrize(("value", "expected"), [
    ("2026-09-04", "2026-09-04"), ("04/09/2026", "2026-09-04"), (date(2026, 9, 4), "2026-09-04")
])
def test_normalize_date(value, expected):
    assert normalize_date(value) == expected


def test_extract_numbers_preserves_leading_zeroes():
    assert extract_numbers("01, 234 00005") == ["01", "234", "00005"]


def test_parse_csv_skips_invalid_rows_and_keeps_positions():
    raw = "date,giai_nhat,giai_nhi\n04/09/2026,00123,45 06789\nbad,,\n".encode()
    draws, warnings = parse_csv(raw)
    assert draws == [("2026-09-04", [("giai_nhat", 1, "00123"), ("giai_nhi", 1, "45"), ("giai_nhi", 2, "06789")])]
    assert len(warnings) == 1


def test_statistics_and_probability_cover_all_100_numbers():
    frame = pd.DataFrame({"draw_date": pd.to_datetime(["2026-09-01", "2026-09-02", "2026-09-02"]), "loto2": ["01", "01", "02"]})
    stats = statistics(frame, 2, pd.Timestamp("2026-09-04"))
    ranking = probability_ranking(frame, 2)
    assert len(stats) == len(ranking) == 100
    assert stats.set_index("Số").loc["01", "Số lần xuất hiện"] == 2
    assert ranking["Tỷ lệ kỳ có số"].between(0, 1).all()
