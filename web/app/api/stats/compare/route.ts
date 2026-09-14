import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import { compareWindows } from "@/lib/statistics";
import type { Region } from "@/lib/lottery-domain";
import { fetchWorkerHistory } from "@/lib/worker-api-client";
import { getNumberStatsFromDb } from "@/lib/server/trend-repository";
import { listStoredDraws } from "@/lib/server/draw-repository";

const VALID_REGIONS: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"];

export async function GET(request: Request) {
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const region = (params.region as Region) || "Miền Bắc";

  if (!VALID_REGIONS.includes(region)) {
    return NextResponse.json({ error: "Miền không hợp lệ." }, { status: 422 });
  }

  let draws = SAMPLE_DRAWS.filter((d) => d.region === region);
  let storage: "postgres" | "worker" | "sample" = "sample";

  // Priority 1: PostgreSQL with SQL-aggregated stats
  try {
    const dbStats = await getNumberStatsFromDb(region);
    if (dbStats) {
      // Use SQL-optimized path: fetch draws for window comparison
      const stored = await listStoredDraws({ region, limit: 365 });
      if (stored?.total) {
        draws = stored.draws;
        storage = "postgres";
      }
    }
  } catch (error) {
    console.error("PostgreSQL không khả dụng cho compare.", error);
  }

  // Priority 2: Worker API
  if (storage === "sample") {
    try {
      const workerDraws = await fetchWorkerHistory(region);
      if (workerDraws.length > 0) {
        draws = workerDraws;
        storage = "worker";
      }
    } catch (error) {
      console.error("Worker API không khả dụng cho compare.", error);
    }
  }

  const windows = compareWindows(draws);

  return NextResponse.json(
    { region, windows, storage, drawCount: draws.length },
    { headers: { "Cache-Control": "public, max-age=600" } }
  );
}
