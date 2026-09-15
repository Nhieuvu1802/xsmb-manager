import type { CsvValidation, LotteryDraw, NumberStat, PrizeResult, Region } from "./lottery-domain";

export const ALL_NUMBERS = Array.from({ length: 100 }, (_, index) =>
  index.toString().padStart(2, "0"),
);

export function lastTwoDigits(value: string) {
  return value.slice(-2).padStart(2, "0");
}

export function calculateNumberStats(draws: LotteryDraw[]): NumberStat[] {
  // All recency metrics use index 0 as the newest draw. Normalizing here keeps
  // imported data and API data correct even if a caller supplies ascending rows.
  const orderedDraws = [...draws].sort(
    (left, right) => right.date.localeCompare(left.date) || left.station.localeCompare(right.station),
  );
  const drawCount = orderedDraws.length;
  const totalSlots = orderedDraws.reduce((sum, draw) => sum + draw.results.length, 0);

  return ALL_NUMBERS.map((number) => {
    const hitIndexes: number[] = [];
    let count = 0;

    orderedDraws.forEach((draw, drawIndex) => {
      let hitInDraw = false;
      draw.results.forEach((result) => {
        if (lastTwoDigits(result.value) === number) {
          count += 1;
          hitInDraw = true;
        }
      });
      if (hitInDraw) hitIndexes.push(drawIndex);
    });

    const expected = totalSlots * 0.01;
    const deviation = Math.sqrt(totalSlots * 0.01 * 0.99);
    const gaps = hitIndexes.slice(1).map((value, index) => value - hitIndexes[index]);

    // currentStreak starts at the newest draw (index 0).
    let currentStreak = 0;
    let longestStreak = 0;
    let tempStreak = 0;
    for (let i = 0; i < drawCount && hitIndexes.includes(i); i += 1) {
      currentStreak += 1;
    }
    // Compute longest streak from hitIndexes
    for (let i = 0; i < hitIndexes.length; i += 1) {
      tempStreak = 1;
      for (let j = i + 1; j < hitIndexes.length; j += 1) {
        if (hitIndexes[j] === hitIndexes[j - 1] + 1) {
          tempStreak += 1;
        } else {
          break;
        }
      }
      longestStreak = Math.max(longestStreak, tempStreak);
    }

    return {
      number,
      count,
      drawHits: hitIndexes.length,
      rate: totalSlots ? count / totalSlots : 0,
      drawRate: drawCount ? hitIndexes.length / drawCount : 0,
      gap: hitIndexes.length ? hitIndexes[0] : null,
      averageGap: gaps.length ? gaps.reduce((a, b) => a + b, 0) / gaps.length : null,
      zScore: deviation ? (count - expected) / deviation : 0,
      currentStreak,
      longestStreak,
    };
  });
}

export function buildTrend(draws: LotteryDraw[], trackedNumbers: string[]) {
  return [...draws]
    .sort((left, right) => right.date.localeCompare(left.date) || left.station.localeCompare(right.station))
    .slice(0, 30)
    .reverse()
    .map((draw) => {
      const values = draw.results.map((result) => lastTwoDigits(result.value));
      return {
        date: new Intl.DateTimeFormat("vi-VN", { day: "2-digit", month: "2-digit" }).format(
          new Date(`${draw.date}T00:00:00`),
        ),
        hits: values.filter((value) => trackedNumbers.includes(value)).length,
      };
    });
}

export function calculateSetProbability(size: number, slots = 27) {
  if (!size || size < 0) return 0;
  const safeSize = Math.min(size, 100);
  return 1 - Math.pow((100 - safeSize) / 100, slots);
}

export function exactDigitProbability(digits: number) {
  if (!Number.isInteger(digits) || digits < 1 || digits > 12) return null;
  return 1 / 10 ** digits;
}

export function combinations(n: number, k: number) {
  if (!Number.isInteger(n) || !Number.isInteger(k) || n < 0 || k < 0 || k > n) return 0;
  const smaller = Math.min(k, n - k);
  let result = 1;
  for (let index = 1; index <= smaller; index += 1) result = (result * (n - smaller + index)) / index;
  return Math.round(result);
}

export function expectedValue(ticketPrice: number, prize: number, winProbability: number) {
  return winProbability * prize - ticketPrice;
}

