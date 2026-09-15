import type { LotteryDraw, Region } from "../../lottery-domain";

/**
 * Unified data provider interface.
 * Each source implements this so the chain can swap them transparently.
 */
export interface LotteryProvider {
  /** Unique code for health tracking (e.g. "legal-provider", "worker-api", "backup-infinityfree"). */
  readonly code: string;
  /** Human-readable name. */
  readonly name: string;

  fetchXSMB(options?: { from?: string; to?: string; limit?: number }): Promise<LotteryDraw[]>;
  fetchXSMN(options?: { from?: string; to?: string; limit?: number }): Promise<LotteryDraw[]>;
  fetchXSMT(options?: { from?: string; to?: string; limit?: number }): Promise<LotteryDraw[]>;
  fetchByDate(region: Region, date: string): Promise<LotteryDraw[]>;
  fetchHistory(region: Region, from?: string, to?: string): Promise<LotteryDraw[]>;
  healthCheck(): Promise<{ reachable: boolean; latencyMs?: number; details?: Record<string, unknown> }>;
}

export type ProviderHealth = {
  code: string;
  name: string;
  score: number; // 0-100
  successCount: number;
  failureCount: number;
  averageResponseTime: number;
  lastSuccess: string | null;
  lastFailure: string | null;
  healthy: boolean;
};

export type ProviderResult<T> = {
  data: T;
  source: string;
  stale: boolean;
  latencyMs: number;
};
