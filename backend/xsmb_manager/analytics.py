"""Pure parsing and statistical logic, intentionally independent of Streamlit."""

from __future__ import annotations

import io
import re
from datetime import date, datetime

import numpy as np
import pandas as pd

from .config import DATE_CANDIDATES


def normalize_date(value) -> str:
    if pd.isna(value):
        raise ValueError("Ngày bị trống")
    if isinstance(value, (datetime, date, pd.Timestamp)):
        return pd.Timestamp(value).strftime("%Y-%m-%d")
    text = str(value).strip()
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
    return [] if pd.isna(value) else re.findall(r"\d+", str(value).strip())


def parse_csv(raw: bytes) -> tuple[list[tuple[str, list[tuple[str, int, str]]]], list[str]]:
    last_error = None
    for encoding in ("utf-8-sig", "utf-8", "cp1258", "latin1"):
        try:
            frame = pd.read_csv(io.BytesIO(raw), dtype=str, encoding=encoding, sep=None, engine="python")
            break
        except Exception as exc:
            last_error = exc
    else:
        raise ValueError(f"Không đọc được CSV: {last_error}")
    if frame.empty:
        raise ValueError("File CSV không có dữ liệu")
    frame.columns = [str(column).strip() for column in frame.columns]
    date_column = next((column for column in frame.columns if column.lower() in DATE_CANDIDATES), None)
    if date_column is None:
        raise ValueError("Không tìm thấy cột ngày (date/ngay/ngày/draw_date)")
    value_columns = [column for column in frame.columns if column != date_column]
    if not value_columns:
        raise ValueError("CSV cần có ít nhất một cột kết quả")
    draws, warnings = [], []
    for row_number, (_, row) in enumerate(frame.iterrows(), start=2):
        try:
            draw_date = normalize_date(row[date_column])
        except ValueError as exc:
            warnings.append(f"Dòng {row_number}: {exc}; đã bỏ qua")
            continue
        results = [
            (column, position, number)
            for column in value_columns
            for position, number in enumerate(extract_numbers(row[column]), start=1)
        ]
        if results:
            draws.append((draw_date, results))
        else:
            warnings.append(f"Dòng {row_number}: không có số; đã bỏ qua")
    return draws, warnings


def statistics(df: pd.DataFrame, total_draws: int, latest_date: pd.Timestamp) -> pd.DataFrame:
    counts = df.groupby("loto2").size() if not df.empty else pd.Series(dtype=int)
    last_seen = df.groupby("loto2")["draw_date"].max() if not df.empty else pd.Series(dtype="datetime64[ns]")
    rows = []
    for number in (f"{i:02d}" for i in range(100)):
        last = last_seen.get(number, pd.NaT)
        rows.append({"Số": number, "Số lần xuất hiện": int(counts.get(number, 0)),
                     "Số ngày gan": (latest_date - last).days if pd.notna(last) else None,
                     "Xác suất ước lượng": int(counts.get(number, 0)) / total_draws if total_draws else 0.0})
    return pd.DataFrame(rows)


def probability_ranking(df: pd.DataFrame, total_draws: int) -> pd.DataFrame:
    if df.empty or not total_draws:
        present = last_10 = pd.Series(dtype=int)
    else:
        present = df.drop_duplicates(["draw_date", "loto2"]).groupby("loto2").size()
        recent_dates = sorted(df["draw_date"].unique())[-10:]
        last_10 = df[df["draw_date"].isin(recent_dates)].drop_duplicates(["draw_date", "loto2"]).groupby("loto2").size()
    recent_denominator = min(10, total_draws)
    rows = []
    for number in (f"{i:02d}" for i in range(100)):
        hits, recent_hits = int(present.get(number, 0)), int(last_10.get(number, 0))
        rows.append({"Số": number, "Số kỳ xuất hiện": hits, "Tỷ lệ kỳ có số": hits / total_draws if total_draws else 0,
                     "Tỷ lệ 10 kỳ gần nhất": recent_hits / recent_denominator if recent_denominator else 0,
                     "Xác suất mô hình kỳ tới": .7 * (hits + 1) / (total_draws + 2) + .3 * (recent_hits + 1) / (recent_denominator + 2)})
    return pd.DataFrame(rows).sort_values(["Xác suất mô hình kỳ tới", "Số"], ascending=[False, True])