export function wilsonInterval(successes: number, trials: number, z = 1.96): [number, number] {
  if (!trials) return [0, 0];
  const observed = successes / trials;
  const denominator = 1 + (z * z) / trials;
  const center = (observed + (z * z) / (2 * trials)) / denominator;
  const margin = (z / denominator) * Math.sqrt((observed * (1 - observed)) / trials + (z * z) / (4 * trials * trials));
  return [Math.max(0, center - margin), Math.min(1, center + margin)];
}

export function chiSquareUniform(stats: NumberStat[]) {
  const total = stats.reduce((sum, item) => sum + item.count, 0);
  const expected = total / 100;
  if (!expected) return 0;
  return stats.reduce((sum, item) => sum + ((item.count - expected) ** 2) / expected, 0);
}

export type PairStat = { pair: string; count: number };
export type DayOfWeekStat = { day: string; dayIndex: number; count: number; drawHits: number };

export function calculatePairStats(draws: LotteryDraw[]): PairStat[] {
  const pairCounts = new Map<string, number>();
  draws.forEach((draw) => {
    const values = [...new Set(draw.results.map((r) => lastTwoDigits(r.value)))];
    for (let i = 0; i < values.length; i += 1) {
      for (let j = i + 1; j < values.length; j += 1) {
        const pair = values[i] < values[j] ? `${values[i]}-${values[j]}` : `${values[j]}-${values[i]}`;
        pairCounts.set(pair, (pairCounts.get(pair) ?? 0) + 1);
      }
    }
  });
  return [...pairCounts]
    .map(([pair, count]) => ({ pair, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 30);
}

export function calculateDayOfWeekStats(draws: LotteryDraw[]): DayOfWeekStat[] {
  const dayNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
  const counts = Array.from({ length: 7 }, (_, i) => ({ day: dayNames[i], dayIndex: i, count: 0, drawHits: 0 }));
  draws.forEach((draw) => {
    const d = new Date(`${draw.date}T00:00:00`);
    const dayIdx = d.getDay();
    const values = draw.results.map((r) => lastTwoDigits(r.value));
    counts[dayIdx].count += values.length;
    counts[dayIdx].drawHits += 1;
  });
  return counts;
}

export function monteCarloAtLeastOne(selectionSize: number, slots: number, simulations = 10000, seed = 2409) {
  let state = seed >>> 0;
  const random = () => {
    state = (1664525 * state + 1013904223) >>> 0;
    return state / 4294967296;
  };
  let wins = 0;
  for (let simulation = 0; simulation < simulations; simulation += 1) {
    let hit = false;
    for (let slot = 0; slot < slots && !hit; slot += 1) hit = Math.floor(random() * 100) < selectionSize;
    if (hit) wins += 1;
  }
  return wins / simulations;
}

export function calculateStructure(draws: LotteryDraw[]) {
  const values = draws.flatMap((draw) => draw.results.map((result) => lastTwoDigits(result.value)));
  const digitCounts = Array.from({ length: 10 }, (_, digit) => ({ digit: String(digit), count: 0 }));
  const heads = Array.from({ length: 10 }, (_, digit) => ({ digit: String(digit), count: 0 }));
  const tails = Array.from({ length: 10 }, (_, digit) => ({ digit: String(digit), count: 0 }));
  const sums = Array.from({ length: 19 }, (_, sum) => ({ sum, count: 0 }));
  const parity = { even: 0, odd: 0 };
  const ranges = Array.from({ length: 5 }, (_, index) => ({ label: `${index * 20}-${index * 20 + 19}`, count: 0 }));

  values.forEach((value) => {
    const head = Number(value[0]);
    const tail = Number(value[1]);
    heads[head].count += 1;
    tails[tail].count += 1;
    digitCounts[head].count += 1;
    digitCounts[tail].count += 1;
    sums[head + tail].count += 1;
    parity[Number(value) % 2 === 0 ? "even" : "odd"] += 1;
    ranges[Math.min(4, Math.floor(Number(value) / 20))].count += 1;
  });

  const sequenceCounts = new Map<string, number>();
  draws.forEach((draw) => {
    const drawValues = draw.results.map((result) => lastTwoDigits(result.value));
    for (let index = 0; index < drawValues.length - 1; index += 1) {
      const pair = `${drawValues[index]}–${drawValues[index + 1]}`;
      sequenceCounts.set(pair, (sequenceCounts.get(pair) ?? 0) + 1);
      if (index < drawValues.length - 2) {
        const triple = `${pair}–${drawValues[index + 2]}`;
        sequenceCounts.set(triple, (sequenceCounts.get(triple) ?? 0) + 1);
      }
    }
  });

  return {
    digitCounts,
    heads,
    tails,
    sums,
    parity,
    ranges,
    sequences: [...sequenceCounts].sort((a, b) => b[1] - a[1]).slice(0, 8),
  };
}

export type WindowComparison = {
  period: number;
  draws: number;
  slots: number;
  distinct: number;
  chiSquare: number;
  top: Array<{ number: string; count: number }>;
  bottom: Array<{ number: string; count: number }>;
  longestGap: number;
};

export function compareWindows(draws: LotteryDraw[], periods: number[] = [7, 30, 90, 180, 365]): WindowComparison[] {
  const orderedDraws = [...draws].sort(
    (left, right) => right.date.localeCompare(left.date) || left.station.localeCompare(right.station),
  );
  return periods.map((period) => {
    const window = orderedDraws.slice(0, period);
    const stats = calculateNumberStats(window);
    const totalSlots = window.reduce((sum, draw) => sum + draw.results.length, 0);
    const sorted = [...stats].sort((a, b) => b.count - a.count);
    const nonzero = stats.filter((s) => s.count > 0);
    const maxGap = Math.max(...nonzero.map((s) => s.gap ?? 0), 0);
    return {
      period,
      draws: window.length,
      slots: totalSlots,
      distinct: nonzero.length,
      chiSquare: chiSquareUniform(stats),
      top: sorted.slice(0, 3).map((s) => ({ number: s.number, count: s.count })),
      bottom: sorted.slice(-3).reverse().map((s) => ({ number: s.number, count: s.count })),
      longestGap: maxGap,
    };
  });
}

export function lookupNumber(draws: LotteryDraw[], target: string, period?: number) {
  const padded = target.padStart(2, "0");
  const orderedDraws = [...draws].sort(
    (left, right) => right.date.localeCompare(left.date) || left.station.localeCompare(right.station),
  );
  const window = period ? orderedDraws.slice(0, period) : orderedDraws;
  const stats = calculateNumberStats(window);
  const stat = stats.find((s) => s.number === padded);
  if (!stat) return null;
  const total = stats.reduce((sum, s) => sum + s.count, 0);
  const [wilsonLow, wilsonHigh] = wilsonInterval(stat.count, total);
  return { ...stat, wilsonLow, wilsonHigh, total, windowPeriod: period ?? draws.length };
}

export function parseNumberSet(raw: string) {
  const invalid: string[] = [];
  const values = raw
    .split(/[\s,;.-]+/)
    .filter(Boolean)
    .map((value) => {
      if (!/^\d{1,2}$/.test(value) || Number(value) > 99) {
        invalid.push(value);
        return null;
      }
      return value.padStart(2, "0");
    })
    .filter((value): value is string => value !== null);

  return { numbers: [...new Set(values)], invalid };
}

export function secureRandomNumbers(amount: number) {
  const target = Math.min(Math.max(amount, 1), 20);
  const selected = new Set<number>();
  const cryptoApi = globalThis.crypto;

  if (!cryptoApi?.getRandomValues) {
    throw new Error("Trình duyệt không hỗ trợ Web Crypto API.");
  }

  while (selected.size < target) {
    const buffer = new Uint32Array(1);
    cryptoApi.getRandomValues(buffer);
    // Rejection sampling avoids modulo bias when mapping uint32 to 0–99.
    if (buffer[0] < 4294967200) selected.add(buffer[0] % 100);
  }

  return [...selected]
    .sort((a, b) => a - b)
    .map((value) => value.toString().padStart(2, "0"));
}

export type HistoricalCandidate = {
  number: string;
  score: number;
  overallHits: number;
  recentHits: number;
  weekdayHits: number;
  sampleDraws: number;
};

export function rankHistoricalCandidates(draws: LotteryDraw[], targetDate: string, limit = 12): HistoricalCandidate[] {
  const target = new Date(`${targetDate}T12:00:00Z`);
  if (Number.isNaN(target.getTime())) return [];

  // Strictly earlier dates prevent a historical back-test from seeing the target day's outcome.
  const historical = draws.filter((draw) => draw.date < targetDate);
  if (!historical.length) return [];

  const recentThreshold = new Date(target);
  recentThreshold.setUTCDate(recentThreshold.getUTCDate() - 30);
  const recentThresholdDate = recentThreshold.toISOString().slice(0, 10);
  const weekday = target.getUTCDay();
  const weekdayDraws = historical.filter((draw) => new Date(`${draw.date}T12:00:00Z`).getUTCDay() === weekday);
  const recentDraws = historical.filter((draw) => draw.date >= recentThresholdDate);

  function countNumbers(source: LotteryDraw[]) {
    const counts = Array.from({ length: 100 }, () => 0);
    source.forEach((draw) => draw.results.forEach((result) => {
      counts[Number(lastTwoDigits(result.value))] += 1;
    }));
    return counts;
  }

  const overallCounts = countNumbers(historical);
  const weekdayCounts = countNumbers(weekdayDraws);
  const recentCounts = countNumbers(recentDraws);
  const overallMax = Math.max(...overallCounts, 1);
  const weekdayMax = Math.max(...weekdayCounts, 1);
  const recentMax = Math.max(...recentCounts, 1);

  return Array.from({ length: 100 }, (_, value) => {
    const score = (
      (overallCounts[value] / overallMax) * 0.45
      + (weekdayCounts[value] / weekdayMax) * 0.35
      + (recentCounts[value] / recentMax) * 0.2
    ) * 100;
    return {
      number: value.toString().padStart(2, "0"),
      score: Math.round(score * 10) / 10,
      overallHits: overallCounts[value],
      recentHits: recentCounts[value],
      weekdayHits: weekdayCounts[value],
      sampleDraws: historical.length,
    };
  })
    .sort((left, right) => right.score - left.score || right.overallHits - left.overallHits || left.number.localeCompare(right.number))
    .slice(0, Math.min(Math.max(limit, 1), 100));
}

export function validateCsv(text: string): CsvValidation {
  const lines = text.replace(/^\uFEFF/, "").split(/\r?\n/).filter((line) => line.trim());
  if (!lines.length) {
    return { validRows: 0, duplicateRows: 0, issues: [{ row: 1, level: "error", message: "Tệp rỗng." }] };
  }

  const headers = lines[0].split(",").map((value) => value.trim().toLowerCase());
  const dateIndex = headers.findIndex((value) => ["date", "ngay", "ngày", "draw_date"].includes(value));
  const stationIndex = headers.findIndex((value) => ["station", "dai", "đài"].includes(value));
  const issues: CsvValidation["issues"] = [];
  const drawKeys = new Set<string>();
  const dates = new Set<string>();
  let validRows = 0;
  let duplicateRows = 0;

  if (dateIndex < 0) {
    issues.push({ row: 1, level: "error", message: "Thiếu cột ngày (date/ngay/draw_date)." });
    return { validRows, duplicateRows, issues };
  }
  if (headers.length < 2) {
    issues.push({ row: 1, level: "error", message: "Cần ít nhất một cột kết quả." });
  }

  lines.slice(1).forEach((line, lineIndex) => {
    const row = lineIndex + 2;
    const cells = line.split(",").map((value) => value.trim().replace(/^"|"$/g, ""));
    const date = cells[dateIndex];
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date ?? "") || Number.isNaN(Date.parse(date))) {
      issues.push({ row, level: "error", message: "Ngày không đúng định dạng YYYY-MM-DD." });
      return;
    }
    const station = stationIndex >= 0 ? cells[stationIndex]?.trim().toLowerCase() : "";
    const drawKey = `${date}|${station}`;
    if (drawKeys.has(drawKey)) {
      duplicateRows += 1;
      issues.push({ row, level: "warning", message: `Kỳ quay ${date}${station ? ` · ${station}` : ""} bị trùng.` });
      return;
    }
    const hasNumber = cells.some((cell, index) => index !== dateIndex && index !== stationIndex && /\d{2,}/.test(cell));
    if (!hasNumber) {
      issues.push({ row, level: "error", message: "Không tìm thấy kết quả số." });
      return;
    }
    drawKeys.add(drawKey);
    dates.add(date);
    validRows += 1;
  });

  const sortedDates = [...dates].sort();
  sortedDates.slice(1).forEach((date, index) => {
    const previous = new Date(`${sortedDates[index]}T00:00:00Z`);
    const current = new Date(`${date}T00:00:00Z`);
    const missing = Math.round((current.getTime() - previous.getTime()) / 86400000) - 1;
    if (missing > 0) {
      issues.push({
        row: 0,
        level: "warning",
        message: `Có thể thiếu ${missing} kỳ giữa ${sortedDates[index]} và ${date}.`,
      });
    }
  });

  return { validRows, duplicateRows, issues };
}

