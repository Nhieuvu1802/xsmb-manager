/**
 * Legal/official lottery data provider adapter.
 * Uses LOTTERY_PROVIDER_URL + LOTTERY_PROVIDER_TOKEN from env.
 */
import type { LotteryDraw, Region } from "../../lottery-domain";
import { fetchLegalProvider, providerRecordsToDraws } from "../provider";
import type { LotteryProvider } from "./types";

const TIMEOUT_MS = 25_000;

async function fetchRegion(region: Region, from?: string, to?: string, limit?: number): Promise<LotteryDraw[]> {
  const today = to ?? new Date().toISOString().slice(0, 10);
  const startDate = from ?? (() => {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    return d.toISOString().slice(0, 10);
  })();

  const payload = await fetchLegalProvider(startDate, today);
  if (!payload) return [];

  let draws = providerRecordsToDraws(payload.records).filter((d) => d.region === region);
  if (limit) draws = draws.slice(0, limit);
  return draws;
}

export const legalProvider: LotteryProvider = {
  code: "legal-provider",
  name: "Legal Provider API",

  async fetchXSMB(options) { return fetchRegion("Miền Bắc", options?.from, options?.to, options?.limit); },
  async fetchXSMN(options) { return fetchRegion("Miền Nam", options?.from, options?.to, options?.limit); },
  async fetchXSMT(options) { return fetchRegion("Miền Trung", options?.from, options?.to, options?.limit); },
  async fetchByDate(region, date) { return fetchRegion(region, date, date); },
  async fetchHistory(region, from, to) { return fetchRegion(region, from, to); },

  async healthCheck() {
    const configuredUrl = process.env.LOTTERY_PROVIDER_URL?.trim();
    if (!configuredUrl) return { reachable: false };
    const start = Date.now();
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
      const response = await fetch(configuredUrl, { signal: controller.signal, method: "HEAD", cache: "no-store" });
      clearTimeout(timer);
      return { reachable: response.ok, latencyMs: Date.now() - start };
    } catch {
      return { reachable: false, latencyMs: Date.now() - start };
    }
  },
};
