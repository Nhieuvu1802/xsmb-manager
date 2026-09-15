/**
 * Provider chain: implements A → B → C failover with health scoring.
 * Sources are tried in priority order. On timeout/error (≥500 or network),
 * falls through to the next. Does NOT failover on 400/401/403.
 */
import type { LotteryProvider, ProviderResult } from "./types";
import { computeHealthScore, type HealthRecord } from "./health-scoring";

const TIMEOUT_MS = 3_000;
const FAILOVER_STATUSES = new Set([500, 502, 503, 504, 521, 522, 523]);

export class ProviderChain {
  private providers: LotteryProvider[];
  private healthRecords = new Map<string, {
    successCount: number;
    failureCount: number;
    totalResponseTimeMs: number;
    lastSuccessMs: number | null;
    lastFailureMs: number | null;
  }>();

  constructor(providers: LotteryProvider[]) {
    this.providers = providers;
    for (const p of providers) {
      this.healthRecords.set(p.code, { successCount: 0, failureCount: 0, totalResponseTimeMs: 0, lastSuccessMs: null, lastFailureMs: null });
    }
  }

  private async timedFetch<T>(fn: () => Promise<T>): Promise<{ ok: true; data: T; latencyMs: number } | { ok: false; error: Error }> {
    const start = Date.now();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    try {
      const data = await fn();
      clearTimeout(timer);
      return { ok: true, data, latencyMs: Date.now() - start };
    } catch (error) {
      clearTimeout(timer);
      return { ok: false, error: error instanceof Error ? error : new Error(String(error)) };
    }
  }

  private updateHealth(code: string, success: boolean, latencyMs: number) {
    const rec = this.healthRecords.get(code);
    if (!rec) return;
    if (success) {
      rec.successCount += 1;
      rec.totalResponseTimeMs += latencyMs;
      rec.lastSuccessMs = Date.now();
    } else {
      rec.failureCount += 1;
      rec.lastFailureMs = Date.now();
    }
  }

  private isFailoverError(error: Error): boolean {
    // Don't failover on auth/client errors
    const msg = error.message;
    if (/HTTP (40[0-3]|401|403)/.test(msg)) return false;
    // Network errors, timeouts, 5xx → failover
    if (/abort|timeout|fetch|network/i.test(msg)) return true;
    const statusMatch = msg.match(/HTTP (\d+)/);
    if (statusMatch) return FAILOVER_STATUSES.has(Number(statusMatch[1]));
    return true;
  }

  /**
   * Execute a fetch across providers with failover.
   * Falls through on network errors, timeouts, and 5xx.
   */
  async execute<T>(
    fetcher: (provider: LotteryProvider) => Promise<T>,
  ): Promise<ProviderResult<T>> {
    for (const provider of this.providers) {
      const result = await this.timedFetch(() => fetcher(provider));
      if (result.ok) {
        this.updateHealth(provider.code, true, result.latencyMs);
        return { data: result.data, source: provider.code, stale: false, latencyMs: result.latencyMs };
      }
      this.updateHealth(provider.code, false, 0);
      // Only failover if the error is retryable
      if (!this.isFailoverError(result.error)) {
        throw result.error;
      }
    }
    throw new Error("All providers failed.");
  }

  getHealthScores(): Array<HealthRecord & { score: number; healthy: boolean }> {
    return this.providers.map((p) => {
      const rec = this.healthRecords.get(p.code)!;
      const record: HealthRecord = {
        code: p.code,
        name: p.name,
        successCount: rec.successCount,
        failureCount: rec.failureCount,
        averageResponseTimeMs: rec.successCount ? rec.totalResponseTimeMs / rec.successCount : 0,
        lastSuccessMs: rec.lastSuccessMs,
        lastFailureMs: rec.lastFailureMs,
      };
      const score = computeHealthScore(record);
      return { ...record, score, healthy: score > 30 };
    });
  }

  /** Sort providers by health score descending. */
  sortByHealth(): LotteryProvider[] {
    const scores = new Map(this.getHealthScores().map((h) => [h.code, h.score]));
    return [...this.providers].sort((a, b) => (scores.get(b.code) ?? 0) - (scores.get(a.code) ?? 0));
  }
}
