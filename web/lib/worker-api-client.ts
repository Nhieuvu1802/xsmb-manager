import type { LotteryDraw, Region } from "./lottery-domain";
import { canonicalStationName } from "./stations";

/**
 * Cloudflare Worker API client.
 * Converts Worker API responses into the app's internal LotteryDraw format.
 *
 * Base URL: https://xsmb-api.nhieuvu1802.workers.dev
 * Endpoints: /v1/xsmb/history, /v1/xsmn/history, /v1/xsmb/latest, /v1/xsmn/latest
 */

const WORKER_BASE = process.env.WORKER_API_URL || "https://xsmb-api.nhieuvu1802.workers.dev";
const TIMEOUT_MS = 8_000;

const REGION_MAP: Record<string, Region> = {
  mb: "Miền Bắc",
  mn: "Miền Nam",
  mt: "Miền Trung",
};

type WorkerPrize = { prize: string; position: number; value: string };

type WorkerDraw = {
  region: string;
  date: string;
  station: string;
  source: string;
  verification: string;
  collected_at: string;
  draw_code: string;
  results: WorkerPrize[];
};

type WorkerHistoryResponse = {
  success?: boolean;
  draws: WorkerDraw[];
  region: string;
  regionLabel?: string;
};

type WorkerLatestResponse = {
  success?: boolean;
  draws: WorkerDraw[];
  region: string;
  regionLabel?: string;
};

function regionKey(region: Region): string {
  if (region === "Miền Bắc") return "mb";
  if (region === "Miền Nam") return "mn";
  return "mt";
}

function drawTime(region: Region): string {
  return region === "Miền Bắc" ? "18:15" : region === "Miền Trung" ? "17:15" : "16:15";
}

function mapDraw(raw: WorkerDraw): LotteryDraw | null {
  const region = REGION_MAP[raw.region];
  if (!region) return null;

  const date = raw.date;
  const drawnAt = `${date}T${drawTime(region)}:00+07:00`;

  return {
    id: `worker-${raw.draw_code}`,
    drawCode: raw.draw_code,
    lotteryType: "TRADITIONAL",
    date,
    drawnAt,
    region,
    station: canonicalStationName(raw.station, region),
    source: raw.source || "Cloudflare Worker API",
    collectedAt: raw.collected_at || new Date().toISOString(),
    verification: raw.verification === "VERIFIED" ? "VERIFIED" : "PENDING",
    results: raw.results.map((r) => ({
      prize: r.prize,
      position: r.position,
      value: r.value,
    })),
  };
}

async function fetchWithTimeout(url: string, signal?: AbortSignal): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

  // Combine external abort signal if provided
  if (signal) {
    signal.addEventListener("abort", () => controller.abort());
  }

  try {
    return await fetch(url, { signal: controller.signal, next: { revalidate: 300 } });
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Fetch history from the Worker API for a given region.
 * If start/end are not specified, fetches all available history.
 */
export async function fetchWorkerHistory(
  region: Region,
  start?: string,
  end?: string,
): Promise<LotteryDraw[]> {
  const key = regionKey(region);
  const params = new URLSearchParams();
  if (start) params.set("start", start);
  if (end) params.set("end", end);
  const qs = params.toString();
  const url = `${WORKER_BASE}/v1/${key === "mb" ? "xsmb" : key === "mn" ? "xsmn" : "xsmt"}/history${qs ? `?${qs}` : ""}`;

  try {
    const response = await fetchWithTimeout(url);
    if (!response.ok) return [];
    const body: WorkerHistoryResponse = await response.json();
    if (!body.draws?.length) return [];

    return body.draws
      .map(mapDraw)
      .filter((d): d is LotteryDraw => d !== null)
      .sort((a, b) => b.date.localeCompare(a.date));
  } catch (error) {
    console.error(`Worker API history fetch failed (${region}):`, error);
    return [];
  }
}

/**
 * Fetch latest draws from the Worker API for a given region.
 * Returns up to the number of draws the API provides (typically 7 for XSMB, 22 for XSMN).
 */
export async function fetchWorkerLatest(region: Region): Promise<LotteryDraw[]> {
  const key = regionKey(region);
  const url = `${WORKER_BASE}/v1/${key === "mb" ? "xsmb" : key === "mn" ? "xsmn" : "xsmt"}/latest`;

  try {
    const response = await fetchWithTimeout(url);
    if (!response.ok) return [];
    const body: WorkerLatestResponse = await response.json();
    if (!body.draws?.length) return [];

    return body.draws
      .map(mapDraw)
      .filter((d): d is LotteryDraw => d !== null)
      .sort((a, b) => b.date.localeCompare(a.date));
  } catch (error) {
    console.error(`Worker API latest fetch failed (${region}):`, error);
    return [];
  }
}

/**
 * Check if the Worker API is reachable.
 */
export async function checkWorkerHealth(): Promise<{
  reachable: boolean;
  xsmbDraws?: number;
  xsmnDraws?: number;
  latestDate?: string;
}> {
  try {
    const response = await fetchWithTimeout(`${WORKER_BASE}/v1/health`);
    if (!response.ok) return { reachable: false };
    const body = await response.json() as {
      history?: { xsmb?: { draws?: number }; xsmn?: { draws?: number } };
    };
    return {
      reachable: true,
      xsmbDraws: body.history?.xsmb?.draws,
      xsmnDraws: body.history?.xsmn?.draws,
    };
  } catch {
    return { reachable: false };
  }
}
