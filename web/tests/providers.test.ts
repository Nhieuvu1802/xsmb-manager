import { describe, expect, it } from "vitest";
import { ProviderChain } from "../lib/server/providers/chain";
import { computeHealthScore } from "../lib/server/providers/health-scoring";
import type { LotteryProvider } from "../lib/server/providers/types";

function mockProvider(code: string, opts?: {
  fetchResult?: unknown[];
  fetchError?: Error;
}): LotteryProvider {
  const base = {
    code,
    name: `Mock ${code}`,
    async fetchXSMB() { if (opts?.fetchError) throw opts.fetchError; return (opts?.fetchResult ?? []) as never[]; },
    async fetchXSMN() { if (opts?.fetchError) throw opts.fetchError; return (opts?.fetchResult ?? []) as never[]; },
    async fetchXSMT() { if (opts?.fetchError) throw opts.fetchError; return (opts?.fetchResult ?? []) as never[]; },
    async fetchByDate() { if (opts?.fetchError) throw opts.fetchError; return (opts?.fetchResult ?? []) as never[]; },
    async fetchHistory() { if (opts?.fetchError) throw opts.fetchError; return (opts?.fetchResult ?? []) as never[]; },
    async healthCheck() { return { reachable: !opts?.fetchError, latencyMs: 0 }; },
  };
  return base;
}

describe("health-scoring", () => {
  it("zero calls → score 0", () => {
    expect(computeHealthScore({
      code: "a", name: "A", successCount: 0, failureCount: 0,
      averageResponseTimeMs: 0, lastSuccessMs: null, lastFailureMs: null,
    })).toBe(0);
  });

  it("100% success fast → high score", () => {
    const score = computeHealthScore({
      code: "a", name: "A", successCount: 100, failureCount: 0,
      averageResponseTimeMs: 50, lastSuccessMs: Date.now() - 1000, lastFailureMs: null,
    });
    expect(score).toBeGreaterThanOrEqual(90);
  });

  it("50% success → medium score", () => {
    const score = computeHealthScore({
      code: "a", name: "A", successCount: 50, failureCount: 50,
      averageResponseTimeMs: 500, lastSuccessMs: Date.now() - 30_000, lastFailureMs: Date.now(),
    });
    expect(score).toBeGreaterThanOrEqual(30);
    expect(score).toBeLessThan(70);
  });

  it("slow response degrades score", () => {
    const fast = computeHealthScore({
      code: "a", name: "A", successCount: 10, failureCount: 0,
      averageResponseTimeMs: 100, lastSuccessMs: Date.now(), lastFailureMs: null,
    });
    const slow = computeHealthScore({
      code: "a", name: "A", successCount: 10, failureCount: 0,
      averageResponseTimeMs: 4000, lastSuccessMs: Date.now(), lastFailureMs: null,
    });
    expect(fast).toBeGreaterThan(slow);
  });
});

describe("ProviderChain", () => {
  it("uses first provider when it succeeds", async () => {
    const chain = new ProviderChain([
      mockProvider("primary", { fetchResult: [{ id: 1 }] }),
      mockProvider("backup", { fetchResult: [{ id: 2 }] }),
    ]);
    const result = await chain.execute(async (p) => p.fetchXSMB());
    expect(result.source).toBe("primary");
    expect(result.stale).toBe(false);
  });

  it("falls through on 500", async () => {
    const chain = new ProviderChain([
      mockProvider("primary", { fetchError: new Error("HTTP 500") }),
      mockProvider("backup", { fetchResult: [{ id: 2 }] }),
    ]);
    const result = await chain.execute(async (p) => p.fetchXSMB());
    expect(result.source).toBe("backup");
  });

  it("does NOT failover on 401", async () => {
    const chain = new ProviderChain([
      mockProvider("primary", { fetchError: new Error("HTTP 401") }),
      mockProvider("backup", { fetchResult: [{ id: 2 }] }),
    ]);
    await expect(chain.execute(async (p) => p.fetchXSMB())).rejects.toThrow("HTTP 401");
  });

  it("does NOT failover on 403", async () => {
    const chain = new ProviderChain([
      mockProvider("primary", { fetchError: new Error("HTTP 403") }),
      mockProvider("backup", { fetchResult: [{ id: 2 }] }),
    ]);
    await expect(chain.execute(async (p) => p.fetchXSMB())).rejects.toThrow("HTTP 403");
  });

  it("all fail → throws", async () => {
    const chain = new ProviderChain([
      mockProvider("a", { fetchError: new Error("HTTP 503") }),
      mockProvider("b", { fetchError: new Error("fetch failed") }),
    ]);
    await expect(chain.execute(async () => { throw new Error("All dead"); })).rejects.toThrow();
  });

  it("tracks health scores after failover", async () => {
    const chain = new ProviderChain([
      mockProvider("primary", { fetchError: new Error("HTTP 500") }),
      mockProvider("backup", { fetchResult: [] }),
    ]);
    await chain.execute(async (p) => p.fetchXSMB());
    const scores = chain.getHealthScores();
    expect(scores.find((s) => s.code === "primary")!.failureCount).toBe(1);
    expect(scores.find((s) => s.code === "backup")!.successCount).toBe(1);
  });
});
