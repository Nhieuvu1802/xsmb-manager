/**
 * Cloudflare Worker API provider adapter.
 * Wraps the existing worker-api-client with the LotteryProvider interface.
 */
import { fetchWorkerHistory, checkWorkerHealth } from "../../worker-api-client";
import type { LotteryProvider } from "./types";

export const workerProvider: LotteryProvider = {
  code: "worker-api",
  name: "Cloudflare Worker API",

  async fetchXSMB(options) {
    const draws = await fetchWorkerHistory("Miền Bắc", options?.from, options?.to);
    return options?.limit ? draws.slice(0, options.limit) : draws;
  },
  async fetchXSMN(options) {
    const draws = await fetchWorkerHistory("Miền Nam", options?.from, options?.to);
    return options?.limit ? draws.slice(0, options.limit) : draws;
  },
  async fetchXSMT(options) {
    const draws = await fetchWorkerHistory("Miền Trung", options?.from, options?.to);
    return options?.limit ? draws.slice(0, options.limit) : draws;
  },
  async fetchByDate(region, date) {
    const draws = await fetchWorkerHistory(region, date, date);
    return draws;
  },
  async fetchHistory(region, from, to) {
    return fetchWorkerHistory(region, from, to);
  },

  async healthCheck() {
    const result = await checkWorkerHealth();
    return {
      reachable: result.reachable,
      details: {
        xsmbDraws: result.xsmbDraws ?? null,
        xsmnDraws: result.xsmnDraws ?? null,
        latestDate: result.latestDate ?? null,
      },
    };
  },
};
