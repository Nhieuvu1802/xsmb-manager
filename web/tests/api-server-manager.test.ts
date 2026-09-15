import { describe, expect, it, vi } from "vitest";
import { ApiServerManager } from "../lib/api-server-manager";

function manager(statuses: Record<string, number>, cache: object | null = { cached: true }) {
  const fetcher = vi.fn(async (url: string | URL | Request) => {
    const key = String(url).includes("primary") ? "primary" : "backup";
    const status = statuses[key];
    return new Response(JSON.stringify({ key }), { status });
  }) as unknown as typeof fetch;
  return { instance: new ApiServerManager("https://primary/api", "https://backup/api", () => cache, () => {}, 100, fetcher), fetcher };
}

describe("ApiServerManager", () => {
  it("uses primary when both are up", async () => expect((await manager({ primary: 200, backup: 200 }).instance.get("draws")).source).toBe("primary"));
  it("uses backup when primary is down", async () => expect((await manager({ primary: 500, backup: 200 }).instance.get("draws")).source).toBe("backup"));
  it("uses primary when backup is down", async () => expect((await manager({ primary: 200, backup: 500 }).instance.get("draws")).source).toBe("primary"));
  it("uses marked stale cache when both are down", async () => expect(await manager({ primary: 500, backup: 500 }).instance.get("draws")).toMatchObject({ source: "cache", stale: true }));
  it("does not fail over on a client error", async () => { const item = manager({ primary: 401, backup: 200 }); await expect(item.instance.get("draws")).rejects.toThrow("HTTP 401"); expect(item.fetcher).toHaveBeenCalledTimes(1); });
});
