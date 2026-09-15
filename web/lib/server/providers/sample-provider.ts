/**
 * Sample data fallback provider.
 * Uses bundled sample data. Always succeeds (stale=true).
 */
import type { LotteryDraw, Region } from "../../lottery-domain";
import { SAMPLE_DRAWS } from "../../sample-data";
import type { LotteryProvider } from "./types";

function filterByRegion(region: Region): LotteryDraw[] {
  return SAMPLE_DRAWS.filter((d) => d.region === region);
}

export const sampleProvider: LotteryProvider = {
  code: "sample-data",
  name: "Bundled Sample Data",

  async fetchXSMB(options) {
    const draws = filterByRegion("Miền Bắc");
    return options?.limit ? draws.slice(0, options.limit) : draws;
  },
  async fetchXSMN(options) {
    const draws = filterByRegion("Miền Nam");
    return options?.limit ? draws.slice(0, options.limit) : draws;
  },
  async fetchXSMT(options) {
    const draws = filterByRegion("Miền Trung");
    return options?.limit ? draws.slice(0, options.limit) : draws;
  },
  async fetchByDate(region, date) {
    return SAMPLE_DRAWS.filter((d) => d.region === region && d.date === date);
  },
  async fetchHistory(region, from, to) {
    return SAMPLE_DRAWS.filter((d) =>
      d.region === region && (!from || d.date >= from) && (!to || d.date <= to),
    );
  },
  async healthCheck() {
    return { reachable: true, latencyMs: 0, details: { draws: SAMPLE_DRAWS.length } };
  },
};
