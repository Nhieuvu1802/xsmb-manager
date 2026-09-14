import { describe, expect, it } from "vitest";
import { fetchWorkerHistory, fetchWorkerLatest, checkWorkerHealth } from "../lib/worker-api-client";

describe("Worker API client", () => {
  it("checkWorkerHealth tra reachable=true", async () => {
    const health = await checkWorkerHealth();
    expect(health.reachable).toBe(true);
    expect(health.xsmbDraws).toBeGreaterThan(0);
    expect(health.xsmnDraws).toBeGreaterThan(0);
  });

  it("fetchWorkerHistory lays lich su XSMB 3 ngay", async () => {
    const draws = await fetchWorkerHistory("Miền Bắc", "2026-09-10", "2026-09-12");
    expect(draws.length).toBe(3);
    for (const draw of draws) {
      expect(draw.region).toBe("Miền Bắc");
      expect(draw.results.length).toBe(27);
      expect(draw.date >= "2026-09-10").toBe(true);
      expect(draw.date <= "2026-09-12").toBe(true);
    }
  });

  it("fetchWorkerHistory lays lich su XSMN", async () => {
    const draws = await fetchWorkerHistory("Miền Nam", "2026-09-11", "2026-09-12");
    expect(draws.length).toBeGreaterThan(0);
    for (const draw of draws) {
      expect(draw.region).toBe("Miền Nam");
      expect(draw.results.length).toBe(18);
    }
  });

  it("fetchWorkerLatest lays XSMB moi nhat", async () => {
    const draws = await fetchWorkerLatest("Miền Bắc");
    expect(draws.length).toBeGreaterThanOrEqual(1);
    for (const draw of draws) {
      expect(draw.region).toBe("Miền Bắc");
      expect(draw.verification).toBe("VERIFIED");
    }
  });

  it("fetchWorkerHistory tra [] cho Mien Trung (chua co du lieu)", async () => {
    const draws = await fetchWorkerHistory("Miền Trung", "2026-09-10", "2026-09-12");
    expect(draws).toEqual([]);
  });
});
