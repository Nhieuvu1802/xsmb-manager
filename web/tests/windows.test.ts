import { describe, expect, it } from "vitest";
import { compareWindows, lookupNumber, calculateNumberStats } from "../lib/statistics";
import { SAMPLE_DRAWS } from "../lib/sample-data";

describe("compareWindows", () => {
  it("trả về 5 cửa sổ mặc định", () => {
    const windows = compareWindows(SAMPLE_DRAWS);
    expect(windows).toHaveLength(5);
    expect(windows[0].period).toBe(7);
    expect(windows[4].period).toBe(365);
  });

  it("mỗi cửa sổ có đủ trường", () => {
    const windows = compareWindows(SAMPLE_DRAWS);
    for (const w of windows) {
      expect(w.draws).toBeGreaterThan(0);
      expect(w.slots).toBeGreaterThan(0);
      expect(w.distinct).toBeGreaterThan(0);
      expect(w.distinct).toBeLessThanOrEqual(100);
      expect(w.chiSquare).toBeGreaterThanOrEqual(0);
      expect(w.top).toHaveLength(3);
      expect(w.bottom).toHaveLength(3);
      expect(w.longestGap).toBeGreaterThanOrEqual(0);
    }
  });

  it("cửa sổ nhỏ hơn có số kỳ đúng", () => {
    const windows = compareWindows(SAMPLE_DRAWS, [7, 30]);
    expect(windows[0].draws).toBe(7);
    expect(windows[1].draws).toBe(30);
  });
});

describe("lookupNumber", () => {
  it("trả về thống kê cho số hợp lệ", () => {
    const result = lookupNumber(SAMPLE_DRAWS, "07");
    expect(result).not.toBeNull();
    expect(result!.number).toBe("07");
    expect(result!.count).toBeGreaterThanOrEqual(0);
    expect(result!.wilsonLow).toBeLessThanOrEqual(result!.wilsonHigh);
    expect(result!.currentStreak).toBeGreaterThanOrEqual(0);
    expect(result!.longestStreak).toBeGreaterThanOrEqual(0);
  });

  it("padStart 2 chữ số cho số 1 chữ số", () => {
    const result = lookupNumber(SAMPLE_DRAWS, "7");
    expect(result!.number).toBe("07");
  });

  it("trả null cho số ngoài 00-99", () => {
    const result = lookupNumber(SAMPLE_DRAWS, "abc");
    expect(result).toBeNull();
  });
});

describe("calculateNumberStats streaks", () => {
  it("currentStreak và longestStreak >= 0", () => {
    const stats = calculateNumberStats(SAMPLE_DRAWS.slice(0, 30));
    for (const s of stats) {
      expect(s.currentStreak).toBeGreaterThanOrEqual(0);
      expect(s.longestStreak).toBeGreaterThanOrEqual(0);
      expect(s.longestStreak).toBeGreaterThanOrEqual(s.currentStreak);
    }
  });

  it("tÃ­nh gap vÃ  currentStreak tá»« ká»³ má»›i nháº¥t dá»¥ báº£n ghi Ä‘áº§u vÃ o bá»‹ Ä‘áº£o chiá»u", () => {
    const referenceRegion = SAMPLE_DRAWS[0].region;
    const base = SAMPLE_DRAWS.filter((draw) => draw.region === referenceRegion).slice(0, 4);
    const newestFirst = base.map((draw, index) => ({
      ...draw,
      results: [{ prize: "Test", position: 1, value: index < 2 ? "07" : "08" }],
    }));

    const fromNewest = calculateNumberStats(newestFirst).find((item) => item.number === "07")!;
    const fromOldest = calculateNumberStats([...newestFirst].reverse()).find((item) => item.number === "07")!;

    expect(fromNewest.gap).toBe(0);
    expect(fromNewest.currentStreak).toBe(2);
    expect(fromOldest).toEqual(fromNewest);
  });

  it("cá»­a sá»• so sÃ¡nh láº¥y ká»³ má»›i nháº¥t, khÃ´ng pháº£i ká»³ cÅ© nháº¥t", () => {
    const referenceRegion = SAMPLE_DRAWS[0].region;
    const draws = SAMPLE_DRAWS.filter((draw) => draw.region === referenceRegion).slice(0, 10)
      .map((draw, index) => ({
        ...draw,
        results: [{ prize: "Test", position: 1, value: index < 7 ? "07" : "99" }],
      }));

    const window = compareWindows([...draws].reverse(), [7])[0];
    expect(window.top[0]).toEqual({ number: "07", count: 7 });
  });
});
