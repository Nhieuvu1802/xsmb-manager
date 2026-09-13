import { describe, expect, it } from "vitest";
import {
  calculateNumberStats,
  calculatePairStats,
  calculateDayOfWeekStats,
  calculateSetProbability,
  combinations,
  exactDigitProbability,
  expectedValue,
  monteCarloAtLeastOne,
  parseCsvDraws,
  validateCsv,
  wilsonInterval,
} from "../lib/statistics";
import { SAMPLE_DRAWS } from "../lib/sample-data";

describe("công thức xác suất", () => {
  it("tính đúng xác suất kết quả 2–6 chữ số", () => {
    expect(exactDigitProbability(2)).toBe(0.01);
    expect(exactDigitProbability(6)).toBe(0.000001);
  });

  it("tính xác suất ít nhất một lần", () => {
    expect(calculateSetProbability(1, 27)).toBeCloseTo(1 - 0.99 ** 27, 12);
  });

  it("tính tổ hợp và giá trị kỳ vọng", () => {
    expect(combinations(45, 6)).toBe(8_145_060);
    expect(expectedValue(10_000, 70_000, 0.01)).toBe(-9_300);
  });

  it("mô phỏng hội tụ gần công thức", () => {
    const simulated = monteCarloAtLeastOne(5, 27, 100_000, 2409);
    expect(simulated).toBeCloseTo(calculateSetProbability(5, 27), 2);
  });

  it("khoảng Wilson chứa tần suất quan sát", () => {
    const [low, high] = wilsonInterval(25, 100);
    expect(low).toBeLessThan(0.25);
    expect(high).toBeGreaterThan(0.25);
  });
});

describe("dữ liệu và thống kê", () => {
  it("luôn trả đủ thống kê 00–99", () => {
    const stats = calculateNumberStats(SAMPLE_DRAWS.slice(0, 30));
    expect(stats).toHaveLength(100);
    expect(stats[0].number).toBe("00");
    expect(stats[99].number).toBe("99");
  });

  it("phát hiện trùng và sai ngày trong CSV", () => {
    const result = validateCsv("date,dac_biet\n2026-09-12,12345\n2026-09-12,54321\nsai-ngay,11111");
    expect(result.validRows).toBe(1);
    expect(result.duplicateRows).toBe(1);
    expect(result.issues.some((issue) => issue.level === "error")).toBe(true);
  });

  it("chuyển CSV hợp lệ thành kỳ quay", () => {
    const draws = parseCsvDraws("date,dac_biet,giai_nhat\n2026-09-12,12345,54321", "Miền Bắc");
    expect(draws).toHaveLength(1);
    expect(draws[0].results).toHaveLength(2);
    expect(draws[0].verification).toBe("PENDING");
  });
});

describe("cặp số và phân bố ngày", () => {
  it("calculatePairStats trả về cặp xuất hiện nhiều nhất", () => {
    const pairs = calculatePairStats(SAMPLE_DRAWS.slice(0, 30));
    expect(pairs.length).toBeGreaterThan(0);
    expect(pairs.length).toBeLessThanOrEqual(30);
    expect(pairs[0].count).toBeGreaterThanOrEqual(pairs[1]?.count ?? 0);
    expect(pairs[0].pair).toMatch(/^\d{2}-\d{2}$/);
  });

  it("calculateDayOfWeekStats trả đủ 7 ngày", () => {
    const days = calculateDayOfWeekStats(SAMPLE_DRAWS.slice(0, 30));
    expect(days).toHaveLength(7);
    expect(days.map((d) => d.day)).toEqual(["CN", "T2", "T3", "T4", "T5", "T6", "T7"]);
    const totalDraws = days.reduce((sum, d) => sum + d.drawHits, 0);
    expect(totalDraws).toBe(30);
  });

  it("pairStats trả rỗng khi không có dữ liệu", () => {
    expect(calculatePairStats([])).toHaveLength(0);
  });

  it("dayStats trả 0 cho mỗi ngày khi không có dữ liệu", () => {
    const days = calculateDayOfWeekStats([]);
    expect(days.every((d) => d.count === 0 && d.drawHits === 0)).toBe(true);
  });
});