export function parseCsvDraws(text: string, region: Region = "Miền Bắc"): LotteryDraw[] {
  const lines = text.replace(/^\uFEFF/, "").split(/\r?\n/).filter((line) => line.trim());
  if (lines.length < 2) return [];
  const headers = lines[0].split(",").map((value) => value.trim());
  const dateIndex = headers.findIndex((value) =>
    ["date", "ngay", "ngày", "draw_date"].includes(value.toLowerCase()),
  );
  const stationIndex = headers.findIndex((value) => ["station", "dai", "đài"].includes(value.toLowerCase()));
  if (dateIndex < 0) return [];

  const seen = new Set<string>();
  return lines.slice(1).flatMap((line) => {
    const cells = line.split(",").map((value) => value.trim().replace(/^"|"$/g, ""));
    const date = cells[dateIndex];
    const station = stationIndex >= 0 && cells[stationIndex] ? cells[stationIndex] : region;
    const drawKey = `${date}|${station}`;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date ?? "") || seen.has(drawKey)) return [];
    const results: PrizeResult[] = [];
    cells.forEach((cell, columnIndex) => {
      if (columnIndex === dateIndex || columnIndex === stationIndex) return;
      const numbers = cell.match(/\d+/g) ?? [];
      numbers.forEach((value, position) => {
        results.push({
          prize: headers[columnIndex] || `Giải ${columnIndex}`,
          position: position + 1,
          value,
        });
      });
    });
    if (!results.length) return [];
    seen.add(drawKey);
    const stationSlug = station.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-zA-Z0-9]+/g, "-").replace(/^-|-$/g, "");
    const drawTime = region === "Miền Bắc" ? "18:15" : region === "Miền Trung" ? "17:15" : "16:15";
    return [{
      id: `csv-${region}-${stationSlug}-${date}`,
      drawCode: `CSV-${region}-${stationSlug}-${date}`,
      lotteryType: "TRADITIONAL" as const,
      date,
      drawnAt: `${date}T${drawTime}:00+07:00`,
      region,
      station,
      source: "CSV do người dùng nhập",
      collectedAt: new Date().toISOString(),
      verification: "PENDING" as const,
      results,
    }];
  });
}

