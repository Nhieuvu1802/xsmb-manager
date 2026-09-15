import { NextResponse } from "next/server";
import type { Region } from "@/lib/lottery-domain";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import { cacheGetOrSet } from "@/lib/server/cache";
import { getNumberFrequencies, getTrendTimeline } from "@/lib/server/trend-repository";
import { buildTrend, calculateNumberStats } from "@/lib/statistics";
import { fetchWorkerHistory } from "@/lib/worker-api-client";

const VALID_REGIONS: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"];

export async function GET(request: Request) {
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const region = (params.region as Region) || "Miền Bắc";

  if (!VALID_REGIONS.includes(region)) {
    return NextResponse.json({ error: "Miền không hợp lệ." }, { status: 422 });
  }

  const limit = Math.min(Math.max(Number(params.limit) || 30, 5), 365);
  const trackedNumbers = params.numbers
    ? params.numbers.split(",").map((number) => number.trim().padStart(2, "0")).filter((number) => /^\d{2}$/.test(number))
    : [];
  const trackedKey = [...trackedNumbers].sort().join(",") || "all";

  const payload = await cacheGetOrSet(`stats:trend:${region}:${limit}:${trackedKey}`, async () => {
    let databaseFrequencies: Awaited<ReturnType<typeof getNumberFrequencies>> = [];
    let databaseTimeline: Awaited<ReturnType<typeof getTrendTimeline>> = [];
    try {
      [databaseFrequencies, databaseTimeline] = await Promise.all([
        getNumberFrequencies(region),
        getTrendTimeline(region, trackedNumbers, limit),
      ]);
    } catch (error) {
      console.error("PostgreSQL không khả dụng cho trend.", error);
    }

    if (databaseFrequencies.length) {
      return {
        region,
        frequencies: databaseFrequencies,
        timeline: databaseTimeline,
        limit,
        trackedNumbers,
        storage: "postgres" as const,
      };
    }

    let draws = SAMPLE_DRAWS.filter((draw) => draw.region === region);
    let storage: "worker" | "sample" = "sample";
    try {
      const workerDraws = await fetchWorkerHistory(region);
      if (workerDraws.length) {
        draws = workerDraws;
        storage = "worker";
      }
    } catch (error) {
      console.error("Worker API không khả dụng cho trend.", error);
    }

    const window = draws.slice(0, limit);
    const frequencies = calculateNumberStats(window).map(({ number, count, drawHits }) => ({ number, count, drawHits }));
    const selectedNumbers = trackedNumbers.length ? trackedNumbers : frequencies.map((item) => item.number);
    const timeline = buildTrend(window, selectedNumbers);
    return { region, frequencies, timeline, limit, trackedNumbers, storage };
  }, 300);

  return NextResponse.json(payload, {
    headers: { "Cache-Control": "public, max-age=300" },
  });
}
