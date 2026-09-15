/**
 * Cache abstraction layer.
 * Uses Upstash Redis when configured, otherwise falls back to in-memory LRU.
 * This allows the app to run without any external dependencies.
 */

type CacheEntry<T> = { value: T; expiresAt: number };

type RedisCacheClient = {
  get: <T>(key: string) => Promise<T | null>;
  set: (key: string, value: unknown, opts?: { ex?: number }) => Promise<unknown>;
  del: (...keys: string[]) => Promise<number>;
  scan: (cursor: string | number, options?: { match?: string; count?: number }) => Promise<[string, string[]]>;
};

const MEMORY_STORE = new Map<string, CacheEntry<unknown>>();
const MEMORY_MAX_ENTRIES = 500;

function memoryGet<T>(key: string): T | null {
  const entry = MEMORY_STORE.get(key) as CacheEntry<T> | undefined;
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    MEMORY_STORE.delete(key);
    return null;
  }
  return entry.value;
}

function memorySet<T>(key: string, value: T, ttlSeconds: number) {
  if (MEMORY_STORE.size >= MEMORY_MAX_ENTRIES) {
    // Evict oldest entry
    const firstKey = MEMORY_STORE.keys().next().value;
    if (firstKey) MEMORY_STORE.delete(firstKey);
  }
  MEMORY_STORE.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
}

// Lazy-loaded Upstash client
let upstashClient: RedisCacheClient | null | undefined;

async function getUpstash() {
  if (upstashClient !== undefined) return upstashClient;
  const url = process.env.UPSTASH_REDIS_REST_URL?.trim();
  const token = process.env.UPSTASH_REDIS_REST_TOKEN?.trim();
  if (!url || !token) {
    upstashClient = null;
    return null;
  }
  try {
    const { Redis } = await import("@upstash/redis");
    upstashClient = new Redis({ url, token }) as RedisCacheClient;
    return upstashClient;
  } catch {
    upstashClient = null;
    return null;
  }
}

/**
 * Get a cached value by key.
 * Returns null if not found or expired.
 */
export async function cacheGet<T>(key: string): Promise<T | null> {
  // Try Upstash first
  const redis = await getUpstash();
  if (redis) {
    try {
      const value = await redis.get<T>(key);
      if (value !== null) return value;
    } catch {
      // Fall through to memory
    }
  }

  // Fallback to memory
  return memoryGet<T>(key);
}

/**
 * Set a value in cache with TTL.
 */
export async function cacheSet<T>(key: string, value: T, ttlSeconds: number): Promise<void> {
  const redis = await getUpstash();
  if (redis) {
    try {
      await redis.set(key, value, { ex: ttlSeconds });
      return;
    } catch {
      // Fall through to memory
    }
  }

  memorySet(key, value, ttlSeconds);
}

/**
 * Invalidate cache entries matching a prefix.
 * Used when new data is imported to clear stale analytics.
 */
export async function cacheInvalidate(prefix: string): Promise<void> {
  const redis = await getUpstash();
  if (redis) {
    try {
      let cursor = "0";
      do {
        const [nextCursor, keys] = await redis.scan(cursor, { match: `${prefix}*`, count: 100 });
        if (keys.length) await redis.del(...keys);
        cursor = nextCursor;
      } while (cursor !== "0");
    } catch {
      // Ignore errors
    }
  }

  // Clear matching memory entries
  for (const key of MEMORY_STORE.keys()) {
    if (key.startsWith(prefix)) MEMORY_STORE.delete(key);
  }
}

/**
 * Get or compute cached value.
 * If the key is not in cache, compute the value, store it, and return it.
 */
export async function cacheGetOrSet<T>(key: string, compute: () => Promise<T>, ttlSeconds: number): Promise<T> {
  const cached = await cacheGet<T>(key);
  if (cached !== null) return cached;

  const value = await compute();
  await cacheSet(key, value, ttlSeconds);
  return value;
}
