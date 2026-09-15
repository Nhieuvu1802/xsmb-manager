/**
 * Source health scoring system.
 * Computes a 0-100 score for each data source based on success/failure ratio,
 * response time, and recency. Prioritizes stable + fast + valid sources.
 */

export type HealthRecord = {
  code: string;
  name: string;
  successCount: number;
  failureCount: number;
  averageResponseTimeMs: number;
  lastSuccessMs: number | null;
  lastFailureMs: number | null;
};

/**
 * Health score formula:
 * - Success rate (0-60 points): successCount / total * 60
 * - Speed (0-25 points): faster = more points. 0ms → 25, ≥5000ms → 0
 * - Recency (0-15 points): 15 if success < 60s ago, 0 if never succeeded
 */
export function computeHealthScore(record: HealthRecord): number {
  const total = record.successCount + record.failureCount;
  if (total === 0) return 0;

  // Success rate: 0-60
  const successRate = record.successCount / total;
  const rateScore = successRate * 60;

  // Speed: 0-25. Linear decay from 0ms (25 pts) to 5000ms (0 pts)
  const speedScore = Math.max(0, (1 - record.averageResponseTimeMs / 5000)) * 25;

  // Recency: 0-15. Full points if last success < 60s ago
  let recencyScore = 0;
  if (record.lastSuccessMs !== null) {
    const age = Date.now() - record.lastSuccessMs;
    recencyScore = age < 60_000 ? 15 : age < 300_000 ? 10 : age < 3600_000 ? 5 : 0;
  }

  return Math.round(rateScore + speedScore + recencyScore);
}

/**
 * Record a success for a source.
 * Returns updated counts.
 */
export function recordSuccess(
  prev: { successCount: number; failureCount: number; totalResponseTimeMs: number },
  responseTimeMs: number,
) {
  const successCount = prev.successCount + 1;
  const totalResponseTimeMs = prev.totalResponseTimeMs + responseTimeMs;
  return { successCount, failureCount: prev.failureCount, totalResponseTimeMs };
}

/**
 * Record a failure for a source.
 */
export function recordFailure(prev: { successCount: number; failureCount: number; totalResponseTimeMs: number }) {
  return { successCount: prev.successCount, failureCount: prev.failureCount + 1, totalResponseTimeMs: prev.totalResponseTimeMs };
}