def _prediction_matrix(df: pd.DataFrame):
    dates = sorted(pd.to_datetime(df["draw_date"].unique()))
    date_index = {stamp: index for index, stamp in enumerate(dates)}
    matrix = np.zeros((len(dates), 100), dtype=float)
    for draw_date, loto in df[["draw_date", "loto2"]].drop_duplicates().itertuples(index=False):
        matrix[date_index[pd.Timestamp(draw_date)], int(loto)] = 1.0
    return dates, matrix


def walk_forward_backtest(df: pd.DataFrame, min_train: int = 30) -> tuple[pd.DataFrame, pd.DataFrame]:
    dates, matrix = _prediction_matrix(df)
    if len(dates) <= min_train:
        return pd.DataFrame(), pd.DataFrame()
    records = []
    for index in range(min_train, len(dates)):
        history, actual = matrix[:index], matrix[index]
        recent_size = min(10, index)
        bayes = (history.sum(axis=0) + 1) / (index + 2)
        recent = (history[-recent_size:].sum(axis=0) + 1) / (recent_size + 2)
        weights = np.exp(-(np.log(2) / 30) * np.arange(index - 1, -1, -1))
        predictions = {"Bayes dài hạn": bayes, "Tần suất 10 kỳ": recent,
                       "EWMA bán rã 30 kỳ": (history * weights[:, None]).sum(axis=0) / weights.sum(),
                       "Hybrid 70/30": .7 * bayes + .3 * recent}
        for model, probability in predictions.items():
            top10 = np.argsort(-probability)[:10]
            records.append({"Ngày kiểm tra": dates[index].strftime("%Y-%m-%d"), "Mô hình": model,
                            "Top 10 trúng ít nhất 1 số": int(actual[top10].sum() > 0),
                            "Số trúng trong Top 10": int(actual[top10].sum()),
                            "Brier score": float(np.mean((probability - actual) ** 2))})
    history = pd.DataFrame(records)
    summary = history.groupby("Mô hình", as_index=False).agg(**{
        "Số kỳ backtest": ("Ngày kiểm tra", "count"), "Tỷ lệ kỳ Top 10 có trúng": ("Top 10 trúng ít nhất 1 số", "mean"),
        "Trung bình số trúng/Top 10": ("Số trúng trong Top 10", "mean"), "Brier score": ("Brier score", "mean")
    }).sort_values(["Brier score", "Tỷ lệ kỳ Top 10 có trúng"], ascending=[True, False])
    return summary, history


def adaptive_top4(df: pd.DataFrame, min_train: int = 30) -> tuple[pd.DataFrame, str, dict]:
    dates, matrix = _prediction_matrix(df)
    if not dates:
        return pd.DataFrame(), "Không đủ dữ liệu", {}
    count, recent_size = len(dates), min(10, len(dates))
    bayes = (matrix.sum(axis=0) + 1) / (count + 2)
    recent = (matrix[-recent_size:].sum(axis=0) + 1) / (recent_size + 2)
    weights = np.exp(-(np.log(2) / 30) * np.arange(count - 1, -1, -1))
    predictions = {"Bayes dài hạn": bayes, "Tần suất 10 kỳ": recent,
                   "EWMA bán rã 30 kỳ": (matrix * weights[:, None]).sum(axis=0) / weights.sum(),
                   "Hybrid 70/30": .7 * bayes + .3 * recent}
    summary, _ = walk_forward_backtest(df, min_train)
    if summary.empty:
        model, evidence = "Hybrid 70/30", {"mode": "fallback", "draws": count}
    else:
        best = summary.iloc[0]
        model = str(best["Mô hình"])
        evidence = {"mode": "backtest", "draws": count, "test_draws": int(best["Số kỳ backtest"]),
                    "brier": float(best["Brier score"]), "top10_hit_rate": float(best["Tỷ lệ kỳ Top 10 có trúng"])}
    probability = predictions[model]
    order = np.argsort(-probability)[:4]
    return pd.DataFrame({"Hạng": np.arange(1, 5), "Số": [f"{number:02d}" for number in order],
                         "Xác suất mô hình": probability[order]}), model, evidence
