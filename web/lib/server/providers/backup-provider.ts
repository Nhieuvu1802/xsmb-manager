/**
 * InfinityFree backup provider adapter.
 * Wraps backup-api.ts with the LotteryProvider interface.
 */
import { fetchBackupDraws, checkBackupHealth } from "../backup-api";
import type { LotteryProvider } from "./types";

export const backupProvider: LotteryProvider = {
  code: "backup-infinityfree",
  name: "InfinityFree Backup",

  async fetchXSMB(options) {
    if (!process.env.BACKUP_API_URL) return [];
    return fetchBackupDraws({ region: "Miền Bắc", from: options?.from, to: options?.to, limit: options?.limit ?? 100 });
  },
  async fetchXSMN(options) {
    if (!process.env.BACKUP_API_URL) return [];
    return fetchBackupDraws({ region: "Miền Nam", from: options?.from, to: options?.to, limit: options?.limit ?? 100 });
  },
  async fetchXSMT(options) {
    if (!process.env.BACKUP_API_URL) return [];
    return fetchBackupDraws({ region: "Miền Trung", from: options?.from, to: options?.to, limit: options?.limit ?? 100 });
  },
  async fetchByDate(region, date) {
    if (!process.env.BACKUP_API_URL) return [];
    return fetchBackupDraws({ region, from: date, to: date, limit: 100 });
  },
  async fetchHistory(region, from, to) {
    if (!process.env.BACKUP_API_URL) return [];
    return fetchBackupDraws({ region, from, to, limit: 500 });
  },
  async healthCheck() {
    if (!process.env.BACKUP_API_URL) return { reachable: false };
    const start = Date.now();
    try {
      const health = await checkBackupHealth();
      return {
        reachable: health.status === "online",
        latencyMs: Date.now() - start,
        details: health,
      };
    } catch {
      return { reachable: false, latencyMs: Date.now() - start };
    }
  },
};
