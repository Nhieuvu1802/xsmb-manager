import { describe, expect, it } from "vitest";
import { SAMPLE_DRAWS } from "../lib/sample-data";
import { canonicalStationName, stationMatches, stationsForRegion } from "../lib/stations";

describe("dữ liệu ba miền", () => {
  it("có danh mục đài miền Trung và miền Nam", () => {
    expect(stationsForRegion("Miền Trung")).toHaveLength(14);
    expect(stationsForRegion("Miền Nam")).toHaveLength(21);
  });

  it("không có mã kỳ mô phỏng bị trùng", () => {
    const codes = SAMPLE_DRAWS.map((draw) => draw.drawCode);
    expect(new Set(codes).size).toBe(codes.length);
  });

  it("dùng đúng cấu trúc giải theo miền", () => {
    expect(SAMPLE_DRAWS.find((draw) => draw.region === "Miền Bắc")?.results).toHaveLength(27);
    expect(SAMPLE_DRAWS.find((draw) => draw.region === "Miền Trung")?.results).toHaveLength(18);
    expect(SAMPLE_DRAWS.find((draw) => draw.region === "Miền Nam")?.results).toHaveLength(18);
  });

  it("chuẩn hóa tên TPHCM từ nguồn dữ liệu", () => {
    expect(stationMatches("TPHCM", "TP. Hồ Chí Minh")).toBe(true);
    expect(canonicalStationName("TPHCM", "Miền Nam")).toBe("TP. Hồ Chí Minh");
  });
});
