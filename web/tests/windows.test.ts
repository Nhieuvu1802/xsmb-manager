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
});
