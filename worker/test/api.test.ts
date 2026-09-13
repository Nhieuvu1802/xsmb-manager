/**
 * Kiểm thử hợp đồng HTTP của Worker API v1.
 *
 * Test chạy trên chính bundle của Worker (SELF.fetch) nên phản ánh đúng những gì
 * app Flutter và website sẽ nhận trên production.
 */

import { SELF } from "cloudflare:test";
import { describe, expect, it } from "vitest";

import { MANIFEST, STATUS, allDraws, availableDates, historyRange } from "../src/dataset";
import type { Draw, Prize } from "../src/types";

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

interface DrawListBody {
  region: string;
  count: number;
  draws: Draw[];
  apiVersion: string;
  success: boolean;
  date: string | null;
  datasetDate: string | null;
  datasetVersion: string;
  stations: string[];
}

async function getJson<T>(path: string, init?: RequestInit): Promise<{ response: Response; body: T }> {
  const response = await SELF.fetch(`https://api.test${path}`, init);
  const text = await response.text();
  const body = text === "" ? (undefined as unknown as T) : (JSON.parse(text) as T);
  return { response, body };
}

function prizeSummary(results: Prize[]): { count: number; digits: boolean; unique: boolean } {
  const keys = new Set(results.map((item) => `${item.prize}#${item.position}`));
  return {
    count: results.length,
    digits: results.every((item) => /^\d+$/.test(item.value)),
    unique: keys.size === results.length,
  };
}

describe("GET /v1/health", () => {
  it("trả JSON ok kèm datasetDate và datasetVersion", async () => {
    const { response, body } = await getJson<Record<string, unknown>>("/v1/health");
    expect(response.status).toBe(200);
    expect(response.headers.get("content-type")).toContain("application/json");
    expect(response.headers.get("access-control-allow-origin")).toBe("*");
    expect(response.headers.get("cache-control")).toContain("max-age=60");
    expect(body.status).toBe("ok");
    expect(body.apiVersion).toBe("v1");
    expect(String(body.datasetDate)).toMatch(ISO_DATE);
    expect(body.datasetVersion).toBe(STATUS.datasetVersion);
    expect(body.datasetVersion).toBe(MANIFEST.datasetVersion);
    expect(body.generatedAt).toBe(MANIFEST.generatedAt);
    const regions = body.regions as Record<string, { prizesPerDraw: number }>;
    expect(regions.xsmb?.prizesPerDraw).toBe(27);
    expect(regions.xsmn?.prizesPerDraw).toBe(18);
  });
});

describe("GET /v1/xsmb/latest", () => {
  it("trả đủ 27 giải cho mỗi kỳ và đúng hợp đồng DrawListResponse", async () => {
    const { response, body } = await getJson<DrawListBody>("/v1/xsmb/latest");
    expect(response.status).toBe(200);
    expect(body.region).toBe("mb");
    expect(body.success).toBe(true);
    expect(body.apiVersion).toBe("v1");
    expect(body.count).toBe(body.draws.length);
    expect(body.count).toBeGreaterThan(0);
    expect(body.date).toMatch(ISO_DATE);
    for (const draw of body.draws) {
      expect(draw.region).toBe("mb");
      expect(draw.date).toMatch(ISO_DATE);
      expect(draw.station).toBe("Hội đồng XSKT miền Bắc");
      expect(draw.draw_code).toBe(`MB-${draw.date.replace(/-/g, "")}`);
      expect(draw.verification).toBe("VERIFIED");
      const summary = prizeSummary(draw.results);
      expect(summary.count).toBe(27);
      expect(summary.digits).toBe(true);
      expect(summary.unique).toBe(true);
    }
  });

  it("mặc định 7 kỳ gần nhất và tôn trọng tham số days", async () => {
    const available = availableDates("xsmb");
    const defaultBody = (await getJson<DrawListBody>("/v1/xsmb/latest")).body;
    expect(defaultBody.count).toBe(Math.min(7, available.length));
    const oneDay = (await getJson<DrawListBody>("/v1/xsmb/latest?days=1")).body;
    expect(oneDay.count).toBe(Math.min(1, available.length));
    expect(oneDay.date).toBe(available[0]);
  });

  it("từ chối tham số days không hợp lệ", async () => {
    for (const value of ["0", "abc", "1000", "-3"]) {
      const { response, body } = await getJson<Record<string, unknown>>(
        `/v1/xsmb/latest?days=${value}`,
      );
      expect(response.status).toBe(400);
      expect(body.code).toBe("invalid_query");
      expect(body.status).toBe("error");
      expect(String(body.message)).toContain("days");
    }
  });
});


