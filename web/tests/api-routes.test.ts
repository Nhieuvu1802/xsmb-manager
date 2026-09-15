import { describe, expect, it } from "vitest";
import { GET as drawsGET } from "../app/api/draws/route";
import { GET as healthGET } from "../app/api/health/route";
import { GET as compareGET } from "../app/api/stats/compare/route";

describe("GET /api/draws", () => {
  it("trả danh sách kỳ với phân trang", async () => {
    const response = await drawsGET(new Request("http://localhost/api/draws?limit=5"));
    const body = await response.json();
    expect(response.status).toBe(200);
    expect(body.draws).toHaveLength(5);
    expect(body.total).toBeGreaterThan(0);
    expect(typeof body.hasMore).toBe("boolean");
  });

  it("lọc theo from/to", async () => {
    const response = await drawsGET(new Request("http://localhost/api/draws?from=2026-09-01&to=2026-09-12"));
    const body = await response.json();
    expect(response.status).toBe(200);
    for (const draw of body.draws) {
      expect(draw.date >= "2026-09-01").toBe(true);
      expect(draw.date <= "2026-09-12").toBe(true);
    }
  });
});

describe("GET /api/health", () => {
  it("trả status healthy", async () => {
    const response = await healthGET();
    const body = await response.json();
    expect(response.status).toBe(200);
    expect(body.status).toBe("healthy");
    expect(body.version).toBeTruthy();
    expect(["postgres", "worker", "sample"]).toContain(body.storage);
  }, 15_000);
});

describe("GET /api/stats/compare", () => {
  it("trả 5 cửa sổ so sánh", async () => {
    const response = await compareGET(new Request("http://localhost/api/stats/compare"));
    const body = await response.json();
    expect(response.status).toBe(200);
    expect(body.windows).toHaveLength(5);
    expect(body.region).toBe("Miền Bắc");
  });

  it("từ chối miền không hợp lệ", async () => {
    const response = await compareGET(new Request("http://localhost/api/stats/compare?region=Invalid"));
    expect(response.status).toBe(422);
  });
});
