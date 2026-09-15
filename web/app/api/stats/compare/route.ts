import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import { compareWindows } from "@/lib/statistics";
import type { Region } from "@/lib/lottery-domain";
import { fetchWorkerHistory } from "@/lib/worker-api-client";
import { cacheGetOrSet } from "@/lib/server/cache";
import { getNumberStatsFromDb } from "@/lib/server/trend-repository";
import { listStoredDraws } from "@/lib/server/draw-repository";

const VALID_REGIONS: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"];

export async function GET(request: Request) {
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const region = (params.region as Region) || "Miền Bắc";

  if (!VALID_REGIONS.includes(region)) {
    return NextResponse.json({ error: "Miền không hợp lệ." }, { status: 422 });
  }

  const payload = await cacheGetOrSet(`stats:compare:${region}`, async () => {
    let draws = SAMPLE_DRAWS.filter((draw) => draw.region === region);
    let storage: "postgres" | "worker" | "sample" = "sample";

    try {
      const databaseStats = await getNumberStatsFromDb(region);
      if (databaseStats) {
        const stored = await listStoredDraws({ region, limit: 365 });
        if (stored?.total) {
          draws = stored.draws;
          storage = "postgres";
        }
      }
    } catch (error) {
      console.error("PostgreSQL không khả dụng cho compare.", error);
    }

    if (storage === "sample") {
      try {
        const workerDraws = await fetchWorkerHistory(region);
        if (workerDraws.length) {
          draws = workerDraws;
          storage = "worker";
        }
      } catch (error) {
        console.error("Worker API không khả dụng cho compare.", error);
      }
    }

    return { region, windows: compareWindows(draws), storage, drawCount: draws.length };
  }, 600);

  return NextResponse.json(payload, {
    headers: { "Cache-Control": "public, max-age=600" },
  });
}
