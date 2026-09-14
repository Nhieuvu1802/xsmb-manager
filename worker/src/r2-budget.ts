/**
 * R2 Budget Guard — tự động ngắt ghi R2 khi gần hết quota free tier.
 *
 * Cloudflare R2 Free Tier limits:
 *   - Storage:         10 GB
 *   - Class A (write): 10,000,000 requests/month
 *   - Class B (read):  10,000,000 requests/month
 *
 * Strategy:
 *   1. Metadata `_meta/budget.json` trong R2 track usage.
 *   2. Mỗi lần ghi → đọc metadata → kiểm tra → ghi nếu hợp lệ.
 *   3. Quá budget → trả 503 + log, KHÔNG ghi.
 *   4. Reads luôn được phép.
 *
 * Default limits: 9GB storage (90%), 9M writes (90%).
 */

import type { R2Bucket } from "@cloudflare/workers-types";

export interface BudgetMeta {
  storageBytes: number;
  writesThisMonth: number;
  readsThisMonth: number;
  currentMonth: string;
  lastUpdated: string;
  circuitBreaker: boolean;
  blockedReason?: string;
}

export interface BudgetLimits {
  maxStorageBytes: number;
  maxWritesPerMonth: number;
  maxReadsPerMonth: number;
  softLimitPercent: number;
  hardLimitPercent: number;
}

export interface BudgetCheckResult {
  allowed: boolean;
  severity: "ok" | "soft" | "hard" | "blocked";
  message: string;
  usage: {
    storageGB: number;
    storagePercent: number;
    writesThisMonth: number;
    writesPercent: number;
    readsThisMonth: number;
  };
  meta: BudgetMeta;
}

const BUDGET_KEY = "_meta/budget.json";