export function parseJsonDraws(text: string, fallbackRegion: Region): LotteryDraw[] {
  const payload: unknown = JSON.parse(text);
  const records = Array.isArray(payload)
    ? payload
    : payload && typeof payload === "object" && Array.isArray((payload as { records?: unknown[] }).records)
      ? (payload as { records: unknown[] }).records
      : [];
  if (!records.length) throw new Error("JSON cần là một mảng hoặc có thuộc tính records.");

  const seen = new Set<string>();
  return records.map((raw, index) => {
    if (!raw || typeof raw !== "object") throw new Error(`Bản ghi ${index + 1} không hợp lệ.`);
    const record = raw as Record<string, unknown>;
    const date = String(record.date ?? record.draw_date ?? record.drawnAt ?? "").slice(0, 10);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(Date.parse(date))) throw new Error(`Bản ghi ${index + 1}: ngày không hợp lệ.`);
    const drawCode = String(record.drawCode ?? record.draw_code ?? `JSON-${fallbackRegion}-${date}`);
    if (seen.has(drawCode)) throw new Error(`Mã kỳ ${drawCode} bị trùng.`);
    seen.add(drawCode);

    const rawResults = Array.isArray(record.results) ? record.results : Array.isArray(record.prizes) ? record.prizes : [];
    const results: PrizeResult[] = rawResults.map((item, resultIndex) => {
      const result = item as Record<string, unknown>;
      const value = String(result.value ?? result.number ?? "");
      if (!/^\d{2,6}$/.test(value)) throw new Error(`Bản ghi ${index + 1}, kết quả ${resultIndex + 1}: số ngoài phạm vi.`);
      return { prize: String(result.prize ?? "Kết quả"), position: Number(result.position ?? resultIndex + 1), value };
    });
    if (!results.length) throw new Error(`Bản ghi ${index + 1}: thiếu danh sách kết quả.`);

    const region = ["Miền Bắc", "Miền Trung", "Miền Nam"].includes(String(record.region)) ? String(record.region) as Region : fallbackRegion;
    return {
      id: `json-${drawCode}`,
      drawCode,
      lotteryType: record.lotteryType === "COMBINATION" ? "COMBINATION" as const : "TRADITIONAL" as const,
      date,
      drawnAt: String(record.drawnAt ?? `${date}T18:00:00+07:00`),
      region,
      station: String(record.station ?? region),
      source: String(record.source ?? "JSON do người dùng nhập"),
      collectedAt: new Date().toISOString(),
      verification: "PENDING" as const,
      results,
    };
  });
}