describe("GET /v1/xsmn/latest", () => {
  it("trả 18 giải cho mỗi đài", async () => {
    const { response, body } = await getJson<DrawListBody>("/v1/xsmn/latest");
    expect(response.status).toBe(200);
    expect(body.region).toBe("mn");
    expect(body.count).toBe(body.draws.length);
    expect(body.count).toBeGreaterThan(0);
    for (const draw of body.draws) {
      expect(draw.region).toBe("mn");
      expect(draw.station.length).toBeGreaterThan(1);
      expect(draw.draw_code).toBe(`MN-${draw.date.replace(/-/g, "")}-${draw.station}`);
      const summary = prizeSummary(draw.results);
      expect(summary.count).toBe(18);
      expect(summary.digits).toBe(true);
      expect(summary.unique).toBe(true);
    }
    const expectedStations = [...new Set(allDraws("xsmn").map((draw) => draw.station))].sort();
    expect([...body.stations].sort()).toEqual(expectedStations);
  });

  it("lọc theo đài (không phân biệt hoa/thường và dấu)", async () => {
    const station = allDraws("xsmn")[0]!.station;
    const plain = station
      .normalize("NFD")
      .replace(/\p{Diacritic}/gu, "")
      .replace(/đ/giu, "d")
      .toUpperCase();

    const exact = await getJson<DrawListBody>(
      `/v1/xsmn/latest?province=${encodeURIComponent(station)}`,
    );
    expect(exact.response.status).toBe(200);
    expect(exact.body.count).toBeGreaterThan(0);
    expect(exact.body.draws.every((draw) => draw.station === station)).toBe(true);

    const relaxed = await getJson<DrawListBody>(
      `/v1/xsmn/latest?station=${encodeURIComponent(plain)}`,
    );
    expect(relaxed.body.count).toBe(exact.body.count);
    expect(relaxed.body.draws.every((draw) => draw.station === station)).toBe(true);
  });
});

describe("Truy vấn theo ngày và theo khoảng", () => {
  it("/v1/xsmb/{date} trả đúng kỳ của ngày có dữ liệu", async () => {
    const date = availableDates("xsmb")[0]!;
    const { response, body } = await getJson<DrawListBody>(`/v1/xsmb/${date}`);
    expect(response.status).toBe(200);
    expect(body.count).toBe(1);
    expect(body.draws[0]!.date).toBe(date);
  });

  it("ngày chưa có dữ liệu trả 404 JSON kèm danh sách ngày hiện có", async () => {
    const { response, body } = await getJson<Record<string, unknown>>(
      "/v1/xsmb/1999-01-01",
    );
    expect(response.status).toBe(404);
    expect(body.code).toBe("not_found");
    expect(body.detail).toBe(body.message);
    expect(body.availableDates).toEqual(availableDates("xsmb"));
  });

  it("/v1/xsmn/history lọc theo start và end", async () => {
    const date = availableDates("xsmn")[0]!;
    const inside = await getJson<DrawListBody>(
      `/v1/xsmn/history?start=${date}&end=${date}`,
    );
    expect(inside.response.status).toBe(200);
    expect(inside.body.count).toBe(
      allDraws("xsmn").filter((draw) => draw.date === date).length,
    );
    const outside = await getJson<DrawListBody>(
      "/v1/xsmn/history?start=1999-01-01&end=1999-12-31",
    );
    expect(outside.body.count).toBe(0);
    expect(outside.body.draws).toEqual([]);
    const invalid = await getJson<Record<string, unknown>>(
      "/v1/xsmn/history?start=2026-02-02&end=2026-01-01",
    );
    expect(invalid.response.status).toBe(400);
    expect(invalid.body.code).toBe("invalid_query");
  });
  it("/v1/xsmb/history trả cả cửa sổ 365 ngày thay vì một kỳ", async () => {
    const range = historyRange("xsmb");
    const { response, body } = await getJson<DrawListBody>(
      `/v1/xsmb/history?start=${range.firstDate}&end=${range.latestDate}`,
    );
    expect(response.status).toBe(200);
    expect(range.days).toBe(365);
    expect(body.count).toBe(allDraws("xsmb").length);
    expect(body.count).toBeGreaterThan(300);
    expect(new Set(body.draws.map((draw) => draw.date)).size).toBe(body.count);
  });

  it("/v1/xsmn/history giữ đài riêng của từng ngày", async () => {
    const range = historyRange("xsmn");
    const { body } = await getJson<DrawListBody>(
      `/v1/xsmn/history?start=${range.firstDate}&end=${range.latestDate}`,
    );
    expect(new Set(body.draws.map((draw) => draw.date)).size).toBeGreaterThan(300);
    const firstDate = body.draws[0]!.date;
    const sameDay = body.draws.filter((draw) => draw.date === firstDate);
    expect(new Set(sameDay.map((draw) => draw.station)).size).toBe(sameDay.length);
  });

  it("/v1/xsmb/latest?days=90 trả đủ 90 ngày gần nhất", async () => {
    const { body } = await getJson<DrawListBody>("/v1/xsmb/latest?days=90");
    expect(new Set(body.draws.map((draw) => draw.date)).size).toBe(90);
    expect(body.date).toBe(availableDates("xsmb")[0]);
  });

});


