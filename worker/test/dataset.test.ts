/**
 * Kiểm thử tính toàn vẹn của dataset được bundle vào Worker.
 *
 * Nếu snapshot trong `public-data/` bị lỗi (thiếu giải, sai ngày, lệch
 * datasetVersion) thì deploy sẽ dừng ngay ở bước test thay vì phục vụ dữ liệu
 * sai cho app.
 */

import { describe, expect, it } from "vitest";

import {
  MANIFEST,
  PUBLIC_CONFIG,
  STATUS,
  allDraws,
  availableDates,
  datasetDate,
  datasetHealthy,
  datasetVersion,
  latestDraws,
  normalizeText,
  prizeCount,
} from "../src/dataset";

const MB_PRIZE_COUNT = 27;
const MN_PRIZE_COUNT = 18;

describe("Dataset snapshot", () => {
  it("khớp metadata công bố trong public-data", () => {
    expect(datasetHealthy()).toBe(true);
    expect(datasetVersion()).toBe(STATUS.datasetVersion);
    expect(datasetVersion()).toBe(MANIFEST.datasetVersion);
    expect(datasetDate()).toBe(availableDates("xsmb")[0]);
    expect(datasetDate()).toBe(availableDates("xsmn")[0]);
    expect(PUBLIC_CONFIG.apiVersion).toBe("v1");
  });

  it("có đúng số giải luật quy định", () => {
    expect(prizeCount("xsmb")).toBe(MB_PRIZE_COUNT);
    expect(prizeCount("xsmn")).toBe(MN_PRIZE_COUNT);
    for (const draw of allDraws("xsmb")) {
      expect(draw.results).toHaveLength(MB_PRIZE_COUNT);
      expect(draw.date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    }
    for (const draw of allDraws("xsmn")) {
      expect(draw.results).toHaveLength(MN_PRIZE_COUNT);
    }
  });

  it("mọi giá trị giải đều là chữ số và có 2 số cuối", () => {
    for (const draw of [...allDraws("xsmb"), ...allDraws("xsmn")]) {
      for (const result of draw.results) {
        expect(result.value, `${draw.station} ${result.prize}`).toMatch(/^\d{2,6}$/);
        expect(result.value.slice(-2)).toMatch(/^\d{2}$/);
        expect(result.prize.length).toBeGreaterThan(2);
      }
    }
  });

  it("lọc theo số ngày và theo đài hoạt động đúng", () => {
    const oneDay = latestDraws("xsmn", 1);
    expect(oneDay.draws.every((draw) => draw.date === oneDay.date)).toBe(true);
    expect(oneDay.draws.length).toBe(
      allDraws("xsmn").filter((draw) => draw.date === oneDay.date).length,
    );
    const filtered = latestDraws("xsmn", 7, normalizeText(allDraws("xsmn")[0]!.station));
    expect(filtered.draws.length).toBeGreaterThan(0);
    expect(filtered.draws.length).toBeLessThanOrEqual(oneDay.draws.length);
  });

  it("normalizeText bỏ dấu tiếng Việt", () => {
    expect(normalizeText("Bình Phước")).toBe("binh phuoc");
    expect(normalizeText("Hội đồng XSKT miền Bắc")).toBe("hoi dong xskt mien bac");
  });
});
