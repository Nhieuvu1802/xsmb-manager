/**
 * Kiểm thử R2 Budget Guard.
 *
 * Test các hàm pure logic: parseLimits, checkBudget (với mock R2Bucket).
 * Không cần cloudflare:test binding — mock R2Bucket trực tiếp.
 */

import { describe, expect, it, vi, beforeEach } from "vitest";
import {
  checkBudget,
  parseLimits,
  activateCircuitBreaker,
  deactivateCircuitBreaker,
  DEFAULT_LIMITS,
  type BudgetMeta,
} from "../src/r2-budget";

/* -------------------------------------------------------------------------- */
/* Mock R2Bucket                                                              */
/* -------------------------------------------------------------------------- */

function createMockBucket(initialMeta?: BudgetMeta) {
  const store = new Map<string, string>();
  if (initialMeta) {
    store.set("_meta/budget.json", JSON.stringify(initialMeta));
  }
  return {
    get: vi.fn(async (key: string) => {
      const data = store.get(key);
      if (!data) return null;
      return { json: async () => JSON.parse(data) } as unknown as R2Object;
    }),
    put: vi.fn(async (key: string, value: string | ArrayBuffer) => {
      const str = typeof value === "string" ? value : new TextDecoder().decode(value);
      store.set(key, str);
      return {} as R2Object;
    }),
    list: vi.fn(async () => ({ objects: [], truncated: false })),
    _store: store,
  };
}

/* -------------------------------------------------------------------------- */
/* Tests                                                                      */
/* -------------------------------------------------------------------------- */

describe("parseLimits", () => {
  it("trả defaults khi env rỗng", () => {
    const limits = parseLimits({});
    expect(limits.maxStorageBytes).toBe(DEFAULT_LIMITS.maxStorageBytes);
    expect(limits.maxWritesPerMonth).toBe(DEFAULT_LIMITS.maxWritesPerMonth);
    expect(limits.hardLimitPercent).toBe(DEFAULT_LIMITS.hardLimitPercent);
  });

  it("parse env vars đúng", () => {
    const limits = parseLimits({
      R2_MAX_STORAGE_BYTES: "5000000000",
      R2_MAX_WRITES_MONTH: "1000000",
      R2_SOFT_LIMIT_PERCENT: "70",
      R2_HARD_LIMIT_PERCENT: "90",
    });
    expect(limits.maxStorageBytes).toBe(5_000_000_000);
    expect(limits.maxWritesPerMonth).toBe(1_000_000);
    expect(limits.softLimitPercent).toBe(70);
    expect(limits.hardLimitPercent).toBe(90);
  });
});

describe("checkBudget", () => {
  it("trả OK khi bucket trống", async () => {
    const bucket = createMockBucket();
    const result = await checkBudget(bucket as any, "write", 1000);
    expect(result.allowed).toBe(true);
    expect(result.severity).toBe("ok");
    expect(result.usage.writesThisMonth).toBe(1);
    expect(result.usage.storagePercent).toBeGreaterThanOrEqual(0);
  });

  it("trả soft limit khi gần reached", async () => {
    const meta: BudgetMeta = {
      storageBytes: Math.floor(DEFAULT_LIMITS.maxStorageBytes * 0.85),
      writesThisMonth: Math.floor(DEFAULT_LIMITS.maxWritesPerMonth * 0.85),
      readsThisMonth: 0,
      currentMonth: new Date().toISOString().slice(0, 7),
      lastUpdated: new Date().toISOString(),
      circuitBreaker: false,
    };
    const bucket = createMockBucket(meta);
    const result = await checkBudget(bucket as any, "write", 0);
    expect(result.allowed).toBe(true);
    expect(result.severity).toBe("soft");
  });

  it("trả hard limit khi storage quá 95%", async () => {
    const meta: BudgetMeta = {
      storageBytes: Math.floor(DEFAULT_LIMITS.maxStorageBytes * 0.96),
      writesThisMonth: 0,
      readsThisMonth: 0,
      currentMonth: new Date().toISOString().slice(0, 7),
      lastUpdated: new Date().toISOString(),
      circuitBreaker: false,
    };
    const bucket = createMockBucket(meta);
    const result = await checkBudget(bucket as any, "write", 0);
    expect(result.allowed).toBe(false);
    expect(result.severity).toBe("hard");
    expect(result.message).toContain("HARD LIMIT");
  });

  it("trả hard limit khi writes quá 95%", async () => {
    const meta: BudgetMeta = {
      storageBytes: 0,
      writesThisMonth: Math.floor(DEFAULT_LIMITS.maxWritesPerMonth * 0.96),
      readsThisMonth: 0,
      currentMonth: new Date().toISOString().slice(0, 7),
      lastUpdated: new Date().toISOString(),
      circuitBreaker: false,
    };
    const bucket = createMockBucket(meta);
    const result = await checkBudget(bucket as any, "write", 0);
    expect(result.allowed).toBe(false);
    expect(result.severity).toBe("hard");
  });

  it("reads luôn allowed", async () => {
    const meta: BudgetMeta = {
      storageBytes: DEFAULT_LIMITS.maxStorageBytes + 1_000_000_000,
      writesThisMonth: DEFAULT_LIMITS.maxWritesPerMonth + 1_000_000,
      readsThisMonth: 0,
      currentMonth: new Date().toISOString().slice(0, 7),
      lastUpdated: new Date().toISOString(),
      circuitBreaker: false,
    };
    const bucket = createMockBucket(meta);
    const result = await checkBudget(bucket as any, "read", 0);
    expect(result.allowed).toBe(true);
  });
});

describe("circuit breaker", () => {
  it("activate chặn writes", async () => {
    const bucket = createMockBucket();
    await activateCircuitBreaker(bucket as any, "test reason");
    const result = await checkBudget(bucket as any, "write", 0);
    expect(result.allowed).toBe(false);
    expect(result.severity).toBe("blocked");
    expect(result.message).toContain("test reason");
  });

  it("deactivate cho phép writes lại", async () => {
    const bucket = createMockBucket();
    await activateCircuitBreaker(bucket as any, "test");
    await deactivateCircuitBreaker(bucket as any);
    const result = await checkBudget(bucket as any, "write", 0);
    expect(result.allowed).toBe(true);
    expect(result.severity).toBe("ok");
  });
});
