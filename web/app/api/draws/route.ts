import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import type { Region } from "@/lib/lottery-domain";

const VALID_REGIONS: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"];

export async function GET(request: Request) {
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const region = params.region as Region | undefined;
  const type = params.type;
  const station = params.station;
  const from = params.from;
  const to = params.to;
  const limit = Math.min(Math.max(Number(params.limit) || 50, 1), 100);
  const offset = Math.max(Number(params.offset) || 0, 0);

  let draws = [...SAMPLE_DRAWS];

  if (region && VALID_REGIONS.includes(region)) {
    draws = draws.filter((d) => d.region === region);
  }
  if (type) {
    draws = draws.filter((d) => d.lotteryType === type);
  }
  if (station) {
    draws = draws.filter((d) => d.station.toLowerCase().includes(station.toLowerCase()));
  }
  if (from) {
    draws = draws.filter((d) => d.date >= from);
  }
  if (to) {
    draws = draws.filter((d) => d.date <= to);
  }

  const total = draws.length;
  const paged = draws.slice(offset, offset + limit);

  return NextResponse.json(
    {
      draws: paged.map((d) => ({
        id: d.id,
        drawCode: d.drawCode,
        lotteryType: d.lotteryType,
        date: d.date,
        drawnAt: d.drawnAt,
        region: d.region,
        station: d.station,
        source: d.source,
        verification: d.verification,
        resultCount: d.results.length,
      })),
      total,
      hasMore: offset + limit < total,
    },
    { headers: { "Cache-Control": "public, max-age=300" } }
  );
}
