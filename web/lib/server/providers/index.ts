/**
 * Provider registry.
 * Builds the provider chain based on environment configuration.
 * Priority: PostgreSQL (if DATABASE_URL) → Worker API → Legal Provider → Backup → Sample
 */
import type { Region } from "../../lottery-domain";
import type { LotteryProvider } from "./types";
import { ProviderChain } from "./chain";
import { postgresProvider } from "./postgres-provider";
import { workerProvider } from "./worker-provider";
import { legalProvider } from "./legal-provider";
import { backupProvider } from "./backup-provider";
import { sampleProvider } from "./sample-provider";

export type { LotteryProvider, ProviderResult, ProviderHealth } from "./types";
export { ProviderChain } from "./chain";
export { computeHealthScore } from "./health-scoring";

/** Build the default provider chain based on env config. */
export function buildProviderChain(): LotteryChain {
  const providers: LotteryProvider[] = [];

  // Primary: PostgreSQL (always first if configured)
  if (process.env.DATABASE_URL?.trim()) {
    providers.push(postgresProvider);
  }

  // Source A: Legal provider (if configured)
  if (process.env.LOTTERY_PROVIDER_URL?.trim()) {
    providers.push(legalProvider);
  }

  // Source B: Worker API (always available)
  providers.push(workerProvider);

  // Source C: Backup (if configured)
  if (process.env.BACKUP_API_URL?.trim()) {
    providers.push(backupProvider);
  }

  // Last resort: Sample data
  providers.push(sampleProvider);

  return new LotteryChain(providers);
}

/**
 * High-level lottery data fetcher with multi-source failover.
 * Wraps ProviderChain with region-aware fetch methods.
 */
export class LotteryChain {
  private chain: ProviderChain;

  constructor(providers: LotteryProvider[]) {
    this.chain = new ProviderChain(providers);
  }

  /** Fetch draws for a region from the best available source. */
  async fetchDraws(region: Region, options?: { from?: string; to?: string; limit?: number }) {
    return this.chain.execute(async (provider) => {
      if (region === "Miền Bắc") return provider.fetchXSMB(options);
      if (region === "Miền Nam") return provider.fetchXSMN(options);
      return provider.fetchXSMT(options);
    });
  }

  /** Get health scores for all configured providers. */
  getHealthScores() {
    return this.chain.getHealthScores();
  }

  /** Sort providers by health score. */
  sortByHealth() {
    return this.chain.sortByHealth();
  }
}