describe("Header, cache và định tuyến", () => {
  it("hỗ trợ ETag/If-None-Match để tiết kiệm băng thông", async () => {
    const first = await SELF.fetch("https://api.test/v1/xsmb/latest");
    expect(first.status).toBe(200);
    const tag = first.headers.get("etag");
    expect(tag).toContain(STATUS.datasetVersion);
    const cached = await SELF.fetch("https://api.test/v1/xsmb/latest", {
      headers: { "if-none-match": tag! },
    });
    expect(cached.status).toBe(304);
    expect(await cached.text()).toBe("");
    expect(cached.headers.get("access-control-allow-origin")).toBe("*");
  });

  it("trả lỗi cho phương thức không hỗ trợ và preflight cho OPTIONS", async () => {
    const post = await SELF.fetch("https://api.test/v1/health", { method: "POST" });
    expect(post.status).toBe(405);
    expect((await post.json<{ code: string }>()).code).toBe("method_not_allowed");

    const preflight = await SELF.fetch("https://api.test/v1/xsmb/latest", {
      method: "OPTIONS",
      headers: { Origin: "https://vvn.freedev.app" },
    });
    expect(preflight.status).toBe(204);
    expect(preflight.headers.get("access-control-allow-origin")).toBe("*");
    expect(preflight.headers.get("access-control-allow-methods")).toContain("GET");
    expect(await preflight.text()).toBe("");
  });

  it("trả 404 JSON cho đường dẫn không tồn tại", async () => {
    for (const path of ["/v2/xsmb/latest", "/v1/xsmb", "/v1/xsmb/abc", "/v1/mt/latest"]) {
      const { response, body } = await getJson<Record<string, unknown>>(path);
      expect(response.status, `path ${path}`).not.toBe(200);
      expect(response.headers.get("cache-control")).toBe("no-store");
      expect(body.status).toBe("error");
    }
  });

  it("liệt kê endpoint ở tài liệu gốc", async () => {
    const { response, body } = await getJson<Record<string, unknown>>("/");
    expect(response.status).toBe(200);
    expect(body.service).toBe("xsmb-manager-api");
    expect(String(body.datasetVersion)).toBe(STATUS.datasetVersion);
    expect((body.endpoints as string[]).some((url) => url.endsWith("/v1/health"))).toBe(true);
  });

  it("công bố config và manifest công khai", async () => {
    const config = await getJson<Record<string, unknown>>("/v1/config");
    expect(config.response.status).toBe(200);
    expect(config.body.apiVersion).toBe("v1");
    expect(String(config.body.apiBaseUrl)).toContain("/v1");

    const manifest = await getJson<Record<string, unknown>>("/v1/manifest");
    expect(manifest.response.status).toBe(200);
    expect(manifest.body.datasetVersion).toBe(STATUS.datasetVersion);
    expect(manifest.body.servedBy).toBe("cloudflare-worker");
  });
});
