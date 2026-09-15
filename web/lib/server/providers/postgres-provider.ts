/**
 * PostgreSQL primary database provider.
 * Uses Prisma to read from the primary database.
 */
import type { LotteryDraw, Region } from "../../lottery-domain";
import { listStoredDraws } from "../draw-repository";
import type { LotteryProvider } from "./types";

async function fetchRegion(region: Region, from?: string, to?: string, limit?: number): Promise<LotteryDraw[]> {
  const stored = await listStoredDraws({ region, from, to, limit: limit ?? 500 });
  return stored?.draws ?? [];
}

export const postgresProvider: LotteryProvider = {
  code: "postgresql",
  name: "PostgreSQL (Primary)",

  async fetchXSMB(options) { return fetchRegion("Miền Bắc", options?.from, options?.to, options?.limit); },
  async fetchXSMN(options) { return fetchRegion("Miền Nam", options?.from, options?.to, options?.limit); },
  async fetchXSMT(options) { return fetchRegion("Miền Trung", options?.from, options?.to, options?.limit); },
  async fetchByDate(region, date) { return fetchRegion(region, date, date); },
  async fetchHistory(region, from, to) { return fetchRegion(region, from, to); },

  async healthCheck() {
    const start = Date.now();
    try {
      const stored = await listStoredDraws({ limit: 1 });
      return { reachable: true, latencyMs: Date.now() - start, details: { drawCount: stored?.total ?? 0 } };
    } catch {
      return { reachable: false, latencyMs: Date.now() - start };
    }
  },
};