function currentMonth(): string {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

export const DEFAULT_LIMITS: BudgetLimits = {
  maxStorageBytes: 9 * 1024 ** 3,   // 9 GB
  maxWritesPerMonth: 9_000_000,
  maxReadsPerMonth: 10_000_000,
  softLimitPercent: 80,
  hardLimitPercent: 95,
};

function freshMeta(month: string): BudgetMeta {
  return {
    storageBytes: 0, writesThisMonth: 0, readsThisMonth: 0,
    currentMonth: month, lastUpdated: new Date().toISOString(), circuitBreaker: false,
  };
}

async function readMeta(bucket: R2Bucket): Promise<BudgetMeta> {
  try {
    const obj = await bucket.get(BUDGET_KEY);
    if (!obj) return freshMeta(currentMonth());
    const meta: BudgetMeta = await obj.json();
    if (meta.currentMonth !== currentMonth()) return freshMeta(currentMonth());
    return meta;
  } catch {
    return freshMeta(currentMonth());
  }
}

async function writeMeta(bucket: R2Bucket, meta: BudgetMeta): Promise<void> {
  meta.lastUpdated = new Date().toISOString();
  await bucket.put(BUDGET_KEY, JSON.stringify(meta, null, 2), {
    httpMetadata: { contentType: "application/json" },
    customMetadata: { purpose: "budget-tracking" },
  });
}

function pct(current: number, max: number): number {
  if (max === 0) return 100;
  return Math.round((current / max) * 10000) / 100;
}

function round4(n: number): number {
  return Math.round(n * 10000) / 10000;
}

function bytesToGB(b: number): number {
  return round4(b / 1024 ** 3);
}

function usage(bm: BudgetMeta, lim: BudgetLimits, bytesDelta: number, op: "write" | "read") {
  const storage = bm.storageBytes + bytesDelta;
  const writes = op === "write" ? bm.writesThisMonth + 1 : bm.writesThisMonth;
  const reads = op === "read" ? bm.readsThisMonth + 1 : bm.readsThisMonth;
  return {
    storageGB: bytesToGB(storage),
    storagePercent: pct(storage, lim.maxStorageBytes),
    writesThisMonth: writes,
    writesPercent: pct(writes, lim.maxWritesPerMonth),
    readsThisMonth: reads,
  };
}

// ── Public API ──────────────────────────────────────────────────────────

/** Kiểm tra budget trước khi thực hiện operation. */
export async function checkBudget(
  bucket: R2Bucket, operation: "write" | "read", bytesDelta: number,
  limits: BudgetLimits = DEFAULT_LIMITS,
): Promise<BudgetCheckResult> {
  const meta = await readMeta(bucket);
  const u = usage(meta, limits, bytesDelta, operation);

  if (operation === "write" && meta.circuitBreaker) {
    return { allowed: false, severity: "blocked",
      message: `Circuit breaker ON: ${meta.blockedReason ?? "manual"}`, usage: u, meta };
  }

  // Only block writes on storage/writes limits — reads are always allowed
  if (operation === "write") {
    if (u.storagePercent >= limits.hardLimitPercent || u.writesPercent >= limits.hardLimitPercent) {
      const reason = u.storagePercent >= limits.hardLimitPercent
        ? `Storage ${u.storagePercent}% >= ${limits.hardLimitPercent}%`
        : `Writes ${u.writesPercent}% >= ${limits.hardLimitPercent}%`;
      return { allowed: false, severity: "hard",
        message: `⛔ R2 HARD LIMIT: ${reason}. Writes blocked.`, usage: u, meta };
    }

    if (u.storagePercent >= limits.softLimitPercent || u.writesPercent >= limits.softLimitPercent) {
      const warnings: string[] = [];
      if (u.storagePercent >= limits.softLimitPercent) warnings.push(`Storage ${u.storagePercent}%`);
      if (u.writesPercent >= limits.softLimitPercent) warnings.push(`Writes ${u.writesPercent}%`);
      return { allowed: true, severity: "soft",
        message: `⚠️ R2 SOFT LIMIT: ${warnings.join(", ")}`, usage: u, meta };
    }
  }

  return { allowed: true, severity: "ok", message: "✅ R2 budget OK", usage: u, meta };
}

/** Ghi có guard — trả về success + budget info. */
export async function guardedPut(
  bucket: R2Bucket, key: string, value: string | ArrayBuffer, options: R2PutOptions,
  limits: BudgetLimits = DEFAULT_LIMITS,
): Promise<{ success: boolean; budget: BudgetCheckResult }> {
  const bytesDelta = typeof value === "string"
    ? new TextEncoder().encode(value).byteLength
    : value.byteLength;

  const budget = await checkBudget(bucket, "write", bytesDelta, limits);
  if (!budget.allowed) {
    console.error(JSON.stringify({ event: "r2_budget_blocked", key, ...budget.usage }));
    return { success: false, budget };
  }
  if (budget.severity === "soft") {
    console.warn(JSON.stringify({ event: "r2_budget_warning", key, ...budget.usage }));
  }

  await bucket.put(key, value, options);

  // Cập nhật counters
  const meta = await readMeta(bucket);
  meta.storageBytes += bytesDelta;
  meta.writesThisMonth += 1;
  await writeMeta(bucket, meta);

  return { success: true, budget };
}

/** Ghi nhận một lần đọc. */
export async function recordRead(bucket: R2Bucket): Promise<void> {
  const meta = await readMeta(bucket);
  meta.readsThisMonth += 1;
  await writeMeta(bucket, meta);
}

/** Bật circuit breaker — chặn tất cả writes. */
export async function activateCircuitBreaker(bucket: R2Bucket, reason: string): Promise<void> {
  const meta = await readMeta(bucket);
  meta.circuitBreaker = true;
  meta.blockedReason = reason;
  await writeMeta(bucket, meta);
  console.error(JSON.stringify({ event: "r2_circuit_breaker_on", reason }));
}

/** Tắt circuit breaker. */
export async function deactivateCircuitBreaker(bucket: R2Bucket): Promise<void> {
  const meta = await readMeta(bucket);
  meta.circuitBreaker = false;
  meta.blockedReason = undefined;
  await writeMeta(bucket, meta);
}

/** Parse limits từ env vars. */
export function parseLimits(env: Record<string, string | undefined>): BudgetLimits {
  return {
    maxStorageBytes: parseInt(env.R2_MAX_STORAGE_BYTES ?? "", 10) || DEFAULT_LIMITS.maxStorageBytes,
    maxWritesPerMonth: parseInt(env.R2_MAX_WRITES_MONTH ?? "", 10) || DEFAULT_LIMITS.maxWritesPerMonth,
    maxReadsPerMonth: parseInt(env.R2_MAX_READS_MONTH ?? "", 10) || DEFAULT_LIMITS.maxReadsPerMonth,
    softLimitPercent: parseInt(env.R2_SOFT_LIMIT_PERCENT ?? "", 10) || DEFAULT_LIMITS.softLimitPercent,
    hardLimitPercent: parseInt(env.R2_HARD_LIMIT_PERCENT ?? "", 10) || DEFAULT_LIMITS.hardLimitPercent,
  };
}
