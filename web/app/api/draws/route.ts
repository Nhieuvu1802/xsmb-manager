import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import type { LotteryDraw, Region } from "@/lib/lottery-domain";
import { listStoredDraws } from "@/lib/server/draw-repository";
import { fetchWorkerHistory } from "@/lib/worker-api-client";
import { stationMatches } from "@/lib/stations";
import { fetchBackupDraws } from "@/lib/server/backup-api";

const VALID_REGIONS: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"];
const VALID_TYPES: LotteryDraw["lotteryType"][] = ["TRADITIONAL", "COMBINATION"];

export async function GET(request: Request) {
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const region = VALID_REGIONS.includes(params.region as Region) ? (params.region as Region) : undefined;
  const lotteryType = VALID_TYPES.includes(params.type as LotteryDraw["lotteryType"])
    ? (params.type as LotteryDraw["lotteryType"])
    : undefined;
  const station = params.station?.trim() || undefined;
  const from = params.from;
  const to = params.to;
  const includeResults = params.includeResults === "true";
  const limit = Math.min(Math.max(Number(params.limit) || 50, 1), 5000);
  const offset = Math.max(Number(params.offset) || 0, 0);

  let storage: "postgres" | "worker" | "backup" | "sample" = "sample";
  let total = 0;
  let draws: LotteryDraw[] = [];

  // Priority 1: PostgreSQL (if configured)
  try {
    const stored = await listStoredDraws({ region, lotteryType, station, from, to, limit, offset });
    if (stored?.total) {
      storage = "postgres";
      total = stored.total;
      draws = stored.draws;
    }
  } catch (error) {
    console.error("Không đọc được PostgreSQL.", error);
  }

  // Priority 2: Cloudflare Worker API (always available, real data)
  if (storage === "sample" && region) {
    try {
      const workerDraws = await fetchWorkerHistory(region, from, to);
      if (workerDraws.length > 0) {
        storage = "worker";
        let filtered = [...workerDraws];
        if (station) filtered = filtered.filter((draw) => stationMatches(draw.station, station));
        if (lotteryType) filtered = filtered.filter((d) => d.lotteryType === lotteryType);
        total = filtered.length;
        draws = filtered.slice(offset, offset + limit);
      }
    } catch (error) {
      console.error("Worker API không khả dụng.", error);
    }
  }

  // Priority 3: InfinityFree read-only backup. Client secrets are never involved.
  if (storage === "sample" && process.env.BACKUP_API_URL) {
    try {
      const backupDraws = await fetchBackupDraws({ region, from, to, limit: limit + offset });
      if (backupDraws.length > 0) {
        storage = "backup";
        let filtered = station ? backupDraws.filter((draw) => stationMatches(draw.station, station)) : backupDraws;
        if (lotteryType) filtered = filtered.filter((draw) => draw.lotteryType === lotteryType);
        total = filtered.length;
        draws = filtered.slice(offset, offset + limit);
      }
    } catch (error) {
      console.error("Backup API is unavailable.", error);
    }
  }

  // Priority 4: bundled stale cache/sample data
  if (storage === "sample") {
    let sample = [...SAMPLE_DRAWS];
    if (region) sample = sample.filter((draw) => draw.region === region);
    if (lotteryType) sample = sample.filter((draw) => draw.lotteryType === lotteryType);
    if (station) sample = sample.filter((draw) => stationMatches(draw.station, station));
    if (from) sample = sample.filter((draw) => draw.date >= from);
    if (to) sample = sample.filter((draw) => draw.date <= to);
    total = sample.length;
    draws = sample.slice(offset, offset + limit);
  }

  return NextResponse.json(
    {
      draws: draws.map((draw) => ({
        id: draw.id,
        drawCode: draw.drawCode,
        lotteryType: draw.lotteryType,
        date: draw.date,
        drawnAt: draw.drawnAt,
        region: draw.region,
        station: draw.station,
        source: draw.source,
        collectedAt: draw.collectedAt,
        verification: draw.verification,
        resultCount: draw.results.length,
        ...(includeResults ? { results: draw.results } : {}),
      })),
      total,
      hasMore: offset + limit < total,
      storage,
      stale: storage === "sample",
      updatedAt: draws[0]?.collectedAt ?? null,
    },
    { headers: { "Cache-Control": "public, s-maxage=300, stale-while-revalidate=900" } },
  );
}
