import { afterEach, describe, expect, it } from "vitest";
import { cacheGet, cacheInvalidate, cacheSet } from "../lib/server/cache";

const prefix = "test:cache:";

afterEach(async () => {
  await cacheInvalidate(prefix);
});

describe("statistics cache", () => {
  it("stores a value with TTL and invalidates every key under a prefix", async () => {
    await cacheSet(`${prefix}one`, { value: 1 }, 60);
    await cacheSet(`${prefix}two`, { value: 2 }, 60);

    expect(await cacheGet(`${prefix}one`)).toEqual({ value: 1 });
    expect(await cacheGet(`${prefix}two`)).toEqual({ value: 2 });

    await cacheInvalidate(prefix);
    expect(await cacheGet(`${prefix}one`)).toBeNull();
    expect(await cacheGet(`${prefix}two`)).toBeNull();
  });
});
